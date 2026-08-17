$scratch = "C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch"
$origJson = [System.IO.File]::ReadAllText("$scratch\modrinth.index.json", [System.Text.Encoding]::UTF8)

# Check UTF8 characters in JSON
if ($origJson -match "Советую Vanilla Tweaks!\.file") {
    Write-Host "modrinth.index.json has valid UTF8 Russian text for Vanilla Tweaks!"
} else {
    Write-Host "Warning: Russian text check failed."
}
