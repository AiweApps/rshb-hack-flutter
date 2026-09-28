# Правила: навигация и роутер

## Главное правило

**`app_router.dart` — это только маршруты. Ни вёрстки, ни бизнес-логики, ни состояния.**

Фича никогда не работает с `go_router` напрямую. Единственный способ уйти на другой экран —
ui-эффект из блока и `sl<AppRouter>().navigateToX(...)` в `_onUiEffect` на странице.

```dart
// ❌ в любом файле lib/features/**
context.go('/home');
context.push('/trackDetails', extra: track);
GoRouter.of(context).pop();

// ✅ блок
emitUiEffect(OpenTrackDetails(track: event.track));

// ✅ страница, _onUiEffect
case OpenTrackDetails(:final track):
  sl<AppRouter>().navigateToTrackDetails(track);
```

`context.go/push/pop` разрешены **только** внутри `lib/core/router/` и
`lib/core/extensions/navigation_extensions.dart`. Больше нигде.

## Слои

```
Pages (pages.dart)          — реестр адресов: path, name, родитель
      ↓
AppRouter (app_router.dart) — GoRouter: дерево маршрутов + билдеры страниц
      ↓
AppRouterExtension          — публичное API навигации: navigateToX()
      ↓
фича                        — только вызовы navigateToX() из _onUiEffect
```

Приватные `_go` / `_push` / `_pop` наружу не торчат. Каждый переход получает **именованный
метод** в `AppRouterExtension` — по нему видно весь список возможных переходов приложения
в одном месте.

## Что в `app_router.dart` быть не должно

| Не должно | Куда |
|---|---|
| `Scaffold`, `AppBar`, `BottomNavigationBar` и прочая вёрстка | отдельный виджет-оболочка в `lib/core/widgets/navigation/` |
| `ValueListenableBuilder`, `InheritedWidget`, любое состояние | туда же, в виджет-оболочку |
| Загрузка данных, `await`, обращения к репозиториям | блок экрана |
| Условия показа экрана (авторизован / онбординг пройден) | `redirect` — отдельный метод, см. ниже |

Билдер маршрута делает ровно три вещи: достаёт аргумент, создаёт `BlocProvider`,
возвращает страницу. Всё остальное — не его работа.

### Оболочка табов

`StatefulShellRoute.indexedStack` получает **готовый виджет-оболочку** из
`lib/core/widgets/navigation/`, а не собирает `Scaffold` с нижней навигацией на месте:

```dart
builder: (context, state, navigationShell) =>
    AppShellScaffold(navigationShell: navigationShell),
```

Всё, что относится к внешнему виду оболочки — нижняя панель, её высота, отступы под
тосты, — живёт в этом виджете. Роут знает только, что оболочка есть.

## Порядок добавления экрана

Ровно четыре шага, все обязательны.

### 1. `pages.dart`

```dart
static const String _favorites = 'favorites';

static PageInfo favorites = PageInfo(
  path: _favorites,
  name: _favorites,
  navigationParent: root,   // или home, или другой экран
);
```

**И добавить в `Pages.all`.** Без этого `parentNavigationPathOf` не найдёт родителя и
`tryNavigateBack` уведёт не туда. Забыть легко, компилятор не подскажет —
lib/core/router/pages.dart:35.

`navigationParent` отражает **иерархию адреса**, а не то, откуда экран открывают.
`trackDetails` вложен в `home`, потому что его адрес `/home/trackDetails`.

### 2. `GoRoute` в `app_router.dart`

| Тип экрана | Куда | `path` |
|---|---|---|
| вложенный в существующую вкладку | в `routes:` родительского `GoRoute` | `Pages.x.path` (без `/`) |
| новая вкладка | новый `StatefulShellBranch` + свой `GlobalKey<NavigatorState>` | `'/${Pages.x.path}'` |
| поверх всего, вне табов (splash, полноэкранный флоу) | верхний `routes:` | `'/${Pages.x.path}'` |

Экран, который должен перекрывать нижнюю навигацию, но логически принадлежит вкладке, —
`parentNavigatorKey: _rootNavigatorKey` у его `GoRoute`. Иначе он откроется внутри таба
и bottom bar останется на экране.

### 3. Билдер

```dart
static Widget _favoritesPageRouteBuilder(
  BuildContext context,
  GoRouterState state,
) {
  return BlocProvider(
    create: (context) => sl<FavoritesBloc>()..add(const StartFavorites()),
    child: const FavoritesPage(),
  );
}
```

**`BlocProvider` создаётся здесь, а не в странице.** Причина: страница обязана уметь
существовать без знания о том, кто её создал, а блок обязан умереть вместе с маршрутом —
`BlocProvider` в билдере даёт и то, и другое. Стартовое событие — тут же, каскадом `..add`.

### 4. Метод в `AppRouterExtension`

```dart
void navigateToFavorites() => _push(Pages.favorites.navigationPath);
```

`_go` — смена корневого экрана или вкладки (splash → home, разлогин).
`_push` — экран поверх текущего, с кнопкой «назад».

## Передача аргументов

### Правило

**`extra` не кастуется вслепую.** Каст `as` в билдере — это краш при deep link, при
hot restart на этом маршруте и при восстановлении стека системой.

```dart
// ❌ падает при deep link, hot restart и восстановлении стека системой
final track = state.extra as Track;

// ✅
final track = state.extra;
if (track is! Track) {
  return RoutingErrorPage(state: state);   // или редирект на список
}
```

### Что передавать

| Ситуация | Как |
|---|---|
| Экран может открыться по ссылке/из пуша | **id в path-параметре**, данные грузит блок |
| Экран открывается только изнутри приложения, данные уже есть | объект в `extra` |
| И то, и другое | id в path + `extra` как необязательный кэш для мгновенной отрисовки |

Объект в `extra` — это оптимизация «не грузить второй раз», а не источник правды.
Экран, который умеет жить только с `extra`, недостижим по ссылке.

Примитивные параметры (id, slug) — только через `pathParameters` / `queryParameters`,
не через `extra`.

## Возврат результата с экрана

Экран не «возвращает значение» вызывающей стороне. Результат уезжает через общее состояние:

1. экран-B сохраняет результат (репозиторий/сервис/хранилище) и закрывается;
2. экран-A подписан на изменение и обновляется сам.

Если нужен именно ответ на месте (выбор из списка, подтверждение) — это не отдельный
маршрут, а диалог или боттом-шит (см. `widgets.md`): их показывает `_onUiEffect`,
и он же отправляет результат событием в блок.

`Navigator.pop(result)` из фичи — запрещено.

## Назад

- Системная кнопка «назад» и свайп работают сами — ничего делать не нужно.
- Кнопка «назад» в шапке экрана — событие блока → ui-эффект `CloseScreen` →
  `sl<AppRouter>()` или `context.tryNavigateBack()` из `navigation_extensions.dart`.
- Перехват «назад» (несохранённые изменения, подтверждение выхода) — `PopScope` на
  странице, `canPop: false`, и вопрос уходит событием в блок. Решение «уходить или нет»
  принимает блок, а не виджет.

## Редиректы и гварды

Условия «пускать / не пускать» живут в одном месте — параметре `redirect` у `GoRouter`,
отдельным приватным методом:

```dart
String? _redirect(BuildContext context, GoRouterState state) { ... }
```

Правила:

- редирект читает **только** синхронно доступное состояние (`sl<AppPreferences>()`,
  токен в памяти). Ни `await`, ни сетевых запросов — роутер должен ответить мгновенно;
- асинхронная проверка (валиден ли токен) — это работа splash-экрана или сервиса,
  результат которой уже лежит в памяти к моменту редиректа;
- `refreshListenable` — если маршрут зависит от меняющегося состояния (разлогин).

Пока авторизации в проекте нет, `redirect` не заводится. Появится — только так.

## Deep links и внешние ссылки

- Каждый экран, на который может вести внешняя ссылка, обязан уметь подняться
  «с нуля»: по id из path, без `extra`, без предположений о стеке под собой.
- Обработчик неизвестного адреса уже есть — `errorBuilder` →
  `RoutingErrorPage`: lib/core/router/app_router.dart:106. Свой не заводить.
- Открытие внешнего URL (браузер, `mailto:`, шаринг) — **не навигация**. Это ui-эффект и
  сервис, адреса — из `LinkConstants` / `ContactConstants` (`constants.md`).

## Чек-лист перед сдачей маршрута

- [ ] `PageInfo` заведён и добавлен в `Pages.all`;
- [ ] `GoRoute` стоит на нужном уровне (таб / поверх табов / корень);
- [ ] билдер только достаёт аргумент, создаёт `BlocProvider` и возвращает страницу;
- [ ] `extra` проверен через `is!`, а не скастован через `as`;
- [ ] экран открывается по ссылке без `extra` (или явно задокументировано, что не должен);
- [ ] в `AppRouterExtension` есть именованный метод перехода;
- [ ] в `lib/features/**` нет `context.go` / `context.push` / `context.pop` / `GoRouter`;
- [ ] в `app_router.dart` не появилось вёрстки.
