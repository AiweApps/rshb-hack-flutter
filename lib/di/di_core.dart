import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:winescan/core/services/flavors.dart';
import 'package:winescan/features/home/application/bloc/home_bloc.dart';
import 'package:winescan/features/home/domain/music_api_repository.dart';
import 'package:winescan/features/track_detail/application/bloc/track_detail_bloc.dart';

import '../core/misc/preferences/app_preferences.dart';
import '../core/router/app_router.dart';
import '../core/services/api/service/api_service.dart';
import '../features/splash/application/bloc/splash_bloc.dart';

Future<void> initDependencies() async {
  try {
    final sl = GetIt.instance;
    await _registerCore(sl);
    await _registerBlocs(sl);
    await _registerApiRepositories(sl);
    await sl.allReady();
  } on Exception catch (error) {
    debugPrint(error.toString());
  }
}

Future<void> _registerCore(GetIt sl) async {
  if (!sl.isRegistered<AppRouter>()) {
    sl.registerSingleton<AppRouter>(AppRouter());
  }
  if (!sl.isRegistered<AppPreferences>()) {
    final prefs = await SharedPreferences.getInstance();
    sl.registerSingleton<AppPreferences>(AppPreferences(prefs));
  }
  if (!sl.isRegistered<AppFlavorService>()) {
    final flavorProviderService = await AssetsAppFlavorService.fromAssets();
    sl.registerSingleton<AppFlavorService>(flavorProviderService);
  }
}

Future<void> _registerBlocs(GetIt sl) async {
  if (!sl.isRegistered<SplashBloc>()) {
    sl.registerFactory<SplashBloc>(() => SplashBloc());
  }
  if (!sl.isRegistered<HomePageBloc>()) {
    sl.registerFactory<HomePageBloc>(() => HomePageBloc());
  }
  if (!sl.isRegistered<TrackDetailBloc>()) {
    sl.registerFactory<TrackDetailBloc>(() => TrackDetailBloc());
  }
}

Future<void> _registerApiRepositories(GetIt sl) async {
  final musicApiService = ApiService("https://api.deezer.com/", {});
  if (!sl.isRegistered<MusicApiRepository>()) {
    sl.registerFactory<MusicApiRepository>(
      () => MusicApiRepository(musicApiService),
    );
  }
}
