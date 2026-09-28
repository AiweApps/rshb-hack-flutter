import 'package:flutter/material.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/app_style_constants.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/helpers/app_haptics.dart';
import '../../../../../core/services/language_service.dart';
import '../../../domain/models/bottle_box.dart';
import 'compare_panes.dart';
import 'photo_crop.dart';

/// The body of the compare sheet: swipe between the bottle from the photo
/// and the catalogue reference, pinch to zoom either.
class ComparePager extends StatefulWidget {
  final String photoPath;
  final BottleBox? crop;
  final List<int>? frame;
  final int bottleNumber;
  final String cardTitle;
  final String? referenceUrl;
  final Map<String, String> referenceHeaders;

  const ComparePager({
    super.key,
    required this.photoPath,
    required this.crop,
    required this.frame,
    required this.bottleNumber,
    required this.cardTitle,
    required this.referenceUrl,
    required this.referenceHeaders,
  });

  @override
  State<ComparePager> createState() => _ComparePagerState();
}

class _ComparePagerState extends State<ComparePager> {
  final PageController _pageController = PageController();
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;
    final captions = [
      l10n.resultYourPhotoBottle(widget.bottleNumber),
      l10n.resultReferenceOf(widget.cardTitle),
    ];

    return Column(
      children: [
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              AppHaptics.select();
              setState(() => _page = index);
            },
            children: [
              _Zoomable(
                child: widget.crop == null
                    ? Center(
                        child: Text(
                          l10n.resultPhotoMissing,
                          style: context.ts.paragraphTiny,
                        ),
                      )
                    : PhotoCrop(
                        photoPath: widget.photoPath,
                        crop: widget.crop!,
                        frame: widget.frame,
                      ),
              ),
              _Zoomable(
                child: ReferencePane(
                  url: widget.referenceUrl,
                  headers: widget.referenceHeaders,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppPadding.p24,
            AppPadding.p12,
            AppPadding.p24,
            AppPadding.p16,
          ),
          child: Column(
            children: [
              Text(
                captions[_page],
                style: context.ts.paragraphSmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpaces.s12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < captions.length; i++)
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpaces.s4,
                      ),
                      width: AppSize.s8,
                      height: AppSize.s8,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? context.colors.wine
                            : context.colors.rule,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

/// Pinch to zoom; pans only once zoomed in, so an unzoomed swipe reaches
/// the pager instead of being eaten as a pan.
class _Zoomable extends StatefulWidget {
  final Widget child;

  const _Zoomable({required this.child});

  @override
  State<_Zoomable> createState() => _ZoomableState();
}

class _ZoomableState extends State<_Zoomable> {
  final TransformationController _transformation = TransformationController();
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _transformation.addListener(_onTransformed);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.p16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.r16),
        child: ColoredBox(
          color: context.colors.paper2,
          child: InteractiveViewer(
            transformationController: _transformation,
            panEnabled: _isZoomed,
            maxScale: LimitConstants.compareMaxZoom,
            child: SizedBox.expand(child: widget.child),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _transformation.removeListener(_onTransformed);
    _transformation.dispose();
    super.dispose();
  }

  void _onTransformed() {
    final bool zoomed = _transformation.value.getMaxScaleOnAxis() > 1;
    if (zoomed != _isZoomed) setState(() => _isZoomed = zoomed);
  }
}
