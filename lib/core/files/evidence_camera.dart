import 'package:image_picker/image_picker.dart';

import 'document_picker.dart';

/// Takes an evidence photo with the camera. There is deliberately no gallery or file option:
/// evidence must be captured live (founder decision 2026-10-19).
abstract class EvidenceCamera {
  /// Null when the user backs out of the camera.
  Future<PickedDocument?> takePhoto();
}

class PlatformEvidenceCamera implements EvidenceCamera {
  final _images = ImagePicker();

  @override
  Future<PickedDocument?> takePhoto() async {
    // Server limit is 10 MB; resizing keeps phone photos well under it.
    final x = await _images.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 85,
    );
    if (x == null) return null;
    return PickedDocument(bytes: await x.readAsBytes(), name: x.name);
  }
}
