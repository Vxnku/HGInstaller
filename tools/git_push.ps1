$repoDir = "C:\Users\Yus\.gemini\antigravity-ide\brain\2c1e1c5a-2240-43e9-9abb-0bf6b17f531b\scratch\repo"
git -C $repoDir add -A
git -C $repoDir commit -m "Add HeroGuild resource packs"
git -C $repoDir branch -M main
git -C $repoDir push -u origin main
