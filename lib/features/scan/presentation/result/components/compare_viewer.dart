import 'package:flutter/material.dart';

import '../../../../../core/constants/app_style_constants.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/helpers/app_haptics.dart';
import '../../../../../core/services/language_service.dart';
import '../../../application/result/bloc/scan_result_uieffect.dart';
import 'compare_panes.dart';
import 'photo_crop.dart';

/// «Сравните с эталоном» full screen: swipe between your bottle and the
/// reference, pinch to zoom either. Shown from `_onUiEffect`.
class CompareViewer extends StatefulWidget {
  final CompareArgs args;

  const CompareViewer({super.key, required this.args});

  static Future<void> show(BuildContext context, CompareArgs args) {
    return showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: context.colors.paper,
        child: CompareViewer(args: args),
      ),
    );
  }

  @override
  State<CompareViewer> createState() => _CompareViewerState();
}

class _CompareViewerState extends State<CompareViewer> {
  final PageController _pageController = PageController();
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;
    final args = widget.args;
    final captions = [
      l10n.resultYourPhotoBottle(args.bottleNumber),
      l10n.resultReferenceOf(args.cardTitle),
    ];

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppPadding.p20,
              AppPadding.p12,
              AppPadding.p8,
              AppPadding.p4,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(l10n.resultCompareTitle, style: context.ts.h3),
                ),
                IconButton(
                  onPressed: () {
                    AppHaptics.tap();
                    Navigator.of(context).pop();
                  },
                  tooltip: l10n.commonClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                AppHaptics.select();
                setState(() => _page = index);
              },
              children: [
                _Zoomable(
                  child: args.crop == null
                      ? Center(
                          child: Text(
                            l10n.resultPhotoMissing,
                            style: context.ts.paragraphTiny,
                          ),
                        )
                      : PhotoCrop(
                          photoPath: args.photoPath,
                          crop: args.crop!,
                          frame: args.frame,
                        ),
                ),
                _Zoomable(
                  child: ReferencePane(
                    url: args.referenceUrl,
                    headers: args.referenceHeaders,
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
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class _Zoomable extends StatelessWidget {
  static const double _maxScale = 5;

  final Widget child;

  const _Zoomable({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.p16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.r16),
        child: ColoredBox(
          color: context.colors.paper2,
          child: InteractiveViewer(
            maxScale: _maxScale,
            child: SizedBox.expand(child: child),
          ),
        ),
      ),
    );
  }
}
