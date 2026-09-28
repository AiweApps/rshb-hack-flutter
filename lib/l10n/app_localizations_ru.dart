// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Винный сканер';

  @override
  String get splashTitle => 'Винный сканер';

  @override
  String get tabScan => 'Сканер';

  @override
  String get tabHistory => 'История';

  @override
  String get tabSettings => 'Настройки';

  @override
  String get disclaimer =>
      'Сканер может ошибаться — сверяйте название и год на карточке.';

  @override
  String get pageNotFound => 'Страница не найдена';

  @override
  String routeDoesNotExist(String route) {
    return 'Маршрут [$route] не существует';
  }

  @override
  String get goToHome => 'На главную';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonGotIt => 'Понятно';

  @override
  String get errorConnectionTitle => 'Нет связи';

  @override
  String get errorConnectionFullScreenTitle => 'Нет подключения к интернету';

  @override
  String get errorConnectionSubtitle => 'Проверьте интернет и попробуйте снова';

  @override
  String get errorServerTitle => 'Что-то пошло не так';

  @override
  String get errorServerSubtitle =>
      'Не удалось загрузить данные. Попробуйте снова';

  @override
  String get errorReloadButton => 'Повторить';

  @override
  String get onboardingKicker => 'каталог «Своё вино»';

  @override
  String get onboardingTitle1 => 'Узнайте вино по фото этикетки';

  @override
  String get onboardingBody1 =>
      'Сканер ищет вино в каталоге «Своё вино» по фотографии этикетки и показывает лучшее совпадение и похожие варианты.';

  @override
  String get onboardingTitle2 => 'Как это работает';

  @override
  String get onboardingStep1Title => 'Снимите бутылку';

  @override
  String get onboardingStep1Body => 'так, чтобы этикетка была видна целиком.';

  @override
  String get onboardingStep2Title => 'Выберите бутылку.';

  @override
  String get onboardingStep2Body =>
      'Если их несколько — нажмите нужную рамку или обведите её сами.';

  @override
  String get onboardingStep3Title => 'Сверьте результат';

  @override
  String get onboardingStep3Body => 'с карточкой по ссылке.';

  @override
  String get onboardingTitle3 => 'Что покажет сканер';

  @override
  String get onboardingGets1 => 'Лучшее совпадение из каталога';

  @override
  String get onboardingGets2 => 'Похожие варианты';

  @override
  String get onboardingGets3 => 'Эталонное фото бутылки';

  @override
  String get onboardingGets4 => 'Ссылку на карточку «Своё вино»';

  @override
  String get onboardingNext => 'Далее';

  @override
  String get onboardingStart => 'Начать';

  @override
  String get onboardingSkip => 'Пропустить';

  @override
  String get scanPickPhoto => 'Выбрать фото';

  @override
  String get scanRecentTitle => 'Последние сканы';

  @override
  String get scanRecentAll => 'Все';

  @override
  String get statusChecking => 'проверяем…';

  @override
  String get statusReady => 'готов';

  @override
  String get statusBusy => 'занят';

  @override
  String statusBusyQueue(int count) {
    return 'занят · в очереди $count';
  }

  @override
  String get statusDown => 'не отвечает';

  @override
  String get statusUnavailable => 'недоступен';

  @override
  String get statusNoAccess => 'нет доступа';

  @override
  String get statusRateLimited => 'подождите';

  @override
  String get statusOffline => 'нет связи';

  @override
  String get statusDev => 'разработка';

  @override
  String get statusReadyDetail =>
      'Сервис распознавания подключён и свободен — можно загружать фото.';

  @override
  String get statusBusyDetail =>
      'Сервис сейчас распознаёт другое фото. Новое фото подождёт своей очереди.';

  @override
  String get statusDownDetail =>
      'Сервис распознавания сейчас не отвечает. Попробуйте позже.';

  @override
  String get statusUnavailableDetail =>
      'Сервис распознавания временно недоступен. Попробуйте позже.';

  @override
  String get statusNoAccessDetail =>
      'Не удалось открыть сессию. Проверьте интернет и попробуйте позже.';

  @override
  String get statusRateLimitedDetail =>
      'Подождите несколько секунд и обновите статус.';

  @override
  String get statusOfflineDetail =>
      'Нет связи со сканером. Проверьте интернет.';

  @override
  String get statusDevDetail =>
      'Режим разработки интерфейса: распознавание не подключено.';

  @override
  String get statusAutoRefresh => 'Статус обновляется сам.';

  @override
  String get loadingReading => 'Читаем этикетку…';

  @override
  String get loadingRoi => 'Распознаём выбранную бутылку…';

  @override
  String get loadingNote => 'Обычно несколько секунд.';

  @override
  String get loadingBusy => 'Сервис занят';

  @override
  String get loadingTooMany => 'Слишком много запросов';

  @override
  String loadingRetryIn(int seconds, int attempt, int total) {
    return 'Повторим автоматически через $seconds с (попытка $attempt из $total).';
  }

  @override
  String get resultTitle => 'Результат';

  @override
  String get resultAnswerTitle => 'Ответ сканера';

  @override
  String resultBottleN(int number) {
    return 'Бутылка $number';
  }

  @override
  String get resultTabAll => 'Все';

  @override
  String get resultBestMatch => 'лучшее совпадение';

  @override
  String get resultAlternatives => 'Похожие варианты';

  @override
  String get resultNoMatchForBottle =>
      'Для этой бутылки совпадение не найдено.';

  @override
  String resultBottleNoMatch(int number) {
    return 'Бутылка $number: совпадение не найдено';
  }

  @override
  String get resultNoBottleAdviceAuto =>
      'Снимите этикетку крупнее и ровнее или обведите бутылку вручную.';

  @override
  String get resultNoBottleAdviceRoi =>
      'Обведите бутылку шире или вернитесь ко всем бутылкам.';

  @override
  String get resultRescan => 'Распознать';

  @override
  String get resultRescanHint => 'Начнёт новый скан только для этой бутылки.';

  @override
  String get resultOpenOnSite => 'Открыть на «Своём вине»';

  @override
  String get resultNoSiteUrl =>
      'Адрес страницы на «Своём вине» в каталоге не указан';

  @override
  String get resultReferenceMissing => 'эталон не показан';

  @override
  String get resultPhotoMissing => 'фото не показано';

  @override
  String get resultYourPhoto => 'Ваше фото';

  @override
  String get resultReference => 'Эталон из каталога';

  @override
  String get resultCompareTitle => 'Сравните с эталоном';

  @override
  String resultYourPhotoBottle(int number) {
    return 'Ваше фото · бутылка $number';
  }

  @override
  String resultReferenceOf(String title) {
    return 'Эталон: $title';
  }

  @override
  String get resultDrawFrame => 'Выделить рамку';

  @override
  String get resultMore => 'Ещё';

  @override
  String get resultNewScan => 'Новый скан';

  @override
  String get resultCompare => 'Сравнить';

  @override
  String get resultFrame => 'Рамка';

  @override
  String get resultShareJson => 'Поделиться полным ответом JSON';

  @override
  String resultShareBottleJson(int number) {
    return 'Поделиться JSON бутылки $number';
  }

  @override
  String get resultShareFrameJson => 'Поделиться JSON рамки';

  @override
  String get resultTechDetails => 'Технические детали';

  @override
  String get noticeRoiFound =>
      'Распознано по выбранной рамке. Ниже — ответ для этой области.';

  @override
  String get noticeRoiEmpty =>
      'Распознано по выбранной рамке. В рамке не найдена бутылка с этикеткой.';

  @override
  String noticeManyBottles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Найдено больше одной бутылки — $count. У каждой свой ответ: выберите нужную рамкой на фото или вкладкой ниже.',
      one: 'Найдена одна бутылка.',
    );
    return '$_temp0';
  }

  @override
  String get decisionUnknown => 'Не удалось выбрать совпадение';

  @override
  String get decisionInsufficient => 'Недостаточно признаков для ответа';

  @override
  String get decisionAmbiguous => 'На фото несколько бутылок — выберите нужную';

  @override
  String get decisionNoTarget => 'Бутылка с этикеткой не найдена';

  @override
  String get frameHint => 'Обведите нужную бутылку пальцем';

  @override
  String get frameScan => 'Сканировать';

  @override
  String get scanErrorTitleDefault => 'Не получилось';

  @override
  String get scanErrorRetry => 'Повторить';

  @override
  String get scanErrorNoAccess => 'Нет доступа';

  @override
  String get scanErrorTooLarge => 'Слишком большое изображение';

  @override
  String get scanErrorFormat => 'Формат не поддерживается';

  @override
  String get scanErrorUnprocessed => 'Изображение не обработано';

  @override
  String get scanErrorTooMany => 'Слишком много запросов';

  @override
  String get scanErrorService => 'Ошибка сервиса';

  @override
  String get scanErrorBusy => 'Сервис занят или недоступен';

  @override
  String get scanErrorTimeout => 'Время ожидания истекло';

  @override
  String get scanErrorNoResponse => 'Нет ответа';

  @override
  String scanErrorCode(int code) {
    return 'Ошибка $code';
  }

  @override
  String get scanErrorPhotoOpen => 'Не удалось открыть фото';

  @override
  String get scanErrorTextNoAccess =>
      'Не удалось открыть сессию. Проверьте интернет и повторите.';

  @override
  String get scanErrorTextTooLarge =>
      'Файл больше 20 МБ или 24 Мп. Снимите фото заново.';

  @override
  String get scanErrorTextFormat => 'Нужен JPEG, PNG или WebP.';

  @override
  String get scanErrorTextUnprocessed =>
      'Сервис не смог обработать изображение. Попробуйте другое фото.';

  @override
  String get scanErrorTextBadRoi =>
      'Рамка не попала в изображение. Обведите бутылку заново.';

  @override
  String get scanErrorTextTooMany => 'Подождите несколько секунд и повторите.';

  @override
  String get scanErrorTextService =>
      'Сервис распознавания ответил ошибкой. Повторите позже.';

  @override
  String get scanErrorTextBusy =>
      'Сервис занят другими фото, повторите чуть позже.';

  @override
  String get scanErrorTextTimeout =>
      'Время ожидания истекло. Повторите запрос.';

  @override
  String get scanErrorTextOffline =>
      'Нет связи с сервисом. Проверьте интернет и повторите.';

  @override
  String get scanErrorTextDefault => 'Повторите попытку.';

  @override
  String get scanErrorTextPhotoOpen => 'Выберите другое фото.';

  @override
  String get techDecision => 'решение';

  @override
  String get techPrimaryBasis => 'основание цели';

  @override
  String get techMode => 'режим';

  @override
  String get techRawSlug => 'raw.slug';

  @override
  String get techBestCandidate => 'best_candidate';

  @override
  String get techCardSlug => 'slug карточки';

  @override
  String get techPageUrl => 'адрес страницы';

  @override
  String get techPageSource => 'источник адреса';

  @override
  String get techSnapshot => 'снимок сайта';

  @override
  String get techSnapshotYes => 'есть в снимках сайта 17–21.09';

  @override
  String get techSnapshotNo => 'не было в снимках сайта 17–21.09';

  @override
  String get techRoi => 'рамка запроса';

  @override
  String get techBottles => 'бутылок';

  @override
  String get techFrame => 'кадр (EXIF)';

  @override
  String get techFile => 'файл';

  @override
  String techFileValue(String format, int bytes) {
    return '$format · $bytes байт';
  }

  @override
  String get techProbability => 'вероятность';

  @override
  String get techProbabilityValue => 'не рассчитывается (без калибровки)';

  @override
  String get techBackendTime => 'время сервиса';

  @override
  String techSeconds(String seconds) {
    return '$seconds с';
  }

  @override
  String get techProfile => 'профиль ответа';

  @override
  String get techReasons => 'причины';

  @override
  String get techNone => '—';

  @override
  String get historyTitle => 'История';

  @override
  String get historyEmptyTitle => 'Пока ничего не отсканировано';

  @override
  String get historyEmptyBody =>
      'Сфотографируйте этикетку — результат появится здесь.';

  @override
  String get historyEmptyAction => 'Сканировать';

  @override
  String get historyClear => 'Очистить историю';

  @override
  String get historyClearConfirmTitle => 'Очистить историю?';

  @override
  String get historyClearConfirmBody =>
      'Все сканы и их фото будут удалены с этого телефона.';

  @override
  String get historyClearConfirm => 'Очистить';

  @override
  String get historyDelete => 'Удалить';

  @override
  String get historyDeleted => 'Скан удалён';

  @override
  String get historyCleared => 'История очищена';

  @override
  String historyBottlesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count бутылок',
      few: '$count бутылки',
      one: '1 бутылка',
    );
    return '$_temp0';
  }

  @override
  String get historyNoMatch => 'Совпадение не найдено';

  @override
  String get historyToday => 'Сегодня';

  @override
  String get historyYesterday => 'Вчера';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsAppearance => 'Оформление';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get themeSystem => 'Как в системе';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsHelp => 'Помощь';

  @override
  String get settingsShowOnboarding => 'Показать вводный экран';

  @override
  String get settingsAbout => 'О сканере';

  @override
  String get settingsAboutBody =>
      'Сканер ищет вино в каталоге «Своё вино» по фотографии этикетки. Уверенность не рассчитывается: сверяйте название и год на карточке. Фото отправляются в сервис распознавания и хранятся только на этом телефоне.';

  @override
  String get settingsOpenSite => 'Открыть «Своё вино»';

  @override
  String get settingsData => 'Данные';

  @override
  String get settingsService => 'Сервис распознавания';

  @override
  String settingsCatalogSize(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count карточек в каталоге',
      few: '$count карточки в каталоге',
      one: '1 карточка в каталоге',
    );
    return '$_temp0';
  }

  @override
  String resultBottleNearCenterTag(int number) {
    return 'Бутылка $number · у центра';
  }

  @override
  String get resultNoBottleAuto =>
      'Бутылка с этикеткой не найдена. Снимите этикетку крупнее и ровнее или обведите бутылку вручную.';

  @override
  String get resultNoBottleRoi =>
      'Бутылка с этикеткой не найдена. Обведите бутылку шире или вернитесь ко всем бутылкам.';

  @override
  String get historyDeleteFailed => 'Не удалось удалить скан';

  @override
  String get historyClearFailed => 'Не удалось очистить историю';

  @override
  String get scanNoCameraTitle => 'Нет доступа к камере';

  @override
  String get scanNoCameraBody =>
      'Разрешите камеру в настройках, чтобы сканировать этикетки.';

  @override
  String get scanAllowCamera => 'Разрешить камеру';

  @override
  String get scanOpenSettings => 'Открыть настройки';

  @override
  String get scanCameraUnavailableTitle => 'Камера недоступна';

  @override
  String get scanCameraUnavailableBody =>
      'На этом устройстве нет камеры. Выберите фото из галереи.';

  @override
  String get scanHint => 'Наведите на этикетку';

  @override
  String get scanShutter => 'Снять';

  @override
  String get scanFlash => 'Вспышка';

  @override
  String settingsVersion(String version, String build) {
    return 'Версия $version ($build)';
  }
}
