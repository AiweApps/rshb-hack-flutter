import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../constants/app_style_constants.dart';
import '../extensions/context_extensions.dart';

/// The only sanctioned way to draw an image that comes from the network.
///
/// A bare `Image.network` leaves four things to the call site, and they get
/// forgotten every time: a placeholder while loading, something to draw when
/// the url is empty or the request fails, an on-disk cache, and a decode size
/// bounded by the box the image is painted in. This widget owns all four.
///
/// ```dart
/// RemoteImage(
///   url: track.album.coverSmall,
///   width: AppSize.s56,
///   height: AppSize.s56,
///   borderRadius: AppRadius.r8,
/// )
/// ```
///
/// When the backend offers several sizes of the same picture, pass the rest as
/// fallbacks: the first url that loads wins, the others are tried in order.
///
/// ```dart
/// RemoteImage.withFallbacks(
///   url: track.album.coverMedium,
///   fallbackUrls: [track.album.coverBig, track.album.cover],
///   width: AppSize.s250,
///   height: AppSize.s250,
/// )
/// ```
class RemoteImage extends StatefulWidget {
  /// Primary url. `null` and blank are valid inputs — they render [errorWidget].
  final String? url;

  /// Tried in order if [url] fails. Blank and `null` entries are skipped.
  final List<String?> fallbackUrls;

  final double? width;
  final double? height;
  final BoxFit fit;

  /// Corner radius from [AppRadius]. Clipping is skipped when it is `null`.
  final double? borderRadius;

  /// Shown while loading. Defaults to a neutral box of the same size.
  final Widget? placeholder;

  /// Shown when every url failed or none was usable. Defaults to [placeholder].
  final Widget? errorWidget;

  final Duration fadeIn;

  const RemoteImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.fadeIn = DurationConstant.d300ms,
  }) : fallbackUrls = const <String?>[];

  const RemoteImage.withFallbacks({
    super.key,
    required this.url,
    required this.fallbackUrls,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.fadeIn = DurationConstant.d300ms,
  });

  @override
  State<RemoteImage> createState() => _RemoteImageState();
}

class _RemoteImageState extends State<RemoteImage> {
  late List<String> _urls;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _urls = _resolveUrls();
  }

  @override
  void didUpdateWidget(covariant RemoteImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // List tiles are recycled: without this the widget keeps showing the
    // previous row's picture, or stays stuck on its failed fallback.
    if (oldWidget.url != widget.url ||
        !listEquals(oldWidget.fallbackUrls, widget.fallbackUrls)) {
      _urls = _resolveUrls();
      _index = 0;
    }
  }

  /// Drops empty entries and repairs protocol-relative urls (`//host/pic.jpg`),
  /// which some backends still return and `Uri` cannot resolve on its own.
  List<String> _resolveUrls() {
    return <String?>[widget.url, ...widget.fallbackUrls]
        .whereType<String>()
        .map((String url) => url.trim())
        .where((String url) => url.isNotEmpty)
        .map((String url) => url.startsWith('//') ? 'https:$url' : url)
        .toList(growable: false);
  }

  void _useNextUrl() {
    // Called from the error builder, i.e. mid-build — defer the rebuild.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _index++);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_index >= _urls.length) return _clipped(_error());

    // Decode at the size the image is actually painted at: a 56pt thumbnail
    // otherwise costs as much memory as the full-resolution original.
    final double pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final int? memWidth = widget.width == null
        ? null
        : (widget.width! * pixelRatio).round();
    final int? memHeight = widget.height == null
        ? null
        : (widget.height! * pixelRatio).round();

    return _clipped(
      CachedNetworkImage(
        imageUrl: _urls[_index],
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        fadeInDuration: widget.fadeIn,
        memCacheWidth: memWidth,
        memCacheHeight: memHeight,
        placeholder: (BuildContext context, String url) => _placeholder(),
        errorWidget: (BuildContext context, String url, Object error) {
          if (_index < _urls.length - 1) {
            _useNextUrl();
            return _placeholder();
          }
          return _error();
        },
      ),
    );
  }

  Widget _clipped(Widget child) {
    if (widget.borderRadius == null) return child;
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius!),
      child: child,
    );
  }

  Widget _placeholder() => widget.placeholder ?? _neutralBox();

  Widget _error() => widget.errorWidget ?? _placeholder();

  Widget _neutralBox() {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ColoredBox(color: context.colors.neutrals300),
    );
  }
}
