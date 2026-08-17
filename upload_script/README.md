# Google Drive Sync & Mirror Tool for HGInstaller

Скрипт для выгрузки файлов сборки (моды, ресурспаки, `server_info.json`) в Google Диск и автоматической генерации мульти-зеркал.

## Папка на Google Диске
* **ID:** `1_apGzd4FCPGIjlCoeSWsX4UQIFZxpl40`
* **Ссылка:** [Google Drive Folder](https://drive.google.com/drive/folders/1_apGzd4FCPGIjlCoeSWsX4UQIFZxpl40?usp=sharing)

---

## Способы использования:

### Вариант 1. Загрузка через браузер + ручная вставка ID
1. Откройте папку на Google Диске и перетащите туда файлы из папки `repo/`.
2. Нажмите правой кнопкой на каждый файл $\rightarrow$ «Поделиться» $\rightarrow$ «Скопировать ссылку».
3. Вставьте ID файлов в `gdrive_files.json`.
4. Запустите `python upload_gdrive.py` — скрипт сформирует ссылки и пересоберёт `modpack.mrpack`.

### Вариант 2. Автоматическая загрузка через Google API
1. Положите файл `credentials.json` или `service_account.json` в эту папку `upload_script/`.
2. Установите зависимости:
   ```bash
   pip install -r requirements.txt
   ```
3. Запустите скрипт:
   ```bash
   python upload_gdrive.py
   ```
   Скрипт сам загрузит/обновит файлы на Google Диске и пересоберёт `modpack.mrpack`.
