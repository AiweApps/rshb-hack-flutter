import '../../../../core/application/bloc/base_bloc_uieffect.dart';

sealed class SplashUiEffect extends BaseBlocUiEffect {}

final class OpenOnboarding extends SplashUiEffect {}

final class OpenScan extends SplashUiEffect {}
