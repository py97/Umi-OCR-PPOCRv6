# ===============================================
# PP-OCRv6 插件 Api 类（SimdPaddleOCR 版）
#
# 通过本地 HTTP 调用自包含 .NET 后端 SimdOcrHost.exe：
#   - start()  拉起后端子进程并等待就绪
#   - stop()   结束后端子进程
#   - runPath/runBytes/runBase64  POST 原始 BGR 像素到 /ocr
#
# 后端进程带父进程守护（--parent-pid）与空闲自退，避免悬挂。
# 接口契约与旧 lw.PPOCR 插件完全一致（code/data/text/box/score）。
# ===============================================

import os
import io
import json
import time
import base64
import socket
import threading
import subprocess
import urllib.request
import urllib.error

# 插件所在目录（backend / models 均位于此目录下）
PluginDir = os.path.dirname(os.path.abspath(__file__))
# 自包含 .NET 后端可执行文件
BackendExe = os.path.join(PluginDir, "backend", "SimdOcrHost.exe")
# 模型根目录
ModelsRoot = os.path.join(PluginDir, "models")

DefaultModelName = "ppocrv6-tiny"
DefaultBackend = "auto"
DefaultNumThread = 4
DefaultMaxSideLen = 1280
StartTimeout = 60  # 等待后端就绪的最长秒数
RunTimeout = 180   # 单次识别 HTTP 超时秒数

# 内部标记：后端调用异常，需要重启后重试
_CODE_ENGINE_ERROR = 900


class Api:  # 公开接口
    def __init__(self, globalArgd):
        self.globalArgd = globalArgd or {}
        self.proc = None          # 后端子进程
        self.port = 0             # 后端监听端口
        self.engineArgs = None    # 当前后端启动参数（用于重启/复用判断）
        self._lock = threading.RLock()

    # -------------------------------------------------- 参数与路径

    def _combineArgs(self, argd):
        """合并全局与局部配置（局部优先）。"""
        merged = {}
        merged.update(self.globalArgd or {})
        merged.update(argd or {})
        model = merged.get("model", DefaultModelName) or DefaultModelName
        angle = bool(merged.get("angle", True))
        try:
            maxSideLen = int(merged.get("maxSideLen", DefaultMaxSideLen) or DefaultMaxSideLen)
        except (TypeError, ValueError):
            maxSideLen = DefaultMaxSideLen
        try:
            numThread = int(merged.get("numThread", DefaultNumThread) or DefaultNumThread)
        except (TypeError, ValueError):
            numThread = DefaultNumThread
        backend = str(merged.get("backend", DefaultBackend) or DefaultBackend)
        return {
            "model": model,
            "angle": angle,
            "maxSideLen": maxSideLen,
            "numThread": max(1, min(16, numThread)),
            "backend": backend,
        }

    def _modelPaths(self, model):
        d = os.path.join(ModelsRoot, model)
        det = os.path.join(d, "det.onnx")
        cls = os.path.join(d, "cls.onnx")
        rec = os.path.join(d, "rec.onnx")
        keys = os.path.join(d, "ppocr_keys.txt")
        for label, p in (("det", det), ("rec", rec), ("keys", keys)):
            if not os.path.exists(p):
                raise FileNotFoundError(
                    f"模型文件缺失: {p}（可在插件 models 目录下添加 {model} 模型）"
                )
        return det, cls, rec, keys

    @staticmethod
    def _freePort():
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        try:
            s.bind(("127.0.0.1", 0))
            return s.getsockname()[1]
        finally:
            s.close()

    # -------------------------------------------------- 后端进程管理

    def _launch(self, args):
        if not os.path.exists(BackendExe):
            raise FileNotFoundError(f"后端可执行文件缺失: {BackendExe}")
        det, cls, rec, keys = self._modelPaths(args["model"])
        port = self._freePort()
        cmd = [
            BackendExe,
            "--port", str(port),
            "--det", det,
            "--rec", rec,
            "--keys", keys,
            "--backend", args["backend"],
            "--limit-side", str(args["maxSideLen"]),
            "--workers", str(args["numThread"]),
            "--parent-pid", str(os.getpid()),
        ]
        if args["angle"] and os.path.exists(cls):
            cmd += ["--cls", cls]
        else:
            cmd += ["--no-cls"]

        # Windows 下隐藏控制台窗口
        kwargs = {}
        if os.name == "nt":
            si = subprocess.STARTUPINFO()
            si.dwFlags |= subprocess.STARTF_USESHOWWINDOW
            si.wShowWindow = 0  # SW_HIDE
            kwargs["startupinfo"] = si
            kwargs["creationflags"] = getattr(subprocess, "CREATE_NO_WINDOW", 0)

        self.proc = subprocess.Popen(
            cmd,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            **kwargs,
        )
        self.port = port
        if not self._waitReady(port, StartTimeout):
            self._kill()
            raise RuntimeError("OCR 后端未在超时时间内就绪。")

    def _waitReady(self, port, timeout):
        url = f"http://127.0.0.1:{port}/health"
        deadline = time.time() + timeout
        while time.time() < deadline:
            if self.proc is not None and self.proc.poll() is not None:
                return False
            try:
                with urllib.request.urlopen(url, timeout=2) as r:
                    if r.status == 200:
                        return True
            except Exception:
                pass
            time.sleep(0.2)
        return False

    def _kill(self):
        p = self.proc
        port = self.port
        self.proc = None
        self.port = 0
        if p is None:
            return
        # 先尝试优雅关闭
        if port:
            try:
                urllib.request.urlopen(
                    urllib.request.Request(f"http://127.0.0.1:{port}/shutdown", data=b""),
                    timeout=2,
                ).read()
            except Exception:
                pass
        try:
            p.wait(timeout=2)
        except Exception:
            pass
        if p.poll() is None:
            try:
                p.terminate()
                try:
                    p.wait(timeout=3)
                except Exception:
                    p.kill()
            except Exception:
                pass

    # -------------------------------------------------- 公开接口

    def start(self, argd):  # 启动引擎。返回："" 成功，"[Error] xxx" 失败
        with self._lock:
            try:
                newArgs = self._combineArgs(argd)
                # 已启动且参数一致：复用
                if self.proc is not None and self.proc.poll() is None:
                    if self.engineArgs == newArgs:
                        return ""
                    self._kill()
                self._launch(newArgs)
                self.engineArgs = newArgs
                return ""
            except Exception as e:
                self._kill()
                return f"[Error] OCR init fail: {e}"

    def stop(self):  # 停止引擎
        with self._lock:
            self._kill()
            self.engineArgs = None

    def runPath(self, imgPath: str):  # 路径识图
        return self._run(lambda: ImageLoader.open(imgPath))

    def runBytes(self, imageBytes):  # 字节流
        return self._run(lambda: ImageLoader.openBytes(imageBytes))

    def runBase64(self, imageBase64):  # base64字符串
        try:
            if imageBase64.startswith("data:"):
                imageBase64 = imageBase64.split(",", 1)[1]
            imageBytes = base64.b64decode(imageBase64)
        except Exception as e:
            return {"code": 102, "data": f"[Error] Base64 解码失败：{e}"}
        return self.runBytes(imageBytes)

    # -------------------------------------------------- 内部执行

    def _run(self, loader):
        with self._lock:
            # 后端未运行：按上次参数重启
            if self.proc is None or self.proc.poll() is not None:
                if self.engineArgs is None:
                    return {"code": 102, "data": "[Error] 引擎未启动。"}
                try:
                    self._launch(self.engineArgs)
                except Exception as e:
                    return {"code": 102, "data": f"[Error] 引擎启动失败：{e}"}
            res = self._runOnce(loader)
            if res["code"] != _CODE_ENGINE_ERROR:
                return res
            # 后端异常：重启一次并重试
            try:
                self._kill()
                self._launch(self.engineArgs)
            except Exception:
                self._kill()
                return {"code": 102, "data": "[Error] OCR init fail: 后端重启失败。"}
            res = self._runOnce(loader)
            if res["code"] == _CODE_ENGINE_ERROR:
                self._kill()
                return {"code": 102, "data": res.get("data", "[Error] OCR run fail.")}
            return res

    def _runOnce(self, loader):
        """执行一次识别。输入错误返回 code=102；后端异常返回 _CODE_ENGINE_ERROR。"""
        # 加载并预处理图片
        try:
            img = ImageLoader.prepare(loader())
            w, h = img.size
            if w <= 0 or h <= 0:
                return {"code": 102, "data": "[Error] 图片尺寸无效。"}
            limit = self.engineArgs.get("maxSideLen", DefaultMaxSideLen) if self.engineArgs else DefaultMaxSideLen
            max_side = max(w, h)
            if max_side > limit:
                scale = limit / max_side
                img = img.resize(
                    (max(1, int(round(w * scale))), max(1, int(round(h * scale)))),
                    ImageLoader.LANCZOS,
                )
                w, h = img.size
            bgr = img.tobytes("raw", "BGR")
            if len(bgr) != w * h * 3:
                return {"code": 102, "data": "[Error] 图片数据长度异常。"}
        except Exception as e:
            return {"code": 102, "data": f"[Error] 图片解析失败：{e}"}
        # 调用后端
        try:
            result = self._ocrHttp(bgr, w, h)
        except Exception as e:
            return {"code": _CODE_ENGINE_ERROR, "data": f"[Error] OCR engine exception: {e}"}
        # 格式化结果
        if not result:
            return {"code": 101, "data": ""}
        data = []
        for r in result:
            data.append({
                "text": r.get("text", ""),
                "box": [
                    [int(round(r.get("x1", 0))), int(round(r.get("y1", 0)))],
                    [int(round(r.get("x2", 0))), int(round(r.get("y2", 0)))],
                    [int(round(r.get("x3", 0))), int(round(r.get("y3", 0)))],
                    [int(round(r.get("x4", 0))), int(round(r.get("y4", 0)))],
                ],
                "score": round(float(r.get("score", 0)), 4),
            })
        return {"code": 100, "data": data}

    def _ocrHttp(self, bgr, w, h):
        url = (
            f"http://127.0.0.1:{self.port}/ocr"
            f"?width={w}&height={h}&stride={w * 3}&format=bgr24"
        )
        req = urllib.request.Request(
            url, data=bgr, headers={"Content-Type": "application/octet-stream"}
        )
        with urllib.request.urlopen(req, timeout=RunTimeout) as resp:
            return json.loads(resp.read().decode("utf-8"))


class ImageLoader:
    """使用 PIL 解码并预处理图片（PIL 已由 Umi-OCR 内置）。"""

    LANCZOS = 1  # PIL 的 LANCZOS 重采样常量（值恒为 1）

    @staticmethod
    def open(path):
        from PIL import Image
        return Image.open(path)

    @staticmethod
    def openBytes(data):
        from PIL import Image
        return Image.open(io.BytesIO(data))

    @staticmethod
    def prepare(img):
        """将 PIL 图片统一为 RGB 模式：EXIF 转正、透明合成白底、其它模式转 RGB。"""
        from PIL import Image, ImageOps

        try:
            img = ImageOps.exif_transpose(img)
        except Exception:
            pass
        if img.mode in ("RGBA", "LA", "PA") or (img.mode == "P" and "transparency" in img.info):
            try:
                rgba = img.convert("RGBA")
                background = Image.new("RGB", rgba.size, (255, 255, 255))
                background.paste(rgba, mask=rgba.split()[-1])
                return background
            except Exception:
                pass
        if img.mode != "RGB":
            img = img.convert("RGB")
        return img
