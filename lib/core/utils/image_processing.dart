import 'dart:typed_data';
import 'dart:ui' as ui;

const kMaxImageWidth = 1600;

/// Result of [prepareImage]: bytes ready to upload + their type.
class PreparedImage {
  const PreparedImage(this.bytes, this.ext, this.mime);
  final Uint8List bytes;
  final String ext;
  final String mime;
}

class UnsupportedImageException implements Exception {
  const UnsupportedImageException();
  @override
  String toString() => 'Unsupported image format';
}

/// File type from magic bytes, or null if unknown.
({String ext, String mime})? detectImageType(Uint8List b) {
  bool starts(List<int> sig, [int offset = 0]) {
    if (b.length < offset + sig.length) return false;
    for (var i = 0; i < sig.length; i++) {
      if (b[offset + i] != sig[i]) return false;
    }
    return true;
  }

  if (starts([0xFF, 0xD8, 0xFF])) return (ext: 'jpg', mime: 'image/jpeg');
  if (starts([0x89, 0x50, 0x4E, 0x47])) return (ext: 'png', mime: 'image/png');
  if (starts([0x47, 0x49, 0x46, 0x38])) return (ext: 'gif', mime: 'image/gif');
  if (starts([0x52, 0x49, 0x46, 0x46]) && starts([0x57, 0x45, 0x42, 0x50], 8)) {
    return (ext: 'webp', mime: 'image/webp');
  }
  return null;
}

/// Makes [raw] safe to upload: verifies it decodes and caps the width at
/// [kMaxImageWidth].
///
/// Mobile/web pickers already resize + JPEG-compress (via image_picker's
/// maxWidth/imageQuality), so those pass through untouched. Where that did not
/// happen (Windows picker, clipboard paste) a too-wide image is downscaled
/// here. Flutter's engine can only encode PNG, so a downscaled image becomes a
/// PNG, not a JPEG. Animated GIFs are never re-encoded.
Future<PreparedImage> prepareImage(Uint8List raw) async {
  final type = detectImageType(raw);
  if (type == null) throw const UnsupportedImageException();

  final ui.Codec codec;
  try {
    codec = await ui.instantiateImageCodec(raw);
  } catch (_) {
    throw const UnsupportedImageException();
  }
  final width = (await codec.getNextFrame()).image.width;
  final animated = codec.frameCount > 1;
  codec.dispose();

  if (width <= kMaxImageWidth || animated) {
    return PreparedImage(raw, type.ext, type.mime);
  }

  final small = await ui.instantiateImageCodec(
    raw,
    targetWidth: kMaxImageWidth,
  );
  final image = (await small.getNextFrame()).image;
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  small.dispose();
  if (data == null) throw const UnsupportedImageException();
  return PreparedImage(data.buffer.asUint8List(), 'png', 'image/png');
}
