import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import '../../../core/constants/app_style_constants.dart';
import '../../../core/extensions/context_extensions.dart';
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.p24),
              child: Text(
                context.localization.routeDoesNotExist(state.uri.toString()),
                style: context.ts.paragraph,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpaces.s16),
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
