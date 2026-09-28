class MusicApiParserException implements Exception {
  final String message;
  final bool noData;

  MusicApiParserException(this.message, this.noData);

  @override
  String toString() => 'GraphqlApiParserException: $message';
}

class MusicApiParser {
  /// Safely extracts a value from a JSON map using a key path.
  /// Key path can be provided as a dot-separated string (e.g., "data.Account.signIn")
  static T get<T>(dynamic json, {required String keyPath}) {
    if (json == null) {
      throw MusicApiParserException('JSON data is null', true);
    }

    final pathKeys = keyPath.split('.');
    if (pathKeys.isEmpty) return _validateType<T>(json);

    dynamic value = json;
    String currentPath = '';

    for (final key in pathKeys) {
      currentPath = currentPath.isEmpty ? key : '$currentPath.$key';

      if (value is! Map<String, dynamic>) {
        throw MusicApiParserException(
          'Expected Map at "$currentPath" but found ${value.runtimeType}',
          false,
        );
      }

      value = value[key];
      if (value == null) {
        throw MusicApiParserException(
          'Required key "$currentPath" not found or null',
          true,
        );
      }
    }

    return _validateType<T>(value);
  }

  /// Validates and converts the value to the expected type T
  static T _validateType<T>(dynamic value) {
    if (value == null) {
      throw MusicApiParserException('Required value is null', true);
    }

    // Handle primitive types
    if (value is T) {
      return value;
    }

    throw MusicApiParserException(
      'Expected $T but found ${value.runtimeType}',
      false,
    );
  }

  /// Safely extracts a list from JSON and maps it to objects
  static List<R> getList<R>(
    dynamic json, {
    required String keyPath,
    required R Function(Map<String, dynamic>) fromJson,
  }) {
    try {
      final list = get<List>(json, keyPath: keyPath);
      return list
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Safely extracts and parses a single object from JSON
  static R getObject<R>(
    dynamic json, {
    required String keyPath,
    required R Function(Map<String, dynamic>) fromJson,
  }) {
    try {
      final map = get<Map<String, dynamic>>(json, keyPath: keyPath);
      return fromJson(map);
    } catch (e) {
      rethrow;
    }
  }
}
