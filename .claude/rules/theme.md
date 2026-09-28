# Правила: тема, цвета, типографика

## Архитектура: токены — источник правды, `ThemeData` — производная

```
AppColors      (ThemeExtension)  ─┐
                                  ├─→ getBaseTheme() ─→ ThemeData ─→ Material-виджеты
AppTextStyles  (ThemeExtension)  ─┘                        │
                                                            └─ ColorScheme / TextTheme
        ▲                                                     (только для Material)
        └── context.colors / context.ts  ←── весь код приложения
```

- `lib/core/constants/app_colors_constants.dart` — `AppColors`, все цвета.
- `lib/core/constants/app_text_styles_constants.dart` — `AppTextStyles`, все стили текста.
- `lib/core/presentation/base_theme.dart` — собирает `ThemeData` **из** токенов.
  `ColorScheme` и `TextTheme` там генерируются приватными `_colorSchemeFrom` /
  `_textThemeFrom` и существуют **только** чтобы стоковые Material-виджеты
  (диалоги, `TextField`, ripple) не выпадали из дизайн-системы.

Смысл схемы: у цвета и стиля ровно одно определение. Раньше `ColorScheme` и `AppColors`
жили независимо и разошлись (`primary` был чёрным при брендовом оранжевом в палитре) —
теперь это невозможно по построению.

## Что можно и что нельзя в коде приложения

```dart
// ✅ единственный правильный доступ
context.colors.neutrals900
context.ts.paragraphSmall
context.ts.h3.copyWith(color: context.colors.error)

// ❌ запрещено везде, кроме base_theme.dart
Theme.of(context).colorScheme        // Material-имена ≠ дизайн-система
Theme.of(context).textTheme          // 15 слотов Material, имена не наши
context.textStyle.bodyMedium         // геттера больше нет
GoogleFonts.lato(...)                // шрифт задаётся в одном месте
```

### Хардкод цвета — запрещён

Цвет в UI берётся **только** из `context.colors`. Ни в каком виде:

```dart
// ❌ всё это — хардкод
Color(0xFF141416)
const Color.fromARGB(255, 20, 20, 22)
Colors.white / Colors.black / Colors.red / Colors.grey.shade200  // палитра Material — тоже чужая
Colors.black.withAlpha(AppAlpha.a50)                             // база обязана быть токеном

// ✅
context.colors.neutrals900
context.colors.neutrals900.withAlpha(AppAlpha.a50)  // прозрачность от токена — можно
```

Единственное исключение — `Colors.transparent`: это не цвет, а его отсутствие.

### Хардкод текстового стиля — запрещён

Стиль в UI берётся **только** из `context.ts`:

```dart
// ❌
TextStyle(fontSize: 15, fontWeight: FontWeight.w400)
context.ts.paragraph.copyWith(fontSize: 17)              // это новый стиль, а не вариация
context.ts.paragraph.copyWith(fontWeight: FontWeight.w600)

// ✅ допустимые copyWith — те, что не меняют саму шкалу
context.ts.paragraphSmall.copyWith(color: context.colors.error)
context.ts.h3.copyWith(decoration: TextDecoration.underline)
context.ts.paragraph.copyWith(height: 1.0)               // локальная подгонка вёрстки
```

`copyWith(fontSize:)` и `copyWith(fontWeight:)` — это создание незадекларированного стиля.
Значит, в макете есть стиль, которого нет в `AppTextStyles`: см. процедуру ниже.

## Процедура: нужного цвета или стиля нет в токенах

Это не редкий случай, а нормальный рабочий момент. Порядок строгий.

**Что делать нельзя:**

- написать значение инлайн («потом вынесем»);
- молча подобрать «похожий» существующий токен, потому что он близко по значению;
- молча выдумать имя и добавить токен, никого не спросив.

**Что делать нужно — остановиться и спросить разработчика.** В вопросе обязательно:

1. **Значение.** Для цвета — hex. Для стиля — кегль, вес, line-height, letter-spacing.
2. **Где встретилось** — файл и что именно этим красится/набирается.
3. **Есть ли близкий существующий токен** и насколько близкий. Если разница в пределах
   пары единиц hex или 1sp — прямо предположить, что это он и есть, и спросить,
   не опечатка ли в макете.
4. **2–3 варианта имени** по конвенции проекта, с коротким обоснованием каждого.
5. **Прямой вопрос:** как назвать — выбрать из предложенного, дать своё имя,
   или «назови сам» (тогда берётся первый предложенный вариант).

Пример формулировки:

> В `track_detail_page.dart` для бейджа «Explicit» нужен фон `#FFF3BD`, такого токена нет.
> Ближайший — `primary100` (`#FFF3BD`) — совпадает точно, возможно это он.
> Если всё-таки нужен отдельный токен, предлагаю имена: `badgeBackground` (по назначению),
> `primary150` (по шкале). Как назвать? Могу выбрать сам — тогда возьму `badgeBackground`.

**Только после ответа** токен добавляется (`AppColors`: поле → конструктор → `copyWith` →
`lerp` → значения в `light` и `dark`; `AppTextStyles`: поле → конструктор → значение в
`from` → `copyWith`) и используется на месте.

Если разработчик недоступен, а работу нужно продолжать — токен всё равно **не** добавляется
инлайн-значением; задача останавливается на этом вопросе, а всё остальное по задаче
доделывается.

## `AppColors`

- Имена полей — `lowerCamelCase`: `primary500`, `neutrals900`, `azure100`.
  Числовая шкала — от светлого к тёмному внутри группы.
- Добавление цвета = поле → конструктор → `copyWith` → `lerp` → значения в `light` и `dark`.
  Пропустить `lerp` нельзя: цвет перестанет анимироваться при смене темы.
- Светлая и тёмная палитры — это `AppColors.light` и `AppColors.dark`, и больше ничего:
  смена палитры не затрагивает ни одной строки кода вне этого файла. Отсюда требование
  к любому цвету — иметь значение в обеих палитрах.
- Семантические имена (`textPrimary`, `surfaceElevated`) вместо числовой шкалы — открытый
  вопрос. Вводить только вместе с реальной тёмной палитрой: именно там числовая шкала
  ломается, потому что «900» в тёмной теме должен быть светлым.

## `AppTextStyles`

- Имена — из дизайн-файла, а не из Material: `h1`…`h4`, `paragraph`, `paragraphSmall`,
  `paragraphTiny` (+ `Bold`-варианты), `paragraphLargeBold`, `fieldsetLabel`,
  `timer`, `timerLarge`, `appBarTitle`.
- Ограничения на количество стилей нет — это не 15 слотов `TextTheme`. Новый стиль в макете →
  новое поле, а не «подберём похожий слот».
- Шкала строится в `AppTextStyles.from(AppColors colors)` — light и dark имеют одно
  определение и отличаются только палитрой.
- Шрифт и правило перевода line-height в множитель — в приватном `_style`. Смена гарнитуры
  приложения = одна строка.
- `lerp` намеренно дискретный (`t < 0.5 ? this : other`): анимировать кегль и насыщенность
  при переключении темы выглядит как глитч. Цвета при этом анимируются нормально —
  они приходят из `AppColors`.
- Добавление стиля = поле → конструктор → значение в `from` → запись в `copyWith`.
  Если стиль должен подхватываться стоковыми Material-виджетами — добавить маппинг
  в `_textThemeFrom`.

## `base_theme.dart`

- Единственный файл, которому разрешено знать про `ColorScheme` и `TextTheme`.
- Component themes (`appBarTheme`, `elevatedButtonTheme`, `switchTheme`, …) берут значения
  напрямую из `colors` / `textStyles`, не из `colorScheme`. Так видно, какой токен где
  используется.
- Размеры и alpha в теме — из `AppSize` / `AppAlpha`, не литералами.
- Новый Material-виджет ведёт себя не так → чиним его component theme здесь,
  а не переопределяем стиль на месте использования.
