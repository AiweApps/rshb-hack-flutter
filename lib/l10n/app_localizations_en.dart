// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Wine Scanner';

  @override
  String get tabScan => 'Scanner';

  @override
  String get tabHistory => 'History';

  @override
  String get tabSettings => 'Settings';

  @override
  String get disclaimer =>
      'The scanner can be wrong — check the name and the year on the card.';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String routeDoesNotExist(String route) {
    return 'Route [$route] does not exist';
  }

  @override
  String get goToHome => 'Go to home';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonGotIt => 'Got it';

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

  @override
  String get onboardingKicker => 'the «Svoe Vino» catalogue';

  @override
  String get onboardingTitle1 => 'Find a wine by a photo of its label';

  @override
  String get onboardingBody1 =>
      'The scanner looks the wine up in the «Svoe Vino» catalogue by a photo of the label and shows the best match and similar options.';

  @override
  String get onboardingTitle2 => 'How it works';

  @override
  String get onboardingStep1Title => 'Shoot the bottle';

  @override
  String get onboardingStep1Body => 'so that the whole label is visible.';

  @override
  String get onboardingStep2Title => 'Pick the bottle.';

  @override
  String get onboardingStep2Body =>
      'If there are several, tap its frame or draw one yourself.';

  @override
  String get onboardingStep3Title => 'Check the result';

  @override
  String get onboardingStep3Body => 'against the card behind the link.';

  @override
  String get onboardingTitle3 => 'What the scanner shows';

  @override
  String get onboardingGets1 => 'The best match from the catalogue';

  @override
  String get onboardingGets2 => 'Similar options';

  @override
  String get onboardingGets3 => 'The reference photo of the bottle';

  @override
  String get onboardingGets4 => 'A link to the «Svoe Vino» card';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Start';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get scanKicker => 'label recogniser';

  @override
  String get scanTitle => 'Wine scanner';

  @override
  String get scanHeroTitle => 'Find a wine by a photo of its label';

  @override
  String get scanLede =>
      'The scanner looks the wine up in the «Svoe Vino» catalogue by a photo of the label and shows the best match and similar options.';

  @override
  String get scanTakePhoto => 'Take a photo';

  @override
  String get scanPickPhoto => 'Choose a photo';

  @override
  String get scanNote =>
      'JPEG, PNG or WebP · up to 20 MB and 24 MP · the photo stays on this phone';

  @override
  String get scanRecentTitle => 'Recent scans';

  @override
  String get scanRecentAll => 'All';

  @override
  String get scanSourceTitle => 'New photo';

  @override
  String get statusChecking => 'checking the service…';

  @override
  String get statusReady => 'ready';

  @override
  String get statusBusy => 'busy';

  @override
  String statusBusyQueue(int count) {
    return 'busy · $count in queue';
  }

  @override
  String get statusDown => 'recognition service is down';

  @override
  String get statusUnavailable => 'service temporarily unavailable';

  @override
  String get statusNoAccess => 'no access';

  @override
  String get statusRateLimited => 'too many requests · wait';

  @override
  String get statusOffline => 'no connection';

  @override
  String get statusDev => 'development · recognition off';

  @override
  String get statusReadyDetail =>
      'The recognition service is connected and idle — you can upload a photo.';

  @override
  String get statusBusyDetail =>
      'The service is recognising another photo. A new photo will wait its turn.';

  @override
  String get statusDownDetail =>
      'The recognition service is not responding. Try again later.';

  @override
  String get statusUnavailableDetail =>
      'The recognition service is temporarily unavailable. Try again later.';

  @override
  String get statusNoAccessDetail =>
      'Could not open a session. Check the internet and try again.';

  @override
  String get statusRateLimitedDetail =>
      'Wait a few seconds and refresh the status.';

  @override
  String get statusOfflineDetail =>
      'No connection to the scanner. Check the internet.';

  @override
  String get statusDevDetail =>
      'Interface development mode: recognition is not connected.';

  @override
  String get statusAutoRefresh => 'The status refreshes by itself.';

  @override
  String get loadingReading => 'Reading the label…';

  @override
  String get loadingRoi => 'Recognising the selected bottle…';

  @override
  String get loadingNote => 'Usually a few seconds.';

  @override
  String get loadingBusy => 'Service is busy';

  @override
  String get loadingTooMany => 'Too many requests';

  @override
  String loadingRetryIn(int seconds, int attempt, int total) {
    return 'Retrying in $seconds s (attempt $attempt of $total).';
  }

  @override
  String get resultTitle => 'Result';

  @override
  String get resultAnswerTitle => 'Scanner answer';

  @override
  String resultBottleN(int number) {
    return 'Bottle $number';
  }

  @override
  String get resultTabAll => 'All';

  @override
  String get resultBestMatch => 'best match';

  @override
  String get resultAlternatives => 'Similar options';

  @override
  String get resultNoMatchForBottle => 'No match found for this bottle.';

  @override
  String resultBottleNoMatch(int number) {
    return 'Bottle $number: no match found';
  }

  @override
  String get resultNoBottleAdviceAuto =>
      'Shoot the label larger and straighter, or draw a frame around the bottle yourself.';

  @override
  String get resultNoBottleAdviceRoi =>
      'Draw a wider frame or go back to all bottles.';

  @override
  String get resultRescan => 'Recognise';

  @override
  String get resultRescanHint => 'Starts a new scan for this bottle only.';

  @override
  String get resultOpenOnSite => 'Open on «Svoe Vino»';

  @override
  String get resultNoSiteUrl =>
      'The catalogue has no «Svoe Vino» page for this card';

  @override
  String get resultReferenceMissing => 'no reference';

  @override
  String get resultPhotoMissing => 'no photo';

  @override
  String get resultYourPhoto => 'Your photo';

  @override
  String get resultReference => 'Catalogue reference';

  @override
  String get resultCompareTitle => 'Compare with the reference';

  @override
  String resultYourPhotoBottle(int number) {
    return 'Your photo · bottle $number';
  }

  @override
  String resultReferenceOf(String title) {
    return 'Reference: $title';
  }

  @override
  String get resultAllBottles => 'All bottles';

  @override
  String get resultDrawFrame => 'Draw a frame';

  @override
  String get resultNewPhoto => 'New photo';

  @override
  String get resultMore => 'More';

  @override
  String get resultShareJson => 'Share the full JSON answer';

  @override
  String resultShareBottleJson(int number) {
    return 'Share bottle $number JSON';
  }

  @override
  String get resultShareFrameJson => 'Share the frame JSON';

  @override
  String get resultTechDetails => 'Technical details';

  @override
  String get noticeRoiFound =>
      'Recognised within the selected frame. Below is the answer for this area.';

  @override
  String get noticeRoiEmpty =>
      'Recognised within the selected frame. No bottle with a label was found in it.';

  @override
  String noticeManyBottles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'More than one bottle found — $count. Each has its own answer: pick one by its frame on the photo or by a chip below.',
      one: 'One bottle found.',
    );
    return '$_temp0';
  }

  @override
  String get decisionUnknown => 'Could not pick a match';

  @override
  String get decisionInsufficient => 'Not enough evidence for an answer';

  @override
  String get decisionAmbiguous => 'Several bottles in the photo — pick one';

  @override
  String get decisionNoTarget => 'No bottle with a label was found';

  @override
  String get frameHint => 'Draw around the bottle with your finger';

  @override
  String get frameEdit => 'Adjust the frame';

  @override
  String get frameDone => 'Done';

  @override
  String get frameClear => 'Clear the frame';

  @override
  String get frameRecognize => 'Recognise the bottle in the frame';

  @override
  String get scanErrorTitleDefault => 'It did not work';

  @override
  String get scanErrorRetry => 'Retry';

  @override
  String get scanErrorOtherPhoto => 'Another photo';

  @override
  String get scanErrorNoAccess => 'No access';

  @override
  String get scanErrorTooLarge => 'Image is too large';

  @override
  String get scanErrorFormat => 'Format not supported';

  @override
  String get scanErrorUnprocessed => 'Image not processed';

  @override
  String get scanErrorTooMany => 'Too many requests';

  @override
  String get scanErrorService => 'Service error';

  @override
  String get scanErrorBusy => 'Service busy or unavailable';

  @override
  String get scanErrorTimeout => 'Timed out';

  @override
  String get scanErrorNoResponse => 'No answer';

  @override
  String scanErrorCode(int code) {
    return 'Error $code';
  }

  @override
  String get scanErrorPhotoOpen => 'Could not open the photo';

  @override
  String get scanErrorTextNoAccess =>
      'Could not open a session. Check the internet and try again.';

  @override
  String get scanErrorTextTooLarge =>
      'The file is over 20 MB or 24 MP. Take the photo again.';

  @override
  String get scanErrorTextFormat => 'JPEG, PNG or WebP is required.';

  @override
  String get scanErrorTextUnprocessed =>
      'The service could not process the image. Try another photo.';

  @override
  String get scanErrorTextBadRoi =>
      'The frame is outside the image. Draw it again.';

  @override
  String get scanErrorTextTooMany => 'Wait a few seconds and retry.';

  @override
  String get scanErrorTextService =>
      'The recognition service answered with an error. Try later.';

  @override
  String get scanErrorTextBusy =>
      'The service is busy with other photos, try again shortly.';

  @override
  String get scanErrorTextTimeout => 'Timed out. Repeat the request.';

  @override
  String get scanErrorTextOffline =>
      'No connection to the service. Check the internet and retry.';

  @override
  String get scanErrorTextDefault => 'Try again.';

  @override
  String get scanErrorTextPhotoOpen => 'Choose another photo.';

  @override
  String get techDecision => 'decision';

  @override
  String get techPrimaryBasis => 'target basis';

  @override
  String get techMode => 'mode';

  @override
  String get techRawSlug => 'raw.slug';

  @override
  String get techBestCandidate => 'best_candidate';

  @override
  String get techCardSlug => 'card slug';

  @override
  String get techPageUrl => 'page address';

  @override
  String get techPageSource => 'address source';

  @override
  String get techSnapshot => 'site snapshot';

  @override
  String get techSnapshotYes => 'present in the site snapshots of 17–21.09';

  @override
  String get techSnapshotNo => 'absent from the site snapshots of 17–21.09';

  @override
  String get techRoi => 'request frame';

  @override
  String get techBottles => 'bottles';

  @override
  String get techFrame => 'frame (EXIF)';

  @override
  String get techFile => 'file';

  @override
  String techFileValue(String format, int bytes) {
    return '$format · $bytes bytes';
  }

  @override
  String get techProbability => 'probability';

  @override
  String get techProbabilityValue => 'not calculated (no calibration)';

  @override
  String get techBackendTime => 'service time';

  @override
  String techSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String get techProfile => 'answer profile';

  @override
  String get techReasons => 'reasons';

  @override
  String get techNone => '—';

  @override
  String get historyTitle => 'History';

  @override
  String get historyEmptyTitle => 'Nothing scanned yet';

  @override
  String get historyEmptyBody =>
      'Take a photo of a label — the result will appear here.';

  @override
  String get historyEmptyAction => 'Scan';

  @override
  String get historyClear => 'Clear history';

  @override
  String get historyClearConfirmTitle => 'Clear the history?';

  @override
  String get historyClearConfirmBody =>
      'All scans and their photos will be deleted from this phone.';

  @override
  String get historyClearConfirm => 'Clear';

  @override
  String get historyDelete => 'Delete';

  @override
  String get historyDeleted => 'Scan deleted';

  @override
  String get historyCleared => 'History cleared';

  @override
  String historyBottlesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bottles',
      one: '1 bottle',
    );
    return '$_temp0';
  }

  @override
  String get historyNoMatch => 'No match found';

  @override
  String get historyToday => 'Today';

  @override
  String get historyYesterday => 'Yesterday';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'As in the system';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsHelp => 'Help';

  @override
  String get settingsShowOnboarding => 'Show the intro again';

  @override
  String get settingsAbout => 'About the scanner';

  @override
  String get settingsAboutBody =>
      'The scanner looks the wine up in the «Svoe Vino» catalogue by a photo of the label. Confidence is not calculated: check the name and the year on the card. Photos are sent to the recognition service and are kept only on this phone.';

  @override
  String get settingsOpenSite => 'Open «Svoe Vino»';

  @override
  String get settingsData => 'Data';

  @override
  String get settingsService => 'Recognition service';

  @override
  String settingsCatalogSize(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards in the catalogue',
      one: '1 card in the catalogue',
    );
    return '$_temp0';
  }

  @override
  String resultBottleNearCenterTag(int number) {
    return 'Bottle $number · near the centre';
  }

  @override
  String get resultNoBottleAuto =>
      'No bottle with a label was found. Shoot the label larger and straighter, or draw a frame around the bottle yourself.';

  @override
  String get resultNoBottleRoi =>
      'No bottle with a label was found. Draw a wider frame or go back to all bottles.';

  @override
  String get historyDeleteFailed => 'Could not delete the scan';

  @override
  String get historyClearFailed => 'Could not clear the history';
}
