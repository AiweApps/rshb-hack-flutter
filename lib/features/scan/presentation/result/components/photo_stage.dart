import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/app_style_constants.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/helpers/app_haptics.dart';
import '../../../../../core/services/language_service.dart';
import '../../../domain/models/bottle_box.dart';
import '../../../domain/models/recognition_view.dart';
import 'bottle_overlay_painter.dart';
import 'photo_geometry.dart';

/// The photo with the bottle frames over it and the manual frame gestures.
///
/// Boxes are in frame pixels; the widget maps them to the letterboxed image
/// with [PhotoGeometry]. Which bottle is selected and what frame was drawn
/// are the bloc's — the widget only reports gestures through callbacks and
/// keeps the frame *while it is being dragged*.
class PhotoStage extends StatefulWidget {
  final String photoPath;

  /// EXIF-oriented frame size from the answer; the decoded image size until
  /// there is one.
  final List<int>? frame;
  final RecognitionView? view;
  final String? selectedInstanceId;
  final BottleBox? requestRoi;
  final bool isDrawing;
  final BottleBox? draft;
  final bool isEditingDraft;
  final ValueChanged<String?> onBottleTap;
  final ValueChanged<BottleBox> onDraftChanged;
  final VoidCallback onDraftCleared;
  final VoidCallback onDraftEditToggled;
  final VoidCallback onDraftRecognize;

  const PhotoStage({
    super.key,
    required this.photoPath,
    required this.frame,
    required this.view,
    required this.selectedInstanceId,
    required this.requestRoi,
    required this.isDrawing,
    required this.draft,
    required this.isEditingDraft,
    required this.onBottleTap,
    required this.onDraftChanged,
    required this.onDraftCleared,
    required this.onDraftEditToggled,
    required this.onDraftRecognize,
  });

  @override
  State<PhotoStage> createState() => _PhotoStageState();
}

class _PhotoStageState extends State<PhotoStage> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  Size? _naturalSize;

  // Gesture state: a frame being drawn or edited, before it is reported.
  Offset? _drawStart;
  BottleBox? _liveDraft;
  _EditDrag? _editDrag;

  @override
  void initState() {
    super.initState();
    _resolveSize();
  }

  @override
  void didUpdateWidget(covariant PhotoStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoPath != widget.photoPath) {
      _naturalSize = null;
      _resolveSize();
    }
    if (oldWidget.draft != widget.draft || !widget.isDrawing) {
      _liveDraft = null;
      _editDrag = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size? frame = _frameSize();

    return LayoutBuilder(
      builder: (context, constraints) {
        final Size box = constraints.biggest;
        final PhotoGeometry? geometry = frame == null
            ? null
            : PhotoGeometry.fit(box: box, frame: frame);
        final BottleBox? draft = _liveDraft ?? widget.draft;

        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(widget.photoPath),
              fit: BoxFit.contain,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: context.colors.muted,
                  size: AppSize.s48,
                ),
              ),
            ),
            if (geometry != null)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: widget.isDrawing
                    ? null
                    : (details) => _onTap(details.localPosition, geometry),
                onPanStart: _canDraw ? (d) => _onDrawStart(d, geometry) : null,
                onPanUpdate: _canDraw
                    ? (d) => _onDrawUpdate(d, geometry)
                    : null,
                onPanEnd: _canDraw ? (_) => _onDrawEnd(geometry) : null,
                onPanCancel: _canDraw ? _onDrawCancel : null,
                child: CustomPaint(
                  painter: BottleOverlayPainter(
                    geometry: geometry,
                    view: widget.view,
                    selectedInstanceId: widget.selectedInstanceId,
                    requestRoi: widget.isDrawing ? null : widget.requestRoi,
                    draft: draft,
                    isEditingDraft: widget.isEditingDraft,
                    showBadges: _showBadges,
                    boxColor: context.colors.card,
                    activeColor: context.colors.gold,
                    shadowColor: context.colors.scrim,
                    badgeColor: context.colors.wine,
                    activeBadgeColor: context.colors.gold,
                    roiColor: context.colors.wine2,
                    badgeStyle: context.ts.badge,
                  ),
                ),
              ),
            if (geometry != null && widget.isEditingDraft && draft != null)
              ..._editHandles(geometry, draft),
            if (geometry != null &&
                widget.isDrawing &&
                draft != null &&
                _drawStart == null &&
                _editDrag == null)
              _RoiCorners(
                rect: geometry.toScreenRect(draft),
                box: box,
                isEditing: widget.isEditingDraft,
                onEdit: widget.onDraftEditToggled,
                onClear: widget.onDraftCleared,
                onRecognize: widget.onDraftRecognize,
              ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  bool get _canDraw => widget.isDrawing && !widget.isEditingDraft;

  bool get _showBadges {
    final RecognitionView? view = widget.view;
    return view != null && (view.bottles.length > 1 || view.isExplicitRoi);
  }

  Size? _frameSize() {
    final List<int>? frame = widget.frame;
    if (frame != null && frame.length == 2 && frame[0] > 0 && frame[1] > 0) {
      return Size(frame[0].toDouble(), frame[1].toDouble());
    }
    return _naturalSize;
  }

  // The decoded size is what the frames refer to until the answer says.
  void _resolveSize() {
    _detach();
    final ImageStream stream = FileImage(
      File(widget.photoPath),
    ).resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener((info, _) {
      if (!mounted) return;
      setState(() {
        _naturalSize = Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
      });
      info.dispose();
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

  void _onTap(Offset position, PhotoGeometry geometry) {
    final RecognitionView? view = widget.view;
    if (view == null) return;
    RecognizedBottle? hit;
    double hitArea = double.infinity;
    for (final bottle in view.bottles) {
      final BottleBox? box = bottle.geometry;
      if (box == null) continue;
      // A thin bottle still gets a finger-sized target (adaptive.md §6).
      final Rect rect = _atLeastTapTarget(geometry.toScreenRect(box));
      final double area = rect.width * rect.height;
      // The smallest box wins when bottles overlap.
      if (rect.contains(position) && area < hitArea) {
        hit = bottle;
        hitArea = area;
      }
    }
    if (hit == null) return;
    AppHaptics.select();
    widget.onBottleTap(hit.instanceId);
  }

  Rect _atLeastTapTarget(Rect rect) {
    final double dx = (AppSize.minTapTarget - rect.width) / 2;
    final double dy = (AppSize.minTapTarget - rect.height) / 2;
    return Rect.fromLTRB(
      rect.left - (dx > 0 ? dx : 0),
      rect.top - (dy > 0 ? dy : 0),
      rect.right + (dx > 0 ? dx : 0),
      rect.bottom + (dy > 0 ? dy : 0),
    );
  }

  void _onDrawStart(DragStartDetails d, PhotoGeometry geometry) {
    setState(() {
      _drawStart = geometry.toFrame(d.localPosition);
      _liveDraft = null;
    });
  }

  void _onDrawUpdate(DragUpdateDetails d, PhotoGeometry geometry) {
    final Offset? start = _drawStart;
    if (start == null) return;
    setState(() {
      _liveDraft = PhotoGeometry.boxFromPoints(
        start,
        geometry.toFrame(d.localPosition),
      );
    });
  }

  void _onDrawEnd(PhotoGeometry geometry) {
    final BottleBox? draft = _liveDraft;
    setState(() {
      _drawStart = null;
      _liveDraft = null;
    });
    if (draft == null) return;
    final double minSide = LimitConstants.minRoiSideOnScreen / geometry.scale;
    if (draft.width < minSide || draft.height < minSide) {
      widget.onDraftCleared();
      return;
    }
    AppHaptics.confirm();
    widget.onDraftChanged(draft);
  }

  void _onDrawCancel() {
    setState(() {
      _drawStart = null;
      _liveDraft = null;
    });
  }

  // Editing: the whole box moves by a drag inside it; a handle resizes.
  List<Widget> _editHandles(PhotoGeometry geometry, BottleBox draft) {
    final Rect rect = geometry.toScreenRect(draft);
    return [
      Positioned.fromRect(
        rect: rect,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (d) => _onEditStart(_EditKind.move, d, geometry, draft),
          onPanUpdate: (d) => _onEditUpdate(d, geometry),
          onPanEnd: (_) => _onEditEnd(),
          onPanCancel: _onEditEnd,
        ),
      ),
      for (final kind in _EditKind.corners)
        _handle(kind, kind.cornerOf(rect), geometry, draft),
    ];
  }

  Widget _handle(
    _EditKind kind,
    Offset corner,
    PhotoGeometry geometry,
    BottleBox draft,
  ) {
    const double size = AppSize.roiHandle;
    return Positioned(
      left: corner.dx - size / 2,
      top: corner.dy - size / 2,
      width: size,
      height: size,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) => _onEditStart(kind, d, geometry, draft),
        onPanUpdate: (d) => _onEditUpdate(d, geometry),
        onPanEnd: (_) => _onEditEnd(),
        onPanCancel: _onEditEnd,
      ),
    );
  }

  void _onEditStart(
    _EditKind kind,
    DragStartDetails d,
    PhotoGeometry geometry,
    BottleBox draft,
  ) {
    AppHaptics.select();
    setState(() {
      _editDrag = _EditDrag(
        kind: kind,
        from: geometry.toFrame(d.globalPosition - _stageOrigin()),
        box: draft,
      );
      _liveDraft = draft;
    });
  }

  void _onEditUpdate(DragUpdateDetails d, PhotoGeometry geometry) {
    final _EditDrag? drag = _editDrag;
    if (drag == null) return;
    final Offset point = geometry.toFrame(d.globalPosition - _stageOrigin());
    final double dx = point.dx - drag.from.dx;
    final double dy = point.dy - drag.from.dy;
    final double w = geometry.frame.width;
    final double h = geometry.frame.height;
    final double min = LimitConstants.minRoiSideWhileResizing / geometry.scale;
    double x1 = drag.box.x1, y1 = drag.box.y1;
    double x2 = drag.box.x2, y2 = drag.box.y2;
    if (drag.kind == _EditKind.move) {
      final double bw = x2 - x1, bh = y2 - y1;
      x1 = (x1 + dx).clamp(0, w - bw);
      y1 = (y1 + dy).clamp(0, h - bh);
      x2 = x1 + bw;
      y2 = y1 + bh;
    } else {
      if (drag.kind.isWest) {
        x1 = (x1 + dx).clamp(0, x2 - min);
      } else {
        x2 = (x2 + dx).clamp(x1 + min, w);
      }
      if (drag.kind.isNorth) {
        y1 = (y1 + dy).clamp(0, y2 - min);
      } else {
        y2 = (y2 + dy).clamp(y1 + min, h);
      }
    }
    setState(() {
      _liveDraft = BottleBox(x1: x1, y1: y1, x2: x2, y2: y2);
    });
  }

  void _onEditEnd() {
    final BottleBox? draft = _liveDraft;
    setState(() {
      _editDrag = null;
      _liveDraft = null;
    });
    if (draft != null) widget.onDraftChanged(draft);
  }

  // Handles report global positions; the stage may sit below a top bar.
  Offset _stageOrigin() {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    return box?.localToGlobal(Offset.zero) ?? Offset.zero;
  }
}

enum _EditKind {
  move,
  nw,
  ne,
  sw,
  se;

  static const List<_EditKind> corners = [nw, ne, sw, se];

  bool get isWest => this == nw || this == sw;

  bool get isNorth => this == nw || this == ne;

  Offset cornerOf(Rect rect) => switch (this) {
    nw => rect.topLeft,
    ne => rect.topRight,
    sw => rect.bottomLeft,
    se => rect.bottomRight,
    move => rect.center,
  };
}

class _EditDrag {
  final _EditKind kind;
  final Offset from;
  final BottleBox box;

  const _EditDrag({required this.kind, required this.from, required this.box});
}

/// The three round buttons on the corners of a drawn frame: adjust (top
/// left), clear (top right), recognise (bottom right). They stay inside the
/// stage even when the frame touches its edge.
class _RoiCorners extends StatelessWidget {
  static const double _button = AppSize.s44;

  final Rect rect;
  final Size box;
  final bool isEditing;
  final VoidCallback onEdit;
  final VoidCallback onClear;
  final VoidCallback onRecognize;

  const _RoiCorners({
    required this.rect,
    required this.box,
    required this.isEditing,
    required this.onEdit,
    required this.onClear,
    required this.onRecognize,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;
    if (isEditing) {
      return _place(
        rect.center,
        _CornerButton(
          icon: Icons.check,
          tooltip: l10n.frameDone,
          filled: true,
          onTap: onEdit,
        ),
      );
    }
    return Stack(
      children: [
        _place(
          rect.topLeft,
          _CornerButton(
            icon: Icons.edit_outlined,
            tooltip: l10n.frameEdit,
            filled: false,
            onTap: onEdit,
          ),
        ),
        _place(
          rect.topRight,
          _CornerButton(
            icon: Icons.close,
            tooltip: l10n.frameClear,
            filled: false,
            onTap: onClear,
          ),
        ),
        _place(
          rect.bottomRight,
          _CornerButton(
            icon: Icons.arrow_forward,
            tooltip: l10n.frameRecognize,
            filled: true,
            onTap: onRecognize,
          ),
        ),
      ],
    );
  }

  Widget _place(Offset at, Widget child) {
    final double x = (at.dx - _button / 2).clamp(0, box.width - _button);
    final double y = (at.dy - _button / 2).clamp(0, box.height - _button);
    return Positioned(
      left: x,
      top: y,
      width: _button,
      height: _button,
      child: child,
    );
  }
}

class _CornerButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool filled;
  final VoidCallback onTap;

  const _CornerButton({
    required this.icon,
    required this.tooltip,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: filled ? colors.wine : colors.card,
      shape: CircleBorder(side: BorderSide(color: colors.wine)),
      elevation: AppSize.s2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          AppHaptics.tap();
          onTap();
        },
        child: Tooltip(
          message: tooltip,
          child: Icon(
            icon,
            size: AppSize.s22,
            color: filled ? colors.onWine : colors.wine,
          ),
        ),
      ),
    );
  }
}
