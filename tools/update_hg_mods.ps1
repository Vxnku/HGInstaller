[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$wc = New-Object System.Net.WebClient
$wc.Headers.Add("User-Agent", "HeroGuild-Dev")

$modsDir = "A:\MultiMC\instances\[HG][Fabric 1.21.1]\.minecraft\mods"

# 1. Remove RoughlyEnoughItems jar to prevent duplicate sidebar
$reiJar = Path-Combine $modsDir "RoughlyEnoughItems-16.0.799-fabric.jar"
if (Test-Path -LiteralPath "$modsDir\RoughlyEnoughItems-16.0.799-fabric.jar") {
    Remove-Item -LiteralPath "$modsDir\RoughlyEnoughItems-16.0.799-fabric.jar" -Force
    Write-Host "Removed duplicate RoughlyEnoughItems jar (EMI remains)."
}

# 2. Download tooltip-scroll-1.5.1+1.21.1.jar
$tooltipScrollUrl = "https://cdn.modrinth.com/data/wySVd6d8/versions/xIlfYF85/tooltip-scroll-1.5.1%2B1.21.1.jar"
$tooltipScrollDst = "$modsDir\tooltip-scroll-1.5.1+1.21.1.jar"
if (-not (Test-Path -LiteralPath $tooltipScrollDst)) {
    $wc.DownloadFile($tooltipScrollUrl, $tooltipScrollDst)
    Write-Host "Downloaded tooltip-scroll-1.5.1+1.21.1.jar!"
}
