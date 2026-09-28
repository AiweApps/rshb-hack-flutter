/// What the result screen is opened with: a fresh photo to recognise, or a
/// scan from the history to show again.
sealed class ScanResultArgs {
  const ScanResultArgs();
}

final class NewScanArgs extends ScanResultArgs {
  /// Path of the picked photo, already downsized for upload.
  final String photoPath;

  const NewScanArgs({required this.photoPath});
}

final class StoredScanArgs extends ScanResultArgs {
  final int scanId;

  const StoredScanArgs({required this.scanId});
}
