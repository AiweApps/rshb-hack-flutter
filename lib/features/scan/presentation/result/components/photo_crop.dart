import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../domain/models/bottle_box.dart';

/// A part of the user's photo — the bottle the answer is about — cut out by
/// a box in frame pixels and scaled to fit the widget.
class PhotoCrop extends StatefulWidget {
  final String photoPath;
  final BottleBox crop;

  /// The frame the box refers to; the decoded image may differ in size.
  final List<int>? frame;

  const PhotoCrop({
    super.key,
    required this.photoPath,
    required this.crop,
    required this.frame,
  });

  @override
  State<PhotoCrop> createState() => _PhotoCropState();
}

class _PhotoCropState extends State<PhotoCrop> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant PhotoCrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoPath != widget.photoPath) _resolve();
  }

  @override
  Widget build(BuildContext context) {
    final ui.Image? image = _image;
    if (image == null) {
      return ColoredBox(color: context.colors.paper2);
    }
    return CustomPaint(
      painter: _CropPainter(
        image: image,
        crop: widget.crop,
        frame: widget.frame,
      ),
    );
  }

  @override
  void dispose() {
    _detach();
    _image?.dispose();
    super.dispose();
  }

  void _resolve() {
    _detach();
    final stream = FileImage(
      File(widget.photoPath),
    ).resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener((info, _) {
      if (!mounted) {
        info.dispose();
        return;
      }
      setState(() {
        _image?.dispose();
        _image = info.image;
      });
    }, onError: (_, _) {});
    stream.addListener(listener);
    _stream = stream;
    _listener = listener;
  }

  void _detach() {
    final listener = _listener;
    if (listener != null) _stream?.removeListener(listener);
    _stream = null;
    _listener = null;
  }
}

class _CropPainter extends CustomPainter {
  final ui.Image image;
  final BottleBox crop;
  final List<int>? frame;

  const _CropPainter({
    required this.image,
    required this.crop,
    required this.frame,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Frame pixels → decoded pixels, in case the two differ.
    final double kx = frame == null || frame![0] == 0
        ? 1
        : image.width / frame![0];
    final double ky = frame == null || frame![1] == 0
        ? 1
        : image.height / frame![1];
    final double pad = LimitConstants.cropPaddingFactor * crop.longerSide;
    final Rect src = Rect.fromLTRB(
      ((crop.x1 - pad) * kx).clamp(0, image.width.toDouble()),
      ((crop.y1 - pad) * ky).clamp(0, image.height.toDouble()),
      ((crop.x2 + pad) * kx).clamp(0, image.width.toDouble()),
      ((crop.y2 + pad) * ky).clamp(0, image.height.toDouble()),
    );
    if (src.width < 1 || src.height < 1) return;

    // Contain the crop in the box, centred.
    final double scale = (size.width / src.width < size.height / src.height)
        ? size.width / src.width
        : size.height / src.height;
    final Size drawn = Size(src.width * scale, src.height * scale);
    final Rect dst = Rect.fromLTWH(
      (size.width - drawn.width) / 2,
      (size.height - drawn.height) / 2,
      drawn.width,
      drawn.height,
    );
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant _CropPainter old) =>
      old.image != image || old.crop != crop || old.frame != frame;
}
