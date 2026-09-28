# Правила: `lib/core/helpers/`

## Что это

`helpers/` — переиспользуемые утилиты, которые **нельзя** выразить extension'ом:
у них есть состояние, жизненный цикл, они наследуют фреймворковый класс или являются миксином.
Ни UI, ни доменной логики, ни DI здесь нет.

## Решающее дерево — куда класть код

1. Это чистое преобразование значения? → `extensions/` (см. `extensions.md`).
2. Это класс с состоянием / миксин / наследник фреймворкового типа? → **`helpers/`**.
3. Это адаптер к платформе, хранилищу или стороннему SDK? → `misc/` (см. `misc.md`).
4. Есть сеть, DI, синглтон-жизненный цикл, подписки? → `services/`.
5. Это виджет? → `core/widgets/` (общий) или `shared/presentation/` (доменный).

## Формы, которые допустимы в `helpers/`

Из `ahhu-flutter` и `recallscope-flutter` — образцы, которые стоит переносить сюда по мере надобности:

| Файл | Форма | Зачем |
|---|---|---|
| `debouncer.dart` | класс с `Timer` + `dispose()` | дебаунс поиска/ввода. Нужен всегда, где есть `TextField` с запросом |
| `app_utils.dart` | статический класс с `initialize()` | `PackageInfo` → `appVersion`. Асинхронная инициализация в `main()` |
| `scroll_tracking_mixin.dart` | `mixin on State<T>` | `ScrollController` + `isScrolled` + корректный `dispose` |
| `phone_input_formatter.dart` | `extends TextInputFormatter` | форматирование ввода телефона |
| `geo_coordinate_validator.dart` | `const` приватный конструктор + `static tryParse` | валидация с возвратом `null` вместо исключения |
| `hide_keyboard_helper.dart` | статический класс | `HideKeyboardHelper.hideKeyboard(context)` |
| `image_preparation_helper.dart` | статический класс | сжатие/подготовка изображений перед загрузкой |

### Что забирать в winescan в первую очередь

- **`Debouncer`** — на главном экране уже есть поиск треков; дебаунс запроса нужен сразу.
- **`ScrollTrackingMixin`** — как только появится аппбар, реагирующий на скролл.
- **`HideKeyboardHelper`** — как только появится второй экран с вводом.
- **`AppUtils`** — как только версия приложения понадобится в UI/аналитике/сапорте.

Остальное (`PhoneInputFormatter`, `GeoCoordinateValidator`, `image_preparation_helper`)
— доменно-специфично для `ahhu`, переносить только при реальной необходимости.

## Соглашения

- Один helper — один файл, имя файла = имя сущности в `snake_case`.
- Утилита без состояния → класс со `static`-методами и приватным конструктором:
  `const GeoCoordinateValidator._();` — чтобы нельзя было создать экземпляр.
- Утилита с состоянием (`Debouncer`) → обычный класс, **обязательно** с `dispose()`/`cancel()`,
  и вызывающий обязан их звать.
- Миксин → `mixin XMixin<T extends StatefulWidget> on State<T>`, все ресурсы освобождаются
  в переопределённом `dispose()` с `super.dispose()` последней строкой.
- Значения по умолчанию (задержка дебаунса, порог скролла) — из `DurationConstant`/`AppSize`,
  а не литералами; либо выставляются как переопределяемый геттер (`double get scrollThreshold`).

## Чего в `helpers/` быть не должно

- Extension'ов-форматтеров — они в `extensions/`.
- Обращений к `sl<...>()` и к API-репозиториям.
- Импортов из `lib/features/**`. `core/` не знает о фичах.
