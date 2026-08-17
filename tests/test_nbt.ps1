$csharpSource = Get-Content "C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch\NbtWriter.cs" -Raw
Add-Type -TypeDefinition $csharpSource

$bytes = [NbtServerWriter]::CreateServersDat("HeroGuild", "vrsetmain.joinserver.ru")
$testPath = "C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch\servers.dat"
[System.IO.File]::WriteAllBytes($testPath, $bytes)

Write-Host "Generated servers.dat size: $($bytes.Length) bytes"
$hex = [BitConverter]::ToString($bytes)
Write-Host "Hex Dump:"
Write-Host $hex
