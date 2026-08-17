import requests
import re
import json

url = 'https://drive.google.com/drive/folders/1_apGzd4FCPGIjlCoeSWsX4UQIFZxpl40'
resp = requests.get(url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'})
html = resp.text

# Look for data-id or jsdata or JSON blobs
matches = re.findall(r'\[\"([a-zA-Z0-9_-]{28,40})\"', html)
print("Unique IDs found in HTML:", len(set(matches)))
for m in list(set(matches))[:20]:
    print("ID candidate:", m)
