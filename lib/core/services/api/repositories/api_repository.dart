import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../constants/app_constants.dart';
import '../models/app_error.dart';
import '../models/result.dart';
import '../service/api_service.dart';

/// Turns a transport call into a [Result]: status codes, JSON decoding and
/// exceptions all end up as an [AppError]. Feature repositories build on it
/// and never write their own try/catch around a call.
class ApiRepository {
  final ApiService _apiService;

  ApiRepository(this._apiService);

  Future<Result<T>> handleAPICall<T>({
    required ApiServiceRequest apiRequest,
    required T Function(dynamic) fromJson,
    ApiError? Function(dynamic)? validateJson,
  }) async {
    try {
      final Response response = await _apiService.performRequest(apiRequest);
      if ((response.statusCode ?? 0).isSuccessfulOrRedirectStatus) {
        return _parseServerResponse(fromJson, validateJson, response);
      } else {
        return Error(error: _apiErrorFrom(response));
      }
    } on Exception catch (e) {
      return _handleApiException(e);
    }
  }

  Result<T> _parseServerResponse<T>(
    T Function(dynamic) fromJson,
    ApiError? Function(dynamic)? validateJson,
    Response<dynamic> response,
  ) {
    try {
      final decodedData = _decoded(response.data);
      final apiError = validateJson?.call(decodedData);
      if (apiError != null) {
        return Error(error: apiError);
      }
      final parsedData = fromJson.call(decodedData);
      return Success<T>(data: parsedData);
    } catch (e) {
      // Anything thrown while reading the body is a contract mismatch,
      // including the `TypeError` a generated `fromJson` throws on a wrong
      // type — an `Error`, which `on Exception` would let through.
      return Error(error: ParsingError(exception: e));
    }
  }

  Result<T> _handleApiException<T>(Exception e) {
    if (e is DioException) {
      final response = e.response;
      final body = _errorBody(response?.data);
      return Error(
        error: ApiError(
          exception: e,
          exceptionType: e.type,
          errorCode: response?.statusCode,
          errorMessage: response?.statusMessage,
          errorKey: body?[_ErrorBodyKeys.error]?.toString(),
          serverMessage: body?[_ErrorBodyKeys.message]?.toString(),
          retryAfter: _retryAfter(response, body),
        ),
      );
    } else {
      return Error(error: DefaultError(exception: e));
    }
  }

  ApiError _apiErrorFrom(Response<dynamic> response) {
    final body = _errorBody(response.data);
    return ApiError(
      errorCode: response.statusCode,
      errorMessage: response.statusMessage,
      errorKey: body?[_ErrorBodyKeys.error]?.toString(),
      serverMessage: body?[_ErrorBodyKeys.message]?.toString(),
      retryAfter: _retryAfter(response, body),
    );
  }

  // dio decodes JSON responses itself; a string is either an empty body or
  // JSON that arrived under a text content type.
  dynamic _decoded(dynamic data) {
    if (data is String) {
      return json.decode(data.isEmpty ? '{}' : data);
    }
    return data;
  }

  Map<String, dynamic>? _errorBody(dynamic data) {
    try {
      final decoded = _decoded(data);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  // The header wins over the body; both are whole seconds.
  Duration? _retryAfter(Response<dynamic>? response, Map<String, dynamic>? b) {
    final header = response?.headers.value(ApiConstants.retryAfterHeader);
    final seconds =
        int.tryParse(header ?? '') ??
        (b?[_ErrorBodyKeys.retryAfter] as num?)?.toInt();
    return seconds == null ? null : Duration(seconds: seconds);
  }
}

class _ErrorBodyKeys {
  static const String error = 'error';
  static const String message = 'message';
  static const String retryAfter = 'retry_after';
}

extension HTTPStatusCode on int {
  bool get isSuccessfulOrRedirectStatus => this >= 200 && this <= 399;

  bool get isUnauthorizedStatusCode => this == 401 || this == 403;
}
