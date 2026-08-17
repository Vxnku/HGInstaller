$f = "A:\MultiMC\instances\[HG][Fabric 1.21.1]\.minecraft\resourcepacks"
Get-ChildItem -LiteralPath $f | Select-Object -Property Name, Length, Mode
