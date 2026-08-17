$installerDir = "A:\MultiMC\instances\[HG][Fabric 1.21.1]\installer"
$scratchDir = "C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch"

[System.IO.File]::Copy("$scratchDir\AssemblyInfo.cs", "$installerDir\AssemblyInfo.cs", $true)
[System.IO.File]::Copy("$scratchDir\HGInstaller.cs", "$installerDir\HGInstaller.cs", $true)

$csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
& $csc /target:winexe /optimize+ /platform:anycpu /win32icon:"$installerDir\app.ico" /win32manifest:"$installerDir\app.manifest" /resource:"$scratchDir\logo.png,HGLogo.png" /resource:"$scratchDir\discord.png,DiscordLogo.png" /r:System.Web.Extensions.dll /r:System.IO.Compression.dll /r:System.IO.Compression.FileSystem.dll /r:System.Windows.Forms.dll /r:System.Drawing.dll /out:"$installerDir\HGInstaller.exe" "$installerDir\AssemblyInfo.cs" "$installerDir\HGInstaller.cs"

Write-Host "Compiled clean HGInstaller.exe!"
