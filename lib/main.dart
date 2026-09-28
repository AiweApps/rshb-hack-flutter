import 'dart:async';

// import 'package:winescan/core/services/flavors.dart';
// import 'package:winescan/shared/helpers/service_locator.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/services/language_service.dart';
import 'core/services/theme_service.dart';
import 'di/di_core.dart';
// import 'firebase/firebase_options_dev.dart' as dev;
// import 'firebase/firebase_options_prod.dart' as prod;

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initDependencies();

    // Initialize services before app starts
    await initializeFirebaseApp();
    await LanguageService.initialize();
    await ThemeService.initialize();

    // to catch flutter sdk framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      _catchUnhandledExceptions(details.exception, details.stack);
    };
    runApp(const MyApp());
  }, _catchUnhandledExceptions);
}

FutureOr<void> initializeFirebaseApp() async {
  // final flavor = sl<AppFlavorService>().flavor;
  // Map<AppFlavor, FirebaseOptions> options() => {
  //   AppFlavor.dev: dev.DefaultFirebaseOptions.currentPlatform,
  //   AppFlavor.prod: prod.DefaultFirebaseOptions.currentPlatform,
  // };
  // await Firebase.initializeApp(options: options()[flavor]);
}

void _catchUnhandledExceptions(Object error, StackTrace? stack) {
  // Show fatal error page
  if (kDebugMode) {
    debugPrintStack(stackTrace: stack, label: error.toString());
  }
}
