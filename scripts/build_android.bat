@echo off
setlocal
REM Builds the signed release APK -> dist\LifeSync-<version>.apk
cd /d "%~dp0.."

if not exist env.json (
  echo ERROR: env.json not found. Copy env.example.json to env.json and fill it in.
  exit /b 1
)
if not exist android\key.properties (
  echo ERROR: android\key.properties not found, so the APK would NOT be release-signed.
  echo        Create the keystore and key.properties first ^(see README^).
  exit /b 1
)

REM Version = text before "+" in pubspec.yaml "version: 1.0.0+1"
for /f "tokens=2 delims=: " %%v in ('findstr /b "version:" pubspec.yaml') do set FULLVER=%%v
for /f "tokens=1 delims=+" %%a in ("%FULLVER%") do set VER=%%a

call flutter build apk --release --dart-define-from-file=env.json
if errorlevel 1 exit /b 1

if not exist dist mkdir dist
copy /y build\app\outputs\flutter-apk\app-release.apk dist\LifeSync-%VER%.apk >nul
if errorlevel 1 exit /b 1

echo.
echo Done: dist\LifeSync-%VER%.apk
