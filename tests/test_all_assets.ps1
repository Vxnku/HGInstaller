Add-Type -AssemblyName System.Web.Extensions
$jsonText = [System.IO.File]::ReadAllText('f:\.Repos\HGInstaller\tools\modrinth.index.json', [System.Text.Encoding]::UTF8)
$js = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$js.MaxJsonLength = [int]::MaxValue
$data = $js.DeserializeObject($jsonText)

$failed = 0
$passed = 0

foreach ($f in $data["files"]) {
    $url = $f["downloads"][0]
    if ($url.Contains("vxnku.github.io") -or $url.Contains("github.com")) {
        try {
            $req = [System.Net.HttpWebRequest]::Create($url)
            $req.UserAgent = "Mozilla/5.0"
            $req.Timeout = 10000
            $res = $req.GetResponse()
            Write-Host "[OK 200] $($f['path']) ($($res.ContentLength) bytes)"
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
