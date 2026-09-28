import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

/// Date and time as the user reads them, in the app locale.
extension DateTimeFormat on DateTime {
  /// "Today", "Yesterday" or the full date, relative to [now].
  ///
  /// [now] is a parameter so the caller decides what "today" is and the
  /// result does not depend on the clock of the machine.
  String relativeDay(AppLocalizations l10n, {required DateTime now}) {
    final today = DateTime(now.year, now.month, now.day);
    final thisDay = DateTime(year, month, day);
    final daysAgo = today.difference(thisDay).inDays;
    if (daysAgo == 0) return l10n.historyToday;
    if (daysAgo == 1) return l10n.historyYesterday;
    return DateFormat.yMMMMd(l10n.localeName).format(this);
  }
}
