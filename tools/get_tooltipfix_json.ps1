[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$wc = New-Object System.Net.WebClient
$wc.Headers.Add("User-Agent", "HeroGuild-Dev")

$url = "https://api.modrinth.com/v2/project/tooltipfix/version?game_versions=[%221.21.1%22]&loaders=[%22fabric%22]"
$json = $wc.DownloadString($url)
$versions = $json | ConvertFrom-Json

Write-Host "Found $($versions.Count) versions for 1.21.1:"
foreach ($v in $versions) {
    Write-Host "Version: $($v.version_number), name: $($v.name)"
    foreach ($f in $v.files) {
        Write-Host "   File: $($f.filename), url: $($f.url)"
    }
}
