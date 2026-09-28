part of 'scan_result_bloc.dart';

sealed class ScanResultEvent {
  const ScanResultEvent();
}

final class StartScanResult extends ScanResultEvent {
  final ScanResultArgs args;

  const StartScanResult({required this.args});
}

/// The session for reference images became available.
final class ReferenceAccessLoaded extends ScanResultEvent {
  final ReferenceAccess access;

  const ReferenceAccessLoaded({required this.access});
}

/// The system back gesture or button.
final class BackPressed extends ScanResultEvent {
  const BackPressed();
}

final class RetryPressed extends ScanResultEvent {
  const RetryPressed();
}

final class NewPhotoPressed extends ScanResultEvent {
  const NewPhotoPressed();
}

/// The source sheet was answered (null: dismissed).
final class NewPhotoSourceChosen extends ScanResultEvent {
  final PhotoSource? source;

  const NewPhotoSourceChosen({required this.source});
}

/// A bottle frame or chip was tapped; null means "all bottles".
final class BottleSelected extends ScanResultEvent {
  final String? instanceId;

  const BottleSelected({required this.instanceId});
}

final class RescanBottlePressed extends ScanResultEvent {
  final String instanceId;

  const RescanBottlePressed({required this.instanceId});
}

final class RescanHintDismissed extends ScanResultEvent {
  const RescanHintDismissed();
}

final class DrawModeToggled extends ScanResultEvent {
  const DrawModeToggled();
}

/// A frame was drawn or moved; in EXIF-oriented frame pixels.
final class DraftChanged extends ScanResultEvent {
  final BottleBox draft;

  const DraftChanged({required this.draft});
}

final class DraftCleared extends ScanResultEvent {
  const DraftCleared();
}

final class DraftEditToggled extends ScanResultEvent {
  const DraftEditToggled();
}

final class DraftRecognizePressed extends ScanResultEvent {
  const DraftRecognizePressed();
}

final class BackToAllPressed extends ScanResultEvent {
  const BackToAllPressed();
}

final class CardLinkPressed extends ScanResultEvent {
  final String url;

  const CardLinkPressed({required this.url});
}

final class CompareTapped extends ScanResultEvent {
  final String instanceId;
  final WineCard card;

  const CompareTapped({required this.instanceId, required this.card});
}

final class MorePressed extends ScanResultEvent {
  const MorePressed();
}

/// The "more" sheet was answered (null: dismissed).
final class MoreOptionChosen extends ScanResultEvent {
  final ResultMoreOption? option;

  const MoreOptionChosen({required this.option});
}

final class ClosePressed extends ScanResultEvent {
  const ClosePressed();
}

/// One second of the auto-retry countdown passed.
final class RetryTicked extends ScanResultEvent {
  const RetryTicked();
}
