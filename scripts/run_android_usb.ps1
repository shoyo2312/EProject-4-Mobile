# Run the app on a real Android phone plugged in over USB, against the backend
# on this machine. adb reverse makes the phone's localhost:8080 (api-gateway)
# and localhost:9000 (MinIO: uploads and media) land on this PC, so the
# localhost URLs the backend signs work on the phone unchanged.
#
#   ./scripts/run_android_usb.ps1              # first device adb sees
#   ./scripts/run_android_usb.ps1 -Device R58M # a specific one (adb devices)

param([string]$Device)

$adbArgs = @()
if ($Device) { $adbArgs = @('-s', $Device) }

foreach ($port in 8080, 9000) {
    & adb @adbArgs reverse "tcp:$port" "tcp:$port"
    if ($LASTEXITCODE -ne 0) { throw "adb reverse tcp:$port failed - is the phone connected with USB debugging on?" }
}

# dart_defines.json carries TURNSTILE_SITE_KEY (shared by the team, public value).
$flutterArgs = @('run', '--dart-define-from-file=dart_defines.json', '--dart-define=API_BASE_URL=http://localhost:8080/api/v1')
if ($Device) { $flutterArgs += @('-d', $Device) }
# .fvmrc pins the team's Flutter version; use it when FVM is installed, so the
# app is built with the same SDK that resolved pubspec.lock.
$fvm = Get-Command fvm -ErrorAction SilentlyContinue
if (-not $fvm -and (Test-Path "$env:LOCALAPPDATA\Pub\Cache\bin\fvm.bat")) { $fvm = "$env:LOCALAPPDATA\Pub\Cache\bin\fvm.bat" }
if ((Test-Path "$PSScriptRoot\..\.fvmrc") -and $fvm) {
    & $fvm flutter @flutterArgs
} else {
    & flutter @flutterArgs
}
