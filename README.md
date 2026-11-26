# VS Code 原生 Android 开发工作流

供 AI 编码代理执行。适用于 Windows 上使用 VS Code、Kotlin、Jetpack Compose、Gradle Wrapper 和 ADB 的原生 Android 项目。当前工作区是参考实例，不需要 Android Studio 或模拟器。

## 1. 确定任务与输入

1. 按用户目标选择验证范围：搭环境检查工具链；修改应用至少构建；部署还要安装和启动；调试还要验证断点。只改文档时不操作设备。
2. 从 [应用构建配置](app/build.gradle.kts)、[Manifest](app/src/main/AndroidManifest.xml) 和 [Gradle Wrapper 配置](gradle/wrapper/gradle-wrapper.properties) 读取模块、应用 ID、入口 Activity、SDK 和 Gradle 版本。迁移到其他项目时重新读取，不照抄本例的包名、设备地址或版本。
3. 本例使用模块 `:app`、应用 ID `com.example.vscodedemo` 和入口 `.MainActivity`。`compileSdk`、`targetSdk` 均为 34，`minSdk` 为 24；已在 Android 7.1.2（API 25）验证。不要为匹配真机 API 而降低 `compileSdk`。

## 2. 检查环境，只补缺项

从工作区根目录执行。先看 `Get-Command adb`，再核对 JDK、SDK 包和扩展。工具可用时跳过安装；除非任务明确要求，不升级项目锁定版本，也不替换现有 ADB。

```powershell
$env:JAVA_HOME = 'D:\ANDROID_DEV\jdk-17'
$env:ANDROID_HOME = 'D:\ANDROID_DEV\sdk'
& "$env:JAVA_HOME\bin\java.exe" -version
$sdkManager = "$env:ANDROID_HOME\cmdline-tools\latest\bin\sdkmanager.bat"
& $sdkManager --list_installed
```

如果 JDK 或 `sdkmanager` 缺失，从 [Adoptium](https://adoptium.net/temurin/releases/?version=17) 和 [Android 开发者网站](https://developer.android.com/studio#command-line-tools-only) 获取对应工具；按目标系统架构下载，并在发布方提供校验值时校验。解压后确认 `cmdline-tools\latest` 直接包含 `bin` 和 `lib`，再仅安装缺失的 SDK 包，例如：

```powershell
& $sdkManager --install 'platforms;android-34' 'build-tools;34.0.0' 'platform-tools'
```

本机已安装的工具：

| 工具 | 版本 | 本机位置 |
| --- | --- | --- |
| Eclipse Temurin JDK | 17.0.21.1 | `D:\ANDROID_DEV\jdk-17` |
| Android SDK Command-line Tools（含 `sdkmanager`） | 22.0 | `D:\ANDROID_DEV\sdk\cmdline-tools\latest` |
| Android SDK Platform | API 34，修订版 3 | `D:\ANDROID_DEV\sdk\platforms\android-34` |
| Android SDK Build Tools | 34.0.0 | `D:\ANDROID_DEV\sdk\build-tools\34.0.0` |
| Android SDK Platform Tools（含 `adb`） | 37.0.3 | `D:\ANDROID_DEV\sdk\platform-tools` |
| Gradle（由 Wrapper 下载） | 8.7 | `D:\ANDROID_DEV\gradle-cache\wrapper\dists` |

Gradle 8.7 由 Wrapper 下载，AGP 8.5.2 和 Kotlin 插件 1.9.24 由 Gradle 解析，不额外安装全局 Gradle 或 Kotlin 编译器。

## 3. 核对 VS Code 配置

用 VS Code 打开项目根目录。核对 [工作区设置](.vscode/settings.json) 和 [构建任务](.vscode/tasks.json) 使用的 JDK、SDK、Gradle 缓存路径；本机 `local.properties` 使用 `sdk.dir=D:/ANDROID_DEV/sdk`，不提交。不要假设代理终端继承 VS Code 集成终端的环境变量；直接运行命令前，在当前 PowerShell 中按第 2 步设置 JDK、SDK 路径，再运行 `$env:GRADLE_USER_HOME = 'D:\ANDROID_DEV\gradle-cache'`。

用当前 VS Code 的 CLI 执行 `code --list-extensions --show-versions`；需要调试或编辑支持且缺少扩展时，用 `code --install-extension <扩展ID>` 安装，再列出版本确认。当前便携版 CLI 是 `D:\Portable_App\VSCode\bin\code.cmd`；没有 `code` 命令时直接调用该路径。本机已安装：

| 扩展 | 扩展 ID | 版本 | 用途 |
| --- | --- | --- | --- |
| Android | `adelphes.android-dev-ext` | 1.4.0 | 部署并连接真机调试器，支持源码断点 |
| Kotlin Language | `mathiasfrohlich.kotlin` | 1.7.1 | 识别 Kotlin 源码和脚本，提供语法高亮 |

Gradle for Java（`vscjava.vscode-gradle`）仅列为工作区推荐，当前未安装；不影响 Gradle Wrapper 构建或真机调试。

## 4. 修改并构建

根据任务改动对应文件：[MainActivity.kt](app/src/main/java/com/example/vscodedemo/MainActivity.kt) 管理 Compose 界面和交互，[strings.xml](app/src/main/res/values/strings.xml) 管理界面文字。修改后优先运行最相关的检查。需要构建 APK 时，复用任务 `Android: 构建 Debug APK`；任务入口不可用时，使用等价命令：

```powershell
.\gradlew.bat :app:assembleDebug --console=plain
```

只有退出码为 `0` 且 `app/build/outputs/apk/debug/app-debug.apk` 存在时，才用本次产物部署。失败时读取第一条具体错误并针对该问题重试；不要用旧 APK 代替，也不要默认执行 `clean`。

## 5. 连接真机并运行

本机优先复用 `D:\Portable_App\adb\adb.exe` 和现有内网连接。先列出设备，确认任务指定的序列号状态为 `device`；多设备时不猜目标，后续命令都带 `-s`。本例序列号是 `192.168.7.10:5555`。

```powershell
adb devices -l
```

对于已知且已启用 TCP ADB 的设备，断线时用 `adb connect 192.168.7.10:5555` 重连，再查状态；若显示 `unauthorized`，请用户在真机上确认授权。不要为部署重启 ADB 服务、清除应用数据或卸载应用。

复用任务 `Android: 在内网设备运行 Demo`，或在构建完成后执行等价命令：

```powershell
adb -s 192.168.7.10:5555 install -r .\app\build\outputs\apk\debug\app-debug.apk
adb -s 192.168.7.10:5555 shell am start -W -n com.example.vscodedemo/.MainActivity
```

确认安装返回 `Success` 后再启动，确认启动结果有 `Status: ok` 且 Activity 与目标一致。更换设备时，用实际序列号更新命令、[运行任务](.vscode/tasks.json)和 [调试配置](.vscode/launch.json) 的 `targetDevice`。

## 6. 设置断点并调试

1. 核对启动配置的 `preLaunchTask`、`targetDevice`、`appSrcRoot`、`apkFile` 和 `manifestFile`。本例用合并后的 Manifest 作为调试输入，并复用 `127.0.0.1:5037` 的本机 ADB 服务。
2. 在 [MainActivity.kt](app/src/main/java/com/example/vscodedemo/MainActivity.kt#L26) 的 `super.onCreate(savedInstanceState)` 设置断点，用 `Android: 调试内网 Demo` 启动。使用 VS Code 时按 `F9` 设置断点、按 `F5` 启动。
3. 验证调试器确实因断点暂停，且调用栈顶部指向对应 Kotlin 文件和行。仅构建成功、APK 启动成功或端口可连接，都不算断点验证。无法操作 VS Code 时，可用已安装的调试适配器验证；若两种方式都不可用，明确报告未验证。

## 7. 验证并报告

结束调试、解锁设备并安装最新 APK 后，在 PowerShell 7 中运行真机冒烟测试。测试会重新打开 Demo，检查首页是否显示设备版本，以及点击按钮后计数是否从 0 变为 1。

```powershell
pwsh -NoProfile -File .\tests\smoke.ps1 -Serial 192.168.7.10:5555
```

根据任务分别报告实际完成的工具检查、构建、安装、启动、断点和真机测试。不要把生成配置说成已经运行，也不要把构建通过说成真机测试通过。遇到阻塞时说明失败步骤、关键输出和需要的用户操作。
