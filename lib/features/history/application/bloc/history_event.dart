part of 'history_bloc.dart';

sealed class HistoryEvent {
  const HistoryEvent();
}

final class StartHistory extends HistoryEvent {
  const StartHistory();
}

/// "Try again" on the error screen: the list is watched from scratch.
final class RetryHistory extends HistoryEvent {
  const RetryHistory();
}

/// The database emitted a new snapshot of the list.
final class HistoryItemsChanged extends HistoryEvent {
  final List<ScanHistoryItem> items;

  const HistoryItemsChanged({required this.items});
}

/// The database stream failed; there is nothing to show.
final class HistoryStreamFailed extends HistoryEvent {
  const HistoryStreamFailed();
}

final class ScanTapped extends HistoryEvent {
  final int id;

  const ScanTapped({required this.id});
}

/// A row was swiped away.
final class ScanDismissed extends HistoryEvent {
  final int id;

  const ScanDismissed({required this.id});
}

/// "Scan" on the empty state.
final class ScanPressed extends HistoryEvent {
  const ScanPressed();
}

final class ClearHistoryPressed extends HistoryEvent {
  const ClearHistoryPressed();
}

/// The user agreed in the confirmation dialog.
final class ClearHistoryConfirmed extends HistoryEvent {
  const ClearHistoryConfirmed();
}
