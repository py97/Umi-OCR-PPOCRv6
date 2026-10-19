# Umi-OCR
# OCR software, free and offline. 开源、免费的离线OCR软件。
# Website - https://github.com/hiroi-sora/Umi-OCR
# Author - hiroi-sora
#
# You are free to use, modify, and distribute Umi-OCR, but it must include
# the original author's copyright statement and the following license statement.
# 您可以免费地使用、修改和分发 Umi-OCR ，但必须包含原始作者的版权声明和下列许可声明。
"""
Copyright (c) 2023 hiroi-sora

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""


"""
======================================================
========== Umi-OCR Windows 运行环境初始化入口 ==========
======================================================

说明：
本文件负责 Windows + PyStand 运行环境的初始化，主要涉及：
- 创建底层弹窗接口 os.MessageBox
- 重定向标准输入输出流
- 指定工作目录为 "/UmiOCR-data"
- 添加Python库搜索目录 "site-packages"
- 添加PySide2插件搜索目录 "PySide2/plugins"

环境初始化后，调用正式入口 py_src/run.py 启动软件。

耗时分析：
runtime/python.exe -X importtime main.py
"""


import os
import sys
import site
import traceback
import subprocess


def MessageBox(msg, type_="error"):
    # 软件中如遇到错误，会优先用QT弹窗来警示。
    # 但一些异常可能触发太早或导致QT事件循环崩溃。
    # 因此 os.MessageBox() 是用于报告错误的最后防线。
    info = "Umi-OCR Message"
    if type_ == "error":
        info = "【错误】 Umi-OCR Error"
    elif type_ == "warning":
        info = "【警告】 Umi-OCR Warning"
    try:
        # 通过 ctypes 发起弹窗
        import ctypes

        ctypes.windll.user32.MessageBoxW(None, str(msg), str(info), 0)
    except Exception:
        # 部分系统，连ctypes也用不了。转为在新的控制台窗口中打印信息。
        msg_cmd = (
            msg.replace("^", "^^")
            .replace("&", "^&")
            .replace("<", "^<")
            .replace(">", "^>")
            .replace("|", "^|")
            .replace("\n\n", "___")
            .replace("\n", "___")
        )
        subprocess.Popen(["start", "cmd", "/k", f"echo {info}: {msg_cmd}"], shell=True)
    return 0


os.MessageBox = MessageBox


def _preloadOcrPluginRuntimes():
    """预载旧版 PP-OCRv6 插件 opencv 运行时目录中的 VC++ 运行时。

    历史遗留修复：PySide2 自带旧版 MSVCP140.dll（site-packages/shiboken2/），
    若它先于 OpenCV 5.0 运行时链加载，Windows 加载器会按模块名去重，
    导致 OCR 引擎绑定到版本不匹配的 C++ 运行时，推理时触发
    access violation（空指针）崩溃。

    本优化版已将 OCR 引擎更换为 SimdPaddleOCR（独立 .NET 推理进程，
    不在 Python 进程内加载任何原生 OCR DLL），上述问题已不存在；
    本函数保留以兼容旧插件目录结构，目录不存在时自动为空操作。
    """
    import ctypes

    here = os.path.dirname(os.path.abspath(__file__))
    rt = os.path.join(
        here, "plugins", "win_x64_PPOCRv6", "runtimes", "win-x64", "opencv"
    )
    if not os.path.isdir(rt):
        return
    if hasattr(os, "add_dll_directory"):
        try:
            os.add_dll_directory(rt)
        except Exception:
            pass
    for name in (
        "msvcp140.dll",
        "msvcp140_1.dll",
        "msvcp140_2.dll",
        "vcruntime140.dll",
        "vcruntime140_1.dll",
    ):
        path = os.path.join(rt, name)
        if os.path.exists(path):
            try:
                ctypes.WinDLL(path)
            except Exception:
                pass


def initRuntimeEnvironment():
    """初始化运行环境"""

    # OCR 插件运行时 DLL 优先级修复（必须在 PySide2 导入前执行）
    _preloadOcrPluginRuntimes()

    # 尝试获取控制台的输出对象
    try:
        fd = os.open("CONOUT$", os.O_RDWR | os.O_BINARY)
        fp = os.fdopen(fd, "w", encoding="utf-8")
    except Exception as e:
        fp = open(os.devnull, "w", encoding="utf-8")
    # 输出流不存在时，重定向到控制台
    if not sys.stdout:
        sys.stdout = fp
    if not sys.stderr:
        sys.stderr = fp
    # def except_hook(cls, exception, traceback):
    #     sys.__excepthook__(cls, exception, traceback)
    # sys.excepthook = except_hook

    # 初始化工作目录和Python搜索路径
    script = os.path.abspath(__file__)  # 启动脚本.py的路径
    cwd = os.path.dirname(script)  # 工作目录
    os.chdir(cwd)  # 重新设定工作目录（不在最顶层，而在 UmiOCR-data 文件夹下）
    for n in [".", "site-packages"]:  # 将模块目录添加到 Python 搜索路径中
        path = os.path.abspath(os.path.join(cwd, n))
        if os.path.exists(path):
            site.addsitedir(path)
    # 初始化Qt搜索路径为相对路径，避免上层目录存在中文编码
    from PySide2.QtCore import QCoreApplication

    QCoreApplication.addLibraryPath("./site-packages/PySide2/plugins")


if __name__ == "__main__":
    try:
        initRuntimeEnvironment()  # 初始化运行环境
    except Exception:
        err = traceback.format_exc()
        from py_src.imports.umi_log import logger, Logs_Dir

        logger.critical(
            "Failed to initialize running environment!",
            exc_info=True,
            stack_info=True,
        )
        msg = f"Failed to initialize running environment!\n\n{err}\n\nSave the log file to: {Logs_Dir}"
        MessageBox(msg)
        sys.exit(0)
    try:
        # 获取 pystand.exe 记录的程序入口环境变量
        app_path = os.environ.get("PYSTAND", "")
        # 启动正式入口
        from py_src.run import main

        main(app_path=app_path, engineAddImportPath="./site-packages/PySide2/qml")
    except Exception:
        err = traceback.format_exc()
        from py_src.imports.umi_log import logger, Logs_Dir

        logger.critical(
            "Failed to startup main program!",
            exc_info=True,
            stack_info=True,
        )
        msg = f"Failed to startup main program!\n\n{err}\n\nSave the log file to: {Logs_Dir}"
        MessageBox(msg)
        sys.exit(0)
