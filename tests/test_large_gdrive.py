import requests

session = requests.Session()
url = "https://drive.usercontent.google.com/download?id=1I511xlxunONUZEix1xuT-fCNLGXEkcGq&export=download&confirm=t"
resp = session.get(url, stream=True)
print("Status:", resp.status_code)
print("Headers:", resp.headers)
print("Content-Length:", resp.headers.get("Content-Length"))
print("First 200 bytes:", resp.raw.read(200))
