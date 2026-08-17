import requests
import re
import json

url = 'https://drive.google.com/drive/folders/1_apGzd4FCPGIjlCoeSWsX4UQIFZxpl40?usp=sharing'
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
    'Accept-Language': 'en-US,en;q=0.9,ru;q=0.8'
}
resp = requests.get(url, headers=headers)
html = resp.text

with open('f:/.Repos/HGInstaller/tests/gdrive_page.html', 'w', encoding='utf-8') as f:
    f.write(html)

print("Saved HTML, length:", len(html))

# Look for filenames and IDs in the rendered data
# Pattern: ["ID","FILENAME",...
items = re.findall(r'\["([a-zA-Z0-9_-]{25,45})",\["([^"]+)"', html)
print(f"Found {len(items)} items:")
for fid, fname in items:
    print(f"  {fname} -> {fid}")
