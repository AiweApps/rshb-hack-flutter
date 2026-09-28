import 'app_error.dart';

sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;

  const Success({required this.data});
}

class Error<T> extends Result<T> {
  final AppError error;

  const Error({required this.error});
}
