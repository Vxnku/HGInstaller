Add-Type -AssemblyName System.IO.Compression.FileSystem
$rpDir = "A:\MultiMC\instances\[HG][Fabric 1.21.1]\.minecraft\resourcepacks"
$scratchDir = "C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch"

$folders = Get-ChildItem -LiteralPath $rpDir -Directory
foreach ($folder in $folders) {
    $zipName = "$($folder.Name).zip"
    $zipPath = Join-Path $scratchDir $zipName
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
    [System.IO.Compression.ZipFile]::CreateFromDirectory($folder.FullName, $zipPath, [System.IO.Compression.CompressionLevel]::Optimal, $false)
    $fi = Get-Item $zipPath
    Write-Host "Created $zipName : $([math]::Round($fi.Length / 1MB, 2)) MB"
}
