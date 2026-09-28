import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/scan_history_table.dart';

part 'scan_history_dao.g.dart';

/// Queries over the scan history table. Called by the history repository
/// only; blocs and widgets never see drift types.
@DriftAccessor(tables: [ScanHistory])
class ScanHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$ScanHistoryDaoMixin {
  ScanHistoryDao(super.db);

  /// Newest first; re-emits on every change.
  Stream<List<ScanHistoryData>> watchAll() {
    return (select(
      scanHistory,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  Stream<List<ScanHistoryData>> watchRecent(int limit) {
    return (select(scanHistory)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .watch();
  }

  Future<ScanHistoryData?> byId(int id) {
    return (select(
      scanHistory,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insert(ScanHistoryCompanion row) => into(scanHistory).insert(row);

  Future<void> deleteById(int id) =>
      (delete(scanHistory)..where((t) => t.id.equals(id))).go();

  Future<void> deleteAll() => delete(scanHistory).go();
}
