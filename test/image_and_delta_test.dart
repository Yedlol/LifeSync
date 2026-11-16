import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:lifesync/core/utils/image_processing.dart';
import 'package:lifesync/features/tasks/models/description_codec.dart';
import 'package:lifesync/features/tasks/ui/widgets/description_editor/description_controller.dart';

Future<Uint8List> _png(int w, int h) async {
  final rec = ui.PictureRecorder();
  ui.Canvas(rec).drawRect(
    ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF1E6FD9),
  );
  final img = await rec.endRecording().toImage(w, h);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

void main() {
  test('detectImageType by magic bytes', () {
    expect(
      detectImageType(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]))?.ext,
      'jpg',
    );
    expect(
      detectImageType(Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]))?.ext,
      'png',
    );
    expect(detectImageType(Uint8List.fromList([1, 2, 3, 4])), isNull);
  });

  testWidgets('prepareImage: small passes through, wide is capped at 1600', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final small = await _png(200, 100);
      final out = await prepareImage(small);
      expect(out.bytes, small);
      expect(out.ext, 'png');

      final wide = await _png(3200, 400);
      final capped = await prepareImage(wide);
      final codec = await ui.instantiateImageCodec(capped.bytes);
      expect((await codec.getNextFrame()).image.width, kMaxImageWidth);

      await expectLater(
        prepareImage(Uint8List.fromList([1, 2, 3, 4, 5])),
        throwsA(isA<UnsupportedImageException>()),
      );
    });
  });

  group('delta helpers', () {
    final delta = [
      {'insert': 'one\n'},
      {
        'insert': {'image': 'u/t/a.jpg'},
      },
      {'insert': '\ntwo\n\nthree\n'},
      {
        'insert': {'image': 'u/t/b.jpg'},
      },
      {'insert': '\n'},
    ];
    test('imagePathsFromDelta', () {
      expect(imagePathsFromDelta(delta), ['u/t/a.jpg', 'u/t/b.jpg']);
      expect(imagePathsFromDelta(null), isEmpty);
    });
    test('descriptionPreviewOf = first 2 non-empty lines', () {
      expect(descriptionPreviewOf(delta), 'one\ntwo');
      expect(descriptionPreviewOf(const []), '');
    });
  });

  group('documentFromDelta', () {
    test('legacy plain-text delta opens and round-trips', () {
      final doc = documentFromDelta([
        {'insert': 'old text\n'},
      ]);
      expect(doc.toPlainText(), 'old text\n');
      expect(doc.toDelta().toJson(), [
        {'insert': 'old text\n'},
      ]);
    });
    test('null / empty / malformed never throw', () {
      expect(documentFromDelta(null).toPlainText(), '\n');
      expect(documentFromDelta(const []).toPlainText(), '\n');
      expect(
        () => documentFromDelta([
          {'insert': 'no trailing newline'},
        ]),
        returnsNormally,
      );
    });
  });
}
