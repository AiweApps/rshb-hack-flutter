import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  LoggingInterceptor();

  @override
  Future onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    _logPrint('*** API Request - Start ***');
    _printKV('URI', options.uri);
    _printKV('METHOD', options.method);
    _logPrint('HEADERS:');
    options.headers.forEach((key, v) => _printKV(' - $key', v));
    _logPrint('BODY:');
    _printAll(options.data ?? '');
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
    if (err.response != null) {
      _printKV('REDIRECT', err.response?.realUri ?? '');
      _logPrint('BODY:');
      _printAll(err.response?.data.toString());
    }

    _logPrint('*** Api Error - End ***:');

    return handler.next(err);
  }

  @override
  Future onResponse(
      Response response, ResponseInterceptorHandler handler) async {
    _logPrint('*** Api Response - Start ***');

    _printKV('URI', response.requestOptions.uri);
    _printKV('STATUS CODE', response.statusCode ?? '');
    _printKV('REDIRECT', response.isRedirect);
    _logPrint('BODY:');
    _printAll(response.data ?? '');

    _logPrint('*** Api Response - End ***');

    return handler.next(response);
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
