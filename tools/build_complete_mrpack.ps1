Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Web.Extensions

$mrpackPath = "C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch\modpack.mrpack"

$zip = [System.IO.Compression.ZipFile]::OpenRead($mrpackPath)
$entry = $zip.GetEntry("modrinth.index.json")
$reader = New-Object System.IO.StreamReader($entry.Open(), [System.Text.Encoding]::UTF8)
$jsonContent = $reader.ReadToEnd()
$reader.Dispose()
$zip.Dispose()

$serializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$serializer.MaxJsonLength = [int]::MaxValue
$data = $serializer.DeserializeObject($jsonContent)

# Filter out existing resourcepack entries if any
$filteredFiles = @()
foreach ($f in $data["files"]) {
    if (-not $f["path"].StartsWith("resourcepacks/")) {
        $filteredFiles += $f
    }
}

# Add 3 GitHub resource packs
$rp1 = @{
    "path" = "resourcepacks/[RP][HG] Invisible Glint.zip"
    "fileSize" = 2261
    "hashes" = @{
        "sha1" = "18ed9652bb77fd843f137fc92e180e14f3d6e683"
        "sha512" = "225faee14e87251c0e42c06dcd664a756a13f29d125dcdf117a58c1e8c46dced08df6bd355dc24b14132a1d4cbbfc6227988b23092fd8540865c679e4a25614c"
    }
    "downloads" = @("https://github.com/Vxnku/-HG-HGMM/raw/main/zips/%5BRP%5D%5BHG%5D%20Invisible%20Glint.zip")
}

$rp2 = @{
    "path" = "resourcepacks/[RP][HG] Morioh o Somero!.zip"
    "fileSize" = 148343
    "hashes" = @{
        "sha1" = "91af8494765d9f222faa11d2b0af4ee213834df0"
        "sha512" = "7910c9c4a8ea472c7d20662e1fac75ce24785ed671ef3b297c5e72af1b368f5edac9cd50d3a50d0aa71d9abb03887cba999241f198f3c080b597a09ef1c75244"
    }
    "downloads" = @("https://github.com/Vxnku/-HG-HGMM/raw/main/zips/%5BRP%5D%5BHG%5D%20Morioh%20o%20Somero%21.zip")
}

$rp3 = @{
    "path" = "resourcepacks/[RP][HG]Mythical Awaited Update.zip"
    "fileSize" = 58776601
    "hashes" = @{
        "sha1" = "0cc55a4b2fbb452bdc1269362c420f5940fba8ed"
        "sha512" = "628873912b1cc26d21a68b185cbe4abce97b597f316a3875912be93ad05e0384b80d9708dc1ce798a33dc41296c1b73b3ee66dbac63efd18609e30687e8a000e"
    }
    "downloads" = @("https://github.com/Vxnku/-HG-HGMM/raw/main/zips/%5BRP%5D%5BHG%5DMythical%20Awaited%20Update.zip")
}

$filteredFiles += $rp1
$filteredFiles += $rp2
$filteredFiles += $rp3

$data["files"] = $filteredFiles

$newJson = $serializer.Serialize($data)
$outJsonPath = "C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch\modrinth.index.json"
[System.IO.File]::WriteAllText($outJsonPath, $newJson, [System.Text.Encoding]::UTF8)

# Re-create lightweight mrpack
$newMrpackPath = "C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch\new_modpack.mrpack"
if (Test-Path $newMrpackPath) { Remove-Item $newMrpackPath -Force }

$newZip = [System.IO.Compression.ZipFile]::Open($newMrpackPath, [System.IO.Compression.ZipArchiveMode]::Create)
[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($newZip, $outJsonPath, "modrinth.index.json", [System.IO.Compression.CompressionLevel]::Optimal)
$newZip.Dispose()

$fi = Get-Item $newMrpackPath
Write-Host "Created new mrpack: $($fi.Length) bytes, total files listed: $($data['files'].Count)"
