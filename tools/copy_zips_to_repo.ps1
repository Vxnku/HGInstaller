$repoDir = "C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch\repo"
$zipsDir = Join-Path $repoDir "zips"
if (-not (Test-Path $zipsDir)) { New-Item -ItemType Directory -Path $zipsDir | Out-Null }

$scratchDir = "C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch"
Copy-Item "$scratchDir\[RP][HG] Invisible Glint.zip" -Destination $zipsDir -Force
Copy-Item "$scratchDir\[RP][HG] Morioh o Somero!.zip" -Destination $zipsDir -Force
Copy-Item "$scratchDir\[RP][HG]Mythical Awaited Update.zip" -Destination $zipsDir -Force

Write-Host "Zips copied to repo/zips directory!"
