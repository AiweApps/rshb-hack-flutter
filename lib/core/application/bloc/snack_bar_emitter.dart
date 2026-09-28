import 'base_bloc_uieffect.dart';

/// Typed facade over the [ShowSnackBar] ui-effect.
///
/// Used from a bloc as `emitSnackBar.success('Saved')`.
class SnackBarEmitter {
  final void Function(ShowSnackBar) _emit;

  SnackBarEmitter(this._emit);

  void info(
    String message, {
    SnackBarDuration duration = SnackBarDuration.medium,
  }) {
    _emit(
      ShowSnackBar(
        message: message,
        type: SnackBarType.info,
        duration: duration,
      ),
    );
  }

  void success(
    String message, {
    SnackBarDuration duration = SnackBarDuration.medium,
  }) {
    _emit(
      ShowSnackBar(
        message: message,
        type: SnackBarType.success,
        duration: duration,
      ),
    );
  }

  void error(
    String message, {
    SnackBarDuration duration = SnackBarDuration.medium,
  }) {
    _emit(
      ShowSnackBar(
        message: message,
        type: SnackBarType.error,
        duration: duration,
      ),
    );
  }
}
