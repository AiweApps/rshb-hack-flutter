# Винный Сканер — инструкция для Claude

Этот файл — точка входа. Он описывает проект, порядок работы и то, какое правило читать
перед какой задачей. Детальные правила лежат в `.claude/rules/` и подключены ниже.

---

## 1. Проект

Flutter-приложение, feature-first архитектура.

```
lib/
  app.dart                  # MaterialApp.router, тема, локали
  main.dart                 # инициализация сервисов, runZonedGuarded
  core/                     # инфраструктура, не знает о фичах
    application/bloc/       # BaseBloc, BaseBlocState, ScreenStatus, ui-эффекты, тосты
    constants/              # app_constants, app_style_constants, app_colors_*, app_text_styles_*
    extensions/             # context_extensions, navigation_extensions, форматтеры
    helpers/                # утилиты с состоянием, миксины
    misc/                   # адаптеры к платформе и хранилищам
    presentation/           # только тема и реестр ассетов: base_theme, app_icons
    router/                 # go_router: app_router, pages
    services/               # api, flavors, language, theme
    widgets/                # все переиспользуемые виджеты без домена, включая диалоги
  features/<feature>/
    application/bloc/       # bloc, event, state (freezed), uieffect
    domain/                 # модели, репозитории, эндпоинты
    presentation/           # page + content/loading/error + components
  shared/                   # доменные, но общие для нескольких фич вещи
  l10n/                     # ARB и сгенерированные AppLocalizations
```

Стек: `flutter_bloc` + `bloc_presentation`, `freezed`, `go_router`, `get_it`, `dio`,
`flutter_svg`, `google_fonts`, `shared_preferences`, Firebase (Analytics/Crashlytics).
Флейворы: `dev`, `prod`. Локали: `en`, `de`.

---

## 2. Агенты и скиллы

### Агенты — `.claude/agents/`

| Агент | Когда вызывать |
|---|---|
| `flutter-reviewer` | **После каждой законченной правки кода.** Сверяет результат с задачей и правилами, компилирует, отчитывается. Ничего не правит. Задача не закрыта, пока он не отчитался. |
| `screen-builder` | Реализация экрана и его блока: вёрстка по макету, наполнение готового каркаса, новый блок на экране. |
| `api-integrator` | Сетевой слой: модели, эндпоинты, репозиторий поверх `ApiRepository`. UI и блоки не трогает. |
| `database-builder` | Слой локальной БД: таблицы, DAO, миграции, кэш в репозитории фичи. UI и блоки не трогает. |

Зоны агентов не пересекаются: `api-integrator` отдаёт сеть, `database-builder` — хранение,
`screen-builder` собирает из этого экран. Задача, где нужно и то, и другое, разбивается
на вызовы по очереди, а не отдаётся одному агенту целиком.

### Скиллы — `.claude/skills/`

Скилл — точка входа разработчика. Агент — исполнитель в своём контексте. Скилл может
вызвать агента; наоборот — только `flutter-reviewer` вызывает `/check`.

| Скилл | Когда |
|---|---|
| `/new-feature <описание>` | Фича целиком: данные → блок → экран → маршрут. Оркестрирует `/new-data` и `/new-screen`, сводит слои. |
| `/new-screen <описание>` | База нового экрана: блок, стейт, ui-эффекты, четыре UI-файла, `components/`, локализация, DI, навигация. |
| `/new-data <описание>` | Слой данных: сеть, локальное хранение или оба. Выбирает исполнителя — `api-integrator` и/или `database-builder` — и сводит их в один репозиторий. |
| `/migrate-screen <экран>` | Приведение существующего экрана к `screens.md` без изменения поведения. |
| `/token <описание>` | Новый цвет, стиль текста, иконка или ключ ARB — сразу во всех обязательных местах. |
| `/rename-project [name=] [dev-name=] [dart-name=] [prod-id=] [dev-id=]` | Переименование проекта по флейворам: имена dev/prod, Dart-пакет, applicationId и bundle ID dev/prod, fastlane, `firebase.sh`, `appTitle`. Можно менять только имя или только ID. |
| `/check [all\|путь] [fix]` | Проверка на соответствие правилам. Без аргументов — текущий дифф. `fix` — применить правки. |
| `/review <задача>` | Ревью законченной правки: сверка с задачей + правила + компиляция. Ничего не правит. |

Типовой ход задачи:

```
/new-feature или /new-screen или /new-data  →  код  →  /check fix  →  /review <задача>
```

---

## 3. Как работать над задачей

0. **Проверить, нет ли подходящего скилла или агента** (§2). Фича целиком — `/new-feature`,
   новый экран — `/new-screen`, данные — `/new-data`, токен — `/token`,
   старый экран по правилам — `/migrate-screen`, переименование проекта — `/rename-project`.
1. **Понять, какого слоя касается задача**, и прочитать соответствующее правило (таблица в §5).
   Правила не «рекомендации» — код, им не соответствующий, считается несделанным.
2. **Проверить, нет ли уже готового.** Перед новым форматтером, хелпером, константой или
   виджетом — поиск по `core/extensions`, `core/helpers`, `core/constants`, `core/widgets`.
   Дубли — главная проблема этой кодовой базы.
3. **Писать код.** Локализация, токены темы и иконки заводятся **в тот же момент**, а не
   после («потом вынесем» не существует).
4. **Если чего-то нет в реестрах — спросить, а не выдумать** (см. §6).
5. **Проверить результат** (см. §7).

### Чего делать не нужно

- Рефакторить соседний код «заодно», если задача этого не требует.
  Заметил нарушение правил в чужом файле — сообщи, не чини молча.
- Добавлять зависимости в `pubspec.yaml` без согласования.
- Писать тесты «на всякий случай» — только если задача про них.
- Коммитить и пушить без явной просьбы.

---

## 4. Правила, которые нарушаются чаще всего

Это выжимка. Полные формулировки — в файлах §5.

1. **Строка в UI — сразу в ARB.** `Text('Some text')` не существует.
   Только `context.localization.someKey`.
2. **Картинка — сразу в реестр.** `SvgPicture.asset('assets/...')` не существует —
   только `SvgIconRes.someIcon.widget(...)`. `Image.network(...)` не существует —
   только `RemoteImage(url: ..., width: ..., height: ...)`.
3. **Цвет и стиль текста — только из токенов.** `Color(0xFF...)`, `Colors.white`,
   `TextStyle(...)`, `copyWith(fontSize:)`, `Theme.of(context).colorScheme`,
   `Theme.of(context).textTheme` не существуют. Только `context.colors.*` и `context.ts.*`.
4. **Число вёрстки — из констант.** `EdgeInsets.all(16)` не существует.
   Только `AppPadding.p16`, `AppSize.s24`, `AppRadius.r8`, `AppAlpha.a50`.
5. **Экран разделён на page / content / loading / error**, каждый — отдельный файл.
   Стейт `implements BaseBlocState` с полем `screenStatus` — иначе `BaseBloc` не примет его
   и код не соберётся.
6. **В `presentation/` нет логики.** Ни `sl<`, ни `await`, ни навигации, ни сайд-эффектов.
   Любой клик — событие блока.
7. **Переход — только через ui-эффект.** `context.go/push/pop` и `GoRouter` в
   `lib/features/**` не существуют. Блок эмитит эффект, `_onUiEffect` зовёт
   `sl<AppRouter>().navigateToX()`.
8. **Пользователь не видит технических строк.** Текст исключения, ответ бэка,
   `DioExceptionType` в тосте не существуют — только ключ из ARB.
9. **Конфигурация — не литерал.** `baseUrl`, таймауты, ключи хранилища, имена событий
   аналитики не пишутся строкой на месте использования, даже внутри `lib/core/`.
10. **Всё private, пока не доказано обратное.** Public-член заводится только при наличии
    вызывающего вне файла. У блока public-методов нет — только события.

---

## 5. Правила по слоям

Перед работой прочитать релевантный файл целиком.

### Подключены всегда

Эти пять касаются почти любой задачи и загружены в контекст ниже — отдельно открывать
не нужно.

| Задача | Правило |
|---|---|
| Новый экран, стейт, разбиение UI, пустое состояние, формы | `screens.md` |
| Любой пользовательский текст, ARB, ключи, plural, даты | `localization.md` |
| Цвета, стили текста, тема, `base_theme` | `theme.md` |
| Картинки, иконки, `app_icons.dart`, картинки из сети | `presentation.md` |
| Константы, размеры, отступы, URL, таймауты, лимиты | `constants.md` |

@.claude/rules/screens.md
@.claude/rules/localization.md
@.claude/rules/theme.md
@.claude/rules/presentation.md
@.claude/rules/constants.md

### Читать перед задачей

Не загружены в контекст — **прочитать целиком перед работой**, если задача их касается.
«Я примерно помню, что там» не считается: правила меняются.

| Задача | Правило |
|---|---|
| Поведение блока: `close`, подписки, дебаунс, конкурентность, связь блоков | `bloc.md` |
| Показ ошибок, `AppError` → `ErrorType`, что логировать | `errors.md` |
| Маршруты, `Pages`, аргументы перехода, deep links, возврат назад | `navigation.md` |
| Эндпоинты, репозитории, `Result`, отмена, пагинация, авторизация | `network.md` |
| Регистрация в `get_it`, `factory` vs `singleton`, старт приложения | `di.md` |
| DTO, domain-модели, `freezed`, `json_serializable`, `build_runner` | `models.md` |
| Prefs, secure storage, база данных, кэш, миграции | `storage.md` |
| Общие виджеты, `core/widgets` vs `shared/`, диалоги и шиты | `widgets.md` |
| События аналитики, Crashlytics, что нельзя отправлять | `analytics.md` |
| Флейворы, конфигурация окружений, секреты | `flavors.md` |
| Форматтеры, преобразования, `context.*` | `extensions.md` |
| Утилиты с состоянием, миксины, форматтеры ввода | `helpers.md` |
| Адаптеры платформы, обработка ошибок SDK | `misc.md` |
| Переполнение, клавиатура, длинные строки, крупный шрифт, a11y | `adaptive.md` |
| Списки, перерисовки, картинки, работа вне UI-потока | `performance.md` |
| Видимость членов, порядок в классе, именование, комментарии | `code-style.md` |
| Тесты | `testing.md` |
| Коммиты, ветки, что не попадает в репозиторий | `git.md` |

### Куда что класть — шпаргалка

| Что пишем | Куда |
|---|---|
| Пользовательский текст | `lib/l10n/app_*.arb` → `context.localization` |
| Картинка/иконка в сборке | `lib/core/presentation/app_icons.dart` |
| Картинка из сети | `RemoteImage` из `lib/core/widgets/remote_image.dart` |
| Цвет | `lib/core/constants/app_colors_constants.dart` (`AppColors`) |
| Стиль текста | `lib/core/constants/app_text_styles_constants.dart` (`AppTextStyles`) |
| Duration, лимит, размер страницы, имя события аналитики | `lib/core/constants/app_constants.dart` |
| Всё, что различается между dev и prod | `assets/flavors/*.json` → `AppFlavorService` |
| Размер, отступ, радиус, alpha, кегль | `lib/core/constants/app_style_constants.dart` |
| Чистое преобразование значения | `lib/core/extensions/<subject>_extensions.dart` |
| Маппинг модель → модель | рядом с моделью в `lib/features/<feature>/domain/` |
| Утилита с состоянием, миксин, `TextInputFormatter` | `lib/core/helpers/` |
| Адаптер к платформе/хранилищу/SDK | `lib/core/misc/` |
| Сервис с DI, IO, сетью | `lib/core/services/` |
| Виджет без домена (кнопка, поле, диалог) | `lib/core/widgets/` |
| Виджет, знающий о понятиях приложения, нужный нескольким фичам | `lib/shared/presentation/` |
| Часть контента одного экрана | `presentation/<screen>/components/` |
| Маршрут и переход | `lib/core/router/pages.dart` + `app_router.dart` |
| Регистрация блока/репозитория | `lib/di/di_core.dart` |
| Таблица, DAO, миграция | `lib/core/database/` + `features/<f>/domain/dao/` |

---

## 6. Токена нет — спросить, а не выдумать

Понадобился цвет, стиль текста, иконка или ключ локализации, которых нет в реестрах —
**не писать инлайн, не подбирать молча «похожее», не выдумывать имя в одиночку.**

Остановиться и задать разработчику вопрос, в котором обязательно есть:

1. значение (hex для цвета; кегль/вес/line-height для стиля);
2. где встретилось — файл и что именно этим оформляется;
3. ближайший существующий токен и насколько он близок;
4. 2–3 варианта имени по конвенции проекта, с обоснованием;
5. прямой вопрос: выбрать из предложенного / дать своё имя / «назови сам».

Если разработчик недоступен — токен всё равно не заводится инлайн-значением. Задача
останавливается на этом вопросе, всё остальное по задаче доделывается.

Полная процедура — `theme.md`, раздел «Процедура: нужного цвета или стиля нет в токенах».

---

## 7. Проверка перед завершением задачи

Задача не закрыта, пока не сделано всё из списка.

1. `flutter analyze` → `No issues found!`. Не «осталось пара warning'ов».
2. Менялись `freezed`/`json_serializable` модели →
   `dart run build_runner build --delete-conflicting-outputs`.
3. Добавлялся ключ локализации → ключ есть **во всех** ARB, l10n пересобран.
4. Пройтись по диффу против §4. Быстрая самопроверка:

```bash
# строки в UI
grep -rnE "Text\(\s*['\"]|hintText:\s*['\"]" lib
# хардкод цветов и стилей
grep -rnE "Color\(0x|Color\.fromARGB|TextStyle\(" lib | grep -v app_colors_constants
grep -rnE "\bColors\.[a-z]" lib | grep -v "Colors.transparent"
grep -rnE "Theme\.of\(.*\)\.(textTheme|colorScheme)" lib
grep -rnE "copyWith\([^)]*font(Size|Weight)" lib
# ассеты мимо реестра
grep -rnE "(SvgPicture|Image)\.asset\(\s*['\"]" lib | grep -v app_icons
# логика в UI
grep -rnE "sl<|await |context\.(go|push|pop)\(" lib/features/*/presentation
# навигация и диалоги мимо ui-эффекта
grep -rnE "context\.(go|push|pop)\(|GoRouter|showDialog\(|showModalBottomSheet\(" lib/features
# технический текст ошибки пользователю
grep -rn "getErrorMessage()" lib | grep -v app_error.dart
# конфигурация литералом
grep -rnE "https?://|Duration\(" lib | grep -v "app_constants\|///"
# картинки из сети мимо обёртки
grep -rn "Image.network" lib
# sl вне разрешённых мест
grep -rn "sl<" lib/core/extensions lib/core/helpers lib/features/*/presentation
```

5. `/review <формулировка задачи>` — вердикт по задаче и правилам. Задача не закрыта,
   пока ревьюер не отчитался.
6. Отчитаться честно: что сделано, что изменилось визуально, что осталось незакрытым и почему.
   Формат — §9. Не заявлять о готовности, пока пункты 1–5 не пройдены.

---

## 8. Команды

```bash
flutter pub get
flutter analyze
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n

flutter run --flavor dev  -t lib/main.dart
flutter run --flavor prod -t lib/main.dart
```

---

## 9. Формат отчётов

Отчёты читают в терминале IDE. Это касается любого вывода со списком мест в коде —
`/check`, `flutter-reviewer`, обычный ответ о проделанной работе.

- **Ссылки на код — кликабельные.** Один путь от корня проекта и **ровно один** номер
  строки, голым текстом без обратных кавычек:
  `lib/features/home/presentation/home_page.dart:57`.
  `home_page.dart:57, 74` или путь без префикса `lib/` кликом не откроются.
  Одно нарушение в четырёх строках — четыре отдельные ссылки.
- **Заголовки человеческие**, а не имена файлов правил: «Локализация», а не
  `localization.md`; «Цвета и текстовые стили», а не `theme.md`; «Структура экранов
  и логика в UI», а не `screens.md`.
- **Сводка сверху**, детали ниже. Списки мест — таблицами, а не абзацами.
- **Пустые разделы не выводить.** Замечаний нет — одна строка об этом.

---

## 10. Стиль кода

Полное правило — `code-style.md`. Выжимка:

- **Всё private, пока не доказано обратное.** Public-член заводится, только если есть
  вызывающий вне этого файла. В Dart уровня `internal` нет: есть public и `_`.
- **Порядок членов класса:** статика → поля (public, затем `_`) → конструкторы →
  геттеры → `@override` в порядке жизненного цикла → public-методы → private-методы.
  Приватные классы файла — после публичного.
- У блока нет public-методов, кроме `close()`. Поля `State` — всегда с `_`.
- Комментарии и doc-комментарии — **на английском**; `///` у публичных классов
  и неочевидных функций; комментарий объясняет **почему**, а не **что**.
- Форматирование — `dart format` (строка 80). Ширину не превышать вручную.
- Имена: файлы `snake_case`, классы `UpperCamelCase`, остальное `lowerCamelCase`.
- `part`/`part of` — только для `freezed`/`json_serializable` и `<screen>_event.dart`.
