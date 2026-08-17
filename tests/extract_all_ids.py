with open('f:/.Repos/HGInstaller/tests/gdrive_page.html', 'r', encoding='utf-8') as f:
    text = f.read()

import re
import json

files = {}
# Pattern: aria-label="FILENAME ... ssk='5:auSv138:FILE_ID-0-16'
pattern = r'aria-label="([^"]+?)\s+(?:Unknown|Compressed archive|Plain text|JSON|Binary|Text)[^"]*"\s+[^>]*?ssk=[\'"][^\'"]*?:([a-zA-Z0-9_-]{28,45})-\d+-\d+[\'"]'

matches = re.findall(pattern, text)
print(f"Direct regex matches: {len(matches)}")
for name, fid in matches:
    print(f"File: '{name}' -> ID: '{fid}'")
    files[name] = fid

# Also do a looser search for all ssk IDs and aria labels
for m in re.finditer(r'aria-label="([^"]+?)(?:\s+(?:Unknown|Compressed archive|Shared|Plain text)[^"]*)?"[^>]*?ssk=[\'"][^\'"]*?:([a-zA-Z0-9_-]{28,45})-\d+-\d+[\'"]', text):
    name, fid = m.groups()
    files[name.strip()] = fid

print("\nAll extracted files:")
print(json.dumps(files, indent=2, ensure_ascii=False))
