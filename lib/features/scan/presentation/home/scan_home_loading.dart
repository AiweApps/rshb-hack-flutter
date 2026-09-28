import 'package:flutter/material.dart';

class ScanHomeLoading extends StatelessWidget {
  const ScanHomeLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
