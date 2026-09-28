# winescan

Flutter-приложение Винный Сканер.

## Установка и настройка

### Сертификаты и ключи

Сборка и заливка настроены только для prod: iOS → TestFlight, Android → RuStore.

#### iOS

- В App Store Connect заведено приложение `com.aiweapps.winescan`.
- Distribution-сертификат и App Store provisioning-профиль с именем `ws_prod_appstore`
  установлены в Xcode / связку ключей. Имя профиля задано в `ios/fastlane/Fastfile`
  (`prodProvisioningProfileName`) и в `ios/Runner.xcodeproj/project.pbxproj`
  (`PROVISIONING_PROFILE_SPECIFIER`). Там же нужно проставить свой `DEVELOPMENT_TEAM` — сейчас он пустой.
- Импорт сертификата и профиля fastlane выполняет только на CI (`is_ci?`) — файлы берутся из:

```
ios/certificates/prod/
├── ws_prod_appstore.mobileprovision
└── prod.p12
```

#### Android

Keystore кладётся в `android/winescan.jks`.

Создайте файл `key.properties` в папке `android` (шаблон — `key.properties.sample`):

- `storeFile=../winescan.jks`
- `storePassword=your_store_password`
- `keyAlias=your_key_alias`
- `keyPassword=your_key_password`

В консоли RuStore должно быть заведено приложение `com.aiweapps.winescan`.

### Переменные окружения

Шаблоны лежат в `ios/fastlane/.env.sample` и `android/fastlane/.env.sample`.
Скопируйте каждый в `.env.prod` в той же папке и заполните (`.env.prod` в git не попадает).

#### iOS — `ios/fastlane/.env.prod`

- `ASC_KEY_ISSUER_ID` — App Store Connect Issuer ID
- `ASC_KEY_ID` — App Store Connect Key ID
- `ASC_KEY_PATH` — путь к `AuthKey_XXXXXXXXXX.p8` (абсолютный или относительно `ios/fastlane`)
- `SLAVE_PASSWORD`, `CERT_PASSWORD` — только для CI: пароль связки ключей и пароль от `.p12`

#### Android — `android/fastlane/.env.prod`

- `RUSTORE_KEY_ID` — key id API-ключа RuStore
- `RUSTORE_PRIVATE_KEY` — приватный ключ API RuStore

Проверить конфигурацию без сборки:

```bash
cd ios/fastlane && bundle exec fastlane verify_prod --env prod
cd android/fastlane && bundle exec fastlane verify_prod --env prod
```

### Firebase

Конфиги генерируются скриптом. Перед первым запуском укажите `project=` внутри `firebase.sh`:

```bash
./firebase.sh dev
./firebase.sh prod
```

Скрипт положит `google-services.json` в `android/app/src/<flavor>/`,
`GoogleService-Info.plist` в `ios/flavors/<flavor>/` и перезапишет
`lib/firebase/firebase_options_<flavor>.dart`.

Инициализация Firebase в `lib/main.dart` пока закомментирована — раскомментируйте
`initializeFirebaseApp` после генерации конфигов. В `android/app/build.gradle.kts`
также нужно раскомментировать плагин `com.google.gms.google-services`.

## Flavors

Приложение поддерживает два flavor:

- `dev` — разработка (applicationId: `com.aiweapps.winescan.dev`)
- `prod` — продакшен (applicationId: `com.aiweapps.winescan`)

Конфигурация flavor читается из `assets/flavors/<flavor>.json` и доступна через
`sl<AppFlavorService>().flavor`.

Локальный запуск:

```bash
flutter run --flavor dev
flutter run --flavor prod
```

## Fastlane

Проект использует Fastlane для автоматизации сборки и заливки:

- `ios/fastlane/` — iOS (lanes: `testflight_prod`, `verify_prod`)
- `android/fastlane/` — Android (lanes: `rustore_prod`, `verify_prod`)

Номер сборки берётся из количества коммитов (`number_of_commits`), поэтому в репозитории
должен быть хотя бы один коммит. Версия — из `pubspec.yaml`. Для iOS нужен Xcode 26.

## Сборка и заливка

```bash
# iOS → TestFlight
./upload_ios_tf_prod.command

# Android → RuStore (загружается как черновик, публикация вручную)
./upload_android_rustore_prod.command
```

## Локализация

ARB-файлы лежат в `lib/l10n` (`app_en.arb`, `app_de.arb`), настройки — в `l10n.yaml`.
После правок:

```bash
flutter gen-l10n
```

В коде доступно через `context.localization.<key>`, а вне `BuildContext` (блоки, сервисы) —
через глобальный `lsl10n.<key>`. `AppLocalizations.of(context)!` в новом коде не используется.

## Кодогенерация

Часть состояний и моделей использует `freezed` / `json_serializable`:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Что уже есть в базе

- **Архитектура** — feature-first (`lib/features/<feature>/{application,domain,presentation}`),
  общее в `lib/core` и `lib/shared`. Стейт на `flutter_bloc` + `bloc_presentation`
  для одноразовых ui-эффектов.
- **DI** — `get_it`, регистрация в `lib/di/di_core.dart`, доступ через `sl<T>()`.
- **Роутинг** — `go_router` со `StatefulShellRoute` и таб-баром, маршруты описаны
  в `lib/core/router/pages.dart`. Для кнопок «назад» — `tryNavigateBack(context)`.
- **Тема** — дизайн-токены `AppColors` и `AppTextStyles` (оба `ThemeExtension`) —
  источник правды; `ColorScheme` и `TextTheme` внутри `getBaseTheme` выводятся из них
  и нужны только стоковым Material-виджетам. В коде — `context.colors.*` и `context.ts.*`.
  Светлая/тёмная схема переключается `ThemeService`; тёмная палитра пока копирует светлую.
- **Экраны** — стейт обязан реализовывать `BaseBlocState` с полем `screenStatus`
  (`ScreenStatus.loading / content / error`) — `BaseBloc` других стейтов не принимает.
- **Тосты** — единственный способ показать сообщение: `emitSnackBar.info/success/error(...)`
  из блока. `ScaffoldMessenger.showSnackBar` не используется.
- **Ошибки** — `AppErrorWidget.connection(...)` / `.serverError(...)` в вариантах
  `ErrorDisplay.fullScreen` и `ErrorDisplay.general` с ретраем.
- **Диалоги** — `BaseDialog`, `BaseBottomSheet`, `ConfirmationDialog`,
  `PickerDialog`, `DialogSuccessStep` / `DialogErrorStep` в `lib/core/widgets/dialog/`.
- **Хранилище** — `sl<AppPreferences>()` поверх `shared_preferences`.
- **API** — `ApiService` на `dio` с логирующим интерцептором, ответы приходят
  как `Result<T>` (`Success` / `Error` с `AppError`).
- **Ассеты** — типизированный реестр `SvgIconRes` в `lib/core/presentation/app_icons.dart`.

- **Картинки из сети** — `RemoteImage` в `lib/core/widgets/remote_image.dart`:
  дисковый кэш, плейсхолдер, обработка пустого и битого URL, ограничение размера
  декодирования. `Image.network` в коде не используется.

## Работа с Claude: правила, скиллы, агенты

Точка входа — `CLAUDE.md` в корне: Claude Code читает его автоматически в начале каждой
сессии. Он описывает проект, порядок работы и подключает часть правил из `.claude/rules/`.
Всё, что ниже, — справочник по тому, что там лежит.

```
CLAUDE.md              # инструкция для Claude: как работать над задачей
.claude/
  rules/               # правила по слоям (пять горячих подключены в CLAUDE.md)
  skills/              # команды, вызываются вручную через /имя
  agents/              # специализированные исполнители
```

**Скилл — точка входа разработчика. Агент — исполнитель в своём контексте.**
Скилл может вызвать агента; обратно — только `flutter-reviewer` вызывает `/check`.

Типовой ход задачи:

```
/new-feature | /new-screen | /new-data  →  код  →  /check fix  →  /review <задача>
```

### Скиллы

Вызываются вручную: `/имя аргументы`.

| Скилл | Для чего |
|---|---|
| `/new-feature <описание>` | фича целиком: данные → блок → экран → маршрут |
| `/new-screen <описание>` | база нового экрана |
| `/new-data <описание>` | слой данных: сеть, локальное хранение или оба |
| `/migrate-screen <экран>` | привести существующий экран к правилам |
| `/token <описание>` | новый цвет, стиль текста, иконка или ключ локализации |
| `/rename-project [name=] [dev-name=] [dart-name=] [prod-id=] [dev-id=]` | переименование проекта: имена и ID dev/prod, Dart-пакет; можно только имя или только ID |
| `/check [all\|путь] [fix]` | проверка соответствия правилам |
| `/review <задача>` | ревью законченной правки по конкретной задаче |

---

#### `/check` — проверка соответствия правилам

Прогоняет код через все правила проекта и `flutter analyze`. Основной инструмент
самопроверки — прогонять перед сдачей любой задачи.

```bash
/check                       # текущий дифф (изменённые + новые файлы), только отчёт
/check fix                   # то же, но применить правки
/check all                   # весь lib/
/check all fix
/check lib/features/home     # конкретный файл или папка
```

Работает в три прохода: быстрые grep'и → чтение подозрительных файлов → компиляция.
Нарушения делятся на три категории:

| Категория | Что происходит |
|---|---|
| Чинится автоматически (в режиме `fix`) | `Theme.of(context).textTheme/colorScheme` → токены, `Colors.white/black/red` → `context.colors`, `AppLocalizations.of(context)!` → `context.localization`, числа вёрстки → `AppSize`/`AppPadding`/`AppRadius` (недостающая константа заводится сама — имя выводится из значения), ассет из реестра → `SvgIconRes` |
| Задаёт вопрос | цвет или стиль текста, которых нет в токенах; новый ключ локализации; новая иконка — всё, где нужно придумать **имя**. Вопросы собираются и задаются одним блоком |
| Только отчёт | архитектурное: экран не разбит на `page/content/loading/error`, логика в `presentation/`, `_build…()`-методы, компонент знает о блоке, утечка в блоке, проглоченная ошибка. Переписывать экран без явной просьбы скилл не будет |

**Исключений нет.** В проекте не заведено «легаси, которое не считается»: правила
описывают целевое состояние, и любой код, ему не соответствующий, — нарушение независимо
от того, когда он написан. Единственное ограничение — область: `/check` без аргументов
смотрит только дифф, `/check all` смотрит весь `lib/`.

---

#### `/review` — ревью по задаче

Отвечает на два вопроса: соответствует ли код правилам и **сделано ли то, что просили**.
Второй — главный, поэтому задачу нужно сформулировать.

```bash
/review добавить на карточку трека кнопку «в избранное» с оптимистичным обновлением
```

Область — текущий дифф. Файлы, которых правка не касается, не проверяются. Ничего не
правит: результат — отчёт с вердиктом «принято / нужны правки». Внутри вызывает агента
`flutter-reviewer`, тот — `/check` для механической части.

Задачу не указать можно, но тогда она будет восстановлена из диффа, и агент честно
напишет об этом: сверять результат будет не с чем.

---

#### `/new-feature` — фича целиком

Вертикаль: слой данных → блок → экран → маршрут. Оркестрирует `/new-data` и `/new-screen`,
после чего проверяет стык, на котором обычно и ломается: сигнатуры репозитория против
того, что вызывает блок.

```bash
/new-feature избранное: список сохранённых треков, добавление и удаление
```

Нужен один экран в существующей фиче — это `/new-screen`. Нужен только запрос или только
хранение — `/new-data`.

---

#### `/new-screen` — база нового экрана

Создаёт каркас экрана: пустой контент и пустая логика, но всё на своих местах и всё
компилируется. Наполнение — отдельная задача (агент `screen-builder`).

```bash
/new-screen создать базу экрана избранного каталога
/new-screen детальная карточка альбома, открывается с главной, принимает Album
```

Перед генерацией уточнит то, что не следует из запроса: откуда экран открывается
(новая вкладка / вложенный в существующую / корневой), нужны ли параметры перехода,
грузит ли данные при открытии, точный заголовок для локализации.

Что создаёт:

```
lib/features/<feature>/
  application/bloc/   <screen>_bloc.dart, _event.dart, _state.dart, _uieffect.dart
  presentation/       <screen>_page.dart, _content.dart, _loading.dart, _error.dart
                      components/
```

плюс ключи в оба ARB-файла, `PageInfo` в `pages.dart`, маршрут и метод перехода
в `app_router.dart`, регистрацию блока в `di_core.dart`.

---

#### `/new-data` — слой данных

Один вход на всё, что лежит между бэкендом или диском и блоком. Сам решает, кого звать:
`api-integrator`, `database-builder`, обоих по очереди — или никого, если задача
закрывается флагом в `AppPreferences`.

```bash
/new-data подключи поиск альбомов: GET /search/album?q=
/new-data закэшируй избранное, чтобы открывалось офлайн
```

Экран и блок не трогает: отдаёт готовые методы репозитория и их сигнатуры.

---

#### `/migrate-screen` — привести экран к правилам

Переводит экран, написанный одним файлом с `_build…`-методами и навигацией из `onTap`,
в структуру `screens.md` — **без изменения поведения**.

```bash
/migrate-screen home
/migrate-screen lib/features/track_detail/presentation/track_detail_page.dart
```

Один вызов — один экран. Заодно чинит токены, локализацию и картинки из сети в этом же
экране. В отчёте явно отвечает на вопрос, изменилось ли что-нибудь в поведении.

---

#### `/token` — завести токен дизайн-системы

Каждый токен живёт не в одном месте, а в четырёх-шести: цвет — это поле, конструктор,
`copyWith`, `lerp`, `light` и `dark`. Пропущенная строка не ломает сборку и всплывает
позже — например, цвет без `lerp` не анимируется при смене темы.

```bash
/token цвет #FFF3BD для фона бейджа Explicit в карточке трека
/token стиль 15sp w500 line-height 20 для текста тоста
/token иконка ic_heart_filled.svg — лайк в карточке трека
/token ключ "Nothing found" для пустого результата поиска
```

Сначала проверит, что такого токена ещё нет; если имя неочевидно — задаст вопрос
с 2–3 вариантами по конвенции проекта.

> Имена скиллов пишутся через дефис — `new-screen`, не `new_screen`.

---

### Агенты

Claude выбирает их сам по описанию задачи; можно позвать явно: «вызови flutter-reviewer».
В отличие от скиллов, агент работает в собственном контексте и возвращает результат.

| Агент | Для чего | Чего не делает |
|---|---|---|
| `flutter-reviewer` | Ревью законченной правки: читает дифф, сверяет результат с исходной задачей и правилами, прогоняет `/check`, компилирует, выдаёт вердикт. Вызывается скиллом `/review` | Ничего не редактирует — только отчёт |
| `screen-builder` | Реализация экрана и его блока: вёрстка по макету, наполнение готового каркаса, новый блок на экране | Не трогает сетевой слой и хранение |
| `api-integrator` | Сетевой слой: модели ответа, `ApiEndpoint`, репозиторий поверх `ApiRepository`, разбор ошибок в `Result`, отмена, пагинация | Не трогает блоки и UI, не добавляет зависимости |
| `database-builder` | Локальное хранение: таблицы, DAO, миграции, entity и маппинг в domain, кэш внутри репозитория фичи | Не трогает блоки и UI; не подключает пакет БД без согласования |

Зоны не пересекаются: `api-integrator` отдаёт сеть, `database-builder` — хранение,
`screen-builder` собирает из этого экран. Задача, где нужно и то и другое, разбивается
на вызовы по очереди.

---

### Правила — `.claude/rules/`

Правила описывают **целевое состояние**. Код, им не соответствующий, считается
несделанным — вне зависимости от того, когда он написан. Списка разрешённых исключений
в проекте нет.

Пять горячих правил подключены в `CLAUDE.md` и загружаются в контекст автоматически.
Остальные Claude читает по мере надобности — таблица соответствия в `CLAUDE.md` §5.

#### Подключены всегда

| Файл | За что отвечает |
|---|---|
| `screens.md` | Устройство экрана: разбиение на `page` / `content` / `loading` / `error` отдельными файлами, `components/`, обязательный `BaseBlocState` со `screenStatus`, полный запрет логики в `presentation/`, клик через событие блока, пустое состояние, формы, обновление поверх контента |
| `localization.md` | Любой пользовательский текст сразу уезжает в ARB; `context.localization` и `lsl10n`; именование ключей, плейсхолдеры, `plural`; даты и числа под локаль |
| `theme.md` | Цвета и типографика: `AppColors` и `AppTextStyles` как источник правды, `ThemeData` как производная. Запрет `Color(0x…)`, `Colors.*`, `TextStyle(…)`, `copyWith(fontSize:)`. Процедура «токена нет — спросить, а не выдумать» |
| `presentation.md` | Ассеты через `app_icons.dart` и картинки из сети через `RemoteImage`: что закрывает обёртка и как ей пользоваться |
| `constants.md` | Никаких магических чисел и строк, включая `lib/core/`. Что лежит в `app_constants.dart` и `app_style_constants.dart` |

#### Читаются по задаче

| Файл | За что отвечает |
|---|---|
| `bloc.md` | Поведение блока: `emit` после `await`, `close()`, конкурентность событий, дебаунс, связь между блоками, иммутабельность стейта |
| `errors.md` | Путь ошибки `AppError` → `ErrorType` → UI; выбор канала (экран / блок / тост); что логировать в Crashlytics; запрет технических строк в UI |
| `navigation.md` | `app_router.dart` — только маршруты; порядок добавления экрана; типизированные аргументы перехода; deep links; возврат результата |
| `network.md` | Слои сетевого стека, `Result` наружу, конфигурация из флейвора, отмена запросов, пагинация, авторизация, логирование |
| `models.md` | DTO / domain / state, nullability, `@JsonKey`, `unknownEnumValue`, кодогенерация |
| `di.md` | `factory` vs `lazySingleton`, кому можно `sl<>()`, порядок старта, фатальность ошибки инициализации |
| `storage.md` | Что где хранить, слои БД, стратегии кэша, миграции, чистка при разлогине, выбор пакета |
| `widgets.md` | `core/widgets` vs `shared/presentation` vs `components`; диалоги и шиты через ui-эффект |
| `analytics.md` | Где вызывается трекинг, имена событий, что нельзя отправлять, Crashlytics |
| `flavors.md` | Конфигурация окружений, ветвление по возможностям, секреты |
| `extensions.md` | Переиспользуемые преобразования значений — extension в `core/extensions/` |
| `helpers.md` | Утилиты с состоянием, миксины, `TextInputFormatter` |
| `misc.md` | Адаптеры к платформе и сторонним SDK |
| `adaptive.md` | Переполнение, клавиатура, длина строк в разных локалях, крупный системный шрифт, доступность |
| `performance.md` | Списки, картинки, область перерисовки, работа вне UI-потока |
| `code-style.md` | Видимость (`public` / `_`, аннотаций `internal` в Dart нет), порядок членов класса, именование, комментарии, форматирование |
| `testing.md` | Когда и как пишутся тесты |
| `git.md` | Коммиты, ветки, что не попадает в репозиторий |

Если нужного цвета, стиля, иконки или ключа нет в реестрах — Claude обязан остановиться
и спросить имя, а не придумывать его самостоятельно.

### Линтер

Часть правил проверяется машинно — `analysis_options.yaml`: `cancel_subscriptions`,
`close_sinks` (утечки в блоках), `unawaited_futures` (проглоченные ошибки),
`prefer_const_*` (лишние перестроения), `avoid_dynamic_calls`,
`always_declare_return_types`. `flutter analyze` обязан быть чистым перед сдачей задачи.
