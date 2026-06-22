# Flutter Reader

Кросс-платформенная читалка книг (EPUB, FB2, PDF) на Flutter.

## Требования

- Flutter ≥ 3.10.0
- Dart ≥ 3.0.0
- Android API 21+ / iOS 8+

## Технологии

| Слой | Технология |
|---|---|
| State management | flutter_bloc |
| DI | get_it + injectable |
| База данных | Drift (SQLite) |
| Настройки | shared_preferences |
| Навигация | go_router |
| EPUB | epubx |
| PDF | pdfx |
| FB2 | xml (ручной парсинг) |
| Файловый менеджер | file_picker |

## Архитектура

Clean Architecture + Feature-first:

```
lib/
├── core/           # DI, БД, роутер, тема, ошибки
└── features/
    ├── book_list/  # Список книг (data / domain / presentation)
    ├── reader/     # Читалка (data / domain / presentation)
    └── settings/   # Настройки читалки
```

## Запуск

```bash
# Установить зависимости
flutter pub get

# Запустить кодогенерацию (Drift + injectable)
dart run build_runner build --delete-conflicting-outputs

# Запустить приложение
flutter run
```

## Кодогенерация

Проект использует `build_runner` для генерации:
- `*.g.dart` — Drift DAO, json_serializable
- `injection.config.dart` — DI-граф get_it

После любых изменений в аннотированных классах запускай:
```bash
dart run build_runner build --delete-conflicting-outputs
```

## Git-ветки

- `main` — стабильные релизы
- `develop` — текущая разработка
- `feature/*` — отдельные фичи
