Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

$url = "https://github.com/Vxnku/-HG-HGMM/archive/refs/heads/main.zip"
$tmpZip = "C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch\github_main.zip"

Write-Host "Downloading $url ..."
$wc = New-Object System.Net.WebClient
$wc.Headers.Add("User-Agent", "HeroGuild-Installer")
$wc.DownloadFile($url, $tmpZip)

$fi = Get-Item $tmpZip
Write-Host "Downloaded size: $([math]::Round($fi.Length / 1MB, 2)) MB"

$zip = [System.IO.Compression.ZipFile]::OpenRead($tmpZip)
Write-Host "Total entries in GitHub zip: $($zip.Entries.Count)"
Write-Host "Sample entry: $($zip.Entries[0].FullName)"
$zip.Dispose()
