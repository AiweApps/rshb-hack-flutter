import 'package:drift/drift.dart';

/// One stored scan: the photo on disk, the answer as the API sent it, and a
/// few columns copied out of it so the list renders without parsing JSON.
class ScanHistory extends Table {
  IntColumn get id => integer().autoIncrement()();

  DateTimeColumn get createdAt => dateTime()();

  /// File name of the photo in `ScanPhotoStore` — a name, not a path: the
  /// app's container moves between iOS updates.
  TextColumn get photoName => text()();

  /// The `view` object of the automatic answer, JSON-encoded, re-read with
  /// `RecognitionView.fromJson` when the scan is opened again.
  TextColumn get viewJson => text()();

  TextColumn get bestTitle => text().nullable()();

  TextColumn get bestProducer => text().nullable()();

  TextColumn get bestSlug => text().nullable()();

  /// Relative reference path of the best card, for the row thumbnail.
  TextColumn get bestReference => text().nullable()();

  IntColumn get bottleCount => integer().withDefault(const Constant(0))();
}
