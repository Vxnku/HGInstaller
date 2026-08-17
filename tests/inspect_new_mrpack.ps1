Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipPath = "A:\MultiMC\instances\[HG][Fabric 1.21.1]\installer\[HG][Fabric 1.21.1].mrpack"
$zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)

Write-Host "Total entries in mrpack: $($zip.Entries.Count)"

$topFolders = $zip.Entries | Group-Object {
    $parts = $_.FullName.Split('/')
    if ($parts.Count -gt 1) { $parts[0] } else { "(root)" }
} | Select-Object -Property Name, Count

Write-Host "Top level structure:"
$topFolders | Format-Table -AutoSize

Write-Host "`nSample of entries:"
$zip.Entries | Select-Object -First 30 -Property FullName, Length | Format-Table -AutoSize

$zip.Dispose()
