@echo off
setlocal
cd /d "%~dp0"

echo ========================================================
echo   Building HeroGuild Client Installer (x64)...
echo ========================================================
echo.

set CSC=C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe
if not exist "%CSC%" (
    set CSC=C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe
)

if not exist "%CSC%" (
    echo [ERROR] csc.exe not found on this system!
    pause
    exit /b 1
)

echo Compiling C# source code and embedding resources...
"%CSC%" /target:winexe /optimize+ /platform:x64 /debug:pdbonly /utf8output /win32icon:app.ico /win32manifest:app.manifest /resource:logo.png,HGLogo.png /resource:discord.png,DiscordLogo.png /r:System.Net.Http.dll /r:System.Web.Extensions.dll /r:System.IO.Compression.dll /r:System.IO.Compression.FileSystem.dll /r:System.Windows.Forms.dll /r:System.Drawing.dll /out:..\HGInstaller.exe AssemblyInfo.cs HGInstaller.cs

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================================
    echo  [SUCCESS] HGInstaller.exe compiled successfully!
    echo  Output saved to: ..\HGInstaller.exe
    echo ========================================================
) else (
    echo.
    echo ========================================================
    echo  [ERROR] Compilation failed.
    echo ========================================================
)

echo.
pause
