Add-Type -AssemblyName System.Drawing
$files = @(
    "A:\MultiMC\instances\[HG][Fabric 1.21.1]\installer\HGPackLogoFabric.jpg",
    "A:\MultiMC\instances\[HG][Fabric 1.21.1]\HGPackLogoFabric128.png"
)
foreach ($f in $files) {
    if ([System.IO.File]::Exists($f)) {
        $img = [System.Drawing.Image]::FromFile($f)
        Write-Host "$f => Format: $($img.RawFormat), Dimensions: $($img.Width) x $($img.Height) px, PixelFormat: $($img.PixelFormat)"
        $img.Dispose()
    }
}
