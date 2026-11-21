@echo off
setlocal
REM One-click watch ADB recovery: switch USB ADB to TCP and reconnect over WiFi.
REM Usage: recover_watch_adb.bat [port]

set "PORT=%~1"
if "%PORT%"=="" set "PORT=5555"

echo [1/4] Waiting for watch on USB (plug the cable if not connected)...
adb -d wait-for-device || exit /b 1

echo [2/4] Switching adbd to TCP %PORT% ...
adb -d tcpip %PORT% || exit /b 1
timeout /t 3 /nobreak >nul
adb -d wait-for-device || exit /b 1

echo [3/4] Reading watch WiFi IP ...
set "WIP="
for /f "tokens=2 delims= " %%a in ('adb -d shell "ip -f inet addr show wlan0" 2^>nul ^| findstr /R /C:"inet [0-9]"') do (
    for /f "tokens=1 delims=/" %%b in ("%%a") do set "WIP=%%b"
)
if "%WIP%"=="" (
    for /f "tokens=1 delims= " %%a in ('adb -d shell "getprop dhcp.wlan0.ipaddress" 2^>nul') do set "WIP=%%a"
)
if "%WIP%"=="" (
    echo [ERROR] Could not read watch WiFi IPv4 address. Is WiFi connected on the watch?
    adb devices
    exit /b 1
)
echo   Watch IP: %WIP%

echo [4/4] Connecting over WiFi ...
adb connect %WIP%:%PORT% || exit /b 1
adb devices
echo DONE - you can unplug the USB cable now.
exit /b 0
