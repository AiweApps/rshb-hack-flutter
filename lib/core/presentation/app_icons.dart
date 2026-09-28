import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// Typed registry of bundled SVG assets.
///
/// Add a case to the enum, map it to a filename in [SvgIconResExt.path], drop
/// the file into `assets/images/`, and use it as
/// `SvgIconRes.toastInfo.widget(width: 32, height: 32)`.
///
/// Mirror this pattern with a `PngIconRes` enum once raster assets are added.
enum SvgIconRes { toastInfo, toastSuccess, toastError, close24, errorReload }

extension SvgIconResExt on SvgIconRes {
  String get path {
    final String assetName = switch (this) {
      SvgIconRes.toastInfo => "ic_toast_info.svg",
      SvgIconRes.toastSuccess => "ic_toast_success.svg",
      SvgIconRes.toastError => "ic_toast_error.svg",
      SvgIconRes.close24 => "ic_close_24.svg",
      SvgIconRes.errorReload => "ic_error_reload.svg",
    };
    return "assets/images/$assetName";
  }

  SvgPicture widget({
    double? width,
    double? height,
    ColorFilter? colorFilter,
    BoxFit? fit,
  }) {
    return SvgPicture.asset(
      path,
      width: width,
      height: height,
      colorFilter: colorFilter,
      fit: fit ?? BoxFit.contain,
    );
  }
}
