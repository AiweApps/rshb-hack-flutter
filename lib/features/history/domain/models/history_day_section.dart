import 'package:freezed_annotation/freezed_annotation.dart';

import 'scan_record.dart';

part 'history_day_section.freezed.dart';

/// The scans of one calendar day, newest first, for a sectioned list.
@freezed
abstract class HistoryDaySection with _$HistoryDaySection {
  const factory HistoryDaySection({
    /// Midnight of the day, in local time.
    required DateTime day,
    required List<ScanHistoryItem> items,
  }) = _HistoryDaySection;

  /// Groups [items] (already sorted newest first) by calendar day.
  static List<HistoryDaySection> group(List<ScanHistoryItem> items) {
    final List<DateTime> days = [];
    final List<List<ScanHistoryItem>> buckets = [];
    for (final item in items) {
      final created = item.createdAt;
      final DateTime day = DateTime(created.year, created.month, created.day);
      if (days.isNotEmpty && days.last == day) {
        buckets.last.add(item);
      } else {
        days.add(day);
        buckets.add([item]);
      }
    }
    return [
      for (int i = 0; i < days.length; i++)
        HistoryDaySection(day: days[i], items: buckets[i]),
    ];
  }
}
