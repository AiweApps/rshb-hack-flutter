abstract class ApiEndpoint {
  String get path => "";
}

enum HTTPMethod { get, put, patch, post, delete }

/// `POST /auth/guest/token` — an anonymous 24-hour Bearer, no body.
class GuestToken extends ApiEndpoint {
  @override
  String get path => '/auth/guest/token';
}
