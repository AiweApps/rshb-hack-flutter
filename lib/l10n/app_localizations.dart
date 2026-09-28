import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

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
    Locale('en'),
    Locale('ru'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Wine Scanner'**
  String get appTitle;

  /// Bottom tab: scan
  ///
  /// In en, this message translates to:
  /// **'Scanner'**
  String get tabScan;

  /// Bottom tab: history
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tabHistory;

  /// Bottom tab: settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// Footer disclaimer, required by the product
  ///
  /// In en, this message translates to:
  /// **'The scanner can be wrong — check the name and the year on the card.'**
  String get disclaimer;

  /// Routing error page title
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// Routing error message
  ///
  /// In en, this message translates to:
  /// **'Route [{route}] does not exist'**
  String routeDoesNotExist(String route);

  /// Routing error button
  ///
  /// In en, this message translates to:
  /// **'Go to home'**
  String get goToHome;

  /// Generic cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Generic close button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Generic acknowledge button
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get commonGotIt;

  /// Inline connection error title
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get errorConnectionTitle;

  /// Full screen connection error title
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get errorConnectionFullScreenTitle;

  /// Connection error subtitle
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again'**
  String get errorConnectionSubtitle;

  /// Server error title
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorServerTitle;

  /// Server error subtitle
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the data. Please try again'**
  String get errorServerSubtitle;

  /// Retry button on the full screen error
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get errorReloadButton;

  /// Small label above the onboarding title
  ///
  /// In en, this message translates to:
  /// **'the «Svoe Vino» catalogue'**
  String get onboardingKicker;

  /// Onboarding page 1 title
  ///
  /// In en, this message translates to:
  /// **'Find a wine by a photo of its label'**
  String get onboardingTitle1;

  /// Onboarding page 1 body
  ///
  /// In en, this message translates to:
  /// **'The scanner looks the wine up in the «Svoe Vino» catalogue by a photo of the label and shows the best match and similar options.'**
  String get onboardingBody1;

  /// Onboarding page 2 title
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get onboardingTitle2;

  /// Onboarding step 1 title
  ///
  /// In en, this message translates to:
  /// **'Shoot the bottle'**
  String get onboardingStep1Title;

  /// Onboarding step 1 body
  ///
  /// In en, this message translates to:
  /// **'so that the whole label is visible.'**
  String get onboardingStep1Body;

  /// Onboarding step 2 title
  ///
  /// In en, this message translates to:
  /// **'Pick the bottle.'**
  String get onboardingStep2Title;

  /// Onboarding step 2 body
  ///
  /// In en, this message translates to:
  /// **'If there are several, tap its frame or draw one yourself.'**
  String get onboardingStep2Body;

  /// Onboarding step 3 title
  ///
  /// In en, this message translates to:
  /// **'Check the result'**
  String get onboardingStep3Title;

  /// Onboarding step 3 body
  ///
  /// In en, this message translates to:
  /// **'against the card behind the link.'**
  String get onboardingStep3Body;

  /// Onboarding page 3 title
  ///
  /// In en, this message translates to:
  /// **'What the scanner shows'**
  String get onboardingTitle3;

  /// Onboarding page 3 bullet
  ///
  /// In en, this message translates to:
  /// **'The best match from the catalogue'**
  String get onboardingGets1;

  /// Onboarding page 3 bullet
  ///
  /// In en, this message translates to:
  /// **'Similar options'**
  String get onboardingGets2;

  /// Onboarding page 3 bullet
  ///
  /// In en, this message translates to:
  /// **'The reference photo of the bottle'**
  String get onboardingGets3;

  /// Onboarding page 3 bullet
  ///
  /// In en, this message translates to:
  /// **'A link to the «Svoe Vino» card'**
  String get onboardingGets4;

  /// Onboarding next button
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// Onboarding last page button
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get onboardingStart;

  /// Onboarding skip button
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// Small label above the scan screen title
  ///
  /// In en, this message translates to:
  /// **'label recogniser'**
  String get scanKicker;

  /// Scan screen title
  ///
  /// In en, this message translates to:
  /// **'Wine scanner'**
  String get scanTitle;

  /// Scan screen hero title
  ///
  /// In en, this message translates to:
  /// **'Find a wine by a photo of its label'**
  String get scanHeroTitle;

  /// Scan screen hero text
  ///
  /// In en, this message translates to:
  /// **'The scanner looks the wine up in the «Svoe Vino» catalogue by a photo of the label and shows the best match and similar options.'**
  String get scanLede;

  /// Open the camera
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get scanTakePhoto;

  /// Open the gallery
  ///
  /// In en, this message translates to:
  /// **'Choose a photo'**
  String get scanPickPhoto;

  /// Note under the scan buttons
  ///
  /// In en, this message translates to:
  /// **'JPEG, PNG or WebP · up to 20 MB and 24 MP · the photo stays on this phone'**
  String get scanNote;

  /// Recent scans section title on the scan screen
  ///
  /// In en, this message translates to:
  /// **'Recent scans'**
  String get scanRecentTitle;

  /// Link to the whole history
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get scanRecentAll;

  /// Photo source sheet title
  ///
  /// In en, this message translates to:
  /// **'New photo'**
  String get scanSourceTitle;

  /// Service status pill: initial
  ///
  /// In en, this message translates to:
  /// **'checking the service…'**
  String get statusChecking;

  /// Service status pill: ready
  ///
  /// In en, this message translates to:
  /// **'ready'**
  String get statusReady;

  /// Service status pill: busy
  ///
  /// In en, this message translates to:
  /// **'busy'**
  String get statusBusy;

  /// Service status pill: busy with a queue
  ///
  /// In en, this message translates to:
  /// **'busy · {count} in queue'**
  String statusBusyQueue(int count);

  /// Service status pill: backend unreachable
  ///
  /// In en, this message translates to:
  /// **'recognition service is down'**
  String get statusDown;

  /// Service status pill: unavailable
  ///
  /// In en, this message translates to:
  /// **'service temporarily unavailable'**
  String get statusUnavailable;

  /// Service status pill: 401
  ///
  /// In en, this message translates to:
  /// **'no access'**
  String get statusNoAccess;

  /// Service status pill: 429
  ///
  /// In en, this message translates to:
  /// **'too many requests · wait'**
  String get statusRateLimited;

  /// Service status pill: network error
  ///
  /// In en, this message translates to:
  /// **'no connection'**
  String get statusOffline;

  /// Service status pill: dev mode
  ///
  /// In en, this message translates to:
  /// **'development · recognition off'**
  String get statusDev;

  /// Status detail: ready
  ///
  /// In en, this message translates to:
  /// **'The recognition service is connected and idle — you can upload a photo.'**
  String get statusReadyDetail;

  /// Status detail: busy
  ///
  /// In en, this message translates to:
  /// **'The service is recognising another photo. A new photo will wait its turn.'**
  String get statusBusyDetail;

  /// Status detail: down
  ///
  /// In en, this message translates to:
  /// **'The recognition service is not responding. Try again later.'**
  String get statusDownDetail;

  /// Status detail: unavailable
  ///
  /// In en, this message translates to:
  /// **'The recognition service is temporarily unavailable. Try again later.'**
  String get statusUnavailableDetail;

  /// Status detail: 401
  ///
  /// In en, this message translates to:
  /// **'Could not open a session. Check the internet and try again.'**
  String get statusNoAccessDetail;

  /// Status detail: 429
  ///
  /// In en, this message translates to:
  /// **'Wait a few seconds and refresh the status.'**
  String get statusRateLimitedDetail;

  /// Status detail: offline
  ///
  /// In en, this message translates to:
  /// **'No connection to the scanner. Check the internet.'**
  String get statusOfflineDetail;

  /// Status detail: dev mode
  ///
  /// In en, this message translates to:
  /// **'Interface development mode: recognition is not connected.'**
  String get statusDevDetail;

  /// Status detail suffix
  ///
  /// In en, this message translates to:
  /// **'The status refreshes by itself.'**
  String get statusAutoRefresh;

  /// Loading title during recognition
  ///
  /// In en, this message translates to:
  /// **'Reading the label…'**
  String get loadingReading;

  /// Loading title during ROI recognition
  ///
  /// In en, this message translates to:
  /// **'Recognising the selected bottle…'**
  String get loadingRoi;

  /// Loading note
  ///
  /// In en, this message translates to:
  /// **'Usually a few seconds.'**
  String get loadingNote;

  /// Auto-retry title for a busy service
  ///
  /// In en, this message translates to:
  /// **'Service is busy'**
  String get loadingBusy;

  /// Auto-retry title for 429
  ///
  /// In en, this message translates to:
  /// **'Too many requests'**
  String get loadingTooMany;

  /// Auto-retry countdown
  ///
  /// In en, this message translates to:
  /// **'Retrying in {seconds} s (attempt {attempt} of {total}).'**
  String loadingRetryIn(int seconds, int attempt, int total);

  /// Result screen title
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get resultTitle;

  /// Heading over the single bottle answer
  ///
  /// In en, this message translates to:
  /// **'Scanner answer'**
  String get resultAnswerTitle;

  /// Bottle label
  ///
  /// In en, this message translates to:
  /// **'Bottle {number}'**
  String resultBottleN(int number);

  /// Bottle chip: all bottles
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get resultTabAll;

  /// Tag on the best card
  ///
  /// In en, this message translates to:
  /// **'best match'**
  String get resultBestMatch;

  /// Alternatives section title
  ///
  /// In en, this message translates to:
  /// **'Similar options'**
  String get resultAlternatives;

  /// Empty best card
  ///
  /// In en, this message translates to:
  /// **'No match found for this bottle.'**
  String get resultNoMatchForBottle;

  /// Empty card on the overview
  ///
  /// In en, this message translates to:
  /// **'Bottle {number}: no match found'**
  String resultBottleNoMatch(int number);

  /// Advice when nothing was found
  ///
  /// In en, this message translates to:
  /// **'Shoot the label larger and straighter, or draw a frame around the bottle yourself.'**
  String get resultNoBottleAdviceAuto;

  /// Advice when nothing was found in the frame
  ///
  /// In en, this message translates to:
  /// **'Draw a wider frame or go back to all bottles.'**
  String get resultNoBottleAdviceRoi;

  /// Re-scan one bottle button
  ///
  /// In en, this message translates to:
  /// **'Recognise'**
  String get resultRescan;

  /// Explanation of the re-scan button
  ///
  /// In en, this message translates to:
  /// **'Starts a new scan for this bottle only.'**
  String get resultRescanHint;

  /// Card link
  ///
  /// In en, this message translates to:
  /// **'Open on «Svoe Vino»'**
  String get resultOpenOnSite;

  /// Card without a link
  ///
  /// In en, this message translates to:
  /// **'The catalogue has no «Svoe Vino» page for this card'**
  String get resultNoSiteUrl;

  /// Placeholder when the reference image is missing
  ///
  /// In en, this message translates to:
  /// **'no reference'**
  String get resultReferenceMissing;

  /// Placeholder when the crop is missing
  ///
  /// In en, this message translates to:
  /// **'no photo'**
  String get resultPhotoMissing;

  /// Compare pane caption
  ///
  /// In en, this message translates to:
  /// **'Your photo'**
  String get resultYourPhoto;

  /// Compare pane caption
  ///
  /// In en, this message translates to:
  /// **'Catalogue reference'**
  String get resultReference;

  /// Compare viewer title
  ///
  /// In en, this message translates to:
  /// **'Compare with the reference'**
  String get resultCompareTitle;

  /// Compare viewer caption
  ///
  /// In en, this message translates to:
  /// **'Your photo · bottle {number}'**
  String resultYourPhotoBottle(int number);

  /// Compare viewer caption
  ///
  /// In en, this message translates to:
  /// **'Reference: {title}'**
  String resultReferenceOf(String title);

  /// Back from a frame answer
  ///
  /// In en, this message translates to:
  /// **'All bottles'**
  String get resultAllBottles;

  /// Enter frame mode
  ///
  /// In en, this message translates to:
  /// **'Draw a frame'**
  String get resultDrawFrame;

  /// Pick another photo
  ///
  /// In en, this message translates to:
  /// **'New photo'**
  String get resultNewPhoto;

  /// More actions sheet
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get resultMore;

  /// Share action
  ///
  /// In en, this message translates to:
  /// **'Share the full JSON answer'**
  String get resultShareJson;

  /// Share action
  ///
  /// In en, this message translates to:
  /// **'Share bottle {number} JSON'**
  String resultShareBottleJson(int number);

  /// Share action
  ///
  /// In en, this message translates to:
  /// **'Share the frame JSON'**
  String get resultShareFrameJson;

  /// Tech details sheet title
  ///
  /// In en, this message translates to:
  /// **'Technical details'**
  String get resultTechDetails;

  /// One-shot tip
  ///
  /// In en, this message translates to:
  /// **'Recognised within the selected frame. Below is the answer for this area.'**
  String get noticeRoiFound;

  /// One-shot tip
  ///
  /// In en, this message translates to:
  /// **'Recognised within the selected frame. No bottle with a label was found in it.'**
  String get noticeRoiEmpty;

  /// One-shot tip
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{One bottle found.} other{More than one bottle found — {count}. Each has its own answer: pick one by its frame on the photo or by a chip below.}}'**
  String noticeManyBottles(int count);

  /// Verdict
  ///
  /// In en, this message translates to:
  /// **'Could not pick a match'**
  String get decisionUnknown;

  /// Verdict
  ///
  /// In en, this message translates to:
  /// **'Not enough evidence for an answer'**
  String get decisionInsufficient;

  /// Verdict
  ///
  /// In en, this message translates to:
  /// **'Several bottles in the photo — pick one'**
  String get decisionAmbiguous;

  /// Verdict
  ///
  /// In en, this message translates to:
  /// **'No bottle with a label was found'**
  String get decisionNoTarget;

  /// Frame mode hint
  ///
  /// In en, this message translates to:
  /// **'Draw around the bottle with your finger'**
  String get frameHint;

  /// Frame mode button
  ///
  /// In en, this message translates to:
  /// **'Adjust the frame'**
  String get frameEdit;

  /// Frame mode button
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get frameDone;

  /// Frame mode button
  ///
  /// In en, this message translates to:
  /// **'Clear the frame'**
  String get frameClear;

  /// Frame mode button
  ///
  /// In en, this message translates to:
  /// **'Recognise the bottle in the frame'**
  String get frameRecognize;

  /// Scan error title
  ///
  /// In en, this message translates to:
  /// **'It did not work'**
  String get scanErrorTitleDefault;

  /// Scan error button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get scanErrorRetry;

  /// Scan error button
  ///
  /// In en, this message translates to:
  /// **'Another photo'**
  String get scanErrorOtherPhoto;

  /// Scan error title 401
  ///
  /// In en, this message translates to:
  /// **'No access'**
  String get scanErrorNoAccess;

  /// Scan error title 413
  ///
  /// In en, this message translates to:
  /// **'Image is too large'**
  String get scanErrorTooLarge;

  /// Scan error title 415
  ///
  /// In en, this message translates to:
  /// **'Format not supported'**
  String get scanErrorFormat;

  /// Scan error title 422
  ///
  /// In en, this message translates to:
  /// **'Image not processed'**
  String get scanErrorUnprocessed;

  /// Scan error title 429
  ///
  /// In en, this message translates to:
  /// **'Too many requests'**
  String get scanErrorTooMany;

  /// Scan error title 502
  ///
  /// In en, this message translates to:
  /// **'Service error'**
  String get scanErrorService;

  /// Scan error title 503
  ///
  /// In en, this message translates to:
  /// **'Service busy or unavailable'**
  String get scanErrorBusy;

  /// Scan error title 504
  ///
  /// In en, this message translates to:
  /// **'Timed out'**
  String get scanErrorTimeout;

  /// Scan error title: network
  ///
  /// In en, this message translates to:
  /// **'No answer'**
  String get scanErrorNoResponse;

  /// Scan error title: other
  ///
  /// In en, this message translates to:
  /// **'Error {code}'**
  String scanErrorCode(int code);

  /// Scan error title: local
  ///
  /// In en, this message translates to:
  /// **'Could not open the photo'**
  String get scanErrorPhotoOpen;

  /// Scan error text
  ///
  /// In en, this message translates to:
  /// **'Could not open a session. Check the internet and try again.'**
  String get scanErrorTextNoAccess;

  /// Scan error text
  ///
  /// In en, this message translates to:
  /// **'The file is over 20 MB or 24 MP. Take the photo again.'**
  String get scanErrorTextTooLarge;

  /// Scan error text
  ///
  /// In en, this message translates to:
  /// **'JPEG, PNG or WebP is required.'**
  String get scanErrorTextFormat;

  /// Scan error text
  ///
  /// In en, this message translates to:
  /// **'The service could not process the image. Try another photo.'**
  String get scanErrorTextUnprocessed;

  /// Scan error text
  ///
  /// In en, this message translates to:
  /// **'The frame is outside the image. Draw it again.'**
  String get scanErrorTextBadRoi;

  /// Scan error text
  ///
  /// In en, this message translates to:
  /// **'Wait a few seconds and retry.'**
  String get scanErrorTextTooMany;

  /// Scan error text
  ///
  /// In en, this message translates to:
  /// **'The recognition service answered with an error. Try later.'**
  String get scanErrorTextService;

  /// Scan error text
  ///
  /// In en, this message translates to:
  /// **'The service is busy with other photos, try again shortly.'**
  String get scanErrorTextBusy;

  /// Scan error text
  ///
  /// In en, this message translates to:
  /// **'Timed out. Repeat the request.'**
  String get scanErrorTextTimeout;

  /// Scan error text
  ///
  /// In en, this message translates to:
  /// **'No connection to the service. Check the internet and retry.'**
  String get scanErrorTextOffline;

  /// Scan error text
  ///
  /// In en, this message translates to:
  /// **'Try again.'**
  String get scanErrorTextDefault;

  /// Scan error text
  ///
  /// In en, this message translates to:
  /// **'Choose another photo.'**
  String get scanErrorTextPhotoOpen;

  /// Tech details key
  ///
  /// In en, this message translates to:
  /// **'decision'**
  String get techDecision;

  /// Tech details key
  ///
  /// In en, this message translates to:
  /// **'target basis'**
  String get techPrimaryBasis;

  /// Tech details key
  ///
  /// In en, this message translates to:
  /// **'mode'**
  String get techMode;

  /// Tech details key
  ///
  /// In en, this message translates to:
  /// **'raw.slug'**
  String get techRawSlug;

  /// Tech details key
  ///
  /// In en, this message translates to:
  /// **'best_candidate'**
  String get techBestCandidate;

  /// Tech details key
  ///
  /// In en, this message translates to:
  /// **'card slug'**
  String get techCardSlug;

  /// Tech details key
  ///
  /// In en, this message translates to:
  /// **'page address'**
  String get techPageUrl;

  /// Tech details key
  ///
  /// In en, this message translates to:
  /// **'address source'**
  String get techPageSource;

  /// Tech details key
  ///
  /// In en, this message translates to:
  /// **'site snapshot'**
  String get techSnapshot;

  /// Tech details value
  ///
  /// In en, this message translates to:
  /// **'present in the site snapshots of 17–21.09'**
  String get techSnapshotYes;

  /// Tech details value
  ///
  /// In en, this message translates to:
  /// **'absent from the site snapshots of 17–21.09'**
  String get techSnapshotNo;

  /// Tech details key
  ///
  /// In en, this message translates to:
  /// **'request frame'**
  String get techRoi;

  /// Tech details key
  ///
  /// In en, this message translates to:
  /// **'bottles'**
  String get techBottles;

  /// Tech details key
  ///
  /// In en, this message translates to:
  /// **'frame (EXIF)'**
  String get techFrame;

  /// Tech details key
  ///
  /// In en, this message translates to:
  /// **'file'**
  String get techFile;

  /// Tech details value
  ///
  /// In en, this message translates to:
  /// **'{format} · {bytes} bytes'**
  String techFileValue(String format, int bytes);

  /// Tech details key
  ///
  /// In en, this message translates to:
  /// **'probability'**
  String get techProbability;

  /// Tech details value
  ///
  /// In en, this message translates to:
  /// **'not calculated (no calibration)'**
  String get techProbabilityValue;

  /// Tech details key
  ///
  /// In en, this message translates to:
  /// **'service time'**
  String get techBackendTime;

  /// Tech details value
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String techSeconds(String seconds);

  /// Tech details key
  ///
  /// In en, this message translates to:
  /// **'answer profile'**
  String get techProfile;

  /// Tech details key
  ///
  /// In en, this message translates to:
  /// **'reasons'**
  String get techReasons;

  /// Tech details empty value
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get techNone;

  /// History screen title
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// History empty state title
  ///
  /// In en, this message translates to:
  /// **'Nothing scanned yet'**
  String get historyEmptyTitle;

  /// History empty state body
  ///
  /// In en, this message translates to:
  /// **'Take a photo of a label — the result will appear here.'**
  String get historyEmptyBody;

  /// History empty state button
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get historyEmptyAction;

  /// Clear history action
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get historyClear;

  /// Clear confirmation title
  ///
  /// In en, this message translates to:
  /// **'Clear the history?'**
  String get historyClearConfirmTitle;

  /// Clear confirmation body
  ///
  /// In en, this message translates to:
  /// **'All scans and their photos will be deleted from this phone.'**
  String get historyClearConfirmBody;

  /// Clear confirmation button
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get historyClearConfirm;

  /// Swipe action
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get historyDelete;

  /// Toast after deleting a scan
  ///
  /// In en, this message translates to:
  /// **'Scan deleted'**
  String get historyDeleted;

  /// Toast after clearing the history
  ///
  /// In en, this message translates to:
  /// **'History cleared'**
  String get historyCleared;

  /// Bottles in a scan
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 bottle} other{{count} bottles}}'**
  String historyBottlesCount(int count);

  /// History row without a best card
  ///
  /// In en, this message translates to:
  /// **'No match found'**
  String get historyNoMatch;

  /// Relative date
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get historyToday;

  /// Relative date
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get historyYesterday;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings section
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// Settings row
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// Theme option
  ///
  /// In en, this message translates to:
  /// **'As in the system'**
  String get themeSystem;

  /// Theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Settings row
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Language option, in its own language
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// Language option, in its own language
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Settings section
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get settingsHelp;

  /// Settings row
  ///
  /// In en, this message translates to:
  /// **'Show the intro again'**
  String get settingsShowOnboarding;

  /// Settings row and sheet title
  ///
  /// In en, this message translates to:
  /// **'About the scanner'**
  String get settingsAbout;

  /// About sheet body
  ///
  /// In en, this message translates to:
  /// **'The scanner looks the wine up in the «Svoe Vino» catalogue by a photo of the label. Confidence is not calculated: check the name and the year on the card. Photos are sent to the recognition service and are kept only on this phone.'**
  String get settingsAboutBody;

  /// Settings row
  ///
  /// In en, this message translates to:
  /// **'Open «Svoe Vino»'**
  String get settingsOpenSite;

  /// Settings section
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsData;

  /// Settings row
  ///
  /// In en, this message translates to:
  /// **'Recognition service'**
  String get settingsService;

  /// Catalogue size
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 card in the catalogue} other{{count} cards in the catalogue}}'**
  String settingsCatalogSize(int count);

  /// Bottle label with the centre hint
  ///
  /// In en, this message translates to:
  /// **'Bottle {number} · near the centre'**
  String resultBottleNearCenterTag(int number);

  /// Empty answer, automatic mode, full sentence
  ///
  /// In en, this message translates to:
  /// **'No bottle with a label was found. Shoot the label larger and straighter, or draw a frame around the bottle yourself.'**
  String get resultNoBottleAuto;

  /// Empty answer, frame mode, full sentence
  ///
  /// In en, this message translates to:
  /// **'No bottle with a label was found. Draw a wider frame or go back to all bottles.'**
  String get resultNoBottleRoi;

  /// Toast when deleting a scan fails
  ///
  /// In en, this message translates to:
  /// **'Could not delete the scan'**
  String get historyDeleteFailed;

  /// Toast when clearing the history fails
  ///
  /// In en, this message translates to:
  /// **'Could not clear the history'**
  String get historyClearFailed;
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
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
