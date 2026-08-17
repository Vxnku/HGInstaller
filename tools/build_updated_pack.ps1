Add-Type -AssemblyName System.Web.Extensions
Add-Type -AssemblyName System.IO.Compression.FileSystem

$scratch = "C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch"
$installerDir = "A:\MultiMC\instances\[HG][Fabric 1.21.1]\installer"
$modsDir = "A:\MultiMC\instances\[HG][Fabric 1.21.1]\.minecraft\mods"

# 1. Read existing modrinth.index.json template
$origJson = Get-Content "$scratch\modrinth.index.json" -Raw -Encoding UTF8
$js = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$js.MaxJsonLength = [int]::MaxValue
$indexObj = $js.DeserializeObject($origJson)

# 2. Filter out roughlyenoughitems from files list
$newFiles = New-Object System.Collections.Generic.List[Object]

foreach ($f in $indexObj["files"]) {
    $p = $f["path"]
    if ($p -match "roughlyenoughitems") {
        Write-Host "Excluded: $p"
        continue
    }
    # Keep others
    $newFiles.Add($f)
}

# 3. Add tooltip-scroll-1.5.1+1.21.1.jar if not present
$tsPath = "$modsDir\tooltip-scroll-1.5.1+1.21.1.jar"
if (Test-Path -LiteralPath $tsPath) {
    $sha1 = (Get-FileHash -Path $tsPath -Algorithm SHA1).Hash.ToLower()
    $sha512 = (Get-FileHash -Path $tsPath -Algorithm SHA512).Hash.ToLower()
    $len = (Get-Item -LiteralPath $tsPath).Length

    $tsEntry = @{
        "path" = "mods/tooltip-scroll-1.5.1+1.21.1.jar"
        "hashes" = @{
            "sha1" = $sha1
            "sha512" = $sha512
        }
        "downloads" = @("https://cdn.modrinth.com/data/wySVd6d8/versions/xIlfYF85/tooltip-scroll-1.5.1%2B1.21.1.jar")
        "fileSize" = $len
    }
    $newFiles.Add($tsEntry)
    Write-Host "Added: mods/tooltip-scroll-1.5.1+1.21.1.jar"
}

# 4. Add Советую Vanilla Tweaks!.file if not present
$vtUrl = "https://github.com/Vxnku/-HG-HGMM/raw/main/%D0%A1%D0%BE%D0%B2%D0%B5%D1%82%D1%83%D1%8E%20Vanilla%20Tweaks!.file"
$vtEntry = @{
    "path" = "resourcepacks/Советую Vanilla Tweaks!.file"
    "hashes" = @{
        "sha1" = "da39a3ee5e6b4b0d3255bfef95601890afd80709"
        "sha512" = "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e"
    }
    "downloads" = @($vtUrl)
    "fileSize" = 0
}
$newFiles.Add($vtEntry)
Write-Host "Added: resourcepacks/Советую Vanilla Tweaks!.file"

$indexObj["files"] = $newFiles.ToArray()
Write-Host "Total files in new modpack: $($indexObj['files'].Count)"

$finalJson = $js.Serialize($indexObj)
[System.IO.File]::WriteAllText("$scratch\modrinth.index.json", $finalJson, [System.Text.Encoding]::UTF8)

# 5. Pack into [HG][Fabric 1.21.1].mrpack
$mrpackPath = "$installerDir\[HG][Fabric 1.21.1].mrpack"
if (Test-Path -LiteralPath $mrpackPath) {
    Remove-Item -LiteralPath $mrpackPath -Force
}

$zip = [System.IO.Compression.ZipFile]::Open($mrpackPath, [System.IO.Compression.ZipArchiveMode]::Create)
$entry = $zip.CreateEntry("modrinth.index.json", [System.IO.Compression.CompressionLevel]::Optimal)
$stream = $entry.Open()
$writer = New-Object System.IO.StreamWriter($stream, [System.Text.Encoding]::UTF8)
$writer.Write($finalJson)
$writer.Flush()
$writer.Dispose()
$stream.Dispose()
$zip.Dispose()

Write-Host "Updated mrpack created at: $mrpackPath (Size: $((Get-Item -LiteralPath $mrpackPath).Length) bytes)"
