Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Web.Extensions

$scratch = "C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch"
$installerDir = "A:\MultiMC\instances\[HG][Fabric 1.21.1]\installer"
$modsDir = "A:\MultiMC\instances\[HG][Fabric 1.21.1]\.minecraft\mods"

# Compute sha1 and sha512 using .NET
function Get-Hashes($filePath) {
    $sha1Alg = [System.Security.Cryptography.SHA1]::Create()
    $sha512Alg = [System.Security.Cryptography.SHA512]::Create()
    
    $stream1 = [System.IO.File]::OpenRead($filePath)
    $hash1 = [BitConverter]::ToString($sha1Alg.ComputeHash($stream1)).Replace("-", "").ToLower()
    $stream1.Dispose()

    $stream2 = [System.IO.File]::OpenRead($filePath)
    $hash512 = [BitConverter]::ToString($sha512Alg.ComputeHash($stream2)).Replace("-", "").ToLower()
    $stream2.Dispose()

    return @{ "sha1" = $hash1; "sha512" = $hash512 }
}

$origJson = [System.IO.File]::ReadAllText("$scratch\modrinth.index.json", [System.Text.Encoding]::UTF8)
$js = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$js.MaxJsonLength = [int]::MaxValue
$indexObj = $js.DeserializeObject($origJson)

$newFiles = New-Object System.Collections.Generic.List[Object]

foreach ($f in $indexObj["files"]) {
    $p = $f["path"]
    if ($p -match "roughlyenoughitems|tooltip-scroll|Советую") {
        continue
    }
    $newFiles.Add($f)
}

# Add tooltip-scroll
$tsPath = "$modsDir\tooltip-scroll-1.5.1+1.21.1.jar"
if (Test-Path -LiteralPath $tsPath) {
    $h = Get-Hashes $tsPath
    $len = (Get-Item -LiteralPath $tsPath).Length

    $tsEntry = @{
        "path" = "mods/tooltip-scroll-1.5.1+1.21.1.jar"
        "hashes" = @{
            "sha1" = $h["sha1"]
            "sha512" = $h["sha512"]
        }
        "downloads" = @("https://cdn.modrinth.com/data/wySVd6d8/versions/xIlfYF85/tooltip-scroll-1.5.1%2B1.21.1.jar")
        "fileSize" = $len
    }
    $newFiles.Add($tsEntry)
    Write-Host "Added tooltip-scroll (SHA1: $($h['sha1']))"
}

# Add Советую Vanilla Tweaks!.file
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
Write-Host "Added Советую Vanilla Tweaks!.file"

$indexObj["files"] = $newFiles.ToArray()
Write-Host "Total files in modpack: $($indexObj['files'].Count)"

$finalJson = $js.Serialize($indexObj)
$jsonPath = "$scratch\modrinth.index.json"
[System.IO.File]::WriteAllText($jsonPath, $finalJson, [System.Text.Encoding]::UTF8)

# Pack into .mrpack
$mrpackPath = "$installerDir\[HG][Fabric 1.21.1].mrpack"
if (Test-Path -LiteralPath $mrpackPath) {
    Remove-Item -LiteralPath $mrpackPath -Force
}

$tempFolder = "$scratch\temp_mrpack"
if (Test-Path -LiteralPath $tempFolder) { Remove-Item -LiteralPath $tempFolder -Recurse -Force }
New-Item -ItemType Directory -Path $tempFolder | Out-Null
[System.IO.File]::Copy($jsonPath, "$tempFolder\modrinth.index.json", $true)

[System.IO.Compression.ZipFile]::CreateFromDirectory($tempFolder, $mrpackPath)
Remove-Item -LiteralPath $tempFolder -Recurse -Force

$fi = Get-Item -LiteralPath $mrpackPath
Write-Host "Successfully built mrpack at $mrpackPath (Size: $($fi.Length) bytes)"
