# Правила: флейворы, конфигурация, секреты

Флейворов два: `dev` и `prod`. Источник — `assets/flavors/<flavor>.json`, читается один раз
на старте в `AssetsAppFlavorService.fromAssets()`
(lib/core/services/flavors.dart:38) и кладётся в DI как `AppFlavorService`.

```bash
flutter run --flavor dev  -t lib/main.dart
flutter run --flavor prod -t lib/main.dart
```

## 1. Всё, что различается между окружениями, — в json флейвора

```json
{
  "FLAVOR": "dev",
  "API_BASE_URL": "https://api.deezer.com/",
  "ANALYTICS_ENABLED": false,
  "LOG_NETWORK_BODIES": true
}
```

Типовой список того, что обязано различаться:

| Ключ | dev | prod |
|---|---|---|
| `API_BASE_URL` | стенд | прод |
| `ANALYTICS_ENABLED` | `false` | `true` |
| `LOG_NETWORK_BODIES` | `true` | `false` |
| Firebase options | `firebase_options_dev.dart` | `firebase_options_prod.dart` |

Значения читаются **типизированными геттерами** `AppFlavorService`
(`String get apiBaseUrl`, `bool get analyticsEnabled`), а не `map['API_BASE_URL']` на месте
использования. Ключи json — приватные константы рядом с `_FlavorKeys`.

Отсутствующий в json ключ — это ошибка конфигурации, а не повод молча взять умолчание:
геттер падает с внятным сообщением на старте, а не отдаёт `''` и роняет сеть позже.

## 2. Ветвление по флейвору

```dart
// ✅ по смыслу
if (sl<AppFlavorService>().analyticsEnabled) { ... }

// ❌ по имени окружения
if (sl<AppFlavorService>().flavor == AppFlavor.dev) { ... }

// ❌ по режиму сборки
if (kDebugMode) { /* другая бизнес-логика */ }
```

Различаются **возможности**, а не окружения: тогда добавление третьего флейвора (staging)
не требует искать все `== AppFlavor.dev` по проекту.

`kDebugMode` допустим только для отладочного вывода и dev-инструментов, но **не** для
логики, поведения экранов и выбора адресов. Отладочный прокси в `ApiService` включается
флейвором, а не полем класса и не режимом сборки.

## 3. Что не должно попадать в репозиторий

- **API-ключи, секреты, пароли, сертификаты, `google-services.json` с боевыми ключами**
  — не коммитятся. Нужен ключ в сборке — он приходит через `--dart-define` /
  CI-переменную, а в коде читается через `String.fromEnvironment`;
- `firebase_options_*.dart` содержат публичные идентификаторы проекта — их коммитить можно,
  но боевые серверные ключи в них не кладутся;
- `.env`-подобные файлы, локальные `local.properties`, keystore — в `.gitignore`.

Секрет, однажды попавший в историю git, считается скомпрометированным: ротация ключа,
а не удаление файла следующим коммитом.

## 4. Firebase

- выбор `FirebaseOptions` — по флейвору, через `Map<AppFlavor, FirebaseOptions>`
  в `main.dart`;
- `Firebase.initializeApp` идёт **после** `initDependencies`, потому что флейвор берётся
  из контейнера;
- падение инициализации Firebase не должно ронять приложение целиком — аналитика не
  критична; но проглатывать молча тоже нельзя (`errors.md`).

## 5. Версия приложения

Версия и билд-номер — из `pubspec.yaml`, в код попадают через `PackageInfo`
(хелпер `AppUtils`, `helpers.md`), а не константой, которую забудут поднять.

## Чек-лист

- [ ] новое различие между окружениями заведено в **оба** json (`dev.json` и `prod.json`);
- [ ] значение читается типизированным геттером `AppFlavorService`;
- [ ] в коде нет `== AppFlavor.dev` ради логики — ветвление по возможности;
- [ ] нет `kDebugMode` в бизнес-логике;
- [ ] секреты не в репозитории;
- [ ] `baseUrl` не литералом (`network.md`).
