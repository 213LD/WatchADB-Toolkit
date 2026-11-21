@echo off
setlocal EnableDelayedExpansion
set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%" || exit /b 1
for %%I in ("%SCRIPT_DIR%..") do set "ROOT_DIR=%%~fI"

set "SDK_DIR="
if defined ANDROID_HOME if exist "%ANDROID_HOME%" set "SDK_DIR=%ANDROID_HOME%"
if not defined SDK_DIR if defined ANDROID_SDK_ROOT if exist "%ANDROID_SDK_ROOT%" set "SDK_DIR=%ANDROID_SDK_ROOT%"
if not defined SDK_DIR if exist "%LOCALAPPDATA%\Android\Sdk" set "SDK_DIR=%LOCALAPPDATA%\Android\Sdk"
if not defined SDK_DIR (
    echo [ERROR] Android SDK not found. Set ANDROID_HOME or ANDROID_SDK_ROOT.
    popd
    exit /b 1
)

if not defined BUILD_TOOLS (
    for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "$p=Join-Path $env:SDK_DIR 'build-tools'; Get-ChildItem -Path $p -Directory -ErrorAction SilentlyContinue | Where-Object { (Test-Path (Join-Path $_.FullName 'aapt2.exe')) -and (Test-Path (Join-Path $_.FullName 'd8.bat')) } | Sort-Object { try { [version]($_.Name -replace '-.*$','') } catch { [version]'0.0' } } | Select-Object -Last 1 -ExpandProperty FullName"`) do set "BUILD_TOOLS=%%D"
)
if not defined BUILD_TOOLS (
    echo [ERROR] No valid Android build-tools found under "%SDK_DIR%\build-tools".
    popd
    exit /b 1
)

if not defined ANDROID_JAR (
    for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "$p=Join-Path $env:SDK_DIR 'platforms'; Get-ChildItem -Path $p -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path (Join-Path $_.FullName 'android.jar') } | Sort-Object { if ($_.Name -match '^android-(\d+)') { [int]$matches[1] } else { 0 } } | Select-Object -Last 1 -ExpandProperty FullName"`) do set "ANDROID_JAR=%%D\android.jar"
)
if not exist "%ANDROID_JAR%" (
    echo [ERROR] android.jar not found under "%SDK_DIR%\platforms".
    popd
    exit /b 1
)

if not defined KEYSTORE set "KEYSTORE=%ROOT_DIR%\debug.keystore"
if not defined KEY_ALIAS set "KEY_ALIAS=androiddebugkey"
if not defined KS_PASS set "KS_PASS=android"
if not defined KEY_PASS set "KEY_PASS=android"

if not exist "%KEYSTORE%" (
    echo [INFO] Generating debug keystore at "%KEYSTORE%" ...
    keytool -genkeypair -keystore "%KEYSTORE%" -alias "%KEY_ALIAS%" -storepass "%KS_PASS%" -keypass "%KEY_PASS%" -dname "CN=Android Debug,O=Android,C=US" -keyalg RSA -keysize 2048 -validity 10000 || (popd & exit /b 1)
)

echo [INFO] Using build-tools: %BUILD_TOOLS%
echo [INFO] Using platform:    %ANDROID_JAR%

if exist obj rmdir /s /q obj
mkdir obj || (popd & exit /b 1)
if exist base.apk del /f /q base.apk
if exist aligned.apk del /f /q aligned.apk
if exist classes.dex del /f /q classes.dex
if exist *.idsig del /f /q *.idsig
if exist DevSettingsLauncher.apk del /f /q DevSettingsLauncher.apk

"%BUILD_TOOLS%\aapt2.exe" link -o base.apk -I "%ANDROID_JAR%" --manifest AndroidManifest.xml || (popd & exit /b 1)
javac -encoding UTF-8 -source 8 -target 8 -nowarn -bootclasspath "%ANDROID_JAR%" -d obj src\com\example\devlaunch\*.java || (popd & exit /b 1)
call "%BUILD_TOOLS%\d8.bat" --min-api 17 --lib "%ANDROID_JAR%" --output . obj\com\example\devlaunch\*.class || (popd & exit /b 1)
if not exist classes.dex (
    echo [ERROR] d8 did not produce classes.dex
    popd
    exit /b 1
)

powershell -NoProfile -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; $zip=[System.IO.Compression.ZipFile]::Open((Resolve-Path 'base.apk').Path,'Update'); [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,(Resolve-Path 'classes.dex').Path,'classes.dex','Optimal') | Out-Null; $zip.Dispose()" || (popd & exit /b 1)

"%BUILD_TOOLS%\zipalign.exe" -f 4 base.apk aligned.apk || (popd & exit /b 1)
call "%BUILD_TOOLS%\apksigner.bat" sign --ks "%KEYSTORE%" --ks-key-alias "%KEY_ALIAS%" --ks-pass "pass:%KS_PASS%" --key-pass "pass:%KEY_PASS%" --out DevSettingsLauncher.apk aligned.apk || (popd & exit /b 1)
call "%BUILD_TOOLS%\apksigner.bat" verify --print-certs DevSettingsLauncher.apk || (popd & exit /b 1)

if not exist "%ROOT_DIR%\dist" mkdir "%ROOT_DIR%\dist"
copy /y "DevSettingsLauncher.apk" "%ROOT_DIR%\dist\DevSettingsLauncher.apk" >nul || (popd & exit /b 1)
copy /y "DevSettingsLauncher.apk" "%ROOT_DIR%\dist\1.apk" >nul || (popd & exit /b 1)

echo BUILD_OK
popd
exit /b 0
