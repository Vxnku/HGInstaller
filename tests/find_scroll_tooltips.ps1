[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$wc = New-Object System.Net.WebClient
$wc.Headers.Add("User-Agent", "HeroGuild-Dev")

$candidates = @("scrollable-tooltips", "tooltip-scroller", "tooltip-scroll", "overflowing-bars", "prism")
foreach ($c in $candidates) {
    try {
        $url = "https://api.modrinth.com/v2/project/$c/version?game_versions=[%221.21.1%22]&loaders=[%22fabric%22]"
        $json = $wc.DownloadString($url)
        $versions = $json | ConvertFrom-Json
        Write-Host "$c => Found $($versions.Count) versions on Modrinth"
        if ($versions.Count -gt 0) {
            Write-Host "   Latest: $($versions[0].version_number) - $($versions[0].files[0].filename) - $($versions[0].files[0].url)"
        }
    } catch {
        Write-Host "$c => Not found"
    }
}
