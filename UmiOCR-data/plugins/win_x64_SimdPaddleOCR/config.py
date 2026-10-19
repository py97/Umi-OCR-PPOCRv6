# ===============================================
# PP-OCRv6（SimdPaddleOCR）插件 配置项
# 引擎：Sdcb.SimdPaddleOCR（纯托管 .NET 推理，无原生 DLL 依赖）
# ===============================================

import os


def _getThreads():
    # SimdPaddleOCR 的 CLS/REC 为行级并发 worker，默认 min(CPU 核数, 4)。
    return min(os.cpu_count() or 4, 4)


_threads = _getThreads()

globalOptions = {
    "title": "PP-OCRv6（SimdPaddleOCR）",
    "type": "group",
    "backend": {
        "title": "推理后端",
        "optionsList": [
            ["auto", "自动（有 GPU 用 Vulkan，否则 CPU）"],
            ["cpu", "CPU（兼容性最好）"],
            ["vulkan", "Vulkan GPU 加速"],
        ],
        "toolTip": "SimdPaddleOCR 为纯托管推理，不依赖 OpenCV/OpenVINO 等原生库。auto 会在检测到可用 GPU 时使用 Vulkan，否则回退 CPU。",
    },
    "numThread": {
        "title": "识别并发数",
        "default": _threads,
        "min": 1,
        "max": 16,
        "isInt": True,
        "toolTip": "CLS/REC 行级并发 worker 数，默认 min(CPU 核数, 4)。过高会争抢 CPU。",
    },
}

localOptions = {
    "title": "文字识别（PP-OCRv6 · Simd）",
    "type": "group",
    "model": {
        "title": "模型",
        "optionsList": [
            ["ppocrv6-tiny", "PP-OCRv6 tiny（默认，中文）"],
        ],
        "toolTip": "当前内置 PP-OCRv6 tiny 中文模型。可在插件 models 目录下加入 small/medium 的 det/cls/rec.onnx 与 ppocr_keys.txt 后使用。",
    },
    "angle": {
        "title": "纠正文本方向",
        "default": True,
        "toolTip": "启用方向分类，识别倾斜或倒置的文本。",
    },
    "maxSideLen": {
        "title": "限制图像边长",
        "optionsList": [
            [1280, "1280（默认）"],
            [960, "960（快速）"],
            [1600, "1600"],
            [1920, "1920"],
            [2560, "2560"],
            [4096, "4096"],
        ],
        "toolTip": "将边长大于该值的图片压缩，提高识别速度；过小会丢失小字。页面/截图识别建议 1280 以上。",
    },
}
