# Run the app on a real Android phone (USB) against the PRODUCTION backend
# (dart_defines.prod.json), saving every log line to logs/ for debugging.
#
#   ./scripts/run_android_prod.ps1                  # debug build: most logs, hot reload
#   ./scripts/run_android_prod.ps1 -Mode profile    # near-release speed, still has logs
#   ./scripts/run_android_prod.ps1 -Mode release    # exactly what users get
#   ./scripts/run_android_prod.ps1 -Device R58M     # a specific phone (adb devices)
#
# Two files per run, in logs/:
#   run-<time>.log     what `flutter run` prints (build output, print/debugPrint)
#   logcat-<time>.log  Android system log: native crashes, plugin errors, flutter tag

param(
    [string]$Device,
    [ValidateSet('debug', 'profile', 'release')][string]$Mode = 'debug'
)

$root = Resolve-Path "$PSScriptRoot\.."
$logDir = Join-Path $root 'logs'
New-Item -ItemType Directory -Force $logDir | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$runLog = Join-Path $logDir "run-$stamp.log"
$logcatLog = Join-Path $logDir "logcat-$stamp.log"

$adbArgs = @()
if ($Device) { $adbArgs = @('-s', $Device) }

# Start logcat fresh so the file only holds this run. Keep warnings and errors
# from everything, plus all lines from Flutter.
& adb @adbArgs logcat -c
if ($LASTEXITCODE -ne 0) { throw 'adb failed - is the phone connected with USB debugging on?' }
$logcat = Start-Process adb -ArgumentList ($adbArgs + @('logcat', '-v', 'time', '*:W', 'flutter:V')) `
    -RedirectStandardOutput $logcatLog -NoNewWindow -PassThru

$flutterArgs = @('run', "--$Mode", "--dart-define-from-file=$root\dart_defines.prod.json")
if ($Device) { $flutterArgs += @('-d', $Device) }

# .fvmrc pins the team's Flutter version; use FVM when it is installed.
$fvm = Get-Command fvm -ErrorAction SilentlyContinue
if (-not $fvm -and (Test-Path "$env:LOCALAPPDATA\Pub\Cache\bin\fvm.bat")) { $fvm = "$env:LOCALAPPDATA\Pub\Cache\bin\fvm.bat" }

Write-Host "Logs: $runLog"
Write-Host "      $logcatLog"
Push-Location $root
try {
    # Show each line on screen and append it to the log as UTF-8.
    # Keys like r (hot reload) and q (quit) still work.
    $write = { $line = "$_"; Write-Host $line; Add-Content -Path $runLog -Value $line -Encoding utf8 }
    if ($fvm) {
        & $fvm flutter @flutterArgs 2>&1 | ForEach-Object $write
    } else {
        & flutter @flutterArgs 2>&1 | ForEach-Object $write
    }
} finally {
    Pop-Location
    if ($logcat -and -not $logcat.HasExited) { Stop-Process -Id $logcat.Id -Force }
    Write-Host "Saved logs to $logDir"
}
