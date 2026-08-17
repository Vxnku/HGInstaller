$mods = Get-ChildItem -LiteralPath "A:\MultiMC\instances\[HG][Fabric 1.21.1]\.minecraft\mods" | Select-Object -Property Name
$mods | Where-Object { $_.Name -match "tooltip" } | Format-Table

$configs = Get-ChildItem -LiteralPath "A:\MultiMC\instances\[HG][Fabric 1.21.1]\.minecraft\config" -ErrorAction SilentlyContinue | Select-Object -Property Name
$configs | Where-Object { $_.Name -match "tooltip" } | Format-Table
