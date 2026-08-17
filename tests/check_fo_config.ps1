$foConfig = "A:\MultiMC\instances\[FO][Fabric]1.21.1\.minecraft\config"
if (Test-Path "$foConfig\emi.json") {
    Get-Content "$foConfig\emi.json" | Select-Object -First 30
}
if (Test-Path "$foConfig\roughlyenoughitems\config.json5") {
    Get-Content "$foConfig\roughlyenoughitems\config.json5" | Select-Object -First 40
}
