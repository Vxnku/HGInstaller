$targetDir = "A:\MultiMC\instances\[HG][Fabric 1.21.1]\installer"
[System.IO.File]::Copy("C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch\HGInstaller.cs", "$targetDir\HGInstaller.cs", $true)
Write-Host "Updated HGInstaller.cs in installer directory!"
