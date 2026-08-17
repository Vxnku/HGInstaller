# AGENTS.md — HeroGuild Client & Installer Maintainer Guide

Данный документ содержит правила, архитектуру и инструкции по сопровождению и обновлению сборки **HeroGuild (Fabric 1.21.1)** и установщика **HGInstaller**.

---

## 1. Архитектура зеркал и CDN (Multi-Mirror Strategy)

Для гарантированной доступности сборки у 100% игроков (включая игроков из РФ в условиях блокировок РКН и игроков по всему миру) используется каскад из 4 зеркал:

1. **Зеркало 1 (Основной CDN):** `https://vxnku.github.io/-HG-HGMM/...` (GitHub Pages Fastly CDN)
2. **Зеркало 2 (Cloudflare CDN Edge):** `https://bold-bread-e4ce.yuliy-ml.workers.dev/...` (Воркер с кэшированием)
3. **Зеркало 3 (Google Drive Backup):** `https://drive.usercontent.google.com/download?id=...` (Резервное облако, папка `1_apGzd4FCPGIjlCoeSWsX4UQIFZxpl40`)
4. **Зеркало 4 (jsDelivr Open CDN):** `https://cdn.jsdelivr.net/gh/Vxnku/-HG-HGMM@main/...`

**Поведение установщика (`HGInstaller.exe`):**
- При скачивании каждого файла установщик последовательно опрашивает зеркала (Зеркало 1 $\rightarrow$ Зеркало 2 $\rightarrow$ Зеркало 3).
- При сетевой ошибке или таймауте включается алгоритм **Linear Backoff Retry (2с, 4с, 6с ... до 30с)** и бесшовное переключение на следующее зеркало.

---

## 2. Структура репозитория

* `src/` — Исходный код C# Windows Forms установщика (`HGInstaller.cs`, `AssemblyInfo.cs`, ресурсы).
  * `src/build.ps1` / `src/build.bat` — Скрипт компиляции `HGInstaller.exe` через `csc.exe` (.NET 4.0/4.8, C# 5).
* `repo/` — Локальное дерево файлов и ассетов:
  * `repo/server_info.json` — Динамический IP и название сервера HeroGuild.
  * `repo/mods/customblocklayer-0.1.jar` — Кастомный мод блоков.
  * `repo/zips/` — Архивы кастомных ресурспаков (`[RP][HG] Invisible Glint.zip`, `Morioh o Somero!`, `CustomBlockLayer Content`, `Mythical Awaited Update`).
  * `repo/Советую Vanilla Tweaks!.file` — Маркер-файл.
* `tools/` — Утилиты и скрипты сборщика:
  * `tools/build_updated_pack.ps1` — Основной генератор `modpack.mrpack` и `modrinth.index.json` с генерацией мульти-зеркал.
* `upload_script/` — Инструменты синхронизации с Google Диском:
  * `upload_script/upload_gdrive.py` — Python-скрипт загрузки в Google Drive и обновления `gdrive_files.json`.
  * `upload_script/gdrive_files.json` — Маппинг имен файлов и их Google Drive File ID / Direct Download URL.
  * `upload_script/README.md` — Инструкция по работе с загрузчиком.
* `modpack.mrpack` — Актуальный скомпилированный архив сборки Modrinth.
* `HGInstaller.exe` — Скомпилированный бинарник установщика.

---

## 3. Регламент обновления сборки и файлов

Когда требуется обновить моды, ресурспаки или IP сервера:

### Шаг 1: Обновление файлов в `repo/`
- Поместите новые/обновленные файлы в соответствующие папки `repo/` (`repo/server_info.json`, `repo/mods/`, `repo/zips/`).

### Шаг 2: Синхронизация с Google Диском (Опционально / При изменении кастомных файлов)
> [!IMPORTANT]
> **ОБЯЗАТЕЛЬНОЕ НАПОМИНАНИЕ ПОЛЬЗОВАТЕЛЮ:**
> При любом обновлении кастомных файлов (модов, ресурспаков, `server_info.json`) в папке `repo/`, агент **ОБЯЗАН** напомнить пользователю самостоятельно закинуть новые файлы в папку [Google Drive](https://drive.google.com/drive/folders/1_apGzd4FCPGIjlCoeSWsX4UQIFZxpl40) и обновить их ID в `upload_script/gdrive_files.json`.

- Если изменились кастомные моды или ресурспаки:
  - Перетащите их в браузере в папку [Google Drive](https://drive.google.com/drive/folders/1_apGzd4FCPGIjlCoeSWsX4UQIFZxpl40) и обновите ID в `upload_script/gdrive_files.json`.
  - Либо запустите `python upload_script/upload_gdrive.py`.

### Шаг 3: Пересборка модпака и установщика
1. Запустите генератор модпака:
   ```powershell
   powershell -ExecutionPolicy Bypass -File tools/build_updated_pack.ps1
   ```
2. Скомпилируйте установщик:
   ```powershell
   powershell -ExecutionPolicy Bypass -File src/build.ps1
   ```
3. Сделайте `git commit` и `git push` в репозитории `HGInstaller` и `-HG-HGMM`.
