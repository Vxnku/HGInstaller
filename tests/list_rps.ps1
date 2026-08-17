Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipPath = "A:\MultiMC\instances\[HG][Fabric 1.21.1]\installer\[HG][Fabric 1.21.1].mrpack"
$zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)

$rpList = $zip.Entries | Where-Object { $_.FullName -like "resourcepacks/*" } | ForEach-Object {
    $sub = $_.FullName.Substring("resourcepacks/".Length)
    $parts = $sub.Split('/')
    if ($parts.Count -gt 0) { $parts[0] }
} | Select-Object -Unique

Write-Host "Resource packs / files found in resourcepacks/:"
$rpList | Format-Table

$zip.Dispose()
