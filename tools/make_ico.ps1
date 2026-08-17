Add-Type -AssemblyName System.Drawing

$srcImgPath = Join-Path $PSScriptRoot "..\src\logo.png"
$outputIcoPath = Join-Path $PSScriptRoot "..\src\app.ico"

if (-not (Test-Path $srcImgPath)) {
    Write-Error "Source image not found at $srcImgPath"
    exit 1
}

$sizes = @(256, 128, 64, 48, 32, 16)
$pngStreams = @()

$srcBitmap = [System.Drawing.Bitmap]::FromFile($srcImgPath)

foreach ($s in $sizes) {
    $resized = New-Object System.Drawing.Bitmap $s, $s
    $g = [System.Drawing.Graphics]::FromImage($resized)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.DrawImage($srcBitmap, 0, 0, $s, $s)
    $g.Dispose()

    $ms = New-Object System.IO.MemoryStream
    $resized.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $resized.Dispose()
    $pngStreams += $ms
}

$srcBitmap.Dispose()

$fs = [System.IO.File]::Create($outputIcoPath)
$bw = New-Object System.IO.BinaryWriter $fs

# ICONDIR
$bw.Write([uint16]0) # Reserved
$bw.Write([uint16]1) # Type (1 = ICO)
$bw.Write([uint16]$sizes.Count) # Count

$offset = 6 + ($sizes.Count * 16)

for ($i = 0; $i -lt $sizes.Count; $i++) {
    $s = $sizes[$i]
    $data = $pngStreams[$i].ToArray()

    $dim = if ($s -eq 256) { [byte]0 } else { [byte]$s }

    $bw.Write($dim) # Width
    $bw.Write($dim) # Height
    $bw.Write([byte]0) # Color count
    $bw.Write([byte]0) # Reserved
    $bw.Write([uint16]1) # Color planes
    $bw.Write([uint16]32) # Bits per pixel
    $bw.Write([uint32]$data.Length) # Size in bytes
    $bw.Write([uint32]$offset) # Offset

    $offset += $data.Length
}

for ($i = 0; $i -lt $sizes.Count; $i++) {
    $data = $pngStreams[$i].ToArray()
    $bw.Write($data)
    $pngStreams[$i].Dispose()
}

$bw.Close()
$fs.Close()

Write-Host "Successfully regenerated app.ico from PNG at $outputIcoPath!"
