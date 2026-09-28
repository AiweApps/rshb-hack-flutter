---
name: rename-project
description: Переименовывает Flutter-проект с учётом флейворов dev/prod — отображаемые имена, имя Dart-пакета (pubspec и `package:` импорты), applicationId/namespace Android с переносом каталога Kotlin, bundle ID iOS, fastlane, firebase.sh, `appTitle` в ARB и упоминания в документации. Умеет менять только имя, только ID или всё сразу. Использовать, когда просят «переименуй проект», «смени bundle id / applicationId / package name», «поменяй название приложения», «сделай из шаблона новый проект».
---

# rename-project — переименование проекта

Имя проекта в Flutter зашито не в одном месте, а в нескольких идентификаторах, которые
у каждого флейвора (`dev`, `prod`) свои и живут в Dart, Gradle, Xcode, fastlane и скриптах.
Пропущенное место не всегда ломает сборку: старый bundle ID в `Fastfile` всплывёт только
при выкладке, старое имя dev-сборки — на экране телефона тестировщика. Скилл проходит все
места разом и доказывает поиском, что старых значений не осталось.

## Аргументы

Именованные, в любом порядке. Каждый — необязательный, но нужен хотя бы один.

| Аргумент | Что меняет | Пример |
|---|---|---|
| `name=` | имя prod-сборки, `appTitle`, заголовки документации | `name="Shop Hub"` |
| `dev-name=` | имя dev-сборки | `dev-name="Shop Hub Dev"` |
| `dart-name=` | имя Dart-пакета и все `package:` импорты | `dart-name=shop_hub` |
| `prod-id=` | applicationId и bundle ID prod, `namespace`, Kotlin-пакет | `prod-id=com.acme.shophub` |
| `dev-id=` | applicationId и bundle ID dev | `dev-id=com.acme.shophub.dev` |

```
/rename-project name="Shop Hub"                                          # только имя
/rename-project prod-id=com.acme.shophub dev-id=com.acme.shophub.dev     # только ID
/rename-project name="Shop Hub" prod-id=com.acme.shophub dev-id=com.acme.shophub.dev
/rename-project dev-id=com.acme.shophub.staging                          # только dev ID
```

Аргументы без ключей (`/rename-project "Shop Hub" com.acme.shophub`) — разобрать по смыслу:
строка с точками и без пробелов — `prod-id`, остальное — `name`. Не получается однозначно —
спросить одним вопросом.

## Шаг 1. Прочитать текущие значения

Старые значения **не хардкодятся** в скилле — их читают из проекта, потому что скилл
запускается и на уже переименованных копиях шаблона.

```bash
grep -m1 "^name:" pubspec.yaml                                         # OLD_DART_NAME
grep -nE "namespace|applicationId|applicationIdSuffix|app_name|create\(" \
  android/app/build.gradle.kts                                          # ID и имена по флейворам
grep -nE "APP_DISPLAY_NAME|PRODUCT_BUNDLE_IDENTIFIER|name = \"?(Debug|Release|Profile)" \
  ios/Runner.xcodeproj/project.pbxproj
grep -nE "BundleId" ios/fastlane/Fastfile android/fastlane/Fastfile firebase.sh
grep -n '"appTitle"' lib/l10n/app_en.arb
```

| Значение | Откуда | Как вычисляется |
|---|---|---|
| `OLD_PROD_ID` | `applicationId` в `defaultConfig` | как есть |
| `OLD_DEV_ID` | флейвор `dev` | `applicationId` флейвора, если задан, иначе `OLD_PROD_ID` + `applicationIdSuffix` |
| `OLD_PROD_NAME` | `resValue("string", "app_name", ...)` флейвора `prod` | как есть |
| `OLD_DEV_NAME` | то же у `dev` | как есть |
| `OLD_DART_NAME` | `name:` в `pubspec.yaml` | как есть |

**Сверить источники между собой.** ID и имена в Gradle, `project.pbxproj`, обоих `Fastfile`
и `firebase.sh` обязаны совпадать по флейвору. Расхождение (например, iOS dev уже на другом
ID) — показать разработчику таблицей и спросить, что считать текущим, до любых правок.

## Шаг 2. Вывести новые значения

Непереданное значение остаётся старым — **кроме** выводимых по правилам ниже. Выведенное
значение не применяется молча: оно попадает в план шага 3 с пометкой «выведено».

| Передано | Что выводится |
|---|---|
| `name` без `dev-name` | `dev-name` = `name` + суффикс старого dev-имени относительно prod (`DiscoMarket Dev` → суффикс ` Dev` → `Shop Hub Dev`). Суффикса нет — спросить |
| `name` без `dart-name` | **спросить**, менять ли имя Dart-пакета. Это правка всех импортов — большой дифф без видимого эффекта. Предложить `snake_case` от `name` |
| `prod-id` без `dev-id` | `dev-id` = `prod-id` + суффикс старого dev ID относительно prod (`.dev`). Старый dev ID не является prod + суффикс — спросить |
| только `dev-id` | prod не трогается, `namespace` и Kotlin-пакет тоже |
| только `dev-name` | prod-имя, `appTitle` и документация не трогаются |

Производные:

| Значение | Правило |
|---|---|
| `NEW_KOTLIN_PATH` | `NEW_PROD_ID` с `.` → `/`. Только если меняется `prod-id` |
| `DEV_SUFFIX` | если `NEW_DEV_ID` начинается с `NEW_PROD_ID.` — хвост (`.dev`); иначе суффикса нет |

### Валидация

До любых правок, по каждому переданному или выведенному значению:

- ID: reverse-DNS, минимум два сегмента, каждый `^[a-z][a-z0-9_]*$`, ни один не
  зарезервированное слово Java/Kotlin (`new`, `class`, `package`, `in`, `is`, `object`…);
- `NEW_DEV_ID != NEW_PROD_ID` — иначе dev и prod не встанут на одно устройство, а Firebase
  и сторы их не различат;
- `dart-name`: `^[a-z][a-z0-9_]*$`, не зарезервированное слово Dart;
- `CFBundleName` в `Info.plist` берётся из `dart-name` и ограничен 15 символами — длиннее
  предупредить и спросить короткий вариант;
- имя содержит `"`, `\` или `$` — предупредить: их придётся экранировать в Gradle,
  `project.pbxproj` и ARB.

Невалидное значение — стоп, сказать разработчику, что не так, и предложить вариант.

## Шаг 3. Показать план и получить подтверждение

Вывести таблицу только по **меняющимся** значениям:

| | dev | prod |
|---|---|---|
| ID | `disco.market.app.dev` → `com.acme.shophub.dev` | `disco.market.app` → `com.acme.shophub` |
| Имя | `DiscoMarket Dev` → `Shop Hub Dev` *(выведено)* | `DiscoMarket` → `Shop Hub` |

Отдельной строкой — Dart-пакет, если меняется. Ниже — какие шаги из 4–8 будут выполнены
и какие пропускаются, потому что их значения не меняются.

Вопросы — только релевантные режиму:

1. **Меняется ID флейвора, который уже опубликован?** Смена ID — это новое приложение
   в Google Play / App Store (для dev — в Firebase App Distribution / TestFlight): обновление
   поверх старого не встанет, пользователи и отзывы не переедут. Переспросить.
2. **Меняется prod-имя:** keystore в `android/key.properties.sample` и `README.md` назван по
   старому имени (`<old>.jks`, alias `<old>_app_key`). Переименовать в шаблоне? Уже
   существующий боевой keystore и его alias не трогаются никогда.
3. **Меняется ID:** префиксы профилей в `ios/fastlane/Fastfile`
   (`devProvisioningProfilePrefix`, `prodProvisioningProfilePrefix`) должны совпадать с
   профилями в Apple Developer Portal. Оставить или сменить — на какие?

Без подтверждения плана — не начинать.

## Шаг 4. Имя Dart-пакета — только если меняется `dart-name`

**`pubspec.yaml`:** `name: OLD_DART_NAME` → `name: NEW_DART_NAME`.

**Импорты** — во всех `.dart` в `lib/`, `test/`, `integration_test/` (если есть):

```bash
grep -rl "package:OLD_DART_NAME/" lib test integration_test 2>/dev/null \
  | xargs perl -pi -e 's#package:OLD_DART_NAME/#package:NEW_DART_NAME/#g'
```

`perl -pi`, а не `sed -i`: у BSD `sed` на macOS другой синтаксис `-i`.
Закомментированные импорты тоже меняются — иначе финальный поиск не будет пустым.

**`ios/Runner/Info.plist`:** `CFBundleName` → `NEW_DART_NAME`.

`lib/l10n/app_localizations*.dart` генерируется — не правится руками, пересобирается в шаге 9.

## Шаг 5. Идентификаторы — только если меняется `prod-id` и/или `dev-id`

### Как заменять, чтобы не задеть соседний флейвор

Старый dev ID обычно содержит prod ID как префикс (`disco.market.app.dev`). Поэтому
**глобальная замена `OLD_PROD_ID` запрещена** — она перепишет и dev ID.

Заменять только **целое значение с ограничителем**: `= OLD_ID;`, `= OLD_ID.RunnerTests;`,
`"OLD_ID"`. Точки в регулярке экранировать. При таком способе порядок замен не важен.

### Android — `android/app/build.gradle.kts`

`prod-id` меняется:
- `namespace = "OLD_PROD_ID"` → `"NEW_PROD_ID"` — namespace один на все флейворы
  и следует за prod;
- `applicationId = "OLD_PROD_ID"` в `defaultConfig` → `"NEW_PROD_ID"`.

Dev ID — привести блок `create("dev")` к одному из двух видов:

| Случай | Что в блоке `dev` |
|---|---|
| `NEW_DEV_ID` = `NEW_PROD_ID` + `DEV_SUFFIX` | `applicationIdSuffix = "DEV_SUFFIX"`, без `applicationId` |
| иначе | `applicationId = "NEW_DEV_ID"`, `applicationIdSuffix` удалить |

Проверить вычислением, а не на глаз: итоговый ID флейвора =
(`applicationId` флейвора, иначе `defaultConfig.applicationId`) + `applicationIdSuffix`.

**Kotlin-каталог** — только если меняется `prod-id`. Перенос через `git mv`, чтобы
сохранилась история:

```bash
mkdir -p android/app/src/main/kotlin/NEW_KOTLIN_PATH
git mv android/app/src/main/kotlin/OLD_KOTLIN_PATH/MainActivity.kt \
       android/app/src/main/kotlin/NEW_KOTLIN_PATH/MainActivity.kt
find android/app/src/main/kotlin -type d -empty -delete
```

Другие `.kt`/`.java` в старом каталоге переносятся все, с сохранением вложенности.
В каждом: `package OLD_PROD_ID` → `package NEW_PROD_ID`, `import OLD_PROD_ID.` → `import NEW_PROD_ID.`.

**`AndroidManifest.xml`** (`main`, `debug`, `profile`) — `android:name` с полным путём
(`OLD_PROD_ID.MainActivity`). Относительные `.MainActivity` не трогать.

`GeneratedPluginRegistrant.java` — генерируется, не правится.

### iOS — `ios/Runner.xcodeproj/project.pbxproj`

Флейвор конфигурации определяется по её имени: `*-dev` → dev, `*-prod` → prod
(`Debug-*`, `Release-*`, `Profile-*`). Относится и к таргету `Runner`, и к `RunnerTests`.

| Конфигурация | Было | Стало |
|---|---|---|
| `Runner`, `*-dev` | `PRODUCT_BUNDLE_IDENTIFIER = OLD_DEV_ID;` | `NEW_DEV_ID;` |
| `Runner`, `*-prod` | `PRODUCT_BUNDLE_IDENTIFIER = OLD_PROD_ID;` | `NEW_PROD_ID;` |
| `RunnerTests`, `*-dev` | `= OLD_DEV_ID.RunnerTests;` | `NEW_DEV_ID.RunnerTests;` |
| `RunnerTests`, `*-prod` | `= OLD_PROD_ID.RunnerTests;` | `NEW_PROD_ID.RunnerTests;` |

После замены — проверить, что в каждой `*-dev` конфигурации стоит dev ID, а в `*-prod` —
prod ID: `grep -nE "PRODUCT_BUNDLE_IDENTIFIER|name = \"?(Debug|Release|Profile)"`.

### fastlane и Firebase

- `ios/fastlane/Fastfile`, `android/fastlane/Fastfile`: `devBundleId` → `NEW_DEV_ID`,
  `prodBundleId` → `NEW_PROD_ID`; префиксы профилей — по ответу на вопрос 3;
- `firebase.sh`: `devBundleId`, `prodBundleId`;
- `ios/fastlane/Appfile`, `ios/.env.sample`, `android/.env.sample` — проверить на старые ID;
  плейсхолдеры вида `[[APP_IDENTIFIER]]` не трогать;
- `README.md` — applicationId флейворов, **каждый своим значением**.

Конфиги Firebase привязаны к ID **своего** флейвора:
`lib/firebase/firebase_options_<flavor>.dart` (`iosBundleId`, `appId`),
`android/app/src/<flavor>/google-services.json`,
`ios/flavors/<flavor>/GoogleService-Info.plist`.

- поля пустые / файлов нет → ничего не делать, упомянуть в отчёте;
- заполнены → **не править руками**: `appId` зарегистрирован в Firebase под старым ID.
  Сказать разработчику зарегистрировать приложение в консоли Firebase и перегенерировать
  `./firebase.sh <flavor>` — только для флейворов, чей ID сменился. `flutterfire` скилл
  сам не запускает — это действие во внешнем сервисе.

## Шаг 6. Отображаемые имена — только если меняется `name` и/или `dev-name`

**`android/app/build.gradle.kts`:**
- `resValue("string", "app_name", "OLD_DEV_NAME")` в `create("dev")` → `"NEW_DEV_NAME"`;
- `resValue("string", "app_name", "OLD_PROD_NAME")` в `create("prod")` → `"NEW_PROD_NAME"`.

Заменять внутри блока своего флейвора, а не по всему файлу: dev-имя обычно содержит
prod-имя как префикс.

**`ios/Runner.xcodeproj/project.pbxproj`** — `APP_DISPLAY_NAME` по флейвору конфигурации
(`*-dev` → `NEW_DEV_NAME`, `*-prod` → `NEW_PROD_NAME`). Значение с пробелом или
спецсимволом — **в кавычках** (`APP_DISPLAY_NAME = "Shop Hub";`), иначе Xcode не откроет
проект.

`CFBundleDisplayName` в `Info.plist` = `$(APP_DISPLAY_NAME)` — не трогать.

**Только если меняется `name`** (prod-имя — это имя продукта):

- `lib/l10n/app_en.arb` и `lib/l10n/app_de.arb`: значение `appTitle` → `NEW_PROD_NAME`
  в **обоих** файлах (`localization.md`). `@appTitle` не меняется;
- другие ключи со старым именем в тексте (`grep -n "OLD_PROD_NAME" lib/l10n/*.arb`) —
  заменить во всех ARB и перечислить в отчёте: немецкая фраза могла требовать другой формы;
- `pubspec.yaml`: `description:`;
- `CLAUDE.md` — заголовок `# OLD_PROD_NAME — инструкция для Claude`;
- `README.md` — заголовок и описание;
- `.claude/agents/*.md` — вводные строки «Flutter-проект OLD_PROD_NAME»;
- `.claude/rules/**`, `.claude/skills/**` — проверить поиском. **Не** заменять упоминания
  других проектов (`recallscope-flutter`, `ahhu-flutter`) и примеры внутри этого скилла;
- `android/key.properties.sample`, `README.md` (keystore) — по ответу на вопрос 2.

## Шаг 7. Не трогать

- таргет `Runner`, `Runner.xcworkspace`, `PRODUCT_NAME = $(TARGET_NAME)` — Flutter-тулинг
  ищет именно `Runner`;
- схемы `dev`/`prod`, имена флейворов, `assets/flavors/*.json`, каталоги
  `android/app/src/{dev,prod}` и `ios/flavors/{dev,prod}` — это имена окружений, а не проекта;
- каталог репозитория, `.idea/*.iml`, git remote — вне задачи; упомянуть в отчёте,
  что при желании это делается руками.

## Шаг 8. Сверка флейворов

Перед сборкой — одна таблица «флейвор → итоговое значение» по всем источникам, собранная
из файлов заново, а не из плана:

| | Gradle | pbxproj (Runner) | pbxproj (RunnerTests) | Fastfile iOS | Fastfile Android | firebase.sh |
|---|---|---|---|---|---|---|
| dev ID | | | | | | |
| prod ID | | | | | | |
| dev имя | | | — | — | — | — |
| prod имя | | | — | — | — | — |

Любое расхождение внутри строки — ошибка правки, исправить до шага 9.

## Шаг 9. Пересборка и проверка

```bash
flutter clean
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

`flutter analyze` → `No issues found!`. Ошибка `Target of URI doesn't exist: package:...` —
пропущенный импорт, вернуться к шагу 4.

Сборки — для Gradle и Xcode, которые `analyze` не видит. **Оба флейвора**: ID и имена
у них разные, и сломаться может один из них.

```bash
flutter build apk --flavor dev  --debug -t lib/main.dart
flutter build apk --flavor prod --debug -t lib/main.dart
cd ios && pod install && cd ..
flutter build ios --flavor dev  --debug --no-codesign -t lib/main.dart
flutter build ios --flavor prod --debug --no-codesign -t lib/main.dart
```

Проверить итоговые ID и имена по артефактам, а не по исходникам:

```bash
# Android: package и label в собранном apk
$ANDROID_HOME/build-tools/*/aapt dump badging build/app/outputs/flutter-apk/app-dev-debug.apk \
  | grep -E "^package|application-label:"
# iOS: bundle id и имя в собранном .app (после сборки соответствующего флейвора)
plutil -p build/ios/iphoneos/Runner.app/Info.plist | grep -E "CFBundleIdentifier|CFBundleDisplayName"
```

Сборка, которую невозможно выполнить в окружении (нет Xcode, SDK), в отчёте так и пишется,
а не считается пройденной.

## Шаг 10. Финальный поиск — обязателен

По каждому **сменившемуся** значению (точки в ID экранированы):

```bash
# prod ID: исключаем совпадения внутри неизменившегося dev ID
git grep -nI -E "OLD_PROD_ID_ESCAPED([^.a-zA-Z0-9_]|\.RunnerTests|$)" -- ':!*.lock'
git grep -nI -E "OLD_DEV_ID_ESCAPED"   -- ':!*.lock'
git grep -nI "OLD_PROD_NAME"           -- ':!*.lock'
git grep -nI "OLD_DEV_NAME"            -- ':!*.lock'
git grep -nIw "OLD_DART_NAME"          -- ':!*.lock'
find android/app/src -path "*OLD_KOTLIN_PATH*"
```

Допустимые остатки — перечислить в отчёте с причиной:

- `macos/Flutter/ephemeral/**` — генерируется, содержит абсолютный путь к репозиторию;
- keystore в `key.properties.sample`/`README.md`, если на вопрос 2 ответили «нет»;
- примеры внутри `.claude/skills/rename-project/SKILL.md`.

Всё остальное — исправить и повторить поиск.

## Шаг 11. Ревью и отчёт

1. `/review` с формулировкой: какие значения по каким флейворам менялись, `старое → новое`.
2. Отчёт по формату `CLAUDE.md` §9:
   - сводка: таблица dev / prod по изменённым значениям;
   - результаты `analyze`, `test`, сборок **по каждому флейвору** — как есть, с ошибками;
   - что требует действий разработчика — только по сменившимся флейворам: Firebase,
     App ID и профили в Apple Developer Portal, приложение в Google Play Console, keystore;
   - остатки финального поиска с причинами.

Не коммитить (`git.md`). Предложить сообщение коммита по режиму:
`Rename app to NEW_PROD_NAME`, `Change bundle ids to NEW_PROD_ID and NEW_DEV_ID`
или `Rename project to NEW_PROD_NAME (NEW_PROD_ID)`.
