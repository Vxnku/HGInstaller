$srcDir = "A:\MultiMC\instances\[HG][Fabric 1.21.1]\.minecraft\resourcepacks"
$repoDir = "C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch\repo"

$items = Get-ChildItem -LiteralPath $srcDir
foreach ($item in $items) {
    $dst = Join-Path $repoDir $item.Name
    if ($item.PSIsContainer) {
        Copy-Item -LiteralPath $item.FullName -Destination $dst -Recurse -Force
    } else {
        Copy-Item -LiteralPath $item.FullName -Destination $dst -Force
    }
    Write-Host "Copied: $($item.Name)"
}

Write-Host "Done copying resourcepacks to repo!"
