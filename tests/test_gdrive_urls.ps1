$gdriveMap = Get-Content 'f:\.Repos\HGInstaller\upload_script\gdrive_files.json' | ConvertFrom-Json

foreach ($prop in $gdriveMap.files.PSObject.Properties) {
    $name = $prop.Name
    $url = $prop.Value.download_url
    try {
        $req = [System.Net.HttpWebRequest]::Create($url)
        $req.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        $req.AllowAutoRedirect = $true
        $req.CookieContainer = New-Object System.Net.CookieContainer
        $res = $req.GetResponse()
        Write-Host "[OK 200] $name (Length: $($res.ContentLength))"
        $res.Dispose()
    } catch {
        Write-Host "[FAIL] $name -> $url : $($_.Exception.Message)"
    }
}
