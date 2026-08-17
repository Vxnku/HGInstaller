Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Web.Extensions

$ErrorActionPreference = "Stop"

$root = "f:\.Repos\HGInstaller"
$test2 = "A:\MultiMC\instances\TEST2\.minecraft"
$repo = "$root\repo"
$repoZips = "$repo\zips"
$repoMods = "$repo\mods"
$tools = "$root\tools"

# 1. Ensure directories exist
if (-not (Test-Path $repoZips)) { New-Item -ItemType Directory -Path $repoZips -Force | Out-Null }
if (-not (Test-Path $repoMods)) { New-Item -ItemType Directory -Path $repoMods -Force | Out-Null }

# 2. Fix mojibake in TEST2 resourcepacks if present
$vtRussianName = [System.Text.Encoding]::UTF8.GetString(@(0xD0,0xA1,0xD0,0xBE,0xD0,0xB2,0xD0,0xB5,0xD1,0x82,0xD1,0x83,0xD1,0x8E,0x20,0x56,0x61,0x6E,0x69,0x6C,0x6C,0x61,0x20,0x54,0x77,0x65,0x61,0x6B,0x73,0x21,0x2E,0x66,0x69,0x6C,0x65))
# "Советую Vanilla Tweaks!.file"

$test2RP = "$test2\resourcepacks"
if (Test-Path $test2RP) {
    Get-ChildItem -LiteralPath $test2RP | Where-Object { $_.Name -like "*Vanilla Tweaks*.file" } | ForEach-Object {
        if ($_.Name -ne $vtRussianName) {
            Write-Host "Fixing mojibake filename in TEST2..."
            $targetFix = Join-Path $test2RP $vtRussianName
            if (Test-Path -LiteralPath $targetFix) { Remove-Item -LiteralPath $_.FullName -Force }
            else { Rename-Item -LiteralPath $_.FullName -NewName $vtRussianName -Force }
        }
    }
}

# 3. Copy customblocklayer mod to repo/mods
$cblSrc = "$test2\mods\customblocklayer-0.1.jar"
$cblDest = "$repoMods\customblocklayer-0.1.jar"
if (Test-Path -LiteralPath $cblSrc) {
    Copy-Item -LiteralPath $cblSrc -Destination $cblDest -Force
    Write-Host "Copied customblocklayer-0.1.jar to $cblDest"
} else {
    Write-Error "customblocklayer-0.1.jar not found at $cblSrc!"
    exit 1
}

# Helper to compute SHA1 and SHA512
function Get-FileHashes($filePath) {
    $sha1Alg = [System.Security.Cryptography.SHA1]::Create()
    $sha512Alg = [System.Security.Cryptography.SHA512]::Create()
    
    $stream1 = [System.IO.File]::OpenRead($filePath)
    $hash1 = [BitConverter]::ToString($sha1Alg.ComputeHash($stream1)).Replace("-", "").ToLower()
    $stream1.Dispose()

    $stream2 = [System.IO.File]::OpenRead($filePath)
    $hash512 = [BitConverter]::ToString($sha512Alg.ComputeHash($stream2)).Replace("-", "").ToLower()
    $stream2.Dispose()

    $fi = Get-Item -LiteralPath $filePath
    return @{
        "sha1" = $hash1
        "sha512" = $hash512
        "size" = $fi.Length
    }
}

# Helper to create clean zip with forward slashes
function Create-CleanZip($sourceFolder, $outputZipPath) {
    if (Test-Path -LiteralPath $outputZipPath) {
        Remove-Item -LiteralPath $outputZipPath -Force
    }
    $zip = [System.IO.Compression.ZipFile]::Open($outputZipPath, [System.IO.Compression.ZipArchiveMode]::Create)
    $files = Get-ChildItem -LiteralPath $sourceFolder -Recurse -File
    $sourceUri = New-Object Uri (($sourceFolder.TrimEnd('\') + '\'))
    foreach ($file in $files) {
        $fileUri = New-Object Uri ($file.FullName)
        $relPath = [Uri]::UnescapeDataString($sourceUri.MakeRelativeUri($fileUri).ToString())
        $entryName = $relPath.Replace('\', '/')
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, $entryName, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
    $zip.Dispose()
}

# Helper to sync directory (clean copy)
function Sync-Directory($srcDir, $dstDir) {
    if (Test-Path -LiteralPath $dstDir) {
        Remove-Item -LiteralPath $dstDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
    
    $files = Get-ChildItem -LiteralPath $srcDir -Recurse -File
    $sourceUri = New-Object Uri (($srcDir.TrimEnd('\') + '\'))
    foreach ($file in $files) {
        $fileUri = New-Object Uri ($file.FullName)
        $relPath = [Uri]::UnescapeDataString($sourceUri.MakeRelativeUri($fileUri).ToString())
        $targetFile = Join-Path $dstDir $relPath
        $targetFolder = [System.IO.Path]::GetDirectoryName($targetFile)
        if (-not (Test-Path -LiteralPath $targetFolder)) {
            New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null
        }
        Copy-Item -LiteralPath $file.FullName -Destination $targetFile -Force
    }
}

# 4. Sync Resource Pack folders and create clean Zips
$rpNames = @(
    "[RP][HG] Invisible Glint",
    "[RP][HG] Morioh o Somero!",
    "[RP][HG]CustomBlockLayer Content",
    "[RP][HG]Mythical Awaited Update"
)

$rpHashInfo = @{}

foreach ($rp in $rpNames) {
    $srcFolder = Join-Path "$test2\resourcepacks" $rp
    $dstFolder = Join-Path $repo $rp
    $zipOut = Join-Path $repoZips "$rp.zip"

    if (-not (Test-Path -LiteralPath $srcFolder)) {
        Write-Error "Resource pack folder not found: $srcFolder"
        exit 1
    }

    Write-Host "Syncing folder: $rp..."
    Sync-Directory $srcFolder $dstFolder

    Write-Host "Creating zip: $rp.zip..."
    Create-CleanZip $srcFolder $zipOut

    $h = Get-FileHashes $zipOut
    $rpHashInfo[$rp] = $h
    Write-Host (" -> " + $rp + ".zip : Size=" + $h["size"] + " bytes, SHA1=" + $h["sha1"])
}

# Ensure Советую Vanilla Tweaks!.file is in repo
$vtRepoFile = Join-Path $repo $vtRussianName
if (-not (Test-Path -LiteralPath $vtRepoFile)) {
    [System.IO.File]::WriteAllBytes($vtRepoFile, @())
}
$vtHash = Get-FileHashes $vtRepoFile

# Hash customblocklayer
$cblHash = Get-FileHashes $cblDest
Write-Host ("customblocklayer-0.1.jar : Size=" + $cblHash["size"] + " bytes, SHA1=" + $cblHash["sha1"])

# 5. Build updated modrinth.index.json
$baseJsonPath = "$tools\modrinth.index.json"
$origJson = [System.IO.File]::ReadAllText($baseJsonPath, [System.Text.Encoding]::UTF8)
$js = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$js.MaxJsonLength = [int]::MaxValue
$indexObj = $js.DeserializeObject($origJson)

$newFiles = New-Object System.Collections.Generic.List[Object]

foreach ($f in $indexObj["files"]) {
    $p = $f["path"]
    # Filter out removed mods and previous repo assets to re-add fresh
    if ($p -match "roughlyenoughitems|customblocklayer|tooltip-scroll|Vanilla Tweaks" -or $p.StartsWith("resourcepacks/")) {
        continue
    }
    $newFiles.Add($f)
}

# Add tooltip-scroll from TEST2
$tsPath = "$test2\mods\tooltip-scroll-1.5.1+1.21.1.jar"
if (Test-Path -LiteralPath $tsPath) {
    $tsHash = Get-FileHashes $tsPath
    $newFiles.Add(@{
        "path" = "mods/tooltip-scroll-1.5.1+1.21.1.jar"
        "hashes" = @{
            "sha1" = $tsHash["sha1"]
            "sha512" = $tsHash["sha512"]
        }
        "downloads" = @("https://cdn.modrinth.com/data/wySVd6d8/versions/xIlfYF85/tooltip-scroll-1.5.1%2B1.21.1.jar")
        "fileSize" = $tsHash["size"]
    })
    Write-Host "Added mod: tooltip-scroll-1.5.1+1.21.1.jar"
}

# Add customblocklayer from GitHub repo
$cblEntry = @{
    "path" = "mods/customblocklayer-0.1.jar"
    "hashes" = @{
        "sha1" = $cblHash["sha1"]
        "sha512" = $cblHash["sha512"]
    }
    "downloads" = @("https://github.com/Vxnku/-HG-HGMM/raw/main/mods/customblocklayer-0.1.jar")
    "fileSize" = $cblHash["size"]
}
$newFiles.Add($cblEntry)
Write-Host "Added mod: customblocklayer-0.1.jar"

# Add the 4 resource packs from GitHub repo
foreach ($rp in $rpNames) {
    $h = $rpHashInfo[$rp]
    $encodedName = [Uri]::EscapeDataString("$rp.zip")
    $downloadUrl = "https://github.com/Vxnku/-HG-HGMM/raw/main/zips/$encodedName"
    
    $rpEntry = @{
        "path" = "resourcepacks/$rp.zip"
        "hashes" = @{
            "sha1" = $h["sha1"]
            "sha512" = $h["sha512"]
        }
        "downloads" = @($downloadUrl)
        "fileSize" = $h["size"]
    }
    $newFiles.Add($rpEntry)
    Write-Host ("Added resourcepack: " + $rp + ".zip")
}

# Add Советую Vanilla Tweaks!.file
$vtEncoded = [Uri]::EscapeDataString($vtRussianName)
$vtUrl = "https://github.com/Vxnku/-HG-HGMM/raw/main/$vtEncoded"
$vtEntry = @{
    "path" = "resourcepacks/$vtRussianName"
    "hashes" = @{
        "sha1" = $vtHash["sha1"]
        "sha512" = $vtHash["sha512"]
    }
    "downloads" = @($vtUrl)
    "fileSize" = 0
}
$newFiles.Add($vtEntry)
Write-Host "Added file: $vtRussianName"

$indexObj["files"] = $newFiles.ToArray()
$totalCount = $indexObj["files"].Count
Write-Host ""
Write-Host ("Total files in updated modpack: " + $totalCount)

$finalJson = $js.Serialize($indexObj)

# Save json to tools/modrinth.index.json
[System.IO.File]::WriteAllText("$tools\modrinth.index.json", $finalJson, [System.Text.Encoding]::UTF8)

# Pack into root modpack.mrpack and tools/new_modpack.mrpack
$rootMrpack = "$root\modpack.mrpack"
$toolsMrpack = "$tools\new_modpack.mrpack"

$tempFolder = "$root\temp_build_mrpack"
if (Test-Path -LiteralPath $tempFolder) { Remove-Item -LiteralPath $tempFolder -Recurse -Force }
New-Item -ItemType Directory -Path $tempFolder -Force | Out-Null
[System.IO.File]::WriteAllText("$tempFolder\modrinth.index.json", $finalJson, [System.Text.Encoding]::UTF8)

if (Test-Path -LiteralPath $rootMrpack) { Remove-Item -LiteralPath $rootMrpack -Force }
[System.IO.Compression.ZipFile]::CreateFromDirectory($tempFolder, $rootMrpack, [System.IO.Compression.CompressionLevel]::Optimal, $false)

Copy-Item -LiteralPath $rootMrpack -Destination $toolsMrpack -Force
Remove-Item -LiteralPath $tempFolder -Recurse -Force

$fi = Get-Item -LiteralPath $rootMrpack
$kbSize = [math]::Round($fi.Length / 1024, 2)
Write-Host ""
Write-Host "[SUCCESS] Successfully created updated modpack.mrpack!" -ForegroundColor Green
Write-Host ("File size: " + $fi.Length + " bytes (" + $kbSize + " KB)") -ForegroundColor Green
Write-Host ("Path: " + $fi.FullName) -ForegroundColor Green
