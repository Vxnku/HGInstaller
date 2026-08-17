$src = "A:\MultiMC\instances\[HG][Fabric 1.21.1]\[HG][Fabric 1.21.1].mrpack"
$dst = "A:\MultiMC\instances\[HG][Fabric 1.21.1]\installer\[HG][Fabric 1.21.1].mrpack"
[System.IO.File]::Copy($src, $dst, $true)
Write-Host "Done copying mrpack!"
