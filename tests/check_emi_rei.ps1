$mods = Get-ChildItem -LiteralPath "A:\MultiMC\instances\[HG][Fabric 1.21.1]\.minecraft\mods" | Select-Object -Property Name
Write-Host "Mods count: $($mods.Count)"
$mods | Where-Object { $_.Name -match "emi|roughly|rei|jei" } | Format-Table

$configs = Get-ChildItem -LiteralPath "A:\MultiMC\instances\[HG][Fabric 1.21.1]\.minecraft\config" -ErrorAction SilentlyContinue | Select-Object -Property Name
$configs | Where-Object { $_.Name -match "emi|roughly|rei|jei" } | Format-Table
