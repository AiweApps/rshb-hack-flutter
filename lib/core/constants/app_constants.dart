/// Every timing in the app, named after its value.
class DurationConstant {
  const DurationConstant._();

  static const Duration d100ms = Duration(milliseconds: 100);
  static const Duration d150ms = Duration(milliseconds: 150);
  static const Duration d200ms = Duration(milliseconds: 200);
  static const Duration d300ms = Duration(milliseconds: 300);
  static const Duration d400ms = Duration(milliseconds: 400);
  static const Duration d500ms = Duration(milliseconds: 500);
  static const Duration d700ms = Duration(milliseconds: 700);
  static const Duration d900ms = Duration(milliseconds: 900);

  static const Duration d1s = Duration(seconds: 1);
  static const Duration d2s = Duration(seconds: 2);
  static const Duration d3s = Duration(seconds: 3);
  static const Duration d5s = Duration(seconds: 5);
  static const Duration d10s = Duration(seconds: 10);
  static const Duration d15s = Duration(seconds: 15);
  static const Duration d30s = Duration(seconds: 30);
  static const Duration d60s = Duration(seconds: 60);
  static const Duration d200s = Duration(seconds: 200);
}

/// Behaviour of the recognition API client. The base URL comes from the flavor.
class ApiConstants {
  const ApiConstants._();

  /// Recognition is queued on the server and may take up to three minutes;
  /// the web client waits the same 200 seconds.
  static const Duration recognizeTimeout = DurationConstant.d200s;
  static const Duration defaultTimeout = DurationConstant.d30s;
  static const Duration guestTokenTimeout = DurationConstant.d15s;

  /// The status pill on the scan screen re-reads the service state this often.
  static const Duration statusRefreshInterval = DurationConstant.d15s;

  /// 429 and "busy" 503 responses say when to come back: the client waits and
  /// retries on its own this many times before showing an error.
  static const int maxAutoRetries = 3;
  static const Duration defaultRetryAfter = DurationConstant.d5s;

  /// A token that would expire within this margin is refreshed ahead of time,
  /// so a long recognition request does not start with a token about to die.
  static const Duration guestTokenExpiryMargin = DurationConstant.d60s;

  static const String bearerPrefix = 'Bearer ';
  static const String authorizationHeader = 'Authorization';
  static const String retryAfterHeader = 'Retry-After';
  static const String imageField = 'image';
  static const String targetRoiField = 'target_roi';
  static const String uploadFileName = 'photo.jpg';
}

/// Limits of what the app keeps and prepares on the device.
class LimitConstants {
  const LimitConstants._();

  /// The picker downsizes the photo to this side before upload: well under
  /// the 24 MP server cap and still enough for the label to be read.
  static const int uploadMaxSide = 4000;
  static const int uploadJpegQuality = 92;

  /// Recent scans shown on the scan tab while the camera is not available.
  static const int maxRecentScansOnHome = 6;

  /// A drawn frame narrower than this (in screen pixels) is a tap, not a box.
  static const double minRoiSideOnScreen = 16;
  static const double minRoiSideWhileResizing = 24;

  /// How far the comparison panes zoom in.
  static const double compareMaxZoom = 5;

  /// Padding around the bottle crop shown next to the reference, as a share
  /// of the longer box side.
  static const double cropPaddingFactor = 0.04;
}

/// External addresses the app opens or recognises.
class LinkConstants {
  const LinkConstants._();

  /// Only catalogue pages under this prefix are offered as a link, the same
  /// rule as the web UI.
  static const String vinoSvoeWinesPrefix = 'https://vino-svoe.ru/wines/';
  static const String vinoSvoeSite = 'https://vino-svoe.ru/';
}
