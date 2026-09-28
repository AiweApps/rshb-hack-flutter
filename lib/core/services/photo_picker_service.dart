import 'package:image_picker/image_picker.dart';

import '../constants/app_constants.dart';

enum PhotoSource { camera, gallery }

/// A photo chosen by the user, already downsized for upload.
class PickedPhoto {
  final String path;

  const PickedPhoto({required this.path});
}

/// Adapter over the platform picker.
///
/// The picker re-encodes the photo as JPEG no larger than
/// [LimitConstants.uploadMaxSide] on a side: that keeps every upload under
/// the service's 24 MP / 20 MiB caps and turns HEIC into JPEG on iOS, so the
/// format check the web UI needs is not needed here.
class PhotoPickerService {
  final ImagePicker _picker;

  PhotoPickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  /// Null when the user dismissed the picker.
  Future<PickedPhoto?> pick(PhotoSource source) async {
    final file = await _picker.pickImage(
      source: switch (source) {
        PhotoSource.camera => ImageSource.camera,
        PhotoSource.gallery => ImageSource.gallery,
      },
      maxWidth: LimitConstants.uploadMaxSide.toDouble(),
      maxHeight: LimitConstants.uploadMaxSide.toDouble(),
      imageQuality: LimitConstants.uploadJpegQuality,
      preferredCameraDevice: CameraDevice.rear,
      requestFullMetadata: false,
    );
    if (file == null) return null;
    return PickedPhoto(path: file.path);
  }
}
