import 'package:bloc_presentation/bloc_presentation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/api/models/app_error.dart';
import 'base_bloc_state.dart';
import 'base_bloc_uieffect.dart';
import 'snack_bar_emitter.dart';

/// Base for every screen bloc.
///
/// [State] is bound to [BaseBlocState] on purpose: it makes "every screen state
/// carries a ScreenStatus" a compile-time guarantee instead of a convention
/// someone has to remember.
abstract class BaseBloc<Event, State extends BaseBlocState>
    extends Bloc<Event, State>
    with BlocPresentationMixin<State, BaseBlocUiEffect> {
  BaseBloc(super.initialState);

  void emitUiEffect(BaseBlocUiEffect effect) {
    if (isClosed) return;
    emitPresentation(effect);
  }

  /// Typed snack bar facade: `emitSnackBar.success('Saved')`.
  SnackBarEmitter get emitSnackBar => SnackBarEmitter(emitUiEffect);

  void emitErrorSnackBar(AppError error) {
    emitSnackBar.error(error.getErrorMessage());
  }
}
