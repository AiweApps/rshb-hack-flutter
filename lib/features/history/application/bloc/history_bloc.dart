import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/application/bloc/base_bloc.dart';
import '../../../../core/application/bloc/screen_status.dart';
import '../../../../core/services/language_service.dart';
import '../../../../shared/helpers/service_locator.dart';
import '../../../../shared/presentation/errors/error_type.dart';
import '../../domain/models/history_day_section.dart';
import '../../domain/models/scan_record.dart';
import '../../domain/scan_history_repository.dart';
import 'history_state.dart';
import 'history_uieffect.dart';

part 'history_event.dart';

/// The list of stored scans. It is a live view of the database: every insert
/// and delete anywhere in the app shows up here without a reload.
class HistoryBloc extends BaseBloc<HistoryEvent, HistoryState> {
  final ScanHistoryRepository _repository = sl<ScanHistoryRepository>();

  StreamSubscription<List<ScanHistoryItem>>? _subscription;

  HistoryBloc() : super(HistoryState.initial()) {
    on<StartHistory>(_start);
    on<RetryHistory>(_retry);
    on<HistoryItemsChanged>(_itemsChanged);
    on<HistoryStreamFailed>(_streamFailed);
    on<ScanTapped>(_scanTapped);
    on<ScanDismissed>(_scanDismissed);
    on<ScanPressed>(_scanPressed);
    on<ClearHistoryPressed>(_clearPressed, transformer: droppable());
    on<ClearHistoryConfirmed>(_clearConfirmed, transformer: droppable());
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }

  void _start(StartHistory event, Emitter<HistoryState> emit) {
    _subscribe(emit);
  }

  void _retry(RetryHistory event, Emitter<HistoryState> emit) {
    _subscribe(emit);
  }

  void _subscribe(Emitter<HistoryState> emit) {
    emit(state.copyWith(screenStatus: ScreenStatus.loading, errorType: null));
    _subscription?.cancel();
    _subscription = _repository.watchAll().listen(
      (items) {
        if (isClosed) return;
        add(HistoryItemsChanged(items: items));
      },
      onError: (Object error) {
        debugPrint('History stream failed: $error');
        if (isClosed) return;
        add(const HistoryStreamFailed());
      },
    );
  }

  void _itemsChanged(HistoryItemsChanged event, Emitter<HistoryState> emit) {
    // A pending id that the database no longer has is done; the rest stay
    // hidden until their delete lands.
    final ids = event.items.map((item) => item.id).toSet();
    final pending = state.pendingDeleteIds.intersection(ids);
    final visible = event.items
        .where((item) => !pending.contains(item.id))
        .toList();
    emit(
      state.copyWith(
        screenStatus: ScreenStatus.content,
        errorType: null,
        items: visible,
        sections: HistoryDaySection.group(visible),
        pendingDeleteIds: pending,
      ),
    );
  }

  void _streamFailed(HistoryStreamFailed event, Emitter<HistoryState> emit) {
    emit(
      state.copyWith(
        screenStatus: ScreenStatus.error,
        errorType: ErrorType.server,
      ),
    );
  }

  void _scanTapped(ScanTapped event, Emitter<HistoryState> emit) {
    emitUiEffect(OpenStoredScan(scanId: event.id));
  }

  Future<void> _scanDismissed(
    ScanDismissed event,
    Emitter<HistoryState> emit,
  ) async {
    // Hide the row at once: the Dismissible has already animated it away and
    // would throw if it were still in the tree on the next build.
    final remaining = state.items.where((item) => item.id != event.id).toList();
    emit(
      state.copyWith(
        items: remaining,
        sections: HistoryDaySection.group(remaining),
        pendingDeleteIds: {...state.pendingDeleteIds, event.id},
      ),
    );
    try {
      await _repository.delete(event.id);
    } on Exception catch (error) {
      debugPrint('Deleting scan ${event.id} failed: $error');
      if (emit.isDone) return;
      // The stream will bring the row back once it is no longer pending.
      emit(
        state.copyWith(
          pendingDeleteIds: state.pendingDeleteIds.difference({event.id}),
        ),
      );
      emitSnackBar.error(lsl10n.historyDeleteFailed);
      return;
    }
    emitSnackBar.info(lsl10n.historyDeleted);
  }

  void _scanPressed(ScanPressed event, Emitter<HistoryState> emit) {
    emitUiEffect(OpenScan());
  }

  void _clearPressed(ClearHistoryPressed event, Emitter<HistoryState> emit) {
    if (!state.canClear) return;
    emitUiEffect(ConfirmClearHistory());
  }

  Future<void> _clearConfirmed(
    ClearHistoryConfirmed event,
    Emitter<HistoryState> emit,
  ) async {
    try {
      await _repository.clear();
    } on Exception catch (error) {
      debugPrint('Clearing history failed: $error');
      emitSnackBar.error(lsl10n.historyClearFailed);
      return;
    }
    emitSnackBar.success(lsl10n.historyCleared);
  }
}
