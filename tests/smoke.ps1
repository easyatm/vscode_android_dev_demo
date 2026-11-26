param([string]$Serial = '192.168.7.10:5555')

$ErrorActionPreference = 'Stop'
$component = 'com.example.vscodedemo/.MainActivity'
$remoteDump = '/data/local/tmp/vscodedemo-smoke.xml'
$adbCommand = Get-Command adb -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
$adbPath = if ($adbCommand) { $adbCommand.Source } else { 'D:\ANDROID_DEV\sdk\platform-tools\adb.exe' }

function Invoke-Adb {
    $output = & $adbPath -s $Serial @args
    if ($LASTEXITCODE -ne 0) { throw "ADB 命令失败：$args" }
    $output
}

function Get-DeviceUi {
    foreach ($attempt in 1..3) {
        Invoke-Adb shell rm -f $remoteDump | Out-Null
        $dumpResult = Invoke-Adb shell uiautomator dump $remoteDump 2>&1
        if ($dumpResult -match ('dumped to: ' + [regex]::Escape($remoteDump))) {
            $xmlLines = Invoke-Adb shell cat $remoteDump
            return [xml]($xmlLines -join "`n")
        }
    }
    throw "无法读取设备界面：$dumpResult"
}

$originalEncoding = [Console]::OutputEncoding
try {
    [Console]::OutputEncoding = [Text.Encoding]::UTF8
    Invoke-Adb shell input keyevent KEYCODE_WAKEUP | Out-Null
    $startResult = Invoke-Adb shell am start -S -W -n $component
    if (-not ($startResult -match '^Status: ok\s*$')) { throw ($startResult -join "`n") }

    $version = (Invoke-Adb shell getprop ro.build.version.release).Trim()
    $api = (Invoke-Adb shell getprop ro.build.version.sdk).Trim()
    $initialUi = Get-DeviceUi
    $screenText = $initialUi.SelectNodes('//node/@text').Value
    if ("Android $version · API $api" -notin $screenText -or '点击次数：0' -notin $screenText) {
        throw '首页未显示设备版本或初始计数。'
    }

    $button = $initialUi.SelectSingleNode('//node[@text="计数 +1"]')
    if (!$button -or $button.bounds -notmatch '^\[(\d+),(\d+)\]\[(\d+),(\d+)\]$') {
        throw '未找到计数按钮。'
    }
    $centerX = [int](([int]$Matches[1] + [int]$Matches[3]) / 2)
    $centerY = [int](([int]$Matches[2] + [int]$Matches[4]) / 2)
    Invoke-Adb shell input tap $centerX $centerY | Out-Null
    $updatedUi = Get-DeviceUi
    if (!$updatedUi.SelectSingleNode('//node[@text="点击次数：1"]')) {
        throw '点击按钮后计数未更新为 1。'
    }
    "真机测试通过：Android $version（API $api），计数从 0 更新为 1。"
} finally {
    & $adbPath -s $Serial shell rm -f $remoteDump | Out-Null
    [Console]::OutputEncoding = $originalEncoding
}