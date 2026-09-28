# Правила: `lib/core/extensions/`

## Главное правило

**Любая переиспользуемая чистая операция над значением — это extension в `lib/core/extensions/`.**

Как только появляется преобразование даты, числа, строки, `Duration`, коллекции или
вытаскивание чего-то из `BuildContext` — оно **сразу** оформляется как extension в
профильном файле. Не приватная функция внутри виджета, не `static`-метод в случайном классе,
не копипаста в двух фичах.

```dart
// ❌ в файле виджета
String _formatDuration(int seconds) => '${seconds ~/ 60}:${(seconds % 60)}';

// ✅ lib/core/extensions/format_extensions.dart
extension DurationFormat on int {
  String get formattedDuration { ... }
}
// вызов: track.duration.formattedDuration
```

Нужного файла нет — **создаём файл**, а не складываем в ближайший подходящий.

## Карта файлов

Один файл = один тип-получатель. Имя файла — `<subject>_extensions.dart`.

| Файл | `on` | Что там |
|---|---|---|
| `context_extensions.dart` | `BuildContext` | `scheme`, `colors`, `textStyle` — доступ к теме |
| `navigation_extensions.dart` | `BuildContext` | `canNavigateBack`, `tryNavigateBack` — навигация go_router |
| `format_extensions.dart` | `int`, `num` | форматирование чисел, длительностей, цен |
| `date_extensions.dart` | `DateTime`, `String` | парсинг/форматирование дат, `formatTimeAgo`, ISO ↔ UI |
| `string_extensions.dart` | `String` | валидация (email, ФИО), маскирование, инициалы, обрезка |
| `num_extensions.dart` | — | безопасные конверсии из `dynamic`: `toIntOrNull`, `toDoubleOrZero` |
| `list_extensions.dart` | `Iterable` | `joinNonEmpty` и подобное |

Файлы заводятся по мере надобности — заранее пустые не создаём.

## Именование

- Extension: `<Тип><Назначение>` — `DurationFormat on int`, `StringValidation on String`,
  `BuildContextColors on BuildContext`, `NullableStringIterableX on Iterable<String?>`.
- Один файл может содержать несколько extension'ов на один тип, если они про разное
  (`StringValidation`, `FormattedDateExtension`) — это нормально и лучше одного гигантского.
- Геттер без параметров (`formattedDuration`) предпочтительнее метода `format()`.

## Что в `extensions/` НЕ кладём

- **Маппинг модель → модель.** DTO → domain, domain → UI-модель — живёт рядом со своей
  моделью в `lib/features/<feature>/domain/` (или `presentation/models/` для UI-моделей).
  В `core/extensions/` — только преобразования примитивов и фреймворковых типов.
- **Логику с состоянием, IO, таймерами.** Это `helpers/` (см. `helpers.md`).
- **Обращения к DI/сети.** Это `services/`.
- **Виджеты и extension'ы, возвращающие виджеты.** Это `core/widgets/` или
  `core/presentation/`.

## Локализация внутри extension'ов

Форматтеры часто нуждаются в строках из ARB. Порядок предпочтения:

1. Extension на `BuildContext` → `context.l10n.someKey` напрямую.
2. Extension на другом типе → передаём `AppLocalizations l10n` параметром:
   `int.reviewLabel(AppLocalizations l10n)`. Это делает зависимость явной и тестируемой.
3. Глобальный `lsl10n` — только там, где контекста нет в принципе (bloc, service).

## Перед написанием новой функции

Сначала грепаем существующие файлы `lib/core/extensions/` и `lib/core/helpers/`.
Дубли форматтеров — самая частая проблема в этих проектах.
