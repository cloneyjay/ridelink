import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class PickedDocument {
  const PickedDocument({required this.bytes, required this.name});

  final List<int> bytes;
  final String name;
}

enum DocumentSource { camera, gallery, file }

/// Camera, gallery, or a file (image or PDF). Returns null when the user cancels.
abstract class DocumentPicker {
  Future<PickedDocument?> pick(DocumentSource source);
}

class PlatformDocumentPicker implements DocumentPicker {
  final _images = ImagePicker();

  @override
  Future<PickedDocument?> pick(DocumentSource source) async {
    switch (source) {
      case DocumentSource.camera:
      case DocumentSource.gallery:
        // Server limit is 10 MB; resizing keeps phone photos well under it.
        final x = await _images.pickImage(
          source: source == DocumentSource.camera
              ? ImageSource.camera
              : ImageSource.gallery,
          maxWidth: 2400,
          maxHeight: 2400,
          imageQuality: 85,
        );
        if (x == null) return null;
        return PickedDocument(bytes: await x.readAsBytes(), name: x.name);
      case DocumentSource.file:
        final f = await FilePicker.pickFile(
          type: FileType.custom,
          allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
        );
        if (f == null) return null;
        return PickedDocument(bytes: await f.xFile.readAsBytes(), name: f.name);
    }
  }
}
