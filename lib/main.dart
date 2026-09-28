import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/helpers/app_utils.dart';
import 'core/services/language_service.dart';
import 'core/services/theme_service.dart';
import 'di/di_core.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initDependencies();

    // Firebase is wired up once the flavor configs are generated
    // (README, "Firebase"); until then analytics and crash reports are off.
    await LanguageService.initialize();
    await ThemeService.initialize();
    await AppUtils.initialize();

    // to catch flutter sdk framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      _catchUnhandledExceptions(details.exception, details.stack);
    };
    runApp(const MyApp());
  }, _catchUnhandledExceptions);
}

void _catchUnhandledExceptions(Object error, StackTrace? stack) {
  if (kDebugMode) {
    debugPrintStack(stackTrace: stack, label: error.toString());
  }
}
