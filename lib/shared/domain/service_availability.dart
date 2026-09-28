import '../../core/services/api/models/app_error.dart';
import '../../core/services/api/models/result.dart';
import 'models/service_status.dart';

/// What the status pill says about the recognition service. Computed by a
/// bloc from `GET /api/status`, drawn by `ServiceStatusPill`.
enum ServiceAvailability {
  checking,
  ready,
  busy,
  down,
  unavailable,
  noAccess,
  rateLimited,
  offline,
  dev;

  bool get canRecognize => this == ready || this == busy;
}

/// The pill's content: the kind plus, when busy, how many wait ahead.
class ServiceState {
  final ServiceAvailability availability;
  final int waiting;

  const ServiceState({required this.availability, this.waiting = 0});

  static const ServiceState checking = ServiceState(
    availability: ServiceAvailability.checking,
  );

  /// The same reading of the status the web UI does (`refreshStatus`).
  static ServiceState fromResult(Result<ServiceStatus> result) {
    switch (result) {
      case Success<ServiceStatus>(:final data):
        if (data.devMode) {
          return const ServiceState(availability: ServiceAvailability.dev);
        }
        if (!data.backendReachable) {
          return const ServiceState(availability: ServiceAvailability.down);
        }
        if (!data.profileMatch) {
          return const ServiceState(
            availability: ServiceAvailability.unavailable,
          );
        }
        if (data.isBusy) {
          return ServiceState(
            availability: ServiceAvailability.busy,
            waiting: data.waiting,
          );
        }
        return const ServiceState(availability: ServiceAvailability.ready);
      case Error<ServiceStatus>(:final error):
        return ServiceState(availability: _fromError(error));
    }
  }

  static ServiceAvailability _fromError(AppError error) {
    if (error is ApiError) {
      if (error.isConnectionIssue) return ServiceAvailability.offline;
      return switch (error.errorCode) {
        401 => ServiceAvailability.noAccess,
        429 => ServiceAvailability.rateLimited,
        _ => ServiceAvailability.unavailable,
      };
    }
    return ServiceAvailability.unavailable;
  }
}
