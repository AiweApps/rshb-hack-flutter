---
name: new-screen
description: Создаёт базу нового экрана строго по .claude/rules/screens.md — блок с событиями и стейтом, ui-эффекты, page/content/loading/error отдельными файлами, папку components, ключи локализации, регистрацию в DI и навигацию. Сначала уточняет, откуда и как экран открывается, если это не следует из запроса. Использовать, когда просят создать новый экран, страницу, базу экрана, заготовку экрана.
---

# new-screen — база нового экрана

Создаёт **каркас**, а не готовую фичу: пустой контент, пустая логика, но всё на своих местах
и всё компилируется. Наполнение — отдельная задача.

Правила, по которым собирается каркас: `.claude/rules/screens.md` (структура),
`bloc.md` (жизненный цикл блока), `navigation.md` (маршрут и аргументы),
`di.md` (регистрация). Первое подключено в `CLAUDE.md`, остальные прочитать перед шагом 5.

## Шаг 1. Разобрать запрос

Из фразы вида «создать базу экрана избранного каталога» вывести:

| Что | Как выводится | Пример |
|---|---|---|
| фича | к какой предметной области относится | `favorites` |
| экран | что именно за экран | `favorites_catalog` |
| класс | UpperCamelCase от экрана | `FavoritesCatalog` |
| заголовок | человеческое название для AppBar | «Избранное» |

Если фича уже есть в `lib/features/` — экран добавляется в неё, новая не создаётся.

## Шаг 2. Уточнить недостающее

**Задать вопросы до генерации**, одним блоком. Спрашивать только то, что не следует
из запроса, — не переспрашивай очевидное.

1. **Откуда открывается?** Варианты:
   - новая вкладка в нижней навигации (`StatefulShellBranch` в `app_router.dart`);
   - вложенный экран внутри существующей вкладки (тогда: внутри какой) — открывается `push`;
   - корневой экран поверх всего (вне shell-роута, как `splash`).
2. **Нужны ли параметры перехода?** Модель или id, который прилетает через
   `state.extra`. Если да — какой тип.
3. **Грузит ли данные при открытии?** Если да — из какого репозитория. Если репозитория
   ещё нет, каркас делается с `TODO` в обработчике, а репозиторий — отдельной задачей.
4. **Заголовок экрана** — точный текст на en и de для ARB, если из запроса он неочевиден.

Если ответы не приходят, а работу нужно продолжить: сделай экран корневым в текущей вкладке
без параметров и без загрузки, и **явно перечисли** принятые допущения в отчёте.

## Шаг 3. Сгенерировать файлы

Ровно по `.claude/rules/screens.md`. Ниже — шаблоны под конвенции этого проекта.
`<Screen>` = `FavoritesCatalog`, `<screen>` = `favorites_catalog`, `<feature>` = `favorites`.

### `application/bloc/<screen>_state.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/application/bloc/base_bloc_state.dart';
import '../../../../core/application/bloc/screen_status.dart';
import '../../../../shared/presentation/errors/error_type.dart';

part '<screen>_state.freezed.dart';

@freezed
abstract class <Screen>State with _$<Screen>State implements BaseBlocState {
  const factory <Screen>State({
    required ScreenStatus screenStatus,
    required ErrorType? errorType,
  }) = _<Screen>State;

  factory <Screen>State.initial() => const <Screen>State(
    screenStatus: ScreenStatus.loading,
    errorType: null,
  );
}
```

Если экран ничего не грузит — начальный статус `ScreenStatus.content`.

### `application/bloc/<screen>_uieffect.dart`

```dart
import '../../../../core/application/bloc/base_bloc_uieffect.dart';

sealed class <Screen>UiEffect extends BaseBlocUiEffect {}
```

### `application/bloc/<screen>_event.dart`

```dart
part of '<screen>_bloc.dart';

sealed class <Screen>Event {
  const <Screen>Event();
}

final class Start<Screen> extends <Screen>Event {
  const Start<Screen>();
}

final class Retry<Screen> extends <Screen>Event {
  const Retry<Screen>();
}
```

### `application/bloc/<screen>_bloc.dart`

```dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/application/bloc/base_bloc.dart';
import '../../../../core/application/bloc/screen_status.dart';
import '<screen>_state.dart';

part '<screen>_event.dart';

class <Screen>Bloc extends BaseBloc<<Screen>Event, <Screen>State> {
  <Screen>Bloc() : super(<Screen>State.initial()) {
    on<Start<Screen>>(_load);
    on<Retry<Screen>>(_load);
  }

  FutureOr<void> _load(<Screen>Event event, Emitter<<Screen>State> emit) async {
    emit(state.copyWith(screenStatus: ScreenStatus.loading, errorType: null));

    // TODO: load data, then emit content or error
    emit(state.copyWith(screenStatus: ScreenStatus.content));
  }
}
```

Экран с параметром перехода: параметр приходит в событии `Start<Screen>` и кладётся в стейт
в обработчике — как это сделано в `TrackDetailBloc`.

### `presentation/<screen>_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/application/bloc/base_bloc_presentation_listener.dart';
import '../../../core/application/bloc/base_bloc_uieffect.dart';
import '../../../core/application/bloc/screen_status.dart';
import '../../../core/services/language_service.dart';
import '../application/bloc/<screen>_bloc.dart';
import '../application/bloc/<screen>_state.dart';
import '<screen>_content.dart';
import '<screen>_error.dart';
import '<screen>_loading.dart';

class <Screen>Page extends StatelessWidget {
  const <Screen>Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.localization.<screenTitleKey>)),
      body: SafeArea(
        child: BaseBlocPresentationListener<<Screen>Bloc>(
          listener: _onUiEffect,
          child: BlocBuilder<<Screen>Bloc, <Screen>State>(
            builder: (context, state) => switch (state.screenStatus) {
              ScreenStatus.loading => const <Screen>Loading(),
              ScreenStatus.content => <Screen>Content(state: state),
              ScreenStatus.error => <Screen>Error(state: state),
            },
          ),
        ),
      ),
    );
  }

  void _onUiEffect(BuildContext context, BaseBlocUiEffect effect) {
    // Effects declared in <screen>_uieffect.dart are handled here.
  }
}
```

### `presentation/<screen>_loading.dart`

```dart
import 'package:flutter/material.dart';

class <Screen>Loading extends StatelessWidget {
  const <Screen>Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
```

### `presentation/<screen>_error.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/presentation/errors/app_error_widget.dart';
import '../application/bloc/<screen>_bloc.dart';
import '../application/bloc/<screen>_state.dart';

class <Screen>Error extends StatelessWidget {
  final <Screen>State state;

  const <Screen>Error({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    void onRefresh() =>
        context.read<<Screen>Bloc>().add(const Retry<Screen>());

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

`app_error_widget.dart` реэкспортит `ErrorType` и `ErrorDisplay` — отдельные импорты не нужны.

### `presentation/<screen>_content.dart`

```dart
import 'package:flutter/material.dart';

import '../application/bloc/<screen>_state.dart';

class <Screen>Content extends StatelessWidget {
  final <Screen>State state;

  const <Screen>Content({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
```

### `presentation/components/`

Создать папку с `.gitkeep`. Части контента появятся здесь по мере наполнения.

## Шаг 4. Локализация

Заголовок экрана — ключ в **обоих** ARB (`lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`),
в `app_en.arb` обязателен блок `@key` с `description`. Имя ключа — по правилам
`.claude/rules/localization.md`. Перевод, в котором не уверен, проставь и явно скажи об этом
разработчику.

## Шаг 5. Навигация

### `lib/core/router/pages.dart`

```dart
static const String _<screenCamel> = '<screenCamel>';

static PageInfo <screenCamel> = PageInfo(
  path: _<screenCamel>,
  name: _<screenCamel>,
  navigationParent: <родитель: root, home или другой экран>,
);
```

И **обязательно** добавить в `Pages.all` — иначе `tryNavigateBack` не найдёт родителя.

### `lib/core/router/app_router.dart`

1. Импорты страницы и блока.
2. `GoRoute` в нужное место:
   - вложенный в существующую вкладку → в `routes:` соответствующего `GoRoute`,
     `path: Pages.<screenCamel>.path` (без ведущего `/`);
   - новая вкладка → новый `StatefulShellBranch` со своим `GlobalKey<NavigatorState>`,
     `path: '/${Pages.<screenCamel>.path}'`; плюс пункт в `CustomBottomNavigationBar`;
   - корневой → в верхний `routes:`, `path: '/${Pages.<screenCamel>.path}'`.
3. Статический билдер рядом с остальными:

```dart
static Widget _<screenCamel>PageRouteBuilder(
  BuildContext context,
  GoRouterState state,
) {
  return BlocProvider(
    create: (context) => sl<<Screen>Bloc>()..add(const Start<Screen>()),
    child: const <Screen>Page(),
  );
}
```

С параметром перехода — `final arg = state.extra as <Type>;` и передача его в событие.

4. Метод перехода в `AppRouterExtension`:

```dart
void navigateTo<Screen>() => _push(Pages.<screenCamel>.navigationPath);
```

`_go` — для смены корневого экрана/вкладки, `_push` — для экрана поверх текущего.

## Шаг 6. DI

В `lib/di/di_core.dart`, в `_registerBlocs`:

```dart
if (!sl.isRegistered<<Screen>Bloc>()) {
  sl.registerFactory<<Screen>Bloc>(() => <Screen>Bloc());
}
```

Блоки регистрируются как `registerFactory` — новый инстанс на каждое открытие экрана.

## Шаг 7. Проверить

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
```

Должно быть `No issues found!`. Затем пройтись по чек-листу из `.claude/rules/screens.md` §8.

## Отчёт

- список созданных файлов;
- куда прописана навигация и каким методом экран открывается;
- добавленные ключи локализации;
- принятые допущения, если на вопросы из шага 2 не было ответа;
- что осталось сделать (наполнение контента, репозиторий, компоненты).
