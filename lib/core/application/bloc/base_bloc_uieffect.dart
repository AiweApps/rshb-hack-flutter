import '../../constants/app_constants.dart';

abstract class BaseBlocUiEffect {}

enum SnackBarType { info, success, error }

enum SnackBarDuration {
  short,
  medium,
  long;

  Duration get duration => switch (this) {
    SnackBarDuration.short => DurationConstant.d1s,
    SnackBarDuration.medium => DurationConstant.d2s,
    SnackBarDuration.long => DurationConstant.d5s,
  };
}

class ShowSnackBar extends BaseBlocUiEffect {
  final String message;
  final SnackBarType type;
  final SnackBarDuration duration;

  ShowSnackBar({
    required this.message,
    required this.type,
    this.duration = SnackBarDuration.medium,
  });
}
