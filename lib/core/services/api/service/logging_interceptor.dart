import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../constants/app_constants.dart';

/// The one place requests are printed. Bodies are printed only when the
/// flavor allows it; the authorization header is never printed.
class LoggingInterceptor extends Interceptor {
  final bool logBodies;

  LoggingInterceptor({required this.logBodies});

  @override
  Future onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    _logPrint('*** API Request - Start ***');
    _printKV('URI', options.uri);
    _printKV('METHOD', options.method);
    _logPrint('HEADERS:');
    options.headers.forEach((key, v) => _printKV(' - $key', _redact(key, v)));
    if (logBodies) {
      _logPrint('BODY:');
      _printAll(_describeBody(options.data));
    }
    _logPrint('*** API Request - End ***');
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logPrint('*** Api Error - Start ***:');
    _logPrint('URI: ${err.requestOptions.uri}');
    if (err.response != null) {
      _logPrint('STATUS CODE: ${err.response?.statusCode?.toString()}');
    }
    _logPrint('$err');
    if (err.response != null && logBodies) {
      _logPrint('BODY:');
      _printAll(err.response?.data.toString());
    }
    _logPrint('*** Api Error - End ***:');
    return handler.next(err);
  }

  @override
  Future onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    _logPrint('*** Api Response - Start ***');
    _printKV('URI', response.requestOptions.uri);
    _printKV('STATUS CODE', response.statusCode ?? '');
    if (logBodies) {
      _logPrint('BODY:');
      _printAll(response.data ?? '');
    }
    _logPrint('*** Api Response - End ***');
    return handler.next(response);
  }

  Object _redact(String key, Object? value) {
    if (key.toLowerCase() == ApiConstants.authorizationHeader.toLowerCase()) {
      return '<redacted>';
    }
    return value ?? '';
  }

  // A multipart body is a photo: printing megabytes of bytes helps nobody.
  String _describeBody(Object? data) {
    if (data is FormData) {
      final fields = data.fields.map((f) => '${f.key}=${f.value}').join(', ');
      final files = data.files
          .map((f) => '${f.key}=<${f.value.length} bytes>')
          .join(', ');
      return 'multipart: $fields $files';
    }
    return data?.toString() ?? '';
  }

  void _printKV(String key, Object v) {
    _logPrint('$key: $v');
  }

  void _printAll(dynamic msg) {
    msg.toString().split('\n').forEach(_logPrint);
  }

  void _logPrint(String s) {
    debugPrint(s);
  }
}
