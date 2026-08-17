# PowerShell build script for HeroGuild Client Installer
$ErrorActionPreference = "Stop"
$srcDir = $PSScriptRoot
$outExe = Join-Path $srcDir "..\HGInstaller.exe"
$outExe = [System.IO.Path]::GetFullPath($outExe)

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  Building HeroGuild Client Installer..." -ForegroundColor Cyan
Write-Host "  Source: $srcDir" -ForegroundColor DarkGray
Write-Host "  Output: $outExe" -ForegroundColor DarkGray
Write-Host "========================================================" -ForegroundColor Cyan

$csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (-not (Test-Path $csc)) {
    $csc = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
}

if (-not (Test-Path $csc)) {
    Write-Error "csc.exe (.NET Framework 4.0/4.8) not found on system!"
    exit 1
}

$icoPath = Join-Path $srcDir "app.ico"
$manifestPath = Join-Path $srcDir "app.manifest"
$logoPath = Join-Path $srcDir "logo.png"
$discordPath = Join-Path $srcDir "discord.png"
$assemblyInfo = Join-Path $srcDir "AssemblyInfo.cs"
$mainCs = Join-Path $srcDir "HGInstaller.cs"

& $csc /target:winexe /optimize+ /platform:anycpu /win32icon:"$icoPath" /win32manifest:"$manifestPath" /resource:"$logoPath,HGLogo.png" /resource:"$discordPath,DiscordLogo.png" /r:System.Web.Extensions.dll /r:System.IO.Compression.dll /r:System.IO.Compression.FileSystem.dll /r:System.Windows.Forms.dll /r:System.Drawing.dll /out:"$outExe" "$assemblyInfo" "$mainCs"

if ($LASTEXITCODE -eq 0) {
    $fi = Get-Item $outExe
    $kb = [math]::Round($fi.Length / 1024, 2)
    Write-Host ""
    Write-Host "[SUCCESS] HGInstaller.exe compiled successfully!" -ForegroundColor Green
    Write-Host "Size: $($fi.Length) bytes ($kb KB)" -ForegroundColor Green
    Write-Host "Output: $($fi.FullName)" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "[ERROR] Compilation failed." -ForegroundColor Red
}
