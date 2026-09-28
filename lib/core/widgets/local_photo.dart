import 'dart:io';

import 'package:flutter/material.dart';

import '../constants/app_style_constants.dart';
import '../extensions/context_extensions.dart';

/// A photo from the device, painted into a fixed box: decoded no larger than
/// the box needs, and a blank card when the file is gone. The counterpart of
/// `RemoteImage` for files the app itself keeps.
class LocalPhoto extends StatelessWidget {
  final String path;
  final double width;
  final double height;
  final double borderRadius;

  const LocalPhoto({
    super.key,
    required this.path,
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.r12,
  });

  @override
  Widget build(BuildContext context) {
    final double pixelRatio = MediaQuery.devicePixelRatioOf(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.file(
        File(path),
        width: width,
        height: height,
        fit: BoxFit.cover,
        cacheWidth: (width * pixelRatio).round(),
        errorBuilder: (context, _, _) => SizedBox(
          width: width,
          height: height,
          child: ColoredBox(
            color: context.colors.paper2,
            child: Icon(Icons.wine_bar_outlined, color: context.colors.muted),
          ),
        ),
      ),
    );
  }
}
