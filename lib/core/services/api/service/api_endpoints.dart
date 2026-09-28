abstract class ApiEndpoint {
  String get path => "";
}

enum HTTPMethod {
  get,
  put,
  patch,
  post,
  delete;
}
