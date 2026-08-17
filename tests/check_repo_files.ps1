$repo = "C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch\repo"
Get-ChildItem -LiteralPath $repo | Select-Object -Property Name, Length
