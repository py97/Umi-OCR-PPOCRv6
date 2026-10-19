using System.Net;
using System.Text;
using System.Text.Json;
using Sdcb.SimdPaddleOCR;

namespace SimdOcrHost;

// ============================================================
// SimdPaddleOCR 本地 OCR 后端服务（供 Umi-OCR Python 端调用）
//
// 协议：
//   GET  /health              -> "ok"（就绪探针）
//   POST /ocr?width=&height=&stride=&format=bgr24
//        body = 原始交错像素缓冲区
//        -> 200 application/json
//           [{"text","score","x1","y1","x2","y2","x3","y3","x4","y4"}, ...]
//   POST /shutdown            -> 退出进程
//
// format: bgr24(默认) | rgb24 | bgra32 | rgba32
// 就绪时向 stdout 打印 "READY <port>" 并刷新。
// ============================================================
internal static class Program
{
    private const long IdleExitMs = 600_000; // 10 分钟无请求则自退（安全网，正常由 stop()/父进程守护）
    private static long _lastActivity = Environment.TickCount64;

    private static async Task<int> Main(string[] args)
    {
        string? det = null, cls = null, rec = null, keys = null;
        int port = 0;
        int parentPid = 0;
        string backend = "auto";   // auto | cpu | vulkan
        int limitSide = 960;
        bool useCls = true;
        int workers = 0;

        for (int i = 0; i < args.Length; i++)
        {
            switch (args[i])
            {
                case "--det":        det = Next(args, ref i); break;
                case "--cls":        cls = Next(args, ref i); break;
                case "--rec":        rec = Next(args, ref i); break;
                case "--keys":       keys = Next(args, ref i); break;
                case "--port":       int.TryParse(Next(args, ref i), out var p); port = p; break;
                case "--parent-pid": int.TryParse(Next(args, ref i), out var pp); parentPid = pp; break;
                case "--backend":    backend = Next(args, ref i) ?? "auto"; break;
                case "--limit-side": int.TryParse(Next(args, ref i), out var ls); limitSide = ls; break;
                case "--workers":    int.TryParse(Next(args, ref i), out var wk); workers = wk; break;
                case "--no-cls":     useCls = false; break;
            }
        }

        // 默认模型路径（相对可执行文件）：<plugin>/backend/SimdOcrHost.exe
        //                              -> <plugin>/models/ppocrv6-tiny/
        string baseDir = AppContext.BaseDirectory;
        string modelDir = Path.GetFullPath(Path.Combine(baseDir, "..", "models", "ppocrv6-tiny"));
        det  ??= Path.Combine(modelDir, "det.onnx");
        rec  ??= Path.Combine(modelDir, "rec.onnx");
        keys ??= Path.Combine(modelDir, "ppocr_keys.txt");
        if (useCls) cls ??= Path.Combine(modelDir, "cls.onnx"); else cls = null;

        foreach (var (label, path) in new[] { ("det", det!), ("rec", rec!), ("keys", keys!) })
        {
            if (!File.Exists(path))
            {
                Console.Error.WriteLine($"[SimdOcrHost] missing {label} model: {path}");
                return 2;
            }
        }
        if (useCls && (cls is null || !File.Exists(cls)))
        {
            Console.Error.WriteLine($"[SimdOcrHost] missing cls model: {cls}");
            return 2;
        }
        if (port <= 0)
        {
            Console.Error.WriteLine("[SimdOcrHost] --port required");
            return 2;
        }

        OcrBackend bk = backend.ToLowerInvariant() switch
        {
            "cpu" => OcrBackend.Cpu,
            "vulkan" => OcrBackend.Vulkan,
            _ => OcrBackend.Auto,
        };

        var opts = new PaddleOcrOptions
        {
            UseDirectionClassification = useCls,
            LineWorkerCount = workers,
            Detector    = new PaddleOcrDetectorOptions    { LimitSideLength = limitSide, Backend = bk },
            Classifier  = new PaddleOcrClassifierOptions  { Backend = bk },
            Recognizer  = new PaddleOcrRecognizerOptions  { Backend = bk },
        };

        PaddleOcrAll ocr;
        try
        {
            Console.WriteLine($"[SimdOcrHost] loading models (backend={backend}, limitSide={limitSide}, cls={useCls}) ...");
            var sw = System.Diagnostics.Stopwatch.StartNew();
            ocr = PaddleOcrAll.Load(det!, cls, rec!, keys!, opts);
            Console.WriteLine($"[SimdOcrHost] models loaded in {sw.ElapsedMilliseconds} ms.");
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"[SimdOcrHost] model load failed: {ex}");
            return 3;
        }

        using (ocr)
        {
            var listener = new HttpListener();
            listener.Prefixes.Add($"http://127.0.0.1:{port}/");
            try { listener.Start(); }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"[SimdOcrHost] listen failed on 127.0.0.1:{port}: {ex}");
                return 4;
            }

            var cts = new CancellationTokenSource();
            Console.CancelKeyPress += (s, e) =>
            {
                e.Cancel = true;
                try { listener.Stop(); } catch { }
                cts.Cancel();
            };

            Console.WriteLine($"READY {port}");
            Console.Out.Flush();

            // 守护线程：父进程消失或长时间空闲则自退，避免悬挂进程占用端口/内存。
            _ = Task.Run(async () =>
            {
                while (!cts.IsCancellationRequested)
                {
                    await Task.Delay(3000, cts.Token).ContinueWith(_ => { });
                    if (cts.IsCancellationRequested) break;
                    if (parentPid > 0 && !ParentAlive(parentPid)) { SelfExit(listener); return; }
                    if (Environment.TickCount64 - Interlocked.Read(ref _lastActivity) > IdleExitMs) { SelfExit(listener); return; }
                }
            });

            var gate = new SemaphoreSlim(1, 1);
            try
            {
                while (!cts.IsCancellationRequested)
                {
                    var ctx = await listener.GetContextAsync();
                    _ = Task.Run(() => Handle(ctx, ocr, gate, cts.Token), cts.Token);
                }
            }
            catch { /* listener stopped / cancelled */ }
            finally
            {
                try { listener.Stop(); } catch { }
                try { listener.Close(); } catch { }
            }
        }
        return 0;
    }

    private static string? Next(string[] args, ref int i)
        => (i + 1 < args.Length) ? args[++i] : null;

    private static bool ParentAlive(int pid)
    {
        try { using var p = System.Diagnostics.Process.GetProcessById(pid); return !p.HasExited; }
        catch { return false; }
    }

    private static void SelfExit(HttpListener listener)
    {
        Console.WriteLine("[SimdOcrHost] self-exit (parent gone or idle).");
        try { listener.Stop(); } catch { }
        Environment.Exit(0);
    }

    // 将 CTC argmax 平均 logit 归一化为 0~1 置信度（sigmoid，center≈12, temp≈8）：
    //   正确文本 logit≈30~44 -> ≈0.90~0.98；低置信 logit≈0~10 -> ≈0.18~0.50。
    private static float ToConfidence(float logitScore)
    {
        float v = 1f / (1f + MathF.Exp(-(logitScore - 12f) / 8f));
        return v < 0f ? 0f : (v > 1f ? 1f : v);
    }

    private static async Task Handle(HttpListenerContext ctx, PaddleOcrAll ocr, SemaphoreSlim gate, CancellationToken ct)
    {
        Interlocked.Exchange(ref _lastActivity, Environment.TickCount64);
        try
        {
            string path = ctx.Request.Url?.AbsolutePath ?? "/";
            string method = ctx.Request.HttpMethod;

            if (method == "GET" && path == "/health")
            {
                await WriteText(ctx, 200, "ok");
                return;
            }
            if (method == "POST" && path == "/shutdown")
            {
                await WriteText(ctx, 200, "bye");
                Environment.Exit(0);
                return;
            }
            if (method == "POST" && path == "/ocr")
            {
                var q = ctx.Request.QueryString;
                if (!int.TryParse(q["width"], out int w) || !int.TryParse(q["height"], out int h))
                {
                    await WriteText(ctx, 400, "missing/invalid width|height");
                    return;
                }
                int stride = int.TryParse(q["stride"], out int st) ? st : 0;
                string fmt = (q["format"] ?? "bgr24").ToLowerInvariant();
                ImagePixelFormat pf = fmt switch
                {
                    "rgb24"  => ImagePixelFormat.Rgb24,
                    "bgra32" => ImagePixelFormat.Bgra32,
                    "rgba32" => ImagePixelFormat.Rgba32,
                    _        => ImagePixelFormat.Bgr24,
                };

                byte[] body;
                using (var ms = new MemoryStream())
                {
                    await ctx.Request.InputStream.CopyToAsync(ms, ct);
                    body = ms.ToArray();
                }

                await gate.WaitAsync(ct);
                PaddleOcrResult result;
                try { result = ocr.Run(body, w, h, stride, pf); }
                finally { gate.Release(); }

                var lines = new List<Dictionary<string, object>>(result.Lines.Length);
                foreach (var line in result.Lines)
                {
                    var b = line.Box;
                    lines.Add(new Dictionary<string, object>
                    {
                        ["text"]  = line.Text,
                        // SimdPaddleOCR 的 RecognitionScore 是 CTC argmax 的平均对数几率
                        // （logit，正确文本约 30~44），并非 0~1 概率。为与 Umi-OCR 原引擎
                        // （0~1 置信度）及 UI 显示保持一致，这里用 sigmoid 归一化到 0~1。
                        ["score"] = ToConfidence(line.RecognitionScore),
                        ["x1"] = b.X1, ["y1"] = b.Y1,
                        ["x2"] = b.X2, ["y2"] = b.Y2,
                        ["x3"] = b.X3, ["y3"] = b.Y3,
                        ["x4"] = b.X4, ["y4"] = b.Y4,
                    });
                }
                byte[] payload = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(lines));
                ctx.Response.StatusCode = 200;
                ctx.Response.ContentType = "application/json";
                ctx.Response.ContentLength64 = payload.Length;
                await ctx.Response.OutputStream.WriteAsync(payload, ct);
                ctx.Response.OutputStream.Close();
                return;
            }

            await WriteText(ctx, 404, "not found");
        }
        catch (Exception ex)
        {
            try { await WriteText(ctx, 500, "error: " + ex.Message); } catch { }
        }
    }

    private static async Task WriteText(HttpListenerContext ctx, int code, string text)
    {
        byte[] payload = Encoding.UTF8.GetBytes(text);
        ctx.Response.StatusCode = code;
        ctx.Response.ContentType = "text/plain; charset=utf-8";
        ctx.Response.ContentLength64 = payload.Length;
        await ctx.Response.OutputStream.WriteAsync(payload);
        ctx.Response.OutputStream.Close();
    }
}
