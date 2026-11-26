# 安卓 Demo

基于参考模板的 Kotlin、Jetpack Compose 和 Gradle Wrapper 工作流，无需 Android Studio 或模拟器。应用支持 Android 7.0（API 24）及以上，首页显示当前 Android 版本和计数按钮。

## 已安装的开发工具

| 工具 | 版本 | 本机位置 |
| --- | --- | --- |
| Eclipse Temurin JDK | 17.0.21.1 | `D:\ANDROID_DEV\jdk-17` |
| Android SDK Command-line Tools（含 `sdkmanager`） | 22.0 | `D:\ANDROID_DEV\sdk\cmdline-tools\latest` |
| Android SDK Platform | API 34，修订版 3 | `D:\ANDROID_DEV\sdk\platforms\android-34` |
| Android SDK Build Tools | 34.0.0 | `D:\ANDROID_DEV\sdk\build-tools\34.0.0` |
| Android SDK Platform Tools（含 `adb`） | 37.0.3 | `D:\ANDROID_DEV\sdk\platform-tools` |
| Gradle（由 Wrapper 下载） | 8.7 | `D:\ANDROID_DEV\gradle-cache\wrapper\dists` |

真机部署沿用本机原有的 `D:\Portable_App\adb\adb.exe`。Android Gradle Plugin（AGP 8.5.2）和 Kotlin 插件（1.9.24，含编译器）由 Gradle 自动下载，不需要单独安装 Kotlin 编译器。本次未安装 Android Studio 或模拟器。

## 已安装的 VS Code 扩展

| 扩展 | 扩展 ID | 版本 | 用途 |
| --- | --- | --- | --- |
| Android | `adelphes.android-dev-ext` | 1.4.0 | 部署并连接真机调试器，支持源码断点 |
| Kotlin Language | `mathiasfrohlich.kotlin` | 1.7.1 | 识别 Kotlin 源码和脚本，提供语法高亮 |

Gradle for Java（`vscjava.vscode-gradle`）仅列为工作区推荐，当前未安装；不影响 Gradle Wrapper 构建或真机调试。

## 构建与运行

在 VS Code 中执行任务 `Android: 在内网设备运行 Demo`，会依次构建、安装和启动。也可以在工作区新开的 PowerShell 终端执行：

```powershell
.\gradlew.bat :app:assembleDebug
adb devices -l
adb -s 192.168.7.10:5555 install -r .\app\build\outputs\apk\debug\app-debug.apk
adb -s 192.168.7.10:5555 shell am start -W -n com.example.vscodedemo/.MainActivity
```

如果设备断开，可执行 `adb connect 192.168.7.10:5555`。更换设备时，把命令、VS Code 任务及调试配置中的设备地址换为 `adb devices -l` 列出的序列号。

在设备解锁、APK 已安装的前提下，执行 `pwsh -NoProfile -File .\tests\smoke.ps1 -Serial 192.168.7.10:5555`，验证首页版本文本以及点击后计数从 0 变为 1。

## 真机断点调试

调试使用 Android 扩展（`adelphes.android-dev-ext`）和 Kotlin Language 扩展（`mathiasfrohlich.kotlin`）。在 [MainActivity.kt](app/src/main/java/com/example/vscodedemo/MainActivity.kt#L26) 的 `super.onCreate(savedInstanceState)` 行按 `F9` 设置断点，选择 `Android: 调试内网 Demo` 后按 `F5`。VS Code 先构建 Debug APK，再通过现有 ADB 服务部署、启动并附加调试器。断住后按 `F5` 继续，按 `Shift+F5` 停止调试。
