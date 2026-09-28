import '../../../../../core/application/bloc/base_bloc_uieffect.dart';
import '../../../../../shared/domain/service_availability.dart';

sealed class ScanHomeUiEffect extends BaseBlocUiEffect {}

final class ShowStatusDetail extends ScanHomeUiEffect {
  final ServiceAvailability availability;

  ShowStatusDetail({required this.availability});
}

final class OpenNewScan extends ScanHomeUiEffect {
  final String photoPath;

  OpenNewScan({required this.photoPath});
}

final class OpenStoredScan extends ScanHomeUiEffect {
  final int scanId;

  OpenStoredScan({required this.scanId});
}

final class OpenHistory extends ScanHomeUiEffect {}

/// The system settings page of the app, where a refused permission lives.
final class OpenAppSettings extends ScanHomeUiEffect {}
