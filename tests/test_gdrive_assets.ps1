Add-Type -AssemblyName System.Web.Extensions
$jsonText = [System.IO.File]::ReadAllText('f:\.Repos\HGInstaller\tools\modrinth.index.json', [System.Text.Encoding]::UTF8)
$js = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$js.MaxJsonLength = [int]::MaxValue
$data = $js.DeserializeObject($jsonText)

$failed = 0
$passed = 0

foreach ($f in $data["files"]) {
    $url = $f["downloads"][0]
    if ($url.Contains("drive.usercontent.google.com")) {
        try {
            $req = [System.Net.HttpWebRequest]::Create($url)
            $req.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
            $req.AllowAutoRedirect = $true
            $req.CookieContainer = New-Object System.Net.CookieContainer
            $req.Timeout = 15000
            $res = $req.GetResponse()
            Write-Host "[OK 200] $($f['path']) (Size: $($res.ContentLength) bytes)"
            $res.Dispose()
            $passed++
        } catch {
            Write-Host "[FAIL] $($f['path']) -> $url : $($_.Exception.Message)"
            $failed++
        }
    }
}

Write-Host ""
Write-Host "Verification: $passed passed, $failed failed."
