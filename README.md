# ⚔️ HeroGuild Client Installer

Автоматический графический установщик клиентской сборки **HeroGuild (Minecraft Fabric 1.21.1)** для Windows.

[![.NET Framework](https://img.shields.io/badge/.NET%20Framework-4.0%20%7C%204.8-512BD4?style=flat&logo=dotnet)](https://dotnet.microsoft.com/)
[![Language](https://img.shields.io/badge/Language-C%23%205.0-239120?style=flat&logo=csharp)](https://docs.microsoft.com/en-us/dotnet/csharp/)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%2F%2011-0078D6?style=flat&logo=windows)](https://microsoft.com/windows)

---

## ✨ Возможности

- **Автоопределение путей**: Автоматически находит папку `.minecraft` в `%APPDATA%` и файл сборки `modpack.mrpack` рядом с исполняемым файлом.
- **Поддержка Modrinth (.mrpack)**: Распаковка индексов `modrinth.index.json`, автоматическая загрузка всех модов с хэш-проверками (SHA-1 / SHA-512).
- **Ресурспаки и оверрайды**: Загрузка кастомных ресурспаков HeroGuild с GitHub, автоматическая распаковка конфигураций и шейдеров.
- **Интеграция сервера**: Автоматическое добавление сервера HeroGuild в `servers.dat` через встроенный NBT-сериализатор.
- **Очистка старых модов**: Опция безопасной очистки папки `mods` перед установкой.
- **Стильный интерфейс**: Тёмная тема в фирменных золотисто-чёрных тонах HeroGuild с плавной анимацией и логом процесса.
- **Полная автономность**: Не требует установки сторонних утилит или тяжелых рантаймов, компилируется стандартным `csc.exe`.

---

## 📁 Структура репозитория

```text
├── HGInstaller.exe          # Готовый исполняемый файл установщика
├── modpack.mrpack           # Файл модпака HeroGuild
├── README.md                # Документация проекта
├── .gitignore               # Исключения Git
│
├── src/                     # Исходный код и ресурсы
│   ├── HGInstaller.cs       # Главный C# исходный код установщика
│   ├── AssemblyInfo.cs      # Метаданные сборки и версии
│   ├── NbtWriter.cs         # NBT сериализатор для Minecraft servers.dat
│   ├── app.manifest         # Манифест Windows (DPI, права)
│   ├── app.ico              # Мульти-разрешение иконка приложения
│   ├── logo.png             # Логотип HeroGuild (512x512)
│   ├── discord.png          # Иконка Discord (512x512)
│   ├── servers.dat          # Шаблон серверов
│   ├── build.bat            # Сборщик в 1 клик (компилирует ..\HGInstaller.exe)
│   └── build.ps1            # PowerShell скрипт сборки
│
├── tests/                   # Тестовые и диагностические утилиты
│   ├── test.cs              # Тестовый C# файл
│   ├── test_github_zip.ps1  # Проверка загрузки архивов с GitHub
│   ├── test_nbt.ps1         # Проверка генерации NBT
│   └── check_*.ps1          # Диагностика и проверка хэшей/разрешений
│
└── tools/                   # Утилиты упаковки и деплоя
    ├── build_complete_mrpack.ps1
    ├── build_mrpack_clean.ps1
    ├── compute_rp_hashes.ps1
    ├── make_ico.ps1
    └── ...
```

---

## 🔨 Сборка из исходников

Для сборки требуется стандартный компилятор C# (`csc.exe`), встроенный в Windows (.NET Framework 4.0 / 4.8). Дополнительных SDK устанавливать не нужно.

### Способ 1 (CMD Batch):
Дважды кликните на файл:
```cmd
src\build.bat
```

### Способ 2 (PowerShell):
Запустите в PowerShell:
```powershell
.\src\build.ps1
```

Скомпилированный файл появится в корне репозитория: `HGInstaller.exe`.

---

## 👥 Ссылки
- **Discord сообщества:** [HeroGuild Discord](https://discord.gg/W3harVKevk)
- **Репозиторий файлов подкачки:** [-HG-HGMM](https://github.com/Vxnku/-HG-HGMM)
