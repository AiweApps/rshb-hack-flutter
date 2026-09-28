import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/application/bloc/base_bloc_state.dart';
import '../../../../core/application/bloc/screen_status.dart';
import '../../../../shared/presentation/errors/error_type.dart';
import '../../domain/models/scan_record.dart';

part 'history_state.freezed.dart';

@freezed
abstract class HistoryState with _$HistoryState implements BaseBlocState {
  const factory HistoryState({
    required ScreenStatus screenStatus,

    /// Set only while [screenStatus] is [ScreenStatus.error].
    required ErrorType? errorType,

    /// Rows the list renders: what the database holds minus the rows the
    /// user has already swiped away and whose deletion is still in flight.
    required List<ScanHistoryItem> items,

    /// Ids swiped away but not yet gone from the database.
    required Set<int> pendingDeleteIds,
  }) = _HistoryState;

  const HistoryState._();

  factory HistoryState.initial() => const HistoryState(
    screenStatus: ScreenStatus.loading,
    errorType: null,
    items: [],
    pendingDeleteIds: {},
  );

  /// The "clear" action only makes sense over a non-empty list.
  bool get canClear => screenStatus == ScreenStatus.content && items.isNotEmpty;
}
