import 'dart:convert';

import 'package:flutter/services.dart';

/// Source-asserted dishes and serving temperature for a catalogue slug.
///
/// The bundle uses exact API details from 15 October 2026 and five preserved
/// responses from 21 September 2026. A missing slug means unknown data, not
/// an empty recommendation. Call [load] before reading any entry.
class GastronomyCatalog {
  static const assetPath = 'assets/data/gastronomy_catalog_v1.json';
  static const _kind = 'rshb-flutter-gastronomy-catalog-v1';

  final AssetBundle _bundle;
  Map<String, _GastronomyEntry>? _entries;
  List<String>? _allDishes;
  Future<void>? _loading;

  GastronomyCatalog({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  Future<void> load() async {
    if (_entries != null) return;
    final pending = _loading ??= _read();
    try {
      await pending;
    } catch (_) {
      _loading = null;
      rethrow;
    }
  }

  /// Null means no source record; [] means the source verified no dishes.
  List<String>? dishesFor(String slug) => _loaded[slug]?.dishes;

  /// Exact source range, without a unit suffix; null means unknown.
  String? temperatureFor(String slug) => _loaded[slug]?.temperature;

  /// Exact source `color` text; null means unknown.
  String? colorFor(String slug) => _loaded[slug]?.color;

  /// Exact source `category.name` text; null means unknown.
  String? sourceCategoryFor(String slug) => _loaded[slug]?.sourceCategory;

  /// Distinct dish categories in the bundled source snapshot.
  List<String> get dishes {
    _loaded;
    return _allDishes!;
  }

  Map<String, _GastronomyEntry> get _loaded =>
      _entries ?? (throw StateError('Call GastronomyCatalog.load() first'));

  Future<void> _read() async {
    final document = jsonDecode(await _bundle.loadString(assetPath));
    if (document is! Map<String, dynamic> || document['kind'] != _kind) {
      throw const FormatException('Unexpected gastronomy asset');
    }
    final rawCards = document['cards'];
    if (rawCards is! Map<String, dynamic>) {
      throw const FormatException('Gastronomy cards are missing');
    }
    final parsed = <String, _GastronomyEntry>{};
    final categories = <String>{};
    for (final row in rawCards.entries) {
      final value = row.value;
      if (row.key.isEmpty || value is! Map<String, dynamic>) {
        throw const FormatException('Invalid gastronomy card');
      }
      final rawDishes = value['dishes'];
      if (rawDishes is! List ||
          rawDishes.any((dish) => dish is! String || dish.trim().isEmpty)) {
        throw FormatException('Invalid dishes for ${row.key}');
      }
      final temperature = value['temperature'];
      if (temperature != null &&
          (temperature is! String || !_validTemperature(temperature))) {
        throw FormatException('Invalid temperature for ${row.key}');
      }
      final color = value['color'];
      final sourceCategory = value['sourceCategory'];
      if ((color != null && (color is! String || color.trim().isEmpty)) ||
          (sourceCategory != null &&
              (sourceCategory is! String || sourceCategory.trim().isEmpty))) {
        throw FormatException('Invalid source fields for ${row.key}');
      }
      final names = List<String>.unmodifiable(rawDishes.cast<String>());
      categories.addAll(names);
      parsed[row.key] = _GastronomyEntry(
        names,
        temperature as String?,
        color as String?,
        sourceCategory as String?,
      );
    }
    final sortedCategories = categories.toList()..sort();
    _allDishes = List<String>.unmodifiable(sortedCategories);
    _entries = Map<String, _GastronomyEntry>.unmodifiable(parsed);
  }

  bool _validTemperature(String value) {
    final parts = value.replaceAll('–', '-').split('-');
    return parts.isNotEmpty &&
        parts.length <= 2 &&
        parts.every((part) {
          final degrees = int.tryParse(part);
          return part.isNotEmpty &&
              part.length <= 2 &&
              degrees != null &&
              degrees >= 0 &&
              degrees <= 99;
        });
  }
}

class _GastronomyEntry {
  final List<String> dishes;
  final String? temperature;
  final String? color;
  final String? sourceCategory;

  const _GastronomyEntry(
    this.dishes,
    this.temperature,
    this.color,
    this.sourceCategory,
  );
}
