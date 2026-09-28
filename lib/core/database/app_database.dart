import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/scan_history_table.dart';

part 'app_database.g.dart';

const String _databaseName = 'winescan';

/// The app's local database. Schema changes bump [schemaVersion] and get a
/// step in [migration]; the history is the only table so far.
@DriftDatabase(tables: [ScanHistory])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (m) => m.createAll());

  static QueryExecutor _openConnection() {
    return driftDatabase(name: _databaseName);
  }
}
