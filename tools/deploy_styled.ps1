$targetDir = "A:\MultiMC\instances\[HG][Fabric 1.21.1]\installer"
[System.IO.Directory]::CreateDirectory($targetDir)

$scratchDir = "C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch"

[System.IO.File]::Copy("$scratchDir\HGInstaller.exe", "$targetDir\HGInstaller.exe", $true)
[System.IO.File]::Copy("$scratchDir\HGInstaller.cs", "$targetDir\HGInstaller.cs", $true)
[System.IO.File]::Copy("$scratchDir\logo.png", "$targetDir\logo.png", $true)

$batContent = @"
@echo off
setlocal
cd /d "%~dp0"
echo ========================================================
echo  Compiling HeroGuild Client Installer...
echo ========================================================

if not exist logo.png (
    if exist HGPackLogoFabric.png copy /y HGPackLogoFabric.png logo.png >nul
)

set CSC=C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe

"%CSC%" /target:winexe /optimize /win32icon:app.ico /win32manifest:app.manifest /resource:logo.png,HGLogo.png /r:System.Web.Extensions.dll /r:System.IO.Compression.dll /r:System.IO.Compression.FileSystem.dll /r:System.Windows.Forms.dll /r:System.Drawing.dll /out:HGInstaller.exe AssemblyInfo.cs HGInstaller.cs

if %ERRORLEVEL% EQU 0 (
    echo.
    echo  [SUCCESS] HGInstaller.exe compiled successfully!
    echo ========================================================
) else (
    echo.
    echo  [ERROR] Compilation failed.
    echo ========================================================
)
pause
"@

[System.IO.File]::WriteAllText("$targetDir\build.bat", $batContent, [System.Text.Encoding]::ASCII)
Write-Host "All updated files and build.bat deployed successfully to $targetDir!"
