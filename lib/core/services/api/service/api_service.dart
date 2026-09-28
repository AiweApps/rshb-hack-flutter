import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'api_endpoints.dart';
import 'logging_interceptor.dart';

class ApiServiceRequest {
  ApiEndpoint endpoint;
  HTTPMethod method;
  String Function()? pathBuilder;
  Map<String, dynamic>? requestBody;
  Map<String, dynamic>? queryParams;
  Map<String, String>? headers;

  ApiServiceRequest({
    required this.endpoint,
    required this.method,
    this.requestBody,
    this.queryParams,
    this.headers,
    this.pathBuilder,
  });
}

class ApiService {
  final _dio = Dio();
  final bool _useProxy = false;
  final String _proxyIP = "192.168.1.61";
  Map<String, String> commonHeaders;

  ApiService(String baseUrl, this.commonHeaders) {
    _dio
      ..interceptors.add(LoggingInterceptor())
      ..options = (BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        baseUrl: baseUrl,
      )..headers = {"Content-Type": "application/json"});
    if (_useProxy) {
      _dio.setupProxyIP(_proxyIP);
    }
  }

  Future<Response<String>> performRequest(ApiServiceRequest request) async {
    final String path;
    if (request.pathBuilder != null) {
      path = request.pathBuilder!();
    } else {
      path = request.endpoint.path;
    }
    final Map<String, String> combinedHeaders = {
      if (request.headers != null) ...request.headers ?? <String, dynamic>{}
    };
    combinedHeaders.addAll(commonHeaders);
    final options = Options(headers: combinedHeaders);
    switch (request.method) {
      case HTTPMethod.get:
        return _dio.get(path,
            queryParameters: request.queryParams, options: options);
      case HTTPMethod.put:
        return _dio.put(path, data: request.requestBody, options: options);
      case HTTPMethod.patch:
        return _dio.patch(path, data: request.requestBody, options: options);
      case HTTPMethod.post:
        return _dio.post(path, data: request.requestBody, options: options);
      case HTTPMethod.delete:
        return _dio.delete(path, data: request.requestBody, options: options);
    }
  }
}

extension DioProxy on Dio {
  void setup(String baseUrl) {
    options = BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      baseUrl: baseUrl,
    );
    options.headers = {
      "Content-Type": "application/json",
    };
  }

  void setupProxyIP(String proxyIP) {
    // ignore: deprecated_member_use
    // This is used for network requests proxy
    (httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient()..idleTimeout = const Duration(seconds: 3);
      client.findProxy = (uri) {
        return "PROXY $proxyIP:8888";
      };
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }
}
