$src = "A:\MultiMC\instances\[HG][Fabric 1.21.1]\installer\discord-round-color-icon.png"
$dst = "C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch\discord.png"
[System.IO.File]::Copy($src, $dst, $true)
Write-Host "Copied discord.png to scratch!"
