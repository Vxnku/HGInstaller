$repoDir = "C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch\repo"
git -C $repoDir add server_info.json
git -C $repoDir commit -m "Add server_info.json for dynamic IP configuration"
git -C $repoDir push origin main
Write-Host "server_info.json pushed to GitHub!"
