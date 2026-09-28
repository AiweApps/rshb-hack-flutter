import 'package:bloc_presentation/bloc_presentation.dart';
import 'package:flutter/material.dart';

import '../../presentation/widgets/app_toast.dart';
import 'base_bloc_uieffect.dart';

class BaseBlocPresentationListener<
  B extends BlocPresentationMixin<dynamic, BaseBlocUiEffect>
>
    extends BlocPresentationListener<B, BaseBlocUiEffect> {
  final Widget child;

  BaseBlocPresentationListener({
    super.key,
    super.bloc,
    required this.child,
    void Function(BuildContext context, BaseBlocUiEffect effect)? listener,
  }) : super(
         listener: (context, effect) {
           if (effect is ShowSnackBar) {
             showAppToast(context, effect);
             return;
           }
           listener?.call(context, effect);
         },
         child: child,
       );
}
