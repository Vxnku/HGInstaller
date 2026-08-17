$repoZips = "C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch\repo\zips"
[System.IO.Directory]::CreateDirectory($repoZips)

$scratchDir = "C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch"
[System.IO.File]::Copy("$scratchDir\[RP][HG] Invisible Glint.zip", "$repoZips\[RP][HG] Invisible Glint.zip", $true)
[System.IO.File]::Copy("$scratchDir\[RP][HG] Morioh o Somero!.zip", "$repoZips\[RP][HG] Morioh o Somero!.zip", $true)
[System.IO.File]::Copy("$scratchDir\[RP][HG]Mythical Awaited Update.zip", "$repoZips\[RP][HG]Mythical Awaited Update.zip", $true)

$files = [System.IO.Directory]::GetFiles($repoZips)
foreach ($f in $files) {
    $fi = New-Object System.IO.FileInfo($f)
    Write-Host "$($fi.Name) : $($fi.Length) bytes"
}
