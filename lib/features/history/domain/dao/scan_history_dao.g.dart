// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_history_dao.dart';

// ignore_for_file: type=lint
mixin _$ScanHistoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $ScanHistoryTable get scanHistory => attachedDatabase.scanHistory;
  ScanHistoryDaoManager get managers => ScanHistoryDaoManager(this);
}

class ScanHistoryDaoManager {
  final _$ScanHistoryDaoMixin _db;
  ScanHistoryDaoManager(this._db);
  $$ScanHistoryTableTableManager get scanHistory =>
      $$ScanHistoryTableTableManager(_db.attachedDatabase, _db.scanHistory);
}
