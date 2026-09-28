part of 'scan_home_bloc.dart';

sealed class ScanHomeEvent {
  const ScanHomeEvent();
}

final class StartScanHome extends ScanHomeEvent {
  const StartScanHome();
}

/// Re-reads the service status (timer, tap, retry).
final class RefreshStatus extends ScanHomeEvent {
  const RefreshStatus();
}

/// The app went to the background or came back: the status is polled only
/// while someone can see it.
final class ScanHomeVisibilityChanged extends ScanHomeEvent {
  final bool isVisible;

  const ScanHomeVisibilityChanged({required this.isVisible});
}

final class StatusTapped extends ScanHomeEvent {
  const StatusTapped();
}

final class TakePhotoPressed extends ScanHomeEvent {
  const TakePhotoPressed();
}

final class PickPhotoPressed extends ScanHomeEvent {
  const PickPhotoPressed();
}

/// The history stream delivered a new list of recent scans.
final class RecentScansChanged extends ScanHomeEvent {
  final List<ScanHistoryItem> items;

  const RecentScansChanged({required this.items});
}

final class RecentScanTapped extends ScanHomeEvent {
  final int scanId;

  const RecentScanTapped({required this.scanId});
}

final class AllScansPressed extends ScanHomeEvent {
  const AllScansPressed();
}
