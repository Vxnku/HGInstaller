$targetDir = "A:\MultiMC\instances\[HG][Fabric 1.21.1]\installer"
[System.IO.Directory]::CreateDirectory($targetDir)

$scratchDir = "C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch"

[System.IO.File]::Copy("$scratchDir\HGInstaller.exe", "$targetDir\HGInstaller.exe", $true)
[System.IO.File]::Copy("$scratchDir\HGInstaller.cs", "$targetDir\HGInstaller.cs", $true)
[System.IO.File]::Copy("$scratchDir\AssemblyInfo.cs", "$targetDir\AssemblyInfo.cs", $true)
[System.IO.File]::Copy("$scratchDir\app.manifest", "$targetDir\app.manifest", $true)
[System.IO.File]::Copy("$scratchDir\modpack.mrpack", "$targetDir\modpack.mrpack", $true)

$buildBat = @"
@echo off
chcp 65001 >nul
echo ========================================================
echo  Компиляция HeroGuild Single-File Standalone Installer...
echo ========================================================

if not exist modpack.mrpack (
    if exist "[HG][Fabric 1.21.1].mrpack" copy /y "[HG][Fabric 1.21.1].mrpack" modpack.mrpack >nul
)

C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe /target:winexe /optimize /win32icon:app.ico /win32manifest:app.manifest /resource:modpack.mrpack,EmbeddedModpack.mrpack /r:System.Web.Extensions.dll /r:System.IO.Compression.dll /r:System.IO.Compression.FileSystem.dll /r:System.Windows.Forms.dll /r:System.Drawing.dll /out:HGInstaller.exe AssemblyInfo.cs HGInstaller.cs

if %ERRORLEVEL% EQU 0 (
    echo.
    echo  [УСПЕХ] Готовый автономный HGInstaller.exe успешно собран!
    echo  Все ресурсы и сборка вшиты в один .exe файл.
    echo ========================================================
) else (
    echo.
    echo  [ОШИБКА] Произошла ошибка компиляции.
    echo ========================================================
)
pause
"@

[System.IO.File]::WriteAllText("$targetDir\build.bat", $buildBat, [System.Text.Encoding]::UTF8)

Write-Host "All files deployed successfully to $targetDir!"

$v = [System.Diagnostics.FileVersionInfo]::GetVersionInfo("$targetDir\HGInstaller.exe")
Write-Host "File: $($v.FileName)"
Write-Host "Product Name: $($v.ProductName)"
Write-Host "Company Name: $($v.CompanyName)"
Write-Host "File Version: $($v.FileVersion)"
Write-Host "File Size: $((Get-Item "$targetDir\HGInstaller.exe").Length) bytes"
