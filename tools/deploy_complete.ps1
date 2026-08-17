$installerDir = "A:\MultiMC\instances\[HG][Fabric 1.21.1]\installer"
$instanceDir = "A:\MultiMC\instances\[HG][Fabric 1.21.1]"
$scratchDir = "C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch"

# Copy new mrpack to installer and instance root
[System.IO.File]::Copy("$scratchDir\new_modpack.mrpack", "$installerDir\[HG][Fabric 1.21.1].mrpack", $true)
[System.IO.File]::Copy("$scratchDir\new_modpack.mrpack", "$instanceDir\[HG][Fabric 1.21.1].mrpack", $true)

# Copy updated HGInstaller.cs
[System.IO.File]::Copy("$scratchDir\HGInstaller.cs", "$installerDir\HGInstaller.cs", $true)

Write-Host "Updated installer and instance files successfully!"
