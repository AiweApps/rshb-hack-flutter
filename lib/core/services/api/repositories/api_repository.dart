import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/app_error.dart';
import '../models/result.dart';
import '../service/api_service.dart';

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
        return Error(
          error: ApiError(
            errorCode: response.statusCode,
            errorMessage: response.statusMessage,
          ),
        );
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
      var data = response.data;
      if ((data is String) && data.isEmpty) {
        data = "{}";
      }
      final decodedData = json.decode(data);
      final apiError = validateJson?.call(decodedData);
      if (apiError != null) {
        return Error(error: apiError);
      }
      final parsedData = fromJson.call(decodedData);
      return Success<T>(data: parsedData);
    } on Exception catch (e) {
      // This is server response parse to model error case
      return Error(error: ParsingError(exception: e));
    }
  }

  Result<T> _handleApiException<T>(Exception e) {
    if (e is DioException) {
      return Error(
        error: ApiError(
          exception: e,
          exceptionType: e.type,
          errorCode: e.response?.statusCode,
          errorMessage: e.response?.statusMessage,
        ),
      );
    } else {
      return Error(error: DefaultError(exception: e));
    }
  }
}

extension HTTPStatusCode on int {
  bool get isSuccessfulOrRedirectStatus => this >= 200 && this <= 399;

  bool get isUnauthorizedStatusCode => this == 401 || this == 403;
}
