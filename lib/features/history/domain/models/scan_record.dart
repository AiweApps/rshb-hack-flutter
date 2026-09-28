import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/database/app_database.dart';
import '../../../scan/domain/models/recognition_view.dart';

part 'scan_record.freezed.dart';

/// A stored scan as the app uses it: the photo and the full answer.
@freezed
abstract class ScanRecord with _$ScanRecord {
  const factory ScanRecord({
    required int id,
    required DateTime createdAt,
    required String photoPath,
    required RecognitionView view,
  }) = _ScanRecord;
}

/// A row of the history list: what the list needs and nothing heavier.
@freezed
abstract class ScanHistoryItem with _$ScanHistoryItem {
  const factory ScanHistoryItem({
    required int id,
    required DateTime createdAt,
    required String photoPath,
    required String? bestTitle,
    required String? bestProducer,
    required String? bestReference,
    required int bottleCount,
  }) = _ScanHistoryItem;
}

/// Mapping between the drift row and the domain models. Lives next to the
/// models so the schema and the domain can change independently. The row
/// holds a file name; the repository supplies the resolved [photoPath].
extension ScanHistoryDataMapping on ScanHistoryData {
  ScanHistoryItem toItem({required String photoPath}) => ScanHistoryItem(
    id: id,
    createdAt: createdAt,
    photoPath: photoPath,
    bestTitle: bestTitle,
    bestProducer: bestProducer,
    bestReference: bestReference,
    bottleCount: bottleCount,
  );

  ScanRecord toRecord({required String photoPath}) => ScanRecord(
    id: id,
    createdAt: createdAt,
    photoPath: photoPath,
    view: RecognitionView.fromJson(
      json.decode(viewJson) as Map<String, dynamic>,
    ),
  );
}
