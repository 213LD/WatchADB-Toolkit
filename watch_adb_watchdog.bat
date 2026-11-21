@echo off
setlocal
REM Poll for an authorized ADB device or a non-MTP USB PID change.
REM Usage: watch_adb_watchdog.bat [VID_filter_or_NONE] [MTP_PID_to_ignore] [max_iterations]

set "VID=%~1"
if "%VID%"=="" set "VID=VID_2ECC"

set "MTP_PID=%~2"
if "%MTP_PID%"=="" set "MTP_PID=PID_2001"

set "MAX_ITER=%~3"
if "%MAX_ITER%"=="" set "MAX_ITER=60"

for /L %%i in (1,1,%MAX_ITER%) do (
    adb devices 2>nul | findstr /V /C:"List of" | findstr /E /C:"device" >nul 2>&1
    if not errorlevel 1 (
        echo ADB_SEEN
        adb devices
        goto :DONE
    )
    if /I not "%VID%"=="NONE" (
        pnputil /enum-devices /connected 2>nul | findstr /I "%VID%" | findstr /V /I "%MTP_PID%" >nul 2>&1
        if not errorlevel 1 (
            echo NEW_USB_PID_SEEN
            pnputil /enum-devices /connected | findstr /I "%VID%"
            goto :DONE
        )
    )
    echo waiting %%i/%MAX_ITER% ...
    ping -n 6 127.0.0.1 >nul
)
echo TIMEOUT
exit /b 1

:DONE
exit /b 0
