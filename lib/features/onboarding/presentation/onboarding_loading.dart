import 'package:flutter/material.dart';

class OnboardingLoading extends StatelessWidget {
  const OnboardingLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
