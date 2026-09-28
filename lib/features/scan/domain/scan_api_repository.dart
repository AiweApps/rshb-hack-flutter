import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/api/models/app_error.dart';
import '../../../core/services/api/models/result.dart';
import '../../../core/services/api/repositories/api_repository.dart';
import '../../../core/services/api/service/api_endpoints.dart';
import '../../../core/services/api/service/api_service.dart';
import '../../../core/services/auth/guest_session_service.dart';
import '../../../shared/domain/models/service_status.dart';
import 'models/bottle_box.dart';
import 'models/recognition_view.dart';
import 'models/reference_access.dart';
import 'scan_api_endpoints.dart';

/// Recognition API: the photo goes up, the `view` comes back.
///
/// Strategy: network-only. A scan is a fresh answer by definition; what the
/// user wants to see again is stored by the history repository.
class ScanApiRepository extends ApiRepository {
  final GuestSessionService _session;
  final String _apiBaseUrl;

  ScanApiRepository(
    super.apiService, {
    required GuestSessionService session,
    required String apiBaseUrl,
  }) : _session = session,
       _apiBaseUrl = apiBaseUrl;

  /// Uploads [imagePath]; with [targetRoi] the service answers for that box
  /// only (`explicit_roi` mode).
  Future<Result<RecognitionView>> recognize({
    required String imagePath,
    BottleBox? targetRoi,
    CancelToken? cancelToken,
  }) async {
    final FormData formData;
    try {
      formData = FormData.fromMap({
        ApiConstants.imageField: await MultipartFile.fromFile(
          imagePath,
          filename: ApiConstants.uploadFileName,
        ),
        if (targetRoi != null)
          ApiConstants.targetRoiField: json.encode(targetRoi.toList()),
      });
    } on Exception catch (e) {
      // The file vanished between picking and uploading (the OS cleaned the
      // cache, the app was restored): a local failure, not a server one.
      return Error(error: DefaultError(exception: e));
    }

    final request = ApiServiceRequest(
      endpoint: Recognize(),
      method: HTTPMethod.post,
      formData: formData,
      cancelToken: cancelToken,
      receiveTimeout: ApiConstants.recognizeTimeout,
      sendTimeout: ApiConstants.recognizeTimeout,
    );

    return handleAPICall(
      apiRequest: request,
      fromJson: (json) => RecognitionView.fromJson(
        (json as Map<String, dynamic>)[_ResponseKeys.view]
            as Map<String, dynamic>,
      ),
    );
  }

  Future<Result<ServiceStatus>> status({CancelToken? cancelToken}) {
    final request = ApiServiceRequest(
      endpoint: ServiceStatusEndpoint(),
      method: HTTPMethod.get,
      cancelToken: cancelToken,
    );

    return handleAPICall(
      apiRequest: request,
      fromJson: (json) => ServiceStatus.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Origin and Bearer for reference thumbnails, which sit behind the same
  /// auth as the API. Asked for once per result screen, so a rotated token
  /// is picked up the next time a result is shown.
  Future<ReferenceAccess> referenceAccess() async {
    final token = await _session.validToken();
    return ReferenceAccess(
      baseUrl: _apiBaseUrl,
      headers: {
        ApiConstants.authorizationHeader: '${ApiConstants.bearerPrefix}$token',
      },
    );
  }
}

class _ResponseKeys {
  static const String view = 'view';
}
