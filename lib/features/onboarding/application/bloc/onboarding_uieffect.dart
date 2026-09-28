import '../../../../core/application/bloc/base_bloc_uieffect.dart';

sealed class OnboardingUiEffect extends BaseBlocUiEffect {}

/// Animate the pager to [pageIndex]; the controller lives in the widget.
final class ScrollToPage extends OnboardingUiEffect {
  final int pageIndex;

  ScrollToPage({required this.pageIndex});
}

final class OpenScan extends OnboardingUiEffect {}
