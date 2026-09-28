import 'package:dio/dio.dart';

import '../../constants/app_constants.dart';
import '../api/service/api_service.dart';
import 'guest_session_service.dart';

/// Puts the guest Bearer on every request and, on a 401, refreshes the token
/// and repeats the request exactly once (docs/mobile-api.md §3).
///
/// Queued so that parallel requests wait for one token instead of each
/// asking for its own.
class AuthInterceptor extends QueuedInterceptor {
  static const String _retriedKey = 'auth_retried';

  final GuestSessionService _session;
  final ApiService _apiService;

  AuthInterceptor(this._session, this._apiService);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _session.validToken();
      options.headers[ApiConstants.authorizationHeader] =
          '${ApiConstants.bearerPrefix}$token';
      handler.next(options);
    } on DioException catch (e) {
      // Could not get a session: the request fails with the transport error
      // of the token call, which the bloc classifies like any other.
      handler.reject(
        DioException(requestOptions: options, error: e, type: e.type),
      );
    } on Exception catch (e) {
      handler.reject(DioException(requestOptions: options, error: e));
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final unauthorized = err.response?.statusCode == 401;
    if (!unauthorized || options.extra[_retriedKey] == true) {
      handler.next(err);
      return;
    }
    try {
      final token = await _session.refreshToken();
      options.extra[_retriedKey] = true;
      options.headers[ApiConstants.authorizationHeader] =
          '${ApiConstants.bearerPrefix}$token';
      handler.resolve(await _apiService.fetch(options));
    } on DioException catch (e) {
      handler.next(e);
    } on Exception {
      handler.next(err);
    }
  }
}
