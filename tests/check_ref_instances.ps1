$foMods = Get-ChildItem -LiteralPath "A:\MultiMC\instances\[FO][Fabric]1.21.1\.minecraft\mods" | Select-Object -Property Name
$foMods | Where-Object { $_.Name -match "tooltip|scroll|rei|emi|roughly" } | Format-Table

$mainMods = Get-ChildItem -LiteralPath "A:\MultiMC\instances\New- Main\.minecraft\mods" -ErrorAction SilentlyContinue | Select-Object -Property Name
if ($mainMods) {
    $mainMods | Where-Object { $_.Name -match "tooltip|scroll|rei|emi|roughly" } | Format-Table
}
