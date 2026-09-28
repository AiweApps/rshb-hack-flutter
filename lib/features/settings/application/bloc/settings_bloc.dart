import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/application/bloc/base_bloc.dart';
import '../../../../core/application/bloc/screen_status.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/misc/preferences/app_preferences.dart';
import '../../../../core/services/api/models/result.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../shared/domain/models/service_status.dart';
import '../../../../shared/domain/service_availability.dart';
import '../../../../shared/helpers/service_locator.dart';
import '../../../history/domain/scan_history_repository.dart';
import '../../../scan/domain/scan_api_repository.dart';
import 'settings_state.dart';
import 'settings_uieffect.dart';

part 'settings_event.dart';

/// The settings tab: theme, language, service status, help links and the
/// history wipe. Every choice is saved through the services and mirrored
/// back into the state.
class SettingsBloc extends BaseBloc<SettingsEvent, SettingsState> {
  final ScanApiRepository _scanRepository = sl<ScanApiRepository>();
  final ScanHistoryRepository _historyRepository = sl<ScanHistoryRepository>();
  final AppPreferences _preferences = sl<AppPreferences>();

  CancelToken? _statusCancelToken;

  SettingsBloc() : super(SettingsState.initial()) {
    on<StartSettings>(_start);
    on<RetrySettings>(_start);
    on<RefreshStatus>(_refreshStatus, transformer: droppable());
    on<ThemePressed>(_themePressed);
    on<ThemeChanged>(_themeChanged);
    on<LanguagePressed>(_languagePressed);
    on<LanguageChanged>(_languageChanged);
    on<StatusTapped>(_statusTapped);
    on<ShowOnboardingPressed>(_showOnboardingPressed, transformer: droppable());
    on<AboutPressed>(_aboutPressed);
    on<OpenSitePressed>(_openSitePressed);
    on<ClearHistoryPressed>(_clearHistoryPressed, transformer: droppable());
    on<ClearHistoryConfirmed>(_clearHistoryConfirmed, transformer: droppable());
  }

  @override
  Future<void> close() {
    _statusCancelToken?.cancel();
    return super.close();
  }

  Future<void> _start(SettingsEvent event, Emitter<SettingsState> emit) async {
    emit(
      state.copyWith(
        screenStatus: ScreenStatus.content,
        errorType: null,
        themeMode: ThemeService.themeNotifier.value,
        languageCode: LanguageService.localeNotifier.value.languageCode,
        serviceState: ServiceState.checking,
      ),
    );
    await _loadStatus(emit);
  }

  Future<void> _refreshStatus(
    RefreshStatus event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));
    await _loadStatus(emit);
    if (emit.isDone) return;
    emit(state.copyWith(isRefreshing: false));
  }

  /// A failed status is never a screen error: it becomes a non-ready pill,
  /// the same reading the scan screen gives it.
  Future<void> _loadStatus(Emitter<SettingsState> emit) async {
    _statusCancelToken?.cancel();
    final cancelToken = CancelToken();
    _statusCancelToken = cancelToken;

    final result = await _scanRepository.status(cancelToken: cancelToken);
    if (emit.isDone || cancelToken.isCancelled) return;

    final int? catalogCards = switch (result) {
      Success<ServiceStatus>(:final data) => data.catalog?.cards,
      Error<ServiceStatus>() => state.catalogCards,
    };
    emit(
      state.copyWith(
        serviceState: ServiceState.fromResult(result),
        catalogCards: catalogCards,
      ),
    );
  }

  void _themePressed(ThemePressed event, Emitter<SettingsState> emit) {
    emitUiEffect(PickTheme(current: state.themeMode));
  }

  Future<void> _themeChanged(
    ThemeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    if (event.themeMode == state.themeMode) return;
    await ThemeService.saveTheme(event.themeMode);
    if (emit.isDone) return;
    emit(state.copyWith(themeMode: event.themeMode));
  }

  void _languagePressed(LanguagePressed event, Emitter<SettingsState> emit) {
    emitUiEffect(
      PickLanguage(
        current: state.languageCode,
        languageCodes: LanguageService.supportedLocales
            .map((locale) => locale.languageCode)
            .toList(),
      ),
    );
  }

  Future<void> _languageChanged(
    LanguageChanged event,
    Emitter<SettingsState> emit,
  ) async {
    if (event.languageCode == state.languageCode) return;
    await LanguageService.saveLanguage(Locale(event.languageCode));
    if (emit.isDone) return;
    emit(state.copyWith(languageCode: event.languageCode));
  }

  void _statusTapped(StatusTapped event, Emitter<SettingsState> emit) {
    emitUiEffect(
      ShowServiceDetail(availability: state.serviceState.availability),
    );
  }

  Future<void> _showOnboardingPressed(
    ShowOnboardingPressed event,
    Emitter<SettingsState> emit,
  ) async {
    // The intro opens by itself on the next launch only while the flag is
    // off; showing it again means resetting it.
    await _preferences.setIsOnboardingDone(false);
    emitUiEffect(OpenOnboarding());
  }

  void _aboutPressed(AboutPressed event, Emitter<SettingsState> emit) {
    emitUiEffect(ShowAbout());
  }

  void _openSitePressed(OpenSitePressed event, Emitter<SettingsState> emit) {
    emitUiEffect(OpenExternalUrl(url: LinkConstants.vinoSvoeSite));
  }

  void _clearHistoryPressed(
    ClearHistoryPressed event,
    Emitter<SettingsState> emit,
  ) {
    if (state.isClearingHistory) return;
    emitUiEffect(ConfirmClearHistory());
  }

  Future<void> _clearHistoryConfirmed(
    ClearHistoryConfirmed event,
    Emitter<SettingsState> emit,
  ) async {
    if (state.isClearingHistory) return;
    emit(state.copyWith(isClearingHistory: true));

    try {
      await _historyRepository.clear();
      emitSnackBar.success(lsl10n.historyCleared);
    } on Exception catch (e) {
      // A local wipe has no AppError to classify; the user still needs to
      // hear that it did not happen.
      debugPrint('History clear failed: $e');
      emitSnackBar.error(lsl10n.historyClearFailed);
    }

    if (emit.isDone) return;
    emit(state.copyWith(isClearingHistory: false));
  }
}
