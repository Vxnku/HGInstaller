$repoDir = "C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch\repo"
git -C $repoDir add zips/
git -C $repoDir commit -m "Add zip archives of resource packs for Modrinth mrpack manifest"
git -C $repoDir push origin main
