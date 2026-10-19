# 署名与许可声明（NOTICE）

本仓库是 **Umi-OCR v2.1.5** 的一个社区优化修改版，主要变化为：移除原版全部 OCR 插件、
更换 PP-OCRv6 离线引擎为 [SimdPaddleOCR](https://github.com/sdcb/SimdPaddleOCR)（独立 .NET 推理进程 + localhost HTTP 调用）、
对图形界面做了暖色主题与无边框窗口的重新设计。

依据 MIT 许可证要求，以下著作权与许可信息必须随分发一同保留。

## 上游项目

- **Umi-OCR**（主体框架、界面与 Python 源码）
  - 作者：hiroi-sora
  - 许可证：MIT
  - 仓库：https://github.com/hiroi-sora/Umi-OCR
  - 许可证文件：本目录 `LICENSE`

## SimdPaddleOCR 引擎（默认且唯一 OCR 引擎）

- **Sdcb.SimdPaddleOCR**（OCR 推理库，C# 托管实现）
  - 作者：sdcb
  - 许可证：Apache-2.0
  - 仓库：https://github.com/sdcb/SimdPaddleOCR
  - 许可证文件：本目录 `LICENSE-SimdPaddleOCR`
  - 以 `SimdOcrHost.exe` 形式随 `UmiOCR-data/plugins/win_x64_SimdPaddleOCR/backend/` 自包含分发

- **SimdOcrHost 推理进程**（本仓库在 SimdPaddleOCR 之上编写的 HTTP 桥接层）
  - 作者：py97（本优化版维护者）
  - 许可证：MIT（随本仓库分发）
  - 源码：`UmiOCR-data/plugins/win_x64_SimdPaddleOCR/src/`

- **.NET 运行时**（随 `SimdOcrHost.exe` 自包含分发）
  - 作者：Microsoft 与 .NET Foundation
  - 许可证：MIT

- **PaddleOCR 模型**（PP-OCRv6 tiny ONNX 模型，检测 + 方向分类 + 识别）
  - 作者：PaddlePaddle
  - 许可证：Apache-2.0
  - 来源：https://github.com/PaddlePaddle/PaddleOCR
  - 文件位置：`UmiOCR-data/plugins/win_x64_SimdPaddleOCR/models/`

## 已移除的原版组件

本优化版已从分发中**移除**以下原版 OCR 插件（其许可信息仅在此备案说明，不随分发保留）：

- `win_x64_PPOCRv6` 插件（作者：天天代码码天天，MIT；依赖 OpenCV / OpenVINO / ONNX Runtime 等原生组件）
- `win7_x64_RapidOCR-json` 插件（作者：hiroi-sora，随上游 Umi-OCR 分发）

## 本优化版维护者

- **Umi-OCR PP-OCRv6 优化版**
  - 维护者：py97
  - 仓库：https://github.com/py97/Umi-OCR-PPOCRv6
  - 本仓库在 MIT 许可之下分发，在保留上述原作者版权与许可的前提下，叠加了本页所列界面与引擎整合修改。

## 本优化版所做的修改

以下改动由本仓库维护者完成，在原 MIT 许可之上叠加，不替换上述任何原有版权声明：

1. 移除原版全部 OCR 引擎插件，更换为 SimdPaddleOCR 引擎并设为默认（唯一）引擎。
2. 编写 `SimdOcrHost` HTTP 桥接进程，使 OCR 推理运行于独立 .NET 进程中（含父进程看护、空闲自动退出、置信度归一化）。
3. 界面重构为无边框窗口（FramelessWindowHint），自带四边/四角拖拽缩放与标题栏拖拽移动。
4. 顶部右侧集成中性风格的 最小化 / 最大化(还原) / 关闭 窗口控制按钮。
5. 以左侧导航栏取代原标签页布局，重构各功能页。
6. 统一暖黄色调主题（画布 / 侧栏 / 卡片背景），消除纯白背景突兀问题。
7. 修复关于页链接在浅色主题下白字不可见的问题。
8. 侧边导航栏展示当前 OCR 引擎信息（PP-OCRv6 · Simd · CPU/Vulkan/自动）。

如需在本优化版基础上继续修改，请同样保留上述所有许可证与署名信息。
