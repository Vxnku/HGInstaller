[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$wc = New-Object System.Net.WebClient
$wc.Headers.Add("User-Agent", "Mozilla/5.0")

$url = "https://github.com/Vxnku/-HG-HGMM/raw/main/%D0%A1%D0%BE%D0%B2%D0%B5%D1%82%D1%83%D1%8E%20Vanilla%20Tweaks!.file"
try {
    $bytes = $wc.DownloadData($url)
    Write-Host "Downloaded successfully! Length: $($bytes.Length) bytes"
} catch {
    Write-Host "Error downloading: $_"
}
