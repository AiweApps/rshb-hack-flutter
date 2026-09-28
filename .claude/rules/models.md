# Правила: модели и кодогенерация

## Три вида моделей

| Вид | Что описывает | Где лежит | Чем генерится |
|---|---|---|---|
| **DTO** | ответ бэка / строка таблицы БД, один в один | `features/<feature>/domain/models/` | `json_serializable` |
| **Domain** | то, чем оперирует приложение | `features/<feature>/domain/models/` | обычный класс или `freezed` |
| **State** | состояние экрана | `features/<feature>/application/bloc/` | `freezed` |

Правило разделения: **DTO повторяет бэк, domain повторяет предметную область.**
Пока они совпадают — модель одна (как `Track` сейчас). Разъезжаются, когда:

- в UI нужно поле, которого нет в ответе (склеенное, посчитанное, из другого запроса);
- бэк присылает `String` там, где приложению нужен `enum` или `DateTime`;
- одна и та же сущность приходит из двух источников (сеть и БД) в разных формах.

С этого момента заводится domain-модель и маппер `TrackDto.toDomain()` **рядом с моделью**,
в `domain/` — не в блоке, не в виджете, не в `core/extensions/` (`extensions.md`).

Отдельная UI-модель (`presentation/models/`) заводится, только если из одной domain-модели
рисуются существенно разные карточки. Обычно это не нужно: подготовленные к отрисовке
значения кладёт в стейт блок.

## DTO: как писать

Эталон — lib/features/home/domain/models/track.dart:8.

```dart
@JsonSerializable()
class Track {
  final int id;                                  // бэк гарантирует — required
  @JsonKey(name: 'title_short')
  final String? titleShort;                      // может не прийти — nullable

  Track({required this.id, this.titleShort});

  factory Track.fromJson(Map<String, dynamic> json) => _$TrackFromJson(json);
  Map<String, dynamic> toJson() => _$TrackToJson(this);
}
```

### Nullability

**Не-nullable только то, без чего объект бессмыслен и что бэк гарантирует контрактом.**
Всё остальное — nullable. Ошибка в эту сторону дешевле: пропущенное поле даст
`ParsingError` на весь список вместо одной пустой строки в карточке.

`required` + nullable (`required this.x` при `String? x`) — осмысленно: «поле обязано
присутствовать в JSON, но может быть `null`». Использовать сознательно, а не случайно.

Не подставлять «умолчания» в конструкторе DTO (`this.count = 0`): DTO обязан отражать
ответ честно, иначе «нет данных» и «ноль» становятся неразличимы. Умолчания — при
маппинге в domain.

### `@JsonKey`

- имя из JSON, отличное от dart-имени, — только через `@JsonKey(name:)`, руками
  ключи не разбираются;
- поле, которого нет в ответе и которое не надо слать обратно, — `@JsonKey(includeToJson: false)`;
- `fieldRename` глобально не включаем: явный `@JsonKey` читается лучше и не ломается,
  когда бэк выбивается из своего же стиля.

### Enum из JSON

Незнакомое значение enum **уронит парсинг всего ответа**. Всегда:

```dart
@JsonEnum()
enum TrackType {
  track,
  album,
  @JsonValue('unknown') unknown,
}

@JsonKey(unknownEnumValue: TrackType.unknown)
final TrackType type;
```

Без `unknownEnumValue` новый тип, добавленный бэком, ломает экран целиком.

### Даты и числа

- дата в JSON — `String` в DTO, `DateTime` в domain. Парсинг — при маппинге, через
  extension из `core/extensions/date_extensions.dart` (`extensions.md`);
- бэк, присылающий число строкой, разбирается безопасными конверсиями из
  `core/extensions/num_extensions.dart`, а не `int.parse` на месте;
- деньги — не `double`. Минорные единицы в `int` либо строка + `Decimal`, решается
  при появлении платежей.

## Стейты: `freezed`

По `screens.md` §2. Дополнительно:

- `@freezed abstract class ... with _$X implements BaseBlocState`;
- обязательный `factory X.initial()` — единственное место, где заданы стартовые значения;
- все поля `required`, включая nullable: `required ErrorType? errorType`. Так добавление
  поля ломает компиляцию в `initial()` и заставляет решить, чему оно равно, вместо
  тихого `null`;
- в стейте нет `BuildContext`, контроллеров, `AppError`, DTO бэка (`bloc.md` §6).

Domain-модель делать `freezed` стоит, когда нужны `copyWith` и сравнение по значению;
DTO — нет: там нужен только парсинг, `freezed` поверх `json_serializable` даёт лишнюю
генерацию без выгоды.

## Кодогенерация

```bash
dart run build_runner build --delete-conflicting-outputs
```

- гонять **после каждого** изменения `@freezed` / `@JsonSerializable` модели, до
  `flutter analyze`;
- `*.g.dart` и `*.freezed.dart` **коммитятся** (в `.gitignore` их нет) и **никогда не
  правятся руками**;
- расхождение сгенерированного файла с исходником — само по себе замечание на ревью;
- `part` / `part of` — только для генерации и для `<screen>_event.dart` (`CLAUDE.md` §10).

## Равенство и хранение в коллекциях

- обычный класс сравнивается по ссылке. Модель, которая кладётся в `Set`, в ключи `Map`
  или сравнивается в `state.copyWith`, обязана иметь равенство по значению — то есть
  быть `freezed` или иметь `==`/`hashCode`;
- `Track` сейчас без `==`: два одинаковых трека из разных ответов — разные объекты.
  Пока список только рисуется, это не мешает; для дедупликации и сравнения стейта
  потребуется равенство.

## Чего не делать

- не тащить `dynamic` и `Map<String, dynamic>` дальше `fromJson`. Блок и UI работают
  с типами;
- не класть в модель логику: запросы, форматирование для UI, обращения к `sl<>()`;
- не форматировать значения внутри модели (`String get durationText`) — это представление,
  ему место в `core/extensions/` (`extensions.md`);
- не заводить одну «универсальную» модель на два разных эндпоинта с половиной nullable
  полей — это два DTO;
- не хранить в модели `BuildContext` и виджеты.

## Чек-лист

- [ ] DTO повторяет ответ бэка, не «улучшает» его;
- [ ] всё, что бэк не гарантирует, — nullable;
- [ ] несовпадающие имена — через `@JsonKey(name:)`;
- [ ] у enum есть `unknownEnumValue`;
- [ ] маппинг DTO → domain лежит рядом с моделью в `domain/`;
- [ ] `build_runner` прогнан, сгенерированные файлы в коммите;
- [ ] в модели нет логики, форматирования и обращений к DI.
