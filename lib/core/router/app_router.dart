import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:winescan/core/router/pages.dart';
import 'package:winescan/features/track_detail/presentation/track_detail_page.dart';

import '../../features/home/application/bloc/home_bloc.dart';
import '../../features/home/domain/models/track.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/splash/application/bloc/splash_bloc.dart';
import '../../features/splash/presentation/splash_page.dart';
import '../../features/track_detail/application/bloc/track_detail_bloc.dart';
import '../../shared/helpers/service_locator.dart';
import '../../shared/presentation/pages/routing_error_page.dart';
import '../widgets/custom_bottom_navigation_bar.dart';
import '../widgets/navigation/nav_bar_height_provider.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _tabHomeNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'home');
final GlobalKey<NavigatorState> _tabSettingsNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'settings');
final GlobalKey<ScaffoldState> _globalAppScaffoldKey =
    GlobalKey<ScaffoldState>();

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
        StatefulShellRoute.indexedStack(
          builder:
              (
                BuildContext context,
                GoRouterState state,
                StatefulNavigationShell navigationShell,
              ) {
                return Scaffold(
                  key: _globalAppScaffoldKey,
                  // Publish the nav bar height down the tree so toasts shown
                  // from these screens sit above the bar instead of under it.
                  body: ValueListenableBuilder<double>(
                    valueListenable: CustomBottomNavigationBar.heightNotifier,
                    builder: (context, navBarHeight, child) {
                      return NavBarHeightProvider(
                        height: navBarHeight,
                        child: child!,
                      );
                    },
                    child: navigationShell,
                  ),
                  bottomNavigationBar: CustomBottomNavigationBar(
                    navigationShell: navigationShell,
                  ),
                );
              },
          branches: <StatefulShellBranch>[
            StatefulShellBranch(
              navigatorKey: _tabHomeNavigatorKey,
              routes: <RouteBase>[
                GoRoute(
                  path: '/${Pages.home.path}',
                  name: Pages.home.name,
                  builder: _homePageRouteBuilder,
                  routes: <RouteBase>[
                    GoRoute(
                      path: Pages.trackDetails.path,
                      name: Pages.trackDetails.name,
                      builder: _trackDetailsPageRouteBuilder,
                    ),
                  ],
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
                  routes: const <RouteBase>[],
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

  static Widget _homePageRouteBuilder(
    BuildContext context,
    GoRouterState state,
  ) {
    return BlocProvider(
      create: (context) => sl<HomePageBloc>()..add(const StartHome()),
      child: const HomePage(),
    );
  }

  static Widget _trackDetailsPageRouteBuilder(
    BuildContext context,
    GoRouterState state,
  ) {
    final track = state.extra as Track;

    return BlocProvider(
      create: (context) =>
          sl<TrackDetailBloc>()..add(TrackDetailStart(track: track)),
      child: const TrackDetailPage(),
    );
  }

  static Widget _settingsPageRouteBuilder(
    BuildContext context,
    GoRouterState state,
  ) {
    return const SettingsPage();
  }

  void _go(String location, {Object? extra}) =>
      _mainRouter.go(location, extra: extra);

  void _push(String location, {Object? extra}) =>
      _mainRouter.push(location, extra: extra);

  /* uncomment when needed
  void _pushReplacement(String location, {Object? extra}) =>
      _mainRouter.pushReplacement(location, extra: extra);

  void _pop<T extends Object?>([T? result]) => _mainRouter.pop(result);

  Future<T?> _replace<T>(String location, {Object? extra}) =>
      _mainRouter.replace(location, extra: extra);
  */
}

extension AppRouterExtension on AppRouter {
  void navigateToHome() => _go(Pages.home.navigationPath);

  void navigateToTrackDetails(Track track) =>
      _push(Pages.trackDetails.navigationPath, extra: track);
}
