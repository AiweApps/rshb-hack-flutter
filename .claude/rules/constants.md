# Правила: `lib/core/constants/`

Четыре файла, четыре разные ответственности. Ничего больше в папку не кладём.

| Файл | Что там |
|---|---|
| `app_constants.dart` | **все** поведенческие/доменные константы приложения |
| `app_style_constants.dart` | числовые константы вёрстки: отступы, размеры, радиусы, alpha, кегли |
| `app_colors_constants.dart` | `AppColors` — палитра как `ThemeExtension` |
| `app_text_styles_constants.dart` | `AppTextStyles` — шкала типографики как `ThemeExtension` |

Правила по двум последним — в `theme.md`, здесь только краткая выжимка.

## Главное правило

**Магических чисел и строк в коде нет.** Любой литерал, у которого есть смысл
(таймаут, URL, лимит, ключ хранилища, размер, отступ, радиус) — выносится в константу
**сразу**, при первом появлении, а не «когда понадобится второй раз».

Допустимы без выноса только арифметические `0`/`1`/`2` без семантики
(`index + 1`, `flex: 1`, `parts.length != 3`). Любое число, влияющее на вёрстку, —
через `AppSize`/`AppPadding`/`AppRadius`.

### `lib/core/` — не исключение

Правило действует на ядро **строже**, чем на фичи: литерал в `core/services/` живёт
дольше, расползается по всем фичам сразу и разъезжается между окружениями.

| Литерал в ядре | Куда |
|---|---|
| Базовый URL API | флейвор (`flavors.md`) |
| Таймауты dio, idle-таймауты | `DurationConstant` |
| Адрес отладочного прокси | параметр конструктора, включается только в dev |
| Размер страницы, лимиты, TTL кэша | `ApiConstants` |

## `app_constants.dart` — группировка по классам-неймспейсам

Константы группируются в классы. Класс — просто неймспейс: только `static const`,
без конструктора и без создания экземпляров. Один класс = одна тема.

Актуальный и целевой набор (см. `recallscope-flutter` и `ahhu-flutter`):

```dart
class DurationConstant { ... }   // все Duration приложения — есть
class ApiConstants { ... }       // baseUrl, размеры страниц, таймауты
class ShareConstants { ... }     // построение шаринговых ссылок
class LimitConstants { ... }     // лимиты/квоты: maxFreeItems, maxAttachments
class LinkConstants { ... }      // privacyPolicyUrl, termsUrl, openSourceLicense
class ContactConstants { ... }   // mailto-ссылки поддержки
class StorageKeys { ... }        // строковые ключи SharedPreferences / secure storage
class AnalyticsEvents { ... }    // имена событий аналитики
```

Классы заводим по мере надобности — но **до** того, как константа окажется
захардкоженной в фиче. Нет подходящего класса → создаём новый в этом же файле.

### `DurationConstant`

Единственный источник таймингов: анимации, дебаунсы, таймауты, задержки сплэша.

- Имя = значение: `d100ms`, `d300ms`, `d2s`, `d60s`.
- Нужного значения нет → добавляем новое поле, сохраняя порядок по возрастанию
  (сначала миллисекунды, потом секунды).
- `Duration(...)` инлайном в коде — запрещено.

```dart
// ❌
await Future.delayed(const Duration(milliseconds: 300));
// ✅
await Future.delayed(DurationConstant.d300ms);
```

### `ApiConstants`

`baseUrl`, размеры страниц пагинации, таймауты dio. Конкретные пути эндпоинтов
остаются в `core/services/api/service/api_endpoints.dart` и
`features/<feature>/domain/<feature>_api_endpoints.dart` — их сюда не переносим.

### `ShareConstants` — исключение из правила «только static»

Единственный класс, который инстанцируется: базовый URL зависит от флейвора,
поэтому объект создаётся в DI и резолвится через `sl<ShareConstants>()`.
Методы строят ссылки (`tourUrl(slug)`, `documentUrl(name)`), а не хранят их.
Собирать шаринговые URL строковой интерполяцией в фиче — запрещено.

## `app_style_constants.dart`

Классы и соглашение об именах (префикс + значение):

| Класс | Префикс | Пример |
|---|---|---|
| `AppPadding` | `p` | `AppPadding.p16` |
| `AppMargin` | `m` | `AppMargin.m12` |
| `AppSpaces` | `s` | `AppSpaces.s4` |
| `AppSize` | `s` | `AppSize.s24`, `AppSize.si8` (int) |
| `AppRadius` | `r` | `AppRadius.r12`, `AppRadius.rPill` |
| `AppAlpha` | `a` | `AppAlpha.a50` (значение 0..255 для `withAlpha`) |
| `FontSize` | `s` | `FontSize.s16` |

- Дробные значения — через `_`: `s1_5` = 1.5.
- Семантические алиасы допустимы и приветствуются:
  `AppPadding.defaultPadding`, `AppSize.dividerThickness`, `AppSize.avatarDefaultHeight`.
  Если размер имеет смысл — заводим именованный алиас, а не используем голое число.
- `AppAlpha` хранит 0..255, потому что используется с `withAlpha`, а не `withOpacity`.

## `app_colors_constants.dart` и `app_text_styles_constants.dart`

Полные правила — в `theme.md`. Главное:

- `AppColors` и `AppTextStyles` — `ThemeExtension`, единственный источник правды
  по цветам и стилям текста.
- Доступ в UI — только `context.colors.<name>` и `context.ts.<name>`.
- `Color(0xFF...)`, `TextStyle(...)`, `GoogleFonts.*`, `Theme.of(context).colorScheme`
  и `Theme.of(context).textTheme` в коде приложения запрещены.
- Имена полей — `lowerCamelCase` (`primary500`, `neutrals900`), имена стилей — из макета
  (`h2`, `paragraphSmall`), а не из Material.
- Нет нужного цвета/стиля → добавляем токен, а не пишем инлайн.
