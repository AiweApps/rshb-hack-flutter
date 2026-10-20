import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../scan/domain/models/wine_card.dart';

/// A saved wine and dish are independent of scan history. Clearing scans must
/// never erase a choice the user explicitly saved.
class SavedWineChoice {
  final String id;
  final WineCard wine;
  final String dish;
  final DateTime savedAt;

  const SavedWineChoice({
    required this.id,
    required this.wine,
    required this.dish,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'wine': wine.toJson(),
    'dish': dish,
    'saved_at': savedAt.toIso8601String(),
  };

  static SavedWineChoice? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    try {
      final wine = WineCard.fromJson(value['wine'] as Map<String, dynamic>);
      final dish = value['dish'] as String;
      final id = value['id'] as String;
      final savedAt = DateTime.parse(value['saved_at'] as String);
      if (wine.slug.isEmpty || dish.isEmpty || id.isEmpty) return null;
      return SavedWineChoice(id: id, wine: wine, dish: dish, savedAt: savedAt);
    } catch (_) {
      return null;
    }
  }
}

/// Small, device-local state. Wine cards are snapshots of actual API answers,
/// keyed by exact catalogue slug. No alternative is selected automatically.
class ComparisonRepository {
  static const _selectedKey = 'comparison.selected.v1';
  static const _choicesKey = 'comparison.choices.v1';
  final SharedPreferences _prefs;

  ComparisonRepository(this._prefs);

  List<WineCard> readSelected() {
    final value = _readList(_selectedKey);
    final seen = <String>{};
    final wines = <WineCard>[];
    for (final item in value) {
      if (item is! Map<String, dynamic>) continue;
      try {
        final card = WineCard.fromJson(item);
        if (card.slug.isNotEmpty && seen.add(card.slug)) wines.add(card);
      } catch (_) {
        // A damaged snapshot cannot prevent old scan history from opening.
      }
      if (wines.length == 3) break;
    }
    return wines;
  }

  List<SavedWineChoice> readChoices() => [
    for (final item in _readList(_choicesKey))
      if (SavedWineChoice.fromJson(item) case final choice?) choice,
  ];

  Future<void> writeSelected(List<WineCard> wines) async {
    final ok = await _prefs.setString(
      _selectedKey,
      jsonEncode([for (final wine in wines) wine.toJson()]),
    );
    if (!ok) throw StateError('Could not save comparison');
  }

  Future<void> writeChoices(List<SavedWineChoice> choices) async {
    final ok = await _prefs.setString(
      _choicesKey,
      jsonEncode([for (final choice in choices) choice.toJson()]),
    );
    if (!ok) throw StateError('Could not save choice');
  }

  List<Object?> _readList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      return decoded is List ? decoded : const [];
    } catch (_) {
      return const [];
    }
  }
}
