import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/database/app_database.dart';
import '../core/misc/preferences/app_preferences.dart';
import '../core/misc/storage/scan_photo_store.dart';
import '../core/router/app_router.dart';
import '../core/services/api/service/api_service.dart';
import '../core/services/auth/auth_interceptor.dart';
import '../core/services/auth/guest_session_service.dart';
import '../core/services/flavors.dart';
import '../core/services/photo_picker_service.dart';
import '../features/history/application/bloc/history_bloc.dart';
import '../features/history/domain/dao/scan_history_dao.dart';
import '../features/history/domain/scan_history_repository.dart';
import '../features/onboarding/application/bloc/onboarding_bloc.dart';
import '../features/scan/application/home/bloc/scan_home_bloc.dart';
import '../features/scan/application/result/bloc/scan_result_bloc.dart';
import '../features/scan/domain/scan_api_repository.dart';
import '../features/settings/application/bloc/settings_bloc.dart';
import '../features/splash/application/bloc/splash_bloc.dart';

/// Fills the container. An error here is fatal on purpose: an app with half
/// a container fails later in a random place with a worse message.
Future<void> initDependencies() async {
  final sl = GetIt.instance;
  await _registerCore(sl);
  _registerServices(sl);
  _registerRepositories(sl);
  _registerBlocs(sl);
  await sl.allReady();
}

Future<void> _registerCore(GetIt sl) async {
  if (!sl.isRegistered<AppPreferences>()) {
    final prefs = await SharedPreferences.getInstance();
    sl.registerSingleton<AppPreferences>(AppPreferences(prefs));
  }
  if (!sl.isRegistered<AppFlavorService>()) {
    final flavorService = await AssetsAppFlavorService.fromAssets();
    sl.registerSingleton<AppFlavorService>(flavorService);
  }
  if (!sl.isRegistered<AppRouter>()) {
    sl.registerSingleton<AppRouter>(AppRouter());
  }
}

void _registerServices(GetIt sl) {
  if (!sl.isRegistered<GuestSessionService>()) {
    sl.registerLazySingleton<GuestSessionService>(
      () => GuestSessionService(apiBaseUrl: sl<AppFlavorService>().apiBaseUrl),
    );
  }
  if (!sl.isRegistered<ApiService>()) {
    sl.registerLazySingleton<ApiService>(() {
      final flavor = sl<AppFlavorService>();
      final service = ApiService(
        flavor.apiBaseUrl,
        const {},
        logBodies: flavor.logNetworkBodies,
      );
      service.addInterceptor(
        AuthInterceptor(sl<GuestSessionService>(), service),
      );
      return service;
    });
  }
  if (!sl.isRegistered<PhotoPickerService>()) {
    sl.registerLazySingleton<PhotoPickerService>(() => PhotoPickerService());
  }
  if (!sl.isRegistered<ScanPhotoStore>()) {
    sl.registerLazySingleton<ScanPhotoStore>(() => ScanPhotoStore());
  }
  if (!sl.isRegistered<AppDatabase>()) {
    sl.registerLazySingleton<AppDatabase>(() => AppDatabase());
  }
  if (!sl.isRegistered<ScanHistoryDao>()) {
    sl.registerLazySingleton<ScanHistoryDao>(
      () => ScanHistoryDao(sl<AppDatabase>()),
    );
  }
}

void _registerRepositories(GetIt sl) {
  if (!sl.isRegistered<ScanApiRepository>()) {
    sl.registerLazySingleton<ScanApiRepository>(
      () => ScanApiRepository(
        sl<ApiService>(),
        session: sl<GuestSessionService>(),
        apiBaseUrl: sl<AppFlavorService>().apiBaseUrl,
      ),
    );
  }
  if (!sl.isRegistered<ScanHistoryRepository>()) {
    sl.registerLazySingleton<ScanHistoryRepository>(
      () => ScanHistoryRepository(sl<ScanHistoryDao>(), sl<ScanPhotoStore>()),
    );
  }
}

void _registerBlocs(GetIt sl) {
  if (!sl.isRegistered<SplashBloc>()) {
    sl.registerFactory<SplashBloc>(() => SplashBloc());
  }
  if (!sl.isRegistered<OnboardingBloc>()) {
    sl.registerFactory<OnboardingBloc>(() => OnboardingBloc());
  }
  if (!sl.isRegistered<ScanHomeBloc>()) {
    sl.registerFactory<ScanHomeBloc>(() => ScanHomeBloc());
  }
  if (!sl.isRegistered<ScanResultBloc>()) {
    sl.registerFactory<ScanResultBloc>(() => ScanResultBloc());
  }
  if (!sl.isRegistered<HistoryBloc>()) {
    sl.registerFactory<HistoryBloc>(() => HistoryBloc());
  }
  if (!sl.isRegistered<SettingsBloc>()) {
    sl.registerFactory<SettingsBloc>(() => SettingsBloc());
  }
}
