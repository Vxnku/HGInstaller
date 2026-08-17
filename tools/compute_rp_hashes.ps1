function Get-Hashes($path) {
    $sha1 = [System.Security.Cryptography.SHA1]::Create()
    $sha512 = [System.Security.Cryptography.SHA512]::Create()
    
    $stream = [System.IO.File]::OpenRead($path)
    $h1 = [BitConverter]::ToString($sha1.ComputeHash($stream)).Replace("-","").ToLower()
    $stream.Position = 0
    $h512 = [BitConverter]::ToString($sha512.ComputeHash($stream)).Replace("-","").ToLower()
    $len = $stream.Length
    $stream.Dispose()
    
    return [PSCustomObject]@{
        Path = $path
        Size = $len
        SHA1 = $h1
        SHA512 = $h512
    }
}

$scratchDir = "C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch"
$txtFile = "A:\MultiMC\instances\[HG][Fabric 1.21.1]\.minecraft\resourcepacks\Советую Vanilla Tweaks!.file"

$res = @()
$res += Get-Hashes "$scratchDir\[RP][HG] Invisible Glint.zip"
$res += Get-Hashes "$scratchDir\[RP][HG] Morioh o Somero!.zip"
$res += Get-Hashes "$scratchDir\[RP][HG]Mythical Awaited Update.zip"
$res += Get-Hashes $txtFile

$res | Format-List
