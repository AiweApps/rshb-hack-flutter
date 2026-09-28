import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

/// Number formatting for display, in the app locale.
extension MillisecondsFormat on int {
  /// Milliseconds as seconds with one decimal: `2340` → "2,3" in ru.
  String toSecondsText(AppLocalizations l10n) {
    final format = NumberFormat('0.0', l10n.localeName);
    return format.format(this / Duration.millisecondsPerSecond);
  }
}
