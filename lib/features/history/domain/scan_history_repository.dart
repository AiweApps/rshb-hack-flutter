import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/misc/storage/scan_photo_store.dart';
import '../../scan/domain/models/recognition_view.dart';
import 'dao/scan_history_dao.dart';
import 'models/scan_record.dart';

/// Scans kept on the device: rows in the database, photos in the store.
///
/// Strategy: local-only. The list is a stream from the database, so every
/// screen showing it updates itself when a scan is added or removed.
class ScanHistoryRepository {
  final ScanHistoryDao _dao;
  final ScanPhotoStore _photos;

  ScanHistoryRepository(this._dao, this._photos);

  Stream<List<ScanHistoryItem>> watchAll() =>
      _dao.watchAll().asyncMap(_toItems);

  Stream<List<ScanHistoryItem>> watchRecent(int limit) =>
      _dao.watchRecent(limit).asyncMap(_toItems);

  Future<ScanRecord?> byId(int id) async {
    final row = await _dao.byId(id);
    if (row == null) return null;
    try {
      return row.toRecord(photoPath: await _photos.pathFor(row.photoName));
    } catch (e) {
      // A row whose JSON no longer parses (an old schema of the answer) is
      // dropped rather than crashing the screen that opened it. A generated
      // `fromJson` throws `TypeError` on a wrong type, so `on Exception`
      // would not do.
      debugPrint('Scan $id is unreadable and will be removed: $e');
      await delete(id);
      return null;
    }
  }

  /// Takes ownership of the photo at [photoPath] and stores the answer.
  Future<int> save({
    required String photoPath,
    required RecognitionView view,
  }) async {
    final createdAt = DateTime.now();
    final storedName = await _photos.keep(
      photoPath,
      id: createdAt.microsecondsSinceEpoch.toString(),
    );
    final best = view.bottles.isEmpty ? null : view.bottles.first.best;
    return _dao.insert(
      ScanHistoryCompanion.insert(
        createdAt: createdAt,
        photoName: storedName,
        viewJson: json.encode(view.toJson()),
        bestTitle: Value(best?.title),
        bestProducer: Value(best?.producer),
        bestSlug: Value(best?.slug),
        bestReference: Value(best?.reference),
        bottleCount: Value(view.bottles.length),
      ),
    );
  }

  Future<void> delete(int id) async {
    final row = await _dao.byId(id);
    if (row == null) return;
    await _dao.deleteById(id);
    await _photos.delete(row.photoName);
  }

  Future<void> clear() async {
    await _dao.deleteAll();
    await _photos.deleteAll();
  }

  Future<List<ScanHistoryItem>> _toItems(List<ScanHistoryData> rows) async {
    return [
      for (final row in rows)
        row.toItem(photoPath: await _photos.pathFor(row.photoName)),
    ];
  }
}
