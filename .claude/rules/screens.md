# Правила: как устроен экран

Это самое жёсткое правило проекта. Оно не имеет исключений и не откладывается «на потом».
Экран, собранный иначе, считается несделанной задачей.

Смежные правила: поведение блока (жизненный цикл, конкурентность, подписки) — `bloc.md`;
показ ошибки — `errors.md`; переходы — `navigation.md`; диалоги — `widgets.md`.

## 1. Структура файлов

Один экран = один каталог. Content, loading и error — **всегда отдельные файлы**,
даже если сейчас это три строки.

```
lib/features/<feature>/
  application/
    bloc/
      <screen>_bloc.dart          # логика, обработчики событий
      <screen>_event.dart         # part of bloc, sealed
      <screen>_state.dart         # freezed, implements BaseBlocState
      <screen>_uieffect.dart      # действия: навигация, ссылки, шаринг
  domain/
    models/…
    <feature>_repository.dart
  presentation/
    <screen>_page.dart            # каркас: Scaffold + listener + switch по статусу
    <screen>_content.dart         # UI успешного состояния
    <screen>_loading.dart         # UI загрузки
    <screen>_error.dart           # UI ошибки
    components/
      <part>_section.dart         # куски контента
      <part>_card.dart
```

Если в фиче несколько экранов — каждый в своей папке внутри `presentation/`:

```
presentation/
  list/    list_page.dart, list_content.dart, list_loading.dart, list_error.dart, components/
  detail/  detail_page.dart, detail_content.dart, detail_loading.dart, detail_error.dart, components/
```

Класть страницу в `presentation/pages/` не нужно — это лишний уровень.

## 2. Стейт обязан реализовывать `BaseBlocState`

`lib/core/application/bloc/base_bloc_state.dart`:

```dart
abstract interface class BaseBlocState {
  ScreenStatus get screenStatus;
}
```

`BaseBloc<Event, State extends BaseBlocState>` принимает **только** такие стейты —
то есть это не соглашение, которое можно забыть, а ограничение компилятора: блок со стейтом
без `screenStatus` просто не соберётся.

Каждый стейт экрана объявляется так:

```dart
@freezed
abstract class CatalogState with _$CatalogState implements BaseBlocState {
  const factory CatalogState({
    required ScreenStatus screenStatus,
    required ErrorType? errorType,   // заполнен только при status == error
    required List<Item> items,
    required String query,
  }) = _CatalogState;

  factory CatalogState.initial() => const CatalogState(
    screenStatus: ScreenStatus.loading,
    errorType: null,
    items: [],
    query: '',
  );
}
```

`ScreenStatus` (`lib/core/application/bloc/screen_status.dart`) — `{ loading, content, error }`.

Никаких `isLoading` + `hasError` + `isEmpty` россыпью: такие флаги допускают невозможные
комбинации (грузится и ошибка одновременно), `screenStatus` исключает их по построению.

Стейт хранит **готовые к отрисовке** данные. Если UI приходится что-то вычислять из полей
стейта — это поле должно было прийти из блока уже вычисленным.

## 3. `<screen>_page.dart` — только каркас

Страница не содержит вёрстки контента. Её работа: `Scaffold`, слушатель ui-эффектов и
исчерпывающий `switch` по статусу.

```dart
class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.localization.catalog)),
      body: SafeArea(
        child: BaseBlocPresentationListener<CatalogBloc>(
          listener: _onUiEffect,
          child: BlocBuilder<CatalogBloc, CatalogState>(
            builder: (context, state) => switch (state.screenStatus) {
              ScreenStatus.loading => const CatalogLoading(),
              ScreenStatus.content => CatalogContent(state: state),
              ScreenStatus.error => CatalogError(state: state),
            },
          ),
        ),
      ),
    );
  }

  void _onUiEffect(BuildContext context, BaseBlocUiEffect effect) {
    switch (effect) {
      case OpenItemDetail(:final item):
        sl<AppRouter>().navigateToItemDetail(item);
    }
  }
}
```

`switch` по `ScreenStatus` — без `default`: добавится новый статус, компилятор покажет,
где его не обработали.

## 4. `<screen>_error.dart` и `<screen>_loading.dart`

Ошибка рисуется через `AppErrorWidget` (`lib/shared/presentation/errors/`), а не собственной
вёрсткой:

```dart
class CatalogError extends StatelessWidget {
  final CatalogState state;
  const CatalogError({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    void onRefresh() => context.read<CatalogBloc>().add(const RetryCatalog());

    return switch (state.errorType) {
      ErrorType.connection => AppErrorWidget.connection(
        display: ErrorDisplay.fullScreen,
        onRefresh: onRefresh,
      ),
      _ => AppErrorWidget.serverError(
        display: ErrorDisplay.fullScreen,
        onRefresh: onRefresh,
      ),
    };
  }
}
```

Загрузка — отдельный виджет, даже если внутри один индикатор. Так место для скелетона уже
готово, и его добавление не трогает страницу.

## 5. `<screen>_content.dart` и `components/`

Контент не пишется одним файлом на 400 строк. Как только внутри появляется логический блок
(шапка, карточка, секция, строка списка) — он уезжает в `components/` рядом с экраном.

Ориентир: файл контента длиннее ~150 строк или содержит второй приватный `_build…`-метод —
пора выносить.

Разделение ответственности:

| | знает о блоке | получает данные | сообщает о действии |
|---|---|---|---|
| `<screen>_content.dart` | да | из `state` | `context.read<Bloc>().add(...)` |
| `components/*` | **нет** | через конструктор | через колбэк (`VoidCallback onTap`) |

Компоненты не знают о блоке намеренно: так они переиспользуются на других экранах и
проверяются без поднятия блока.

Приватные `_build…`-методы, возвращающие `Widget`, — запрещены. Виджет — это класс.
Приватный `class _SomePart extends StatelessWidget` в том же файле допустим для мелочи,
всё остальное — в `components/`.

## 6. Никакой логики в UI

**Вся логика живёт в блоке. Файлы `presentation/` только рисуют.**

### Запрещено в `presentation/`

- `sl<...>()` и любые обращения к репозиториям/сервисам;
- навигация: `context.go`, `context.push`, `context.pop`, `AppRouter`;
- любые сайд-эффекты: открытие ссылок, шаринг, буфер обмена, диалоги, файлы;
- `async` / `await` / `Future` / `Timer` / подписки;
- фильтрация, сортировка, агрегация, группировка коллекций;
- бизнес-условия (`if (user.age > 18 && !user.isBlocked)`);
- вычисление отображаемых значений из нескольких полей стейта;
- `setState` для состояния экрана.

Единственное исключение — обработка ui-эффектов в `_onUiEffect` на странице: это и есть
то место, куда блок отправляет действие на исполнение.

### Разрешено в `presentation/`

- `switch (state.screenStatus)` и выбор виджета по **готовому** полю стейта
  (`state.items.isEmpty`, `state.cover == null`);
- вёрстка, отступы, констрейнты;
- `context.localization`, `context.colors`, `context.ts`;
- форматтеры-extension'ы из `core/extensions` (`track.duration.formattedDuration`) —
  это представление, а не логика;
- `TextEditingController` / `ScrollController` / `AnimationController` и их `dispose`
  в `StatefulWidget` — это жизненный цикл виджета, а не состояние экрана.

### Клик — всегда через событие блока

Даже самое тривиальное действие:

```dart
// ❌ логика и сайд-эффект в UI
onTap: () => sl<AppRouter>().navigateToItemDetail(item),

// ✅ UI сообщает о намерении, блок решает, что с ним делать
onTap: () => context.read<CatalogBloc>().add(ItemTapped(item: item)),
```

Полный цикл:

```
UI  ──add(ItemTapped)──▶  Bloc
                           │  проверки, запросы, аналитика
                           ├─ emit(state.copyWith(...))     ──▶ перерисовка
                           └─ emitUiEffect(OpenItemDetail)  ──▶ listener на странице
                                                                  выполняет действие
```

Почему так, а не «ну это же просто открыть экран»: намерение пользователя — единственная
точка, где вешается аналитика, проверка подписки, подтверждение, троттлинг. Как только
один клик обработан в обход блока, эти вещи начинают дублироваться по виджетам.

### Действия — это ui-эффекты

Всё, что не является перерисовкой, — наследник `BaseBlocUiEffect` в `<screen>_uieffect.dart`:

```dart
sealed class CatalogUiEffect extends BaseBlocUiEffect {}

final class OpenItemDetail extends CatalogUiEffect {
  final Item item;
  OpenItemDetail({required this.item});
}
```

Тосты отдельным эффектом объявлять не нужно — в блоке есть `emitSnackBar.info/success/error`
и `emitErrorSnackBar(error)`, их перехватывает `BaseBlocPresentationListener` сам.

## 7. Блок: обязательный скелет

```dart
class CatalogBloc extends BaseBloc<CatalogEvent, CatalogState> {
  final ItemsRepository _repository = sl<ItemsRepository>();

  CatalogBloc() : super(CatalogState.initial()) {
    on<StartCatalog>(_load);
    on<RetryCatalog>(_load);
    on<ItemTapped>(_itemTapped);
  }

  Future<void> _load(CatalogEvent event, Emitter<CatalogState> emit) async {
    emit(state.copyWith(screenStatus: ScreenStatus.loading, errorType: null));

    final result = await _repository.loadItems(state.query);

    switch (result) {
      case Success<List<Item>>():
        emit(state.copyWith(
          screenStatus: ScreenStatus.content,
          items: result.data,
        ));
      case Error<List<Item>>():
        emit(state.copyWith(
          screenStatus: ScreenStatus.error,
          errorType: ErrorType.server,
        ));
    }
  }

  Future<void> _itemTapped(ItemTapped event, Emitter<CatalogState> emit) async {
    emitUiEffect(OpenItemDetail(item: event.item));
  }
}
```

- События — `sealed class` в `<screen>_event.dart` как `part of` блока.
- Один обработчик — один `on<Event>`, тело вынесено в приватный метод.
- Загрузка **поверх уже показанного контента** (pull-to-refresh, догрузка страницы) —
  это отдельное поле стейта (`isRefreshing`), а не `ScreenStatus.loading`:
  статус `loading` означает «контента ещё нет».

## 8. Чек-лист перед сдачей экрана

- [ ] `presentation/` содержит `_page`, `_content`, `_loading`, `_error` отдельными файлами;
- [ ] стейт `implements BaseBlocState`, поле `screenStatus` есть, флагов `isLoading`/`hasError` нет;
- [ ] `switch` по статусу исчерпывающий, без `default`;
- [ ] в `presentation/` нет `sl<`, `await`, навигации, сайд-эффектов (кроме `_onUiEffect`);
- [ ] нет приватных `_build…()`, возвращающих `Widget`;
- [ ] компоненты в `components/` не знают о блоке;
- [ ] каждый `onTap`/`onPressed` шлёт событие блока;
- [ ] ошибка рисуется через `AppErrorWidget`, тип ошибки посчитан блоком (`errors.md`);
- [ ] пустой результат отличим от ошибки (§9);
- [ ] диалоги и шиты показываются из `_onUiEffect` (§10);
- [ ] обновление и догрузка не переводят экран в `loading` (§12);
- [ ] соблюдены правила `localization.md`, `theme.md`, `constants.md`.

## 9. Пустое состояние

Пустой результат — **не ошибка и не отдельный статус**. `ScreenStatus` остаётся
`{ loading, content, error }`, а пустота — это поле стейта:

```dart
switch (state.screenStatus) {
  ScreenStatus.content => state.items.isEmpty
      ? const CatalogEmpty()
      : CatalogList(items: state.items),
  ...
}
```

Причина: «пусто» — это разновидность контента, у него своя вёрстка (текст, картинка,
кнопка «сбросить фильтр»), и он должен уметь сосуществовать с шапкой и поиском, которые
при `error` не рисуются.

Проверка `state.items.isEmpty` в UI разрешена (`§6`, «выбор виджета по готовому полю»).
Если пустых состояний несколько по смыслу (ничего не найдено / ничего не добавлено),
различие считает блок и кладёт в стейт готовым полем, а не UI по набору условий.

`CatalogEmpty` — файл в `components/`.

## 10. Диалоги, шиты, внешние действия

Показ диалога, боттом-шита, шаринг, открытие ссылки, копирование в буфер — сайд-эффекты.
В `presentation/` их нет (§6). Все они идут через ui-эффект и `_onUiEffect`:

```
UI ──add(DeleteTapped)──▶ Bloc ──emitUiEffect(ConfirmDelete)──▶ _onUiEffect
                                                                    ↓ показ диалога
                          Bloc ◀──add(DeleteConfirmed)─────────────┘
```

Результат диалога всегда возвращается в блок событием, а не выполняется на месте.
После `await` — проверка `context.mounted`. Подробности — `widgets.md`, раздел «Диалоги
и боттом-шиты».

## 11. Формы и ввод

- `TextEditingController`, `FocusNode`, `ScrollController` живут в `StatefulWidget` и
  освобождаются в `dispose()` — это жизненный цикл виджета (§6);
- **значение поля всё равно уезжает в блок** событием (`QueryChanged`, `FieldChanged`):
  контроллер хранит текст для отрисовки, стейт — для логики;
- валидация — в блоке. Сообщение об ошибке приходит в стейт готовой строкой-ключом
  или enum-ом, а UI только рисует. `TextFormField.validator` с логикой внутри —
  нарушение;
- дебаунс ввода — в блоке (`bloc.md` §4), не в виджете;
- кнопка отправки блокируется полем стейта (`isSubmitting`), а не локальным `setState`;
- маски и ограничения ввода — `TextInputFormatter` в `core/helpers/` (`helpers.md`).

## 12. Обновление, догрузка, повтор

`ScreenStatus.loading` означает «контента ещё нет». Всё, что происходит **поверх**
показанного контента, — отдельные поля стейта:

| Действие | Поле | Что видит пользователь |
|---|---|---|
| Pull-to-refresh | `isRefreshing` | индикатор `RefreshIndicator`, список остаётся |
| Догрузка страницы | `isLoadingMore` | спиннер в конце списка |
| Повтор после ошибки | `screenStatus: loading` | контента нет — полноценная загрузка |
| Действие над элементом | поле в модели элемента или `Set<int> pendingIds` | спиннер на карточке |

Ошибка обновления или догрузки **не сносит** уже показанный контент: она показывается
тостом или строкой в конце списка (`errors.md`).
