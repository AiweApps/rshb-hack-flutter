---
name: check
description: Проверяет код на соответствие правилам проекта из .claude/rules и приводит его к ним. Без аргументов проверяет текущий дифф, `all` — весь lib/, можно передать путь к файлу или папке. Слово `fix` в аргументах включает применение правок. Использовать перед сдачей любой задачи, а также когда просят проверить код, дифф, соответствие правилам, «проверь что я не нарушил», «приведи к правилам».
---

# check — проверка соответствия правилам проекта

## Аргументы

| Аргумент | Что делает |
|---|---|
| (пусто) | проверяет текущий дифф: `git diff HEAD` + untracked файлы в `lib/` |
| `all` | проверяет весь `lib/` |
| путь | проверяет указанный файл или папку |
| `fix` | дополнительно применяет правки (сочетается с остальными) |

Без `fix` — только отчёт, ни одного изменения на диске.

## Связь с `flutter-reviewer`

Скилл и агент — **разные входы**, а не один вызывает другой:

- `/check` — самопроверка. Отвечает на вопрос «соответствует ли код правилам».
  Умеет чинить (`fix`);
- `flutter-reviewer` — ревью законченной правки. Отвечает ещё и на вопрос «сделано ли то,
  что просили, и не сломалось ли поведение». **Он вызывает этот скилл** для механической
  части и добавляет сверху сверку с задачей. Ничего не правит.

Отсюда правило: набор grep'ов и структурных проверок живёт **здесь и только здесь**.
Агент его не дублирует.

## Порядок работы

Три прохода: дешёвые grep'и → чтение подозрительных файлов → компиляция.
Не начинай со чтения всех файлов подряд — это долго и не нужно.

### Шаг 0. Определить область

```bash
git status --short
git diff HEAD --name-only -- 'lib/**'
```

Untracked файлы тоже входят в дифф. Сгенерированные (`*.g.dart`, `*.freezed.dart`)
и `lib/l10n/app_localizations*.dart` из проверки исключаются всегда.

### Шаг 1. Текстовые нарушения (grep)

Прогони по области. Каждый блок соответствует правилу из `.claude/rules/`.

```bash
# localization.md — хардкод строк в UI
grep -rnE "Text\(\s*['\"]|hintText:\s*['\"]|labelText:\s*['\"]|SnackBar\(" <scope>
grep -rn "AppLocalizations.of(" <scope>

# theme.md — хардкод цветов и стилей
grep -rnE "Color\(0x|Color\.fromARGB|TextStyle\(" <scope> | grep -v app_colors_constants
grep -rnE "\bColors\.[a-z]" <scope> | grep -v "Colors.transparent"
grep -rnE "Theme\.of\(.*\)\.(textTheme|colorScheme)" <scope>
grep -rnE "copyWith\([^)]*font(Size|Weight)" <scope>
grep -rn "GoogleFonts\." <scope> | grep -v app_text_styles_constants

# presentation.md — ассеты мимо реестра
grep -rnE "(SvgPicture|Image)\.asset\(\s*['\"]|AssetImage\(" <scope> | grep -v app_icons

# constants.md — магические числа вёрстки
grep -rnE "EdgeInsets\.(all|symmetric|only)\([^)]*[0-9]|SizedBox\((width|height): ?[0-9]|BorderRadius\.circular\([0-9]|Duration\(" <scope>

# screens.md — логика в UI
grep -rnE "sl<|await |Future|context\.(go|push|pop)\(" <scope>/features/*/presentation
grep -rnE "Widget _build[A-Z]" <scope>

# navigation.md — навигация мимо AppRouter
grep -rnE "context\.(go|push|pop)\(|GoRouter|Navigator\." <scope>/features
grep -rn "state.extra as " <scope>

# widgets.md — диалоги и шиты мимо ui-эффекта
grep -rnE "showDialog\(|showModalBottomSheet\(|ScaffoldMessenger" <scope>/features

# errors.md — технический текст ошибки пользователю
grep -rn "getErrorMessage()" <scope> | grep -v app_error.dart
grep -rnE "catch \(.*\) \{\s*\}|\?\? ''" <scope>

# network.md / flavors.md / constants.md — конфигурация литералом
grep -rnE "https?://" <scope> | grep -v "app_constants\|///"
grep -rnE "Duration\(" <scope> | grep -v app_constants
grep -rnE "AppFlavor\.(dev|prod)|kDebugMode" <scope>

# performance.md / presentation.md — картинки из сети и списки
grep -rn "Image.network" <scope>
grep -rnE "ListView\(|GridView\(|shrinkWrap: true" <scope>

# di.md — sl вне разрешённых мест
grep -rn "sl<" <scope>/core/extensions <scope>/core/helpers <scope>/features/*/presentation
grep -rn "SharedPreferences.getInstance" <scope> | grep -v app_preferences

# models.md — enum без запасного значения
grep -rn "@JsonKey" <scope> | grep -v unknownEnumValue   # смотреть только enum-поля

# code-style.md — публичное там, где должно быть приватным
grep -rnE "^  [A-Za-z].*\(.*\) (async )?\{" <scope>/features/*/application/bloc/*_bloc.dart
grep -rnE "^  [a-zA-Z].* [a-z][A-Za-z]* ?;" <scope>/features/*/presentation   # поля State без _
```

Первый — public-методы блока: их не должно быть, кроме `close()`. Второй — поля
`State` без `_`. Оба дают ложные срабатывания на конструкторах и параметрах виджета,
отсекай глазами.

Ложные срабатывания отсекай сам: doc-комментарии (`///`), сами файлы реестров
(`app_icons.dart`, `app_colors_constants.dart`, `app_text_styles_constants.dart`,
`base_theme.dart`), параметры виджетов вроде `final bool isLoading` в диалогах.

### Шаг 2. Структурные нарушения (чтение)

Grep их не ловит. Читай файлы, затронутые диффом. Проверяй только те группы, которые
дифф действительно задевает, — и открывай соответствующее правило из `.claude/rules/`,
если оно не подключено в `CLAUDE.md`.

**Структура экрана — `screens.md`**

- у экрана есть `_page` / `_content` / `_loading` / `_error` отдельными файлами;
- стейт `implements BaseBlocState`, флагов `isLoading`/`hasError` в стейте нет;
- `switch` по `screenStatus` исчерпывающий, без `default`;
- виджеты в `components/` не обращаются к блоку (`context.read<`, `BlocBuilder`);
- каждый `onTap`/`onPressed` шлёт событие блока, а не делает работу сам;
- пустой результат — `content` + отдельный виджет, а не ошибка и не новый статус;
- обновление поверх контента — поле стейта, а не `ScreenStatus.loading`.

**Поведение блока — `bloc.md`**

- после `await` перед `emit` есть `emit.isDone` / `isClosed`;
- заведённые подписки, таймеры, `CancelToken`, `Debouncer` освобождены в `close()`;
- поиск/фильтр с сетью — с дебаунсом; кнопка с запросом защищена от двойного нажатия;
- коллекции в стейте пересоздаются, а не мутируются;
- блок не обращается к другому блоку.

**Ошибки — `errors.md`**

- ошибка не проглочена: провалившийся запрос виден пользователю;
- `AppError` не пересекает границу `presentation/`;
- в стейте есть `errorType`, если экран умеет показывать ошибку;
- ошибка рисуется через `AppErrorWidget`.

**Данные — `models.md`, `network.md`, `storage.md`**

- метод репозитория возвращает `Result`, исключения наружу не летят;
- DTO nullable там, где бэк не гарантирует поле; enum с `unknownEnumValue`;
- маппинг DTO → domain лежит рядом с моделью, а не в блоке или виджете;
- сгенерированные файлы соответствуют исходникам;
- новое хранимое значение — именованная пара в `AppPreferences`, а не строковый ключ
  на месте вызова.

**Стиль и видимость — `code-style.md`**

- у каждого public-члена есть вызывающий **вне его файла**. Проверяется точечно:
  `grep -rn "\.<имя>(" <scope> | grep -v <сам файл>` — пусто значит должно быть `_`;
- у блока нет public-методов, кроме `close()`;
- все поля `State` — с `_`;
- порядок членов: статика → поля → конструкторы → геттеры → `@override` по жизненному
  циклу → public-методы → private-методы; приватные классы — после публичного;
- `dispose` / `close` — последний из переопределений;
- класс-неймспейс констант имеет приватный конструктор;
- комментарии на английском, `TODO` с пояснением.

**Слои и связность**

- в `lib/core/` нет импортов из `lib/features/**`;
- новый форматтер не дублирует то, что уже есть в `core/extensions/` и `core/helpers/`;
- extension лежит в `core/extensions/`, а не в `core/helpers/` или `core/misc/`;
- виджет лежит там, где ему позволяют импорты (`core/widgets` / `shared/presentation` /
  `components`); в `core/presentation/` виджетов нет;
- блок регистрируется `factory`, репозиторий — `lazySingleton`;
- ключ локализации присутствует **во всех** ARB-файлах.

### Шаг 3. Компиляция

```bash
flutter analyze
```

Если менялись freezed/json-модели — сначала
`dart run build_runner build --delete-conflicting-outputs`.

## Что чинится автоматически (режим `fix`)

Эти правки применяй без вопросов: правильный результат берётся из таблиц ниже или выводится
из значения, выбирать нечего.

### `Theme.of(context).textTheme.X` → `context.ts.Y`

| Material-слот | Токен |
|---|---|
| `displayLarge` | `h1` |
| `displayMedium` | `h2` |
| `displaySmall` | `h3` |
| `headlineLarge` | `h4` |
| `headlineMedium` | `paragraphLargeBold` |
| `headlineSmall` | `fieldsetLabel` |
| `titleLarge` | `timerLarge` |
| `titleMedium` | `timer` |
| `titleSmall` | `appBarTitle` |
| `labelLarge` | `paragraphBold` |
| `labelMedium` | `paragraphSmallBold` |
| `labelSmall` | `paragraphTinyBold` |
| `bodyLarge` | `paragraph` |
| `bodyMedium` | `paragraphSmall` |
| `bodySmall` | `paragraphTiny` |

Поля `AppTextStyles` не-nullable — убирай `?` перед `.copyWith`.

### `Theme.of(context).colorScheme.X` → `context.colors.Y`

`primary`→`neutrals900`, `onPrimary`→`neutrals100`, `secondary`→`primary500`,
`onSecondary`→`neutrals900`, `error`→`error`, `onError`→`neutrals100`,
`surface`→`neutrals100`, `onSurface`→`neutrals900`, `outline`→`neutrals400`,
`primaryContainer`→`neutrals300`, `secondaryContainer`→`primary100`.

Источник истины — `_colorSchemeFrom` в `lib/core/presentation/base_theme.dart`.
Если он изменился, бери маппинг оттуда, а не из этой таблицы.

### `Colors.X` → `context.colors.Y`

`Colors.white`→`neutrals100`, `Colors.black`→`neutrals900`, `Colors.red`→`red`,
`Colors.grey`→`grey`. `Colors.transparent` не трогай — это разрешено.

### `AppLocalizations.of(context)!` → `context.localization`

Добавь импорт `core/services/language_service.dart`, убери импорт
`l10n/app_localizations.dart`, если он больше не нужен.

### Числа вёрстки → константы

Есть константа с таким значением — подставь её. Нет — **заведи**: имя выводится из значения
механически (`16` → `AppPadding.p16` / `AppSize.s16` / `AppRadius.r16`, `1.5` → `s1_5`),
спрашивать тут нечего. Вставляй в нужный класс `app_style_constants.dart`, сохраняя
порядок по возрастанию.

Выбор класса: отступ внутри `EdgeInsets` → `AppPadding`; ширина/высота/размер иконки →
`AppSize`; `BorderRadius.circular` → `AppRadius`; `withAlpha` → `AppAlpha`; `Duration` →
`DurationConstant`.

### Ассет, который уже есть в реестре

`SvgPicture.asset('assets/images/ic_close_24.svg')` → `SvgIconRes.close24.widget(...)`.

## Что НЕ чинится автоматически

### Требует вопроса разработчику

Действуй по процедуре из `.claude/rules/theme.md` («Процедура: нужного цвета или стиля нет
в токенах»): значение → где встретилось → ближайший токен → 2–3 варианта имени → вопрос.

- цвет, которому не нашлось точного соответствия в `AppColors`;
- текстовый стиль, которого нет в `AppTextStyles` (в том числе возникший из
  `copyWith(fontSize:)` / `copyWith(fontWeight:)`);
- новый ключ локализации — нужно имя ключа и текст на всех локалях;
- новая иконка — нужно семантическое имя для enum.

Собери **все** такие вопросы и задай их одним блоком в конце, а не по одному.

### Требует ручной работы — только отчёт

- экран не разбит на `_page`/`_content`/`_loading`/`_error`;
- логика в `presentation/` (навигация из `onTap`, `await`, `sl<`);
- приватные `_build…()`, возвращающие `Widget`;
- компонент в `components/`, знающий о блоке;
- дублирующийся форматтер или виджет;
- утечка в блоке: незакрытая подписка, таймер, отсутствующий `close()`;
- проглоченная ошибка и технический текст, показанный пользователю;
- `Image.network` вместо общей обёртки;
- неверный тип регистрации в DI;
- виджет лежит не в том каталоге;
- public-член без внешних вызывающих; public-метод у блока; поле `State` без `_`;
- порядок членов класса.

Для каждого — что нарушено, какое правило, и одной строкой что нужно сделать.
Не переписывай экран целиком без явной просьбы: это отдельная задача.

## Формат отчёта

Отчёт читает разработчик в терминале. Он должен сканироваться глазами за 10 секунд,
а детали — открываться кликом. Соблюдай формат ниже буквально.

### Правило №1: пути должны быть кликабельными

В терминале IDE путь становится ссылкой (cmd + клик), только если он записан как
**один путь от корня проекта и ровно один номер строки**.

```
✅ lib/features/home/presentation/home_page.dart:57
❌ lib/core/services/theme_service.dart:39, 45      — два номера, ссылка не соберётся
❌ core/services/api/service/api_service.dart:36    — нет префикса lib/
❌ home_page.dart:123, 124, 127, 130                — нет пути и четыре номера
```

Одно нарушение в четырёх строках — **четыре строки таблицы**, а не одна с перечислением.
Путь пиши голым текстом, без обратных кавычек — так его надёжнее распознаёт терминал.

### Правило №2: человеческие заголовки, а не имена файлов правил

Разработчику не нужно знать, в каком `.md` лежит правило. Заголовок говорит,
**что проверяли**:

| Вместо | Пиши |
|---|---|
| `localization.md` | Локализация |
| `theme.md` | Цвета и текстовые стили |
| `presentation.md` | Иконки и ассеты |
| `constants.md` | Константы и магические числа |
| `screens.md` | Структура экранов и логика в UI |
| `bloc.md` | Поведение блока |
| `errors.md` | Обработка ошибок |
| `navigation.md` | Навигация |
| `network.md` | Сетевой слой |
| `models.md` | Модели и кодогенерация |
| `di.md` | Внедрение зависимостей |
| `storage.md` | Локальные данные |
| `widgets.md` | Общие виджеты и диалоги |
| `analytics.md` | Аналитика |
| `flavors.md` | Конфигурация и флейворы |
| `adaptive.md` | Адаптивность |
| `performance.md` | Производительность |
| `extensions.md` | Расширения и форматтеры |
| `helpers.md` | Хелперы и утилиты |
| `code-style.md` | Стиль и видимость |
| `misc.md` | Платформенные адаптеры |
| — | Связность слоёв |

Имя файла правила упоминай только если разработчик просит объяснить, откуда требование.

### Правило №3: исключений нет

В проекте нет «легаси, которое не считается», и нет списка разрешённых нарушений.
Правила описывают целевое состояние; всё, что ему не соответствует, попадает в отчёт
как нарушение — независимо от того, когда этот код написан.

Из этого следует только одно послабление в **отчёте по диффу**: файлы, которых дифф не
касается, не проверяются, потому что не входят в область. Проверка `all` показывает всё.

### Правило №4: сводка сверху

Первым делом — таблица «сколько чего», чтобы масштаб был виден сразу. Детали ниже.

### Структура отчёта

```markdown
## Проверка проекта — весь lib/        ← или «изменённые файлы», или путь

| | Категория | Кол-во | Что дальше |
|---|---|---|---|
| 🔵 | Вопросы к тебе | 2 | блокируют — ответь, и я доделаю |
| 🟡 | Чинится командой /check all fix | 10 | скажи слово — применю |
| 🔴 | Ручная работа | 7 | отдельные задачи, список ниже |

`flutter analyze` — чисто.

---

### 🔵 Вопросы к тебе

**1. Стиль текста для тоста** — lib/core/presentation/widgets/app_toast.dart:220

Сейчас 15sp / w500, такого стиля в токенах нет. Ближайшие: `paragraphSmall` (15sp/w400),
`paragraphSmallBold` (15sp/w700) — по весу не совпадает ни один.

| Вариант имени | Логика |
|---|---|
| `toastMessage` | по назначению, в пару к `toastSuccess` / `toastError` |
| `paragraphSmallMedium` | по шкале, честно отражает w500 |

Как назвать? Могу выбрать сам — тогда возьму `toastMessage`.

---

### 🟡 Чинится командой /check all fix

**Числа вёрстки → константы**

| Файл | Литерал | Куда |
|---|---|---|
| lib/features/home/presentation/home_page.dart:57 | `SizedBox(height: 16)` | `AppSize.s16` |
| lib/features/home/presentation/home_page.dart:74 | `EdgeInsets.all(16.0)` | `AppPadding.p16` |
| lib/core/services/api/service/api_service.dart:36 | `Duration(seconds: 30)` | `DurationConstant.d30s` — завести |

---

### 🔴 Ручная работа

#### Структура экранов и логика в UI

| Файл | Что не так | Что делать |
|---|---|---|
| lib/features/settings/presentation/pages/settings_page.dart:51 | `await ThemeService.saveTheme()` прямо из `onChanged` | завести блок, действие — через событие |
| lib/features/home/application/bloc/home_state.dart:12 | нет поля `errorType` | добавить, иначе `_error`-виджет строить не из чего |

#### Хранилища и платформенные адаптеры

| Файл | Что не так | Что делать |
|---|---|---|
| lib/core/services/theme_service.dart:39 | `SharedPreferences.getInstance()` напрямую | геттер/сеттер в `AppPreferences`, доступ через `sl<AppPreferences>()` |

---

### ✅ Без замечаний

Локализация (34 ключа согласованы в обоих ARB), цвета и текстовые стили, иконки и ассеты.
```

### Общие требования

- **Категорий может не быть** — пустые разделы не выводи. Нет вопросов — нет блока вопросов.
- **Прозы минимум.** Пояснение уместно там, где из таблицы не понятно, — одним абзацем
  под таблицей, а не вместо неё.
- **Раздел «Без замечаний» обязателен** — по нему видно, что проверка была полной,
  а не что до этих правил руки не дошли.
- **Не выдумывай замечания ради объёма.** Нарушений нет — так и напиши одной строкой.
- **В конце** — одна строка о том, что делать дальше: например
  «скажи `/check all fix` — применю блок с числами вёрстки, остальное не трону».
- Если запуск был **с `fix`** — колонка «Что дальше» у жёлтой категории меняется
  на «исправлено», а в таблицах вместо «Куда» пишется, что именно подставлено.
