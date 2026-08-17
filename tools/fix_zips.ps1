$repoZips = "C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch\repo\zips"
if (-not (Test-Path $repoZips)) {
    New-Item -ItemType Directory -Path $repoZips | Out-Null
}

$scratchDir = "C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch"
Copy-Item (Join-Path $scratchDir "[RP][HG] Invisible Glint.zip") -Destination $repoZips -Force
Copy-Item (Join-Path $scratchDir "[RP][HG] Morioh o Somero!.zip") -Destination $repoZips -Force
Copy-Item (Join-Path $scratchDir "[RP][HG]Mythical Awaited Update.zip") -Destination $repoZips -Force

Get-ChildItem -LiteralPath $repoZips | Select-Object -Property Name, Length
