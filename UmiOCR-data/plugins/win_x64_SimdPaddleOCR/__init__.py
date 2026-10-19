# ===============================================
# PP-OCRv6 Umi-OCR 插件（SimdPaddleOCR 版）
# 引擎：Sdcb.SimdPaddleOCR（纯托管 .NET 推理）
# 通过本地 HTTP 服务调用自包含 .NET 后端 SimdOcrHost.exe
# ===============================================

from . import config as simdpaddleocr_config
from .api_simdpaddleocr import Api

# 插件信息
PluginInfo = {
    # 插件组别
    "group": "ocr",
    # 全局配置
    "global_options": simdpaddleocr_config.globalOptions,
    # 局部配置
    "local_options": simdpaddleocr_config.localOptions,
    # 接口类
    "api_class": Api,
}
