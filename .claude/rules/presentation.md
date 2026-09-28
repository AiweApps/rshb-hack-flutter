# Правила: `lib/core/presentation/`

## 1. Ассеты и `app_icons.dart` — обязательное правило

**Любая картинка, попадающая в `assets/`, обязана быть объявлена в
`lib/core/presentation/app_icons.dart` и использоваться только через него.**

Запрещено в любом коде за пределами `app_icons.dart`:

```dart
// ❌ никогда
SvgPicture.asset('assets/images/ic_close_24.svg')
Image.asset('assets/images/ic_splash.png')
const AssetImage('assets/images/bg.png')
```

Правильно:

```dart
// ✅
SvgIconRes.close24.widget(width: AppSize.s24, height: AppSize.s24)
PngIconRes.splashLogo.widget(width: AppSize.s120)
```

### Как устроен реестр

Один enum на формат + extension с `path` и `widget()`:

- `SvgIconRes` + `SvgIconResExt` — для `.svg` (уже есть).
- `PngIconRes` + `PngIconResExt` — для растровых (`.png`, `.jpg`, `.webp`).
  Заводится при добавлении **первой** растровой картинки, по образцу
  `recallscope-flutter/lib/core/presentation/app_icons.dart`:

```dart
enum PngIconRes { splashLogo, onboardingHero }

extension PngIconResExt on PngIconRes {
  String get path {
    final String assetName = switch (this) {
      PngIconRes.splashLogo => "ic_splash.png",
      PngIconRes.onboardingHero => "ic_onboarding_hero.png",
    };
    return "assets/images/$assetName";
  }

  Image widget({double? width, double? height, BoxFit fit = BoxFit.contain}) {
    return Image.asset(path, width: width, height: height, fit: fit);
  }
}
```

Возвращаемый тип `widget()` — конкретный (`SvgPicture` / `Image`), не `Widget`:
это позволяет вызывающему коду дотянуться до специфичных свойств без каста.

### Чек-лист при добавлении картинки

1. Файл кладём в `assets/images/`. Имя — `snake_case`, префикс `ic_` для иконок:
   `ic_close_24.svg`, `ic_toast_success.svg`. Фоны/иллюстрации — без префикса.
   Регистрировать файл в `pubspec.yaml` не нужно: папка `assets/images/` уже подключена целиком.
2. Добавляем значение в enum. Имя — `lowerCamelCase`, **семантическое** (что это, а не как выглядит):
   `errorReload`, а не `yellowArrow`.
   - размер в имени — только если есть варианты одной иконки разных размеров: `close24`, `close16`;
   - тёмный вариант — суффикс `Dark`: `scannerOverlayDark`.
3. Добавляем ветку в `switch` внутри `path`. `switch` — исчерпывающий, без `default`:
   компилятор сам подсветит забытую ветку.
4. Используем через `.widget(...)`.

### Имя непонятно — спросить

Если из макета/файла не следует однозначное семантическое имя (или картинка похожа на уже
существующую в реестре) — не выдумываем молча. Спрашиваем разработчика тем же порядком,
что и для цветов: показываем файл, где используется, ближайшее существующее значение enum
и 2–3 варианта имени. См. `theme.md`, раздел «Процедура: нужного цвета или стиля нет в токенах».

### Перекраска вместо дублирования файла

Не добавляем второй SVG только ради другого цвета. Красим через `colorFilter`:

```dart
SvgIconRes.errorReload.widget(
  width: AppSize.s24,
  height: AppSize.s24,
  colorFilter: ColorFilter.mode(context.colors.neutrals_900, BlendMode.srcIn),
)
```

Цвет берём **только** из `context.colors` (см. `constants.md`), размеры — из `AppSize`.

### Удаление

Удаляя файл из `assets/`, удаляем и значение enum, и ветку `switch`.
Мёртвых значений в реестре быть не должно.

## 2. Картинки из сети — только `RemoteImage`

Реестр `app_icons.dart` — про ассеты в сборке. Картинка, приходящая по URL, — другое,
и рисуется она **единственным** виджетом: `RemoteImage`
(`lib/core/widgets/remote_image.dart`).

```dart
// ❌ запрещено везде
Image.network(url)
NetworkImage(url)
DecorationImage(image: NetworkImage(url))
CachedNetworkImage(imageUrl: url)   // пакет — деталь реализации RemoteImage

// ✅
RemoteImage(
  url: track.album.coverSmall,
  width: AppSize.s56,
  height: AppSize.s56,
  borderRadius: AppRadius.r8,
)
```

Причина запрета: голый `Image.network` оставляет вызывающему коду четыре вещи, которые
забывают всегда, — плейсхолдер, поведение при битой ссылке, кэш и ограничение размера
декодирования. `RemoteImage` закрывает их сам.

### Что он делает за тебя

| | |
|---|---|
| `url` может быть `null` или пустым | это не ошибка вызова: рисуется `errorWidget`, ничего не падает |
| Протокол-относительные ссылки (`//host/pic.jpg`) | чинятся в `https://` — некоторые бэки отдают именно так |
| Кэш на диске и в памяти | картинка не перезагружается при каждом прокруте списка |
| Размер декодирования | считается из `width`/`height` × `devicePixelRatio`: миниатюра 56pt не занимает память полноразмерного оригинала |
| Переиспользование в списке | при смене `url` состояние сбрасывается — иначе переработанная строка `ListView` показывает чужую картинку |
| Плавное появление | `fadeIn`, по умолчанию `DurationConstant.d300ms` |

### Как пользоваться

**Размеры задаются всегда.** `width` и `height` — не украшение: без них не считается
размер декодирования, а раскладка дёргается, когда картинка приедет. Значения — из
`AppSize`, как и любые размеры (`constants.md`).

**Скругление — параметром `borderRadius`, а не внешним `ClipRRect`.** Значение из
`AppRadius`. Свой `ClipRRect` поверх — лишний слой отсечения.

**Плейсхолдер и ошибка.** По умолчанию рисуется нейтральный прямоугольник
`context.colors.neutrals300` того же размера — этого достаточно для списков. Когда экрану
нужна осмысленная заглушка (обложка без картинки, аватар с инициалами), она передаётся
параметрами:

```dart
RemoteImage(
  url: track.album.coverMedium,
  width: AppSize.s250,
  height: AppSize.s250,
  borderRadius: AppRadius.r8,
  errorWidget: const _CoverPlaceholder(),
)
```

`errorWidget` по умолчанию равен `placeholder` — если внешний вид «грузится» и «не
загрузилось» совпадает, достаточно передать один `placeholder`.

**Несколько размеров одной картинки** — `RemoteImage.withFallbacks`. Первый успешный URL
выигрывает, остальные пробуются по порядку. Это про **одну и ту же** картинку в разных
разрешениях, а не про «любые другие картинки»:

```dart
RemoteImage.withFallbacks(
  url: album.coverMedium,
  fallbackUrls: [album.coverBig, album.cover],
  width: AppSize.s250,
  height: AppSize.s250,
)
```

### Чего не делать

- не оборачивать `RemoteImage` в `SizedBox` ради размеров — они его параметры;
- не подставлять `?? ''` в `url`: пустая строка обрабатывается внутри;
- не импортировать `cached_network_image` в фичах — пакет виден только этому файлу.
  Смена реализации кэша не должна затрагивать ни один экран;
- не собирать URL интерполяцией в виджете: адреса и шаблоны — в `ApiConstants`
  (`constants.md`), сами ссылки приходят из моделей бэка;
- не рисовать картинку из сети фоном через `DecorationImage` — вместо этого
  `RemoteImage` в `Stack` под контентом.

SVG по URL `RemoteImage` не поддерживает — это отдельный случай (`SvgPicture.network`),
он заводится отдельным виджетом, когда появится реальная задача.

## 3. `base_theme.dart`

Правила вынесены в отдельный файл — см. `theme.md`.

Коротко: `base_theme.dart` собирает `ThemeData` из токенов `AppColors` и `AppTextStyles`
и является единственным местом в проекте, которому разрешено знать про `ColorScheme`
и `TextTheme`. В коде приложения — только `context.colors` и `context.ts`.
