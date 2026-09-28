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

/// «Новый скан»: back to the scanner tab.
final class NewScanPressed extends ScanResultEvent {
  const NewScanPressed();
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

/// «Рамка» in the toolbar: open the sheet to draw one.
final class DrawFramePressed extends ScanResultEvent {
  const DrawFramePressed();
}

/// The frame sheet handed back a frame; in EXIF-oriented frame pixels.
final class FrameDrawn extends ScanResultEvent {
  final BottleBox roi;

  const FrameDrawn({required this.roi});
}

final class BackToAllPressed extends ScanResultEvent {
  const BackToAllPressed();
}

final class CardLinkPressed extends ScanResultEvent {
  final String url;

  const CardLinkPressed({required this.url});
}

/// «Сравнить» in the toolbar: the selected bottle against its best match.
final class ComparePressed extends ScanResultEvent {
  const ComparePressed();
}

/// A card's preview was tapped: that bottle against [card].
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
