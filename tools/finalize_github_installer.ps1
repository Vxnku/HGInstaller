$installerDir = "A:\MultiMC\instances\[HG][Fabric 1.21.1]\installer"
$scratchDir = "C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch"

# 1. Copy clean 8KB mrpack
[System.IO.File]::Copy("$scratchDir\modpack.mrpack", "$installerDir\[HG][Fabric 1.21.1].mrpack", $true)

# 2. Copy updated HGInstaller.cs
[System.IO.File]::Copy("$scratchDir\HGInstaller.cs", "$installerDir\HGInstaller.cs", $true)

Write-Host "Updated installer directory successfully!"
