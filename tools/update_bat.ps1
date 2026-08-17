$targetBat = "A:\MultiMC\instances\[HG][Fabric 1.21.1]\installer\build.bat"

$batContent = @"
@echo off
setlocal
cd /d "%~dp0"
echo ========================================================
echo  Compiling HeroGuild Client Installer...
echo ========================================================

if not exist modpack.mrpack (
    if exist "[HG][Fabric 1.21.1].mrpack" copy /y "[HG][Fabric 1.21.1].mrpack" modpack.mrpack >nul
)

set CSC=C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe

"%CSC%" /target:winexe /optimize /win32icon:app.ico /win32manifest:app.manifest /resource:modpack.mrpack,EmbeddedModpack.mrpack /r:System.Web.Extensions.dll /r:System.IO.Compression.dll /r:System.IO.Compression.FileSystem.dll /r:System.Windows.Forms.dll /r:System.Drawing.dll /out:HGInstaller.exe AssemblyInfo.cs HGInstaller.cs

if %ERRORLEVEL% EQU 0 (
    echo.
    echo  [SUCCESS] HGInstaller.exe compiled successfully!
    echo  All assets and modpack are embedded into a single EXE.
    echo ========================================================
) else (
    echo.
    echo  [ERROR] Compilation failed.
    echo ========================================================
)
pause
"@

[System.IO.File]::WriteAllText($targetBat, $batContent, [System.Text.Encoding]::ASCII)
Write-Host "Updated build.bat in ASCII format!"
