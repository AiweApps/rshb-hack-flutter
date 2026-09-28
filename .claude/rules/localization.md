# Правила: локализация

## Главное правило — без исключений

**Любой текст, который увидит пользователь, выносится в локализацию СРАЗУ, в тот же момент,
когда написан.**

Как только в коде появляется `'Some text'` или `"Some text"`, попадающий в UI —
он в ту же правку уезжает в ARB и возвращается как ключ. Не «потом», не «когда будет
время на локализацию», не «пока заглушка» — **сразу**.

```dart
// ❌ запрещено, в любом виде
Text('Track details')
AppBar(title: const Text("Настройки"))
SnackBar(content: Text('Ошибка загрузки'))
throw Exception('Не удалось загрузить'); // если текст показывается пользователю
hintText: 'Search...'
'Найдено: $count'                        // интерполяция — тоже строка UI

// ✅
Text(context.localization.trackDetails)
AppBar(title: Text(context.localization.settings))
hintText: context.localization.searchForTracks
context.localization.foundCount(count)   // плейсхолдер в ARB, не интерполяция в коде
```

Это касается заглушек и временного кода тоже. Временная строка живёт дольше всех.

## Как добавлять ключ

1. Добавить ключ во **все** ARB-файлы: `lib/l10n/app_en.arb` и `lib/l10n/app_de.arb`.
   Файл с отсутствующим ключом — сломанная локаль.
2. В шаблоне (`app_en.arb`) рядом с ключом обязателен блок `@key` с `description`:

```json
"trackDetails": "Track Details",
"@trackDetails": {
  "description": "Track details page title"
}
```

3. Подстановки — через `placeholders`, а не через интерполяцию в Dart:

```json
"routeDoesNotExist": "Route [{route}] does not exist",
"@routeDoesNotExist": {
  "description": "Error message when route does not exist",
  "placeholders": {
    "route": { "type": "String", "description": "The route that was not found" }
  }
}
```

4. Пересобрать: `flutter gen-l10n` (или любой билд — `generate: true` в `pubspec.yaml`).

### Именование ключей

`lowerCamelCase`, смысловое, с префиксом области: `errorConnectionTitle`,
`settingsLanguageDescription`, `trackDetails`. Не `text1`, не `label_2`.

Ключ добавляется всегда — вопрос только в имени. Если имя неочевидно или ключ похож на
уже существующий, работает та же процедура, что и для токенов темы: показать строку, место
использования, ближайший существующий ключ и 2–3 варианта имени, и спросить разработчика.
См. `theme.md`, раздел «Процедура: нужного цвета или стиля нет в токенах».

Перевод на языки, которыми не владеешь: значение всё равно проставляется во все ARB
(machine-перевод или копия английского), и это **явно проговаривается** разработчику,
чтобы он заменил его на выверенный.

## Как читать локализацию

| Откуда | Как |
|---|---|
| Виджет / есть `BuildContext` | `context.localization.someKey` |
| Bloc, service, helper — контекста нет | `lsl10n.someKey` |
| Extension не на `BuildContext` | параметром `AppLocalizations l10n` (явная зависимость) |

Оба объявлены в `lib/core/services/language_service.dart`:

```dart
extension BuildContextL10n on BuildContext {
  AppLocalizations get localization => AppLocalizations.of(this)!;
}

AppLocalizations get lsl10n => LanguageService.localizations;
```

**`AppLocalizations.of(context)!` в новом коде не пишем** — только `context.localization`.

## Множественное число

Строка, в которой есть счётчик, **не** склеивается условиями в Dart. Только `plural` в ARB:

```json
"tracksFound": "{count, plural, =0{No tracks found} =1{1 track found} other{{count} tracks found}}",
"@tracksFound": {
  "description": "Search results counter",
  "placeholders": { "count": { "type": "int" } }
}
```

```dart
// ❌
Text('${count} ${count == 1 ? 'track' : 'tracks'}')
Text(context.localization.tracksFound + ': $count')

// ✅
Text(context.localization.tracksFound(count))
```

Правило жёсткое, потому что формы множественного числа различаются по языкам: правило
«1 / всё остальное» верно для английского и немецкого, но не для русского, и переписывать
это позже придётся во всех местах сразу.

Аналогично `select` — для строк, зависящих от рода или типа сущности.

## Даты, числа, валюта

Формат зависит от локали, а не от кода: `1,234.5` в en против `1.234,5` в de,
`12/31/2025` против `31.12.2025`.

- форматирование — через `intl` (`DateFormat`, `NumberFormat`) с **текущей локалью**,
  завёрнутое в extension из `core/extensions/` (`extensions.md`);
- `toString()`, `toStringAsFixed()` и ручная сборка `'$day.$month.$year'` для показа
  пользователю — запрещены;
- локаль берётся из `LanguageService`, не из `Platform.localeName`;
- относительное время («2 часа назад») — тоже локализуемая строка с `plural`,
  а не собранная конкатенацией.

## Тексты ошибок

Ошибка — такой же пользовательский текст, и правило то же: ключ в ARB.

- в блоке контекста нет — используется `lsl10n` (см. таблицу выше);
- текст сообщения из ответа бэка по умолчанию **не показывается**: он технический и
  не переведён. Показывается ключ, соответствующий типу ошибки (`errors.md`);
- исключение — если бэк по контракту отдаёт готовые локализованные сообщения для
  пользователя; это оговаривается явно, а не предполагается.

## Что НЕ является строкой UI

Правило про «сразу в локализацию» относится к тексту для пользователя. Технические строки
остаются строками — но у каждой из них есть своё место, и инлайн в коде фичи им тоже нельзя:

| Строка | Куда |
|---|---|
| Пути к ассетам (`"ic_close_24.svg"`) | `lib/core/presentation/app_icons.dart` |
| URL, эндпоинты, `mailto:` | `app_constants.dart` / `api_endpoints.dart` |
| Ключи `SharedPreferences` / secure storage | приватные `const` в файле хранилища |
| Имена полей JSON, `@JsonKey(name: ...)` | рядом с моделью |
| Имена событий аналитики | `AnalyticsEvents` в `app_constants.dart` |
| Тексты логов и `debugPrint` | инлайн допустим — пользователь их не видит |
| Сообщения `assert` | инлайн допустим |

Если сомневаешься, увидит ли строку пользователь — считай, что увидит, и локализуй.

## Проверка перед завершением задачи

Прогнать по диффу поиск строковых литералов внутри `Text(`, `hintText:`, `labelText:`,
`title:`, `message:`, `SnackBar`, `Tooltip`. Ни одного попадания быть не должно.
