abstract class BaseBlocUiEffect {}

enum SnackBarType { info, success, error }

enum SnackBarDuration {
  short,
  medium,
  long;

  Duration get duration => switch (this) {
    SnackBarDuration.short => const Duration(seconds: 1),
    SnackBarDuration.medium => const Duration(seconds: 2),
    SnackBarDuration.long => const Duration(seconds: 4),
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
