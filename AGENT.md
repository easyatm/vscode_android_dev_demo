# 工作区说明

修改项目功能与结构时需要同步更新此文件，并维护对应的使用说明和测试。

- `app/src/main/`：Compose 首页、启动 Activity、Manifest 和界面文本。包名为 `com.example.vscodedemo`，最低支持 API 24。
- `app/build.gradle.kts`：应用配置及 Compose 依赖。根目录 Gradle 配置与 `gradle/wrapper/` 固定构建工具链。
- `local.properties`：本机 Android SDK 路径，不提交。
- `.vscode/`：本机 JDK 和 SDK 环境、扩展推荐、构建与 ADB 真机运行任务。`launch.json` 复用 Debug APK 构建任务，并通过本机 ADB 服务调试指定设备。
- `tests/smoke.ps1`：使用 PowerShell 7 和 ADB 验证真机启动、系统版本文本和计数按钮。
- `README.md`：供 AI 编码代理执行的 VS Code 原生 Android 工作流，包含环境检查、构建、部署、调试和验收标准。
