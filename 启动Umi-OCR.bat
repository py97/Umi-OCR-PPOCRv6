@echo off
rem ============================================
rem  Umi-OCR PP-OCRv6 便携版 启动器
rem  双击本文件即可离线使用（不打开控制台窗口）
rem ============================================
cd /d "%~dp0UmiOCR-data"
start "" runtime\pythonw.exe main.py