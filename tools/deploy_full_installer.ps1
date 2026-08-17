$targetDir = "A:\MultiMC\instances\[HG][Fabric 1.21.1]\installer"
[System.IO.Directory]::CreateDirectory($targetDir)

$scratchDir = "C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch"

[System.IO.File]::Copy("$scratchDir\HGInstaller.exe", "$targetDir\HGInstaller.exe", $true)
[System.IO.File]::Copy("$scratchDir\HGInstaller.cs", "$targetDir\HGInstaller.cs", $true)
[System.IO.File]::Copy("$scratchDir\AssemblyInfo.cs", "$targetDir\AssemblyInfo.cs", $true)
[System.IO.File]::Copy("$scratchDir\app.manifest", "$targetDir\app.manifest", $true)

$buildBat = @"
@echo off
chcp 65001 >nul
echo ========================================================
echo  Компиляция HeroGuild Client Installer...
echo ========================================================

C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe /target:winexe /optimize /win32icon:app.ico /win32manifest:app.manifest /r:System.Web.Extensions.dll /r:System.IO.Compression.dll /r:System.IO.Compression.FileSystem.dll /r:System.Windows.Forms.dll /r:System.Drawing.dll /out:HGInstaller.exe AssemblyInfo.cs HGInstaller.cs

if %ERRORLEVEL% EQU 0 (
    echo.
    echo  [УСПЕХ] HGInstaller.exe успешно скомпилирован!
    echo ========================================================
) else (
    echo.
    echo  [ОШИБКА] Произошла ошибка компиляции.
    echo ========================================================
)
pause
"@

[System.IO.File]::WriteAllText("$targetDir\build.bat", $buildBat, [System.Text.Encoding]::UTF8)

Write-Host "All installer files successfully deployed to $targetDir!"

$v = [System.Diagnostics.FileVersionInfo]::GetVersionInfo("$targetDir\HGInstaller.exe")
Write-Host "Product Name: $($v.ProductName)"
Write-Host "Company Name: $($v.CompanyName)"
Write-Host "File Description: $($v.FileDescription)"
Write-Host "Copyright: $($v.LegalCopyright)"
Write-Host "Version: $($v.FileVersion)"
