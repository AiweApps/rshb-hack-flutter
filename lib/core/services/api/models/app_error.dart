import 'dart:core';

import 'package:dio/dio.dart';

/// Technical cause of a failed call. Never shown to the user as is: the bloc
/// maps it to an `ErrorType` or a screen-specific failure, and the text comes
/// from the ARB.
sealed class AppError {
  AppError();

  /// Debug description for logs and Crashlytics — not for the UI.
  String getErrorMessage() {
    String result = "";
    if (this is ApiError) {
      final apiError = this as ApiError;
      result =
          "Api error: ${[apiError.errorMessage, apiError.exceptionType, apiError.errorCode, apiError.errorKey].nonNulls.join(";\n")}";
    } else if (this is DefaultError) {
      result =
          (this as DefaultError).errorMessage ??
          (this as DefaultError).exception.toString();
    } else if (this is ParsingError) {
      result = (this as ParsingError).exception.toString();
    }
    return result;
  }
}

class ApiError extends AppError {
  final Exception? exception;
  final DioExceptionType? exceptionType;
  final String? errorMessage;
  final int? errorCode;

  /// Machine-readable code from the body (`{"error": "busy"}`), when the
  /// backend sent one.
  final String? errorKey;

  /// Human text from the body. Technical and untranslated: logged, not shown.
  final String? serverMessage;

  /// When the backend asked to come back later (429, busy 503).
  final Duration? retryAfter;

  ApiError({
    this.exception,
    this.exceptionType,
    this.errorMessage,
    this.errorCode,
    this.errorKey,
    this.serverMessage,
    this.retryAfter,
  });

  bool get isCancelled => exceptionType == DioExceptionType.cancel;

  bool get isTimeout =>
      exceptionType == DioExceptionType.connectionTimeout ||
      exceptionType == DioExceptionType.sendTimeout ||
      exceptionType == DioExceptionType.receiveTimeout;

  bool get isConnectionIssue =>
      isTimeout || exceptionType == DioExceptionType.connectionError;
}

/// The answer did not match the model. Holds an [Object]: a type mismatch in
/// generated `fromJson` throws a `TypeError`, which is an `Error`, not an
/// `Exception`, and it is exactly the contract drift this class is for.
class ParsingError extends AppError {
  final Object exception;

  ParsingError({required this.exception});
}

class DefaultError extends AppError {
  final Exception exception;
  final String? errorMessage;

  DefaultError({required this.exception, this.errorMessage});
}
