$targetDir = "A:\MultiMC\instances\[HG][Fabric 1.21.1]\installer"
[System.IO.Directory]::CreateDirectory($targetDir)

[System.IO.File]::Copy("C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch\HGInstaller.exe", "$targetDir\HGInstaller.exe", $true)
[System.IO.File]::Copy("C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch\HGInstaller.cs", "$targetDir\HGInstaller.cs", $true)

$buildBat = @"
@echo off
chcp 65001 >nul
echo Компиляция HeroGuild Installer...
C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe /target:winexe /optimize /r:System.Web.Extensions.dll /r:System.IO.Compression.dll /r:System.IO.Compression.FileSystem.dll /r:System.Windows.Forms.dll /r:System.Drawing.dll /out:HGInstaller.exe HGInstaller.cs
if %ERRORLEVEL% EQU 0 (
    echo [УСПЕХ] HGInstaller.exe успешно скомпилирован!
) else (
    echo [ОШИБКА] Ошибка при компиляции.
)
pause
"@

[System.IO.File]::WriteAllText("$targetDir\build.bat", $buildBat, [System.Text.Encoding]::UTF8)
Write-Host "Files created and copied successfully to $targetDir!"
