import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../../../constants/app_constants.dart';
import 'api_endpoints.dart';
import 'logging_interceptor.dart';

/// One HTTP call. A request carries either a JSON [requestBody] or a
/// multipart [formData], never both.
class ApiServiceRequest {
  final ApiEndpoint endpoint;
  final HTTPMethod method;
  final String Function()? pathBuilder;
  final Map<String, dynamic>? requestBody;
  final FormData? formData;
  final Map<String, dynamic>? queryParams;
  final Map<String, String>? headers;

  /// Lets the caller abandon a request that is no longer wanted (a newer
  /// photo, a closed screen).
  final CancelToken? cancelToken;

  /// Overrides the client default when one call legitimately takes longer,
  /// such as recognition, which is queued on the server.
  final Duration? receiveTimeout;

  /// Overrides the client default for a large upload (a photo on a slow
  /// connection).
  final Duration? sendTimeout;

  const ApiServiceRequest({
    required this.endpoint,
    required this.method,
    this.requestBody,
    this.formData,
    this.queryParams,
    this.headers,
    this.pathBuilder,
    this.cancelToken,
    this.receiveTimeout,
    this.sendTimeout,
  }) : assert(
         requestBody == null || formData == null,
         'A request sends either JSON or multipart, not both',
       );
}

/// Transport for one backend. Knows about URL, headers, timeouts, proxy and
/// interceptors; knows nothing about endpoints or models.
class ApiService {
  final Dio _dio = Dio();
  final Map<String, String> _commonHeaders;

  /// [proxyIp] is a debugging aid for capturing traffic and is only ever
  /// passed for the dev flavor; the accompanying certificate bypass never
  /// reaches a prod build because the parameter stays null there.
  ApiService(
    String baseUrl,
    Map<String, String> commonHeaders, {
    required bool logBodies,
    String? proxyIp,
  }) : _commonHeaders = commonHeaders {
    _dio
      ..interceptors.add(LoggingInterceptor(logBodies: logBodies))
      ..options = BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: ApiConstants.defaultTimeout,
        sendTimeout: ApiConstants.defaultTimeout,
        receiveTimeout: ApiConstants.defaultTimeout,
        headers: {Headers.contentTypeHeader: Headers.jsonContentType},
      );
    if (proxyIp != null) {
      _dio.setupProxyIP(proxyIp);
    }
  }

  /// Interceptors added after construction sit before the logger, so the log
  /// shows the request exactly as it leaves (with the auth header redacted).
  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.insert(0, interceptor);
  }

  Future<Response<dynamic>> performRequest(ApiServiceRequest request) async {
    final String path = request.pathBuilder?.call() ?? request.endpoint.path;
    final Map<String, String> combinedHeaders = {
      ...?request.headers,
      ..._commonHeaders,
    };
    final options = Options(
      headers: combinedHeaders,
      receiveTimeout: request.receiveTimeout,
      sendTimeout: request.sendTimeout,
      // Multipart content type (with its boundary) is set by dio itself.
      contentType: request.formData != null ? null : Headers.jsonContentType,
    );
    final Object? data = request.formData ?? request.requestBody;

    switch (request.method) {
      case HTTPMethod.get:
        return _dio.get(
          path,
          queryParameters: request.queryParams,
          options: options,
          cancelToken: request.cancelToken,
        );
      case HTTPMethod.put:
        return _dio.put(
          path,
          data: data,
          queryParameters: request.queryParams,
          options: options,
          cancelToken: request.cancelToken,
        );
      case HTTPMethod.patch:
        return _dio.patch(
          path,
          data: data,
          queryParameters: request.queryParams,
          options: options,
          cancelToken: request.cancelToken,
        );
      case HTTPMethod.post:
        return _dio.post(
          path,
          data: data,
          queryParameters: request.queryParams,
          options: options,
          cancelToken: request.cancelToken,
        );
      case HTTPMethod.delete:
        return _dio.delete(
          path,
          data: data,
          queryParameters: request.queryParams,
          options: options,
          cancelToken: request.cancelToken,
        );
    }
  }

  /// Re-sends a request as it was built, for an interceptor that has to retry
  /// after refreshing credentials.
  Future<Response<dynamic>> fetch(RequestOptions options) =>
      _dio.fetch(options);
}

extension DioProxy on Dio {
  void setupProxyIP(String proxyIP) {
    (httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient()..idleTimeout = DurationConstant.d3s;
      client.findProxy = (uri) => 'PROXY $proxyIP:8888';
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }
}
