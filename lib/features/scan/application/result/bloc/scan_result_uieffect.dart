import '../../../../../core/application/bloc/base_bloc_uieffect.dart';
import '../../../domain/models/bottle_box.dart';
import '../../../domain/models/recognition_view.dart';
import '../../../domain/models/tech_row.dart';

sealed class ScanResultUiEffect extends BaseBlocUiEffect {}

/// Leave the result for the scanner tab.
final class OpenScanner extends ScanResultUiEffect {}

/// Open the sheet to draw a frame; the frame comes back as `FrameDrawn`.
final class OpenDrawFrame extends ScanResultUiEffect {
  final DrawFrameArgs args;

  OpenDrawFrame({required this.args});
}

final class OpenCompare extends ScanResultUiEffect {
  final CompareArgs args;

  OpenCompare({required this.args});
}

final class OpenMoreSheet extends ScanResultUiEffect {
  final MoreSheetArgs args;

  OpenMoreSheet({required this.args});
}

final class ShareJson extends ScanResultUiEffect {
  final String json;
  final String fileName;

  ShareJson({required this.json, required this.fileName});
}

final class ShowTechDetails extends ScanResultUiEffect {
  final List<TechRow> rows;

  ShowTechDetails({required this.rows});
}

final class OpenExternalUrl extends ScanResultUiEffect {
  final String url;

  OpenExternalUrl({required this.url});
}

final class CloseScreen extends ScanResultUiEffect {}

/// What the frame sheet draws on; no bloc access from there.
class DrawFrameArgs {
  final String photoPath;
  final List<int>? frame;

  /// The answer's boxes, drawn for orientation; null while a frame request
  /// is in flight.
  final RecognitionView? view;

  const DrawFrameArgs({
    required this.photoPath,
    required this.frame,
    required this.view,
  });
}

/// Everything the comparison sheet needs; no bloc access from there.
class CompareArgs {
  final String photoPath;
  final BottleBox? crop;
  final List<int>? frame;
  final int bottleNumber;
  final String cardTitle;
  final String? referenceUrl;
  final Map<String, String> referenceHeaders;

  const CompareArgs({
    required this.photoPath,
    required this.crop,
    required this.frame,
    required this.bottleNumber,
    required this.cardTitle,
    required this.referenceUrl,
    required this.referenceHeaders,
  });
}

/// Which actions the "more" sheet offers.
class MoreSheetArgs {
  final bool isRoi;
  final int? bottleNumber;

  const MoreSheetArgs({required this.isRoi, required this.bottleNumber});
}

/// The user's pick in the "more" sheet.
enum ResultMoreOption { shareFull, shareBottle, techDetails }
