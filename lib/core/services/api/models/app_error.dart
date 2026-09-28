import 'dart:core';
import 'package:dio/dio.dart';

sealed class AppError {
  AppError();

  String getErrorMessage() {
    String result = "";
    if (this is ApiError) {
      final apiError = this as ApiError;
      result = "Api error: ${[
        apiError.errorMessage,
        apiError.exceptionType,
        apiError.errorCode
      ].nonNulls.join(";\n")}";
    } else if (this is DefaultError) {
      result = (this as DefaultError).errorMessage ??
          (this as DefaultError).exception.toString();
    } else if (this is ParsingError) {
      result = (this as ParsingError).exception.toString();
    } else if (this is StringError) {
      result = (this as StringError).errorMessage;
    }
    return result;
  }

  int? getErrorCode() {
    if (this is ApiError) {
      return (this as ApiError).errorCode;
    }
    return null;
  }

  Exception? getException() {
    if (this is ApiError) {
      return (this as ApiError).exception;
    } else if (this is DefaultError) {
      return (this as DefaultError).exception;
    }
    return null;
  }
}

class ApiError extends AppError {
  final Exception? exception;
  final DioExceptionType? exceptionType;
  final String? errorMessage;
  final int? errorCode;

  ApiError(
      {this.exception, this.exceptionType, this.errorMessage, this.errorCode});
}

class ParsingError extends AppError {
  final Exception exception;

  ParsingError({
    required this.exception,
  });
}

class DefaultError extends AppError {
  Exception exception;
  String? errorMessage;

  DefaultError({required this.exception, this.errorMessage});
}

class StringError extends AppError {
  String errorMessage;

  StringError({required this.errorMessage});
}
