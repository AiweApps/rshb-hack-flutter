import '../../../../core/application/bloc/base_bloc_uieffect.dart';

sealed class HistoryUiEffect extends BaseBlocUiEffect {}

/// Ask the user before wiping the list; the answer comes back as an event.
final class ConfirmClearHistory extends HistoryUiEffect {}

final class OpenScan extends HistoryUiEffect {}

final class OpenStoredScan extends HistoryUiEffect {
  final int scanId;

  OpenStoredScan({required this.scanId});
}
