import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../constants/app_constants.dart';
import '../api/service/api_endpoints.dart';

const String _keyGuestToken = 'guest_access_token';
const String _keyGuestTokenExpiresAt = 'guest_access_token_expires_at';

/// Anonymous 24-hour session of the recognition API (docs/mobile-api.md).
///
/// The token lives in the OS secure storage and is handed to the auth
/// interceptor on every request. It is not an identity: the backend issues a
/// fresh guest on every call to the token endpoint, so the app keeps one and
/// only asks for another when the current one expired or was rejected.
class GuestSessionService {
  final FlutterSecureStorage _storage;

  /// Plain client on purpose: the token call must not go through the auth
  /// interceptor that depends on this service.
  final Dio _dio;

  String? _token;
  DateTime? _expiresAt;
  bool _loaded = false;

  // Several requests hitting 401 at once must share one refresh, or each
  // would invalidate the token the previous one just obtained.
  Future<String>? _refreshing;

  GuestSessionService({
    required String apiBaseUrl,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _dio = Dio(
         BaseOptions(
           baseUrl: apiBaseUrl,
           connectTimeout: ApiConstants.guestTokenTimeout,
           receiveTimeout: ApiConstants.guestTokenTimeout,
         ),
       );

  /// A token that is valid for at least [ApiConstants.guestTokenExpiryMargin]
  /// more, fetching a new one when needed.
  Future<String> validToken() async {
    await _loadOnce();
    final token = _token;
    final expiresAt = _expiresAt;
    if (token != null &&
        expiresAt != null &&
        expiresAt.isAfter(
          DateTime.now().add(ApiConstants.guestTokenExpiryMargin),
        )) {
      return token;
    }
    return refreshToken();
  }

  /// Drops the current token and obtains a new one. Concurrent callers get
  /// the same future.
  Future<String> refreshToken() {
    return _refreshing ??= _fetchToken().whenComplete(() => _refreshing = null);
  }

  Future<void> _loadOnce() async {
    if (_loaded) return;
    _loaded = true;
    try {
      _token = await _storage.read(key: _keyGuestToken);
      final raw = await _storage.read(key: _keyGuestTokenExpiresAt);
      _expiresAt = raw == null ? null : DateTime.tryParse(raw);
    } on Exception catch (e) {
      // Unreadable storage (a restored backup, a changed keychain group) just
      // means a new guest session; nothing of value is lost.
      debugPrint('Guest token storage unreadable: $e');
      _token = null;
      _expiresAt = null;
    }
  }

  Future<String> _fetchToken() async {
    final response = await _dio.post<Map<String, dynamic>>(
      GuestToken().path,
      data: const <String, dynamic>{},
    );
    final body = response.data;
    final token = body?[_TokenKeys.accessToken];
    final expiresIn = body?[_TokenKeys.expiresIn];
    if (token is! String || token.isEmpty || expiresIn is! num) {
      throw const FormatException('Guest token response is incomplete');
    }
    _token = token;
    _expiresAt = DateTime.now().add(Duration(seconds: expiresIn.toInt()));
    await _persist(token, _expiresAt!);
    return token;
  }

  // The token is usable from memory as soon as it arrived; a keychain that
  // refuses to store it (a simulator without the entitlement) only costs a
  // new guest session on the next launch.
  Future<void> _persist(String token, DateTime expiresAt) async {
    try {
      await _storage.write(key: _keyGuestToken, value: token);
      await _storage.write(
        key: _keyGuestTokenExpiresAt,
        value: expiresAt.toIso8601String(),
      );
    } on Exception catch (e) {
      debugPrint('Guest token not persisted: $e');
    }
  }
}

class _TokenKeys {
  static const String accessToken = 'access_token';
  static const String expiresIn = 'expires_in';
}
