import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/history/application/bloc/history_bloc.dart';
import '../../features/history/presentation/history_page.dart';
import '../../features/onboarding/application/bloc/onboarding_bloc.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import '../../features/scan/application/home/bloc/scan_home_bloc.dart';
import '../../features/scan/application/result/bloc/scan_result_bloc.dart';
import '../../features/scan/domain/models/scan_result_args.dart';
import '../../features/scan/presentation/home/scan_home_page.dart';
import '../../features/scan/presentation/result/scan_result_page.dart';
import '../../features/settings/application/bloc/settings_bloc.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/splash/application/bloc/splash_bloc.dart';
import '../../features/splash/presentation/splash_page.dart';
import '../../shared/helpers/service_locator.dart';
import '../../shared/presentation/pages/routing_error_page.dart';
import '../widgets/navigation/app_shell_scaffold.dart';
import 'pages.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _tabScanNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'scan');
final GlobalKey<NavigatorState> _tabHistoryNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'history');
final GlobalKey<NavigatorState> _tabSettingsNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'settings');

/// Routes only: every builder takes its argument, creates the bloc and
/// returns the page. Navigation from features goes through
/// [AppRouterExtension].
class AppRouter {
  AppRouter() {
    _initRouter();
  }

  late GoRouter _mainRouter;

  GoRouter get mainRouter => _mainRouter;

  void _initRouter() {
    _mainRouter = GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: Pages.splash.navigationPath,
      routes: <RouteBase>[
        GoRoute(
          path: '/${Pages.splash.path}',
          name: Pages.splash.name,
          builder: _splashPageRouteBuilder,
        ),
        GoRoute(
          path: '/${Pages.onboarding.path}',
          name: Pages.onboarding.name,
          builder: _onboardingPageRouteBuilder,
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppShellScaffold(navigationShell: navigationShell),
          branches: <StatefulShellBranch>[
            StatefulShellBranch(
              navigatorKey: _tabScanNavigatorKey,
              routes: <RouteBase>[
                GoRoute(
                  path: '/${Pages.scan.path}',
                  name: Pages.scan.name,
                  builder: _scanHomePageRouteBuilder,
                  routes: <RouteBase>[
                    GoRoute(
                      path: Pages.scanResult.path,
                      name: Pages.scanResult.name,
                      // The answer covers the tabs: the photo needs the
                      // whole screen.
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: _scanResultPageRouteBuilder,
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _tabHistoryNavigatorKey,
              routes: <RouteBase>[
                GoRoute(
                  path: '/${Pages.history.path}',
                  name: Pages.history.name,
                  builder: _historyPageRouteBuilder,
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _tabSettingsNavigatorKey,
              routes: <RouteBase>[
                GoRoute(
                  path: '/${Pages.settings.path}',
                  name: Pages.settings.name,
                  builder: _settingsPageRouteBuilder,
                ),
              ],
            ),
          ],
        ),
      ],
      errorBuilder: (_, GoRouterState state) => RoutingErrorPage(state: state),
    );
  }

  static Widget _splashPageRouteBuilder(
    BuildContext context,
    GoRouterState state,
  ) {
    return BlocProvider(
      create: (context) => sl<SplashBloc>()..add(const SplashStart()),
      child: const SplashPage(),
    );
  }

  static Widget _onboardingPageRouteBuilder(
    BuildContext context,
    GoRouterState state,
  ) {
    return BlocProvider(
      create: (context) => sl<OnboardingBloc>()..add(const StartOnboarding()),
      child: const OnboardingPage(),
    );
  }

  static Widget _scanHomePageRouteBuilder(
    BuildContext context,
    GoRouterState state,
  ) {
    return BlocProvider(
      create: (context) => sl<ScanHomeBloc>()..add(const StartScanHome()),
      child: const ScanHomePage(),
    );
  }

  static Widget _scanResultPageRouteBuilder(
    BuildContext context,
    GoRouterState state,
  ) {
    final args = state.extra;
    if (args is! ScanResultArgs) {
      return RoutingErrorPage(state: state);
    }
    return BlocProvider(
      create: (context) =>
          sl<ScanResultBloc>()..add(StartScanResult(args: args)),
      child: const ScanResultPage(),
    );
  }

  static Widget _historyPageRouteBuilder(
    BuildContext context,
    GoRouterState state,
  ) {
    return BlocProvider(
      create: (context) => sl<HistoryBloc>()..add(const StartHistory()),
      child: const HistoryPage(),
    );
  }

  static Widget _settingsPageRouteBuilder(
    BuildContext context,
    GoRouterState state,
  ) {
    return BlocProvider(
      create: (context) => sl<SettingsBloc>()..add(const StartSettings()),
      child: const SettingsPage(),
    );
  }

  void _go(String location, {Object? extra}) =>
      _mainRouter.go(location, extra: extra);

  void _push(String location, {Object? extra}) =>
      _mainRouter.push(location, extra: extra);

  void _pop() => _mainRouter.pop();

  bool get _canPop => _mainRouter.canPop();
}

extension AppRouterExtension on AppRouter {
  void navigateToOnboarding() => _go(Pages.onboarding.navigationPath);

  void navigateToScan() => _go(Pages.scan.navigationPath);

  void navigateToHistory() => _go(Pages.history.navigationPath);

  void navigateToScanResult(ScanResultArgs args) =>
      _push(Pages.scanResult.navigationPath, extra: args);

  /// Closes the topmost screen; falls back to the scan tab when there is
  /// nothing to pop (a restored stack).
  void navigateBack() {
    if (_canPop) {
      _pop();
    } else {
      navigateToScan();
    }
  }
}
