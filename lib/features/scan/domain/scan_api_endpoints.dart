import '../../../core/services/api/service/api_endpoints.dart';

/// `POST /api/recognize` — multipart `image` plus optional `target_roi`.
class Recognize extends ApiEndpoint {
  @override
  String get path => '/api/recognize';
}

/// `GET /api/status` — readiness, queue and limits of the service.
class ServiceStatusEndpoint extends ApiEndpoint {
  @override
  String get path => '/api/status';
}
