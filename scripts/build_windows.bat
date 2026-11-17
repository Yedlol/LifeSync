@echo off
setlocal
REM Builds the Windows release + installer -> dist\LifeSync-Setup-<version>.exe
cd /d "%~dp0.."

if not exist env.json (
  echo ERROR: env.json not found. Copy env.example.json to env.json and fill it in.
  exit /b 1
)

REM Version = text before "+" in pubspec.yaml "version: 1.0.0+1"
for /f "tokens=2 delims=: " %%v in ('findstr /b "version:" pubspec.yaml') do set FULLVER=%%v
for /f "tokens=1 delims=+" %%a in ("%FULLVER%") do set VER=%%a

REM Inno Setup compiler (default install locations)
set ISCC=
if exist "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe" set ISCC=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe
if exist "%ProgramFiles%\Inno Setup 6\ISCC.exe" set ISCC=%ProgramFiles%\Inno Setup 6\ISCC.exe
if exist "%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe" set ISCC=%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe
if "%ISCC%"=="" (
  echo ERROR: Inno Setup 6 not found. Install it from https://jrsoftware.org/isdl.php
  exit /b 1
)

call flutter build windows --release --dart-define-from-file=env.json
if errorlevel 1 exit /b 1

if not exist dist mkdir dist
"%ISCC%" /DAppVersion=%VER% installer\lifesync.iss
if errorlevel 1 exit /b 1

echo.
echo Done: dist\LifeSync-Setup-%VER%.exe
