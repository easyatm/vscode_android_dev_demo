# 安卓 Demo

基于参考模板的 Kotlin、Jetpack Compose 和 Gradle Wrapper 工作流，无需 Android Studio 或模拟器。应用支持 Android 7.0（API 24）及以上，首页显示当前 Android 版本和计数按钮。

本机使用 `D:\ANDROID_DEV\jdk-17`、`D:\ANDROID_DEV\sdk` 和 `D:\ANDROID_DEV\gradle-cache`。构建使用 Gradle 8.7、AGP 8.5.2、Kotlin 1.9.24、Android SDK 34 和 Build Tools 34.0.0。Kotlin 编译器由 Gradle 插件提供。

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