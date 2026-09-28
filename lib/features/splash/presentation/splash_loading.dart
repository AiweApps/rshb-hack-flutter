import 'package:flutter/material.dart';

import 'splash_content.dart';

/// Nothing is fetched on the splash, so loading looks like the content.
class SplashLoading extends StatelessWidget {
  const SplashLoading({super.key});

  @override
  Widget build(BuildContext context) => const SplashContent();
}
