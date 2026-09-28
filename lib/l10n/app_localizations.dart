import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Винный Сканер'**
  String get appTitle;

  /// Settings page title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Home page title and navigation label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Search field placeholder text
  ///
  /// In en, this message translates to:
  /// **'Search for tracks...'**
  String get searchForTracks;

  /// Message when no search results are found
  ///
  /// In en, this message translates to:
  /// **'No tracks found. Try searching for something!'**
  String get noTracksFound;

  /// Splash screen app name
  ///
  /// In en, this message translates to:
  /// **'Splash App'**
  String get splashApp;

  /// Error page title when route not found
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// Error message when route does not exist
  ///
  /// In en, this message translates to:
  /// **'Route [{route}] does not exist'**
  String routeDoesNotExist(String route);

  /// Button text to navigate to home
  ///
  /// In en, this message translates to:
  /// **'Go to home'**
  String get goToHome;

  /// Appearance settings section title
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Theme mode setting title
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// System theme mode description
  ///
  /// In en, this message translates to:
  /// **'Follow system theme'**
  String get followSystemTheme;

  /// Light theme mode description
  ///
  /// In en, this message translates to:
  /// **'Always use light theme'**
  String get alwaysUseLightTheme;

  /// Dark theme mode description
  ///
  /// In en, this message translates to:
  /// **'Always use dark theme'**
  String get alwaysUseDarkTheme;

  /// System theme mode dropdown option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// Light theme mode dropdown option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// Dark theme mode dropdown option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// Language setting title
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Language setting description
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language'**
  String get languageDescription;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// German language option
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get german;

  /// Splash screen flavor and duration message
  ///
  /// In en, this message translates to:
  /// **'Flavor - {flavor}\nSplash will hide in {duration}'**
  String flavorMessage(String flavor, String duration);

  /// Track details page title
  ///
  /// In en, this message translates to:
  /// **'Track Details'**
  String get trackDetails;

  /// Artist label
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get artist;

  /// Album label
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get album;

  /// Duration label
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// Explicit content badge text
  ///
  /// In en, this message translates to:
  /// **'Explicit'**
  String get explicit;

  /// Play preview button text
  ///
  /// In en, this message translates to:
  /// **'Play Preview'**
  String get playPreview;

  /// Title of the inline connection error block
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get errorConnectionTitle;

  /// Title of the full screen connection error
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get errorConnectionFullScreenTitle;

  /// Subtitle of the connection error
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again'**
  String get errorConnectionSubtitle;

  /// Title of the server error
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorServerTitle;

  /// Subtitle of the server error
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the data. Please try again'**
  String get errorServerSubtitle;

  /// Retry button on the full screen error
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get errorReloadButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
