#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
HGInstaller Google Drive Auto-Sync Script
Uploads assets from repo/ to Google Drive folder (ID: 1_apGzd4FCPGIjlCoeSWsX4UQIFZxpl40)
and updates upload_script/gdrive_files.json for multi-mirror generation.
"""

import os
import sys
import json
import subprocess
from pathlib import Path

FOLDER_ID = "1_apGzd4FCPGIjlCoeSWsX4UQIFZxpl40"
SCRIPT_DIR = Path(__file__).resolve().parent
ROOT_DIR = SCRIPT_DIR.parent
REPO_DIR = ROOT_DIR / "repo"
JSON_MAPPING_FILE = SCRIPT_DIR / "gdrive_files.json"

TARGET_FILES = [
    {"name": "server_info.json", "path": REPO_DIR / "server_info.json"},
    {"name": "customblocklayer-0.1.jar", "path": REPO_DIR / "mods" / "customblocklayer-0.1.jar"},
    {"name": "[RP][HG] Invisible Glint.zip", "path": REPO_DIR / "zips" / "[RP][HG] Invisible Glint.zip"},
    {"name": "[RP][HG] Morioh o Somero!.zip", "path": REPO_DIR / "zips" / "[RP][HG] Morioh o Somero!.zip"},
    {"name": "[RP][HG]CustomBlockLayer Content.zip", "path": REPO_DIR / "zips" / "[RP][HG]CustomBlockLayer Content.zip"},
    {"name": "[RP][HG]Mythical Awaited Update.zip", "path": REPO_DIR / "zips" / "[RP][HG]Mythical Awaited Update.zip"},
    {"name": "Советую Vanilla Tweaks!.file", "path": REPO_DIR / "Советую Vanilla Tweaks!.file"},
    {"name": "fabric-loader-0.19.3-1.21.1.zip", "path": REPO_DIR / "fabric" / "fabric-loader-0.19.3-1.21.1.zip"},
]

def load_mapping():
    if JSON_MAPPING_FILE.exists():
        with open(JSON_MAPPING_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    return {"folder_id": FOLDER_ID, "files": {}}

def save_mapping(data):
    with open(JSON_MAPPING_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"[OK] Saved mapping to {JSON_MAPPING_FILE}")

def get_direct_download_url(file_id: str) -> str:
    if not file_id:
        return ""
    return f"https://drive.usercontent.google.com/download?id={file_id}&export=download"

def upload_via_google_api():
    """Uploads files using Google Drive API if credentials.json or service_account.json exists."""
    cred_file = SCRIPT_DIR / "credentials.json"
    sa_file = SCRIPT_DIR / "service_account.json"
    
    if not cred_file.exists() and not sa_file.exists():
        print("[INFO] No credentials.json or service_account.json found in upload_script/.")
        print("To use automatic API upload:")
        print("1. Place your Google Cloud 'service_account.json' or 'credentials.json' in upload_script/")
        print("2. Re-run this script.")
        return False

    try:
        from googleapiclient.discovery import build
        from googleapiclient.http import MediaFileUpload
        from google.oauth2 import service_account
        from google_auth_oauthlib.flow import InstalledAppFlow

        SCOPES = ['https://www.googleapis.com/auth/drive.file', 'https://www.googleapis.com/auth/drive']
        token_file = SCRIPT_DIR / "token.json"
        creds = None

        if token_file.exists():
            try:
                from google.oauth2.credentials import Credentials
                creds = Credentials.from_authorized_user_file(str(token_file), SCOPES)
            except Exception:
                creds = None

        if not creds or not creds.valid:
            if creds and creds.expired and creds.refresh_token:
                from google.auth.transport.requests import Request
                creds.refresh(Request())
            elif cred_file.exists():
                import webbrowser
                flow = InstalledAppFlow.from_client_secrets_file(str(cred_file), SCOPES)
                print("\n" + "=" * 70, flush=True)
                print("  [АВТОРИЗАЦИЯ GOOGLE] Ожидание подтверждения входа в браузере...", flush=True)
                print("=" * 70 + "\n", flush=True)
                creds = flow.run_local_server(port=0, open_browser=True)
                with open(token_file, "w", encoding="utf-8") as token:
                    token.write(creds.to_json())
            elif sa_file.exists():
                creds = service_account.Credentials.from_service_account_file(str(sa_file), scopes=SCOPES)
            else:
                return False

        service = build('drive', 'v3', credentials=creds)
        mapping = load_mapping()

        for item in TARGET_FILES:
            name = item["name"]
            file_path = item["path"]
            if not file_path.exists():
                print(f"[WARN] File not found locally: {file_path}")
                continue

            print(f"[UPLOADING] {name} ({file_path.stat().st_size} bytes)...")
            
            # Check existing file in folder
            query = f"'{FOLDER_ID}' in parents and name = '{name}' and trashed = false"
            results = service.files().list(q=query, fields="files(id, name)").execute()
            existing_files = results.get('files', [])

            media = MediaFileUpload(str(file_path), resumable=True)

            if existing_files:
                file_id = existing_files[0]['id']
                updated = service.files().update(fileId=file_id, media_body=media).execute()
                print(f"[UPDATED] {name} -> File ID: {file_id}")
            else:
                metadata = {'name': name, 'parents': [FOLDER_ID]}
                created = service.files().create(body=metadata, media_body=media, fields='id').execute()
                file_id = created.get('id')
                # Make publicly readable
                service.permissions().create(fileId=file_id, body={'type': 'anyone', 'role': 'viewer'}).execute()
                print(f"[CREATED] {name} -> File ID: {file_id}")

            mapping["files"][name] = {
                "file_id": file_id,
                "download_url": get_direct_download_url(file_id)
            }

        save_mapping(mapping)
        return True
    except ImportError:
        print("[ERROR] Google API packages not installed. Run: pip install -r requirements.txt")
        return False
    except Exception as e:
        print(f"[ERROR] API Upload failed: {e}")
        return False

def sync_from_manual_ids():
    """Reads mapping and verifies URLs."""
    mapping = load_mapping()
    updated = False
    for item in TARGET_FILES:
        name = item["name"]
        entry = mapping.get("files", {}).get(name, {})
        file_id = entry.get("file_id", "").strip()
        if file_id and not entry.get("download_url"):
            entry["download_url"] = get_direct_download_url(file_id)
            mapping["files"][name] = entry
            updated = True
    if updated:
        save_mapping(mapping)

def main():
    print("=" * 60)
    print("  HeroGuild - Google Drive Asset Sync")
    print(f"  Target Folder ID: {FOLDER_ID}")
    print("=" * 60)

    # Try automatic API upload
    success = upload_via_google_api()
    if not success:
        print("\n[FALLBACK MODE] Checking existing file mappings in gdrive_files.json...")
        sync_from_manual_ids()

    # Re-build mrpack with updated mirrors
    build_script = ROOT_DIR / "tools" / "build_updated_pack.ps1"
    if build_script.exists():
        print("\n[BUILD] Triggering modpack.mrpack rebuild with multi-mirrors...")
        cmd = ["powershell", "-ExecutionPolicy", "Bypass", "-File", str(build_script)]
        res = subprocess.run(cmd)
        if res.returncode == 0:
            print("[SUCCESS] modpack.mrpack rebuilt successfully!")
        else:
            print(f"[WARN] Rebuild returned exit code {res.returncode}")

if __name__ == "__main__":
    main()
