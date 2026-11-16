import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show TextSelection;
import 'package:flutter_quill/flutter_quill.dart';

import '../../../models/description_codec.dart';
import 'image_upload_session.dart';

/// Opens a saved description. Handles both rich Deltas and the plain
/// `[{"insert": "text\n"}]` written by Phase 2A; anything unreadable falls
/// back to its plain text so a task can always be opened.
Document documentFromDelta(Object? delta) {
  final ops = delta is List ? delta : const <dynamic>[];
  if (ops.isEmpty) return Document();
  try {
    return Document.fromJson(ops);
  } catch (e) {
    debugPrint('Description is not a valid Delta, showing plain text: $e');
    final doc = Document();
    final text = deltaToPlainText(delta);
    if (text.isNotEmpty) doc.insert(0, text);
    return doc;
  }
}

/// Quill Delta ops (what is stored in tasks.description).
List<dynamic> deltaFromController(QuillController c) =>
    c.document.toDelta().toJson();

/// Controller for the task description.
///
/// [onPasteError] is called when a pasted image could not be uploaded. Image
/// paste is only wired up by flutter_quill on web and mobile; on Windows the
/// package can't read images from the clipboard.
QuillController createDescriptionController({
  required Object? delta,
  required ImageUploadSession session,
  required void Function(Object error) onPasteError,
}) {
  return QuillController(
    document: documentFromDelta(delta),
    selection: const TextSelection.collapsed(offset: 0),
    config: QuillControllerConfig(
      clipboardConfig: QuillClipboardConfig(
        onImagePaste: (bytes) async {
          try {
            return await session.add(bytes);
          } catch (e) {
            onPasteError(e);
            return null;
          }
        },
      ),
    ),
  );
}

/// Inserts an image embed (storage path) at the cursor and moves the cursor
/// after it.
void insertImageEmbed(QuillController c, String path) {
  final sel = c.selection;
  final max = c.document.length - 1;
  final index = (sel.isValid ? sel.start : max).clamp(0, max);
  c.replaceText(index, 0, BlockEmbed.image(path), null);
  c.updateSelection(
    TextSelection.collapsed(offset: index + 1),
    ChangeSource.local,
  );
}
