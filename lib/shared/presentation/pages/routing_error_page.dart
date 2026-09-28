import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import '../../../core/router/pages.dart';
import '../../../core/services/language_service.dart';

class RoutingErrorPage extends StatelessWidget {
  const RoutingErrorPage({super.key, required this.state});

  final GoRouterState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.localization.pageNotFound),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(context.localization.routeDoesNotExist(state.uri.toString())),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => context.go(Pages.splash.navigationPath),
              child: Text(context.localization.goToHome),
            ),
          ],
        ),
      ),
    );
  }
}
