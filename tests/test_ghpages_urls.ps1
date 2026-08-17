$urls = @(
    'https://vxnku.github.io/-HG-HGMM/server_info.json',
    'https://vxnku.github.io/-HG-HGMM/mods/customblocklayer-0.1.jar',
    'https://vxnku.github.io/-HG-HGMM/zips/%5BRP%5D%5BHG%5D%20Invisible%20Glint.zip',
    'https://vxnku.github.io/-HG-HGMM/zips/%5BRP%5D%5BHG%5D%20Morioh%20o%20Somero!.zip',
    'https://vxnku.github.io/-HG-HGMM/zips/%5BRP%5D%5BHG%5DCustomBlockLayer%20Content.zip',
    'https://vxnku.github.io/-HG-HGMM/zips/%5BRP%5D%5BHG%5DMythical%20Awaited%20Update.zip',
    'https://vxnku.github.io/-HG-HGMM/%D0%A1%D0%BE%D0%B2%D0%B5%D1%82%D1%83%D1%8E%20Vanilla%20Tweaks!.file'
)

foreach ($u in $urls) {
    try {
        $req = [System.Net.HttpWebRequest]::Create($u)
        $req.UserAgent = "Mozilla/5.0"
        $req.Timeout = 10000
        $res = $req.GetResponse()
        Write-Host "[OK 200] $u (Length: $($res.ContentLength))"
        $res.Dispose()
    } catch {
        Write-Host "[FAIL] $u : $($_.Exception.Message)"
    }
}
