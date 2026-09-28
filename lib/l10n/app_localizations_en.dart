// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Винный Сканер';

  @override
  String get settings => 'Settings';

  @override
  String get home => 'Home';

  @override
  String get searchForTracks => 'Search for tracks...';

  @override
  String get noTracksFound => 'No tracks found. Try searching for something!';

  @override
  String get splashApp => 'Splash App';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String routeDoesNotExist(String route) {
    return 'Route [$route] does not exist';
  }

  @override
  String get goToHome => 'Go to home';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get followSystemTheme => 'Follow system theme';

  @override
  String get alwaysUseLightTheme => 'Always use light theme';

  @override
  String get alwaysUseDarkTheme => 'Always use dark theme';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageDescription => 'Select your preferred language';

  @override
  String get english => 'English';

  @override
  String get german => 'German';

  @override
  String flavorMessage(String flavor, String duration) {
    return 'Flavor - $flavor\nSplash will hide in $duration';
  }

  @override
  String get trackDetails => 'Track Details';

  @override
  String get artist => 'Artist';

  @override
  String get album => 'Album';

  @override
  String get duration => 'Duration';

  @override
  String get explicit => 'Explicit';

  @override
  String get playPreview => 'Play Preview';

  @override
  String get errorConnectionTitle => 'No connection';

  @override
  String get errorConnectionFullScreenTitle => 'No internet connection';

  @override
  String get errorConnectionSubtitle =>
      'Check your internet connection and try again';

  @override
  String get errorServerTitle => 'Something went wrong';

  @override
  String get errorServerSubtitle =>
      'We couldn\'t load the data. Please try again';

  @override
  String get errorReloadButton => 'Try again';
}
