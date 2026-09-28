import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// Typed registry of bundled SVG assets.
///
/// Add a case to the enum, map it to a filename in [SvgIconResExt.path], drop
/// the file into `assets/images/`, and use it as
/// `SvgIconRes.toastInfo.widget(width: 32, height: 32)`.
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

/// Typed registry of bundled raster assets.
enum PngIconRes { appLogo }

extension PngIconResExt on PngIconRes {
  String get path {
    final String assetName = switch (this) {
      PngIconRes.appLogo => "app_logo.png",
    };
    return "assets/images/$assetName";
  }

  Image widget({double? width, double? height, BoxFit fit = BoxFit.contain}) {
    return Image.asset(path, width: width, height: height, fit: fit);
  }
}

/// Glyph icons, one name per meaning, drawn from the platform's own set:
/// SF Symbols-styled [CupertinoIcons] on iOS, [Icons] elsewhere.
/// Use as `Icon(AppIcon.camera.data)`.
enum AppIcon {
  camera,
  cameraOff,
  gallery,
  flashOn,
  flashOff,
  history,
  settings,
  back,
  close,
  check,
  chevronRight,
  more,
  share,
  code,
  edit,
  frame,
  forward,
  openExternal,
  delete,
  info,
  language,
  appearance,
  play,
  cloud,
  error,
  brokenImage,
  compare,
}

extension AppIconData on AppIcon {
  IconData get data =>
      defaultTargetPlatform == TargetPlatform.iOS ? _cupertino : _material;

  IconData get _cupertino => switch (this) {
    AppIcon.camera => CupertinoIcons.camera,
    AppIcon.cameraOff => CupertinoIcons.camera_on_rectangle,
    AppIcon.gallery => CupertinoIcons.photo_on_rectangle,
    AppIcon.flashOn => CupertinoIcons.bolt_fill,
    AppIcon.flashOff => CupertinoIcons.bolt_slash,
    AppIcon.history => CupertinoIcons.clock,
    AppIcon.settings => CupertinoIcons.slider_horizontal_3,
    AppIcon.back => CupertinoIcons.chevron_back,
    AppIcon.close => CupertinoIcons.xmark,
    AppIcon.check => CupertinoIcons.checkmark,
    AppIcon.chevronRight => CupertinoIcons.chevron_right,
    AppIcon.more => CupertinoIcons.ellipsis,
    AppIcon.share => CupertinoIcons.square_arrow_up,
    AppIcon.code => CupertinoIcons.chevron_left_slash_chevron_right,
    AppIcon.edit => CupertinoIcons.pencil,
    AppIcon.frame => CupertinoIcons.crop,
    AppIcon.forward => CupertinoIcons.arrow_right,
    AppIcon.openExternal => CupertinoIcons.arrow_up_right_square,
    AppIcon.delete => CupertinoIcons.trash,
    AppIcon.info => CupertinoIcons.info_circle,
    AppIcon.language => CupertinoIcons.globe,
    AppIcon.appearance => CupertinoIcons.circle_lefthalf_fill,
    AppIcon.play => CupertinoIcons.play_circle,
    AppIcon.cloud => CupertinoIcons.cloud,
    AppIcon.error => CupertinoIcons.exclamationmark_circle,
    AppIcon.brokenImage => CupertinoIcons.photo,
    AppIcon.compare => CupertinoIcons.square_split_2x1,
  };

  IconData get _material => switch (this) {
    AppIcon.camera => Icons.photo_camera_outlined,
    AppIcon.cameraOff => Icons.no_photography_outlined,
    AppIcon.gallery => Icons.photo_library_outlined,
    AppIcon.flashOn => Icons.flash_on,
    AppIcon.flashOff => Icons.flash_off,
    AppIcon.history => Icons.history,
    AppIcon.settings => Icons.tune,
    AppIcon.back => Icons.arrow_back,
    AppIcon.close => Icons.close,
    AppIcon.check => Icons.check,
    AppIcon.chevronRight => Icons.chevron_right,
    AppIcon.more => Icons.more_horiz,
    AppIcon.share => Icons.share_outlined,
    AppIcon.code => Icons.code,
    AppIcon.edit => Icons.edit_outlined,
    AppIcon.frame => Icons.crop_free,
    AppIcon.forward => Icons.arrow_forward,
    AppIcon.openExternal => Icons.open_in_new,
    AppIcon.delete => Icons.delete_outline,
    AppIcon.info => Icons.info_outline,
    AppIcon.language => Icons.language,
    AppIcon.appearance => Icons.brightness_6_outlined,
    AppIcon.play => Icons.play_circle_outline,
    AppIcon.cloud => Icons.cloud_outlined,
    AppIcon.error => Icons.error_outline,
    AppIcon.brokenImage => Icons.broken_image_outlined,
    AppIcon.compare => Icons.compare_outlined,
  };
}
