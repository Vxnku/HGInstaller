with open('f:/.Repos/HGInstaller/tests/gdrive_page.html', 'r', encoding='utf-8') as f:
    text = f.read()

import re

for keyword in ['customblocklayer', 'server_info', 'Invisible Glint', 'Morioh', 'Mythical']:
    idx = text.find(keyword)
    if idx != -1:
        print(f"=== Found '{keyword}' at index {idx} ===")
        print(text[max(0, idx - 150): min(len(text), idx + 250)])
    else:
        print(f"=== Keyword '{keyword}' NOT FOUND in page ===")
