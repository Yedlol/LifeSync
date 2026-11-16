import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/utils/image_processing.dart';

/// Android/iOS app (not web): offer Gallery or Camera.
bool get _isMobileApp =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Lets the user choose image(s) and returns their raw bytes (empty = cancelled).
///
/// Phone: Gallery or Camera. Desktop/web: the system file dialog.
/// Resize/quality are requested from image_picker, which honours them on
/// Android, iOS and web; on Windows they are ignored and `prepareImage` caps the
/// width afterwards instead.
Future<List<Uint8List>> pickImages(BuildContext context) async {
  final picker = ImagePicker();
  const maxW = kMaxImageWidth * 1.0;
  const quality = 80;

  if (_isMobileApp) {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return const [];
    if (source == ImageSource.camera) {
      final f = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxW,
        imageQuality: quality,
      );
      return f == null ? const [] : [await f.readAsBytes()];
    }
  }

  final files = await picker.pickMultiImage(
    maxWidth: maxW,
    imageQuality: quality,
  );
  return [for (final f in files) await f.readAsBytes()];
}
