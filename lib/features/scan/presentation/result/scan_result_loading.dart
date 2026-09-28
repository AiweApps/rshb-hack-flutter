import 'package:flutter/material.dart';

/// Shown only while a stored scan is read from the database.
class ScanResultLoading extends StatelessWidget {
  const ScanResultLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
