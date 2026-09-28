// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Винный Сканер';

  @override
  String get settings => 'Einstellungen';

  @override
  String get home => 'Startseite';

  @override
  String get searchForTracks => 'Nach Tracks suchen...';

  @override
  String get noTracksFound =>
      'Keine Tracks gefunden. Versuchen Sie etwas anderes zu suchen!';

  @override
  String get splashApp => 'Splash App';

  @override
  String get pageNotFound => 'Seite nicht gefunden';

  @override
  String routeDoesNotExist(String route) {
    return 'Route [$route] existiert nicht';
  }

  @override
  String get goToHome => 'Zur Startseite';

  @override
  String get appearance => 'Erscheinungsbild';

  @override
  String get themeMode => 'Theme-Modus';

  @override
  String get followSystemTheme => 'System-Theme folgen';

  @override
  String get alwaysUseLightTheme => 'Immer helles Theme verwenden';

  @override
  String get alwaysUseDarkTheme => 'Immer dunkles Theme verwenden';

  @override
  String get system => 'System';

  @override
  String get light => 'Hell';

  @override
  String get dark => 'Dunkel';

  @override
  String get language => 'Sprache';

  @override
  String get languageDescription => 'Wählen Sie Ihre bevorzugte Sprache';

  @override
  String get english => 'Englisch';

  @override
  String get german => 'Deutsch';

  @override
  String flavorMessage(String flavor, String duration) {
    return 'Flavor - $flavor\nSplash wird in $duration ausgeblendet';
  }

  @override
  String get trackDetails => 'Track-Details';

  @override
  String get artist => 'Künstler';

  @override
  String get album => 'Album';

  @override
  String get duration => 'Dauer';

  @override
  String get explicit => 'Explizit';

  @override
  String get playPreview => 'Vorschau abspielen';

  @override
  String get errorConnectionTitle => 'Keine Verbindung';

  @override
  String get errorConnectionFullScreenTitle => 'Keine Internetverbindung';

  @override
  String get errorConnectionSubtitle =>
      'Überprüfen Sie Ihre Internetverbindung und versuchen Sie es erneut';

  @override
  String get errorServerTitle => 'Etwas ist schiefgelaufen';

  @override
  String get errorServerSubtitle =>
      'Die Daten konnten nicht geladen werden. Bitte versuchen Sie es erneut';

  @override
  String get errorReloadButton => 'Erneut versuchen';
}
