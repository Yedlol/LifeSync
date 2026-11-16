import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../../../core/utils/breakpoints.dart';
import '../../../../../core/utils/image_processing.dart';
import '../../../../../core/widgets/responsive_dialog.dart';
import 'description_controller.dart';
import 'image_source_picker.dart';
import 'image_upload_session.dart';
import 'storage_image.dart';

/// Rich text description: toolbar + editor + upload indicator.
/// The [controller] is owned by the caller (it reads the Delta on save).
class DescriptionEditor extends StatefulWidget {
  const DescriptionEditor({
    super.key,
    required this.controller,
    required this.session,
  });
  final QuillController controller;
  final ImageUploadSession session;

  @override
  State<DescriptionEditor> createState() => _DescriptionEditorState();
}

class _DescriptionEditorState extends State<DescriptionEditor> {
  final _focus = FocusNode();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _insertImages() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await pickImages(context);
      for (final bytes in picked) {
        final path = await widget.session.add(bytes);
        if (!mounted) return;
        insertImageEmbed(widget.controller, path);
      }
    } catch (e) {
      debugPrint('insert image failed: $e');
      showSnack(
        messenger,
        e is UnsupportedImageException
            ? 'That image format is not supported.'
            : 'Could not upload image. Check your connection.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final desktop = isDesktop(context);
    final border = BorderSide(color: Colors.grey.shade400);
    return Container(
      decoration: BoxDecoration(
        border: Border.fromBorderSide(border),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Colors.grey.shade50,
            child: QuillSimpleToolbar(
              controller: widget.controller,
              config: QuillSimpleToolbarConfig(
                // Phone: one horizontally scrollable row. Desktop: wraps.
                multiRowsDisplay: desktop,
                showDividers: desktop,
                showFontFamily: false,
                showFontSize: false,
                showSmallButton: false,
                showInlineCode: false,
                showColorButton: false,
                showBackgroundColorButton: false,
                showClearFormat: false,
                showHeaderStyle: false,
                showCodeBlock: false,
                showQuote: false,
                showIndent: false,
                showSearchButton: false,
                showSubscript: false,
                showSuperscript: false,
                customButtons: [
                  QuillToolbarCustomButtonOptions(
                    icon: const Icon(Icons.image_outlined),
                    tooltip: 'Insert image',
                    onPressed: _insertImages,
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: border.color),
          ValueListenableBuilder<int>(
            valueListenable: widget.session.uploading,
            builder: (context, n, _) => n == 0
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          n == 1 ? 'Uploading image…' : 'Uploading $n images…',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
          ),
          QuillEditor(
            focusNode: _focus,
            scrollController: _scroll,
            controller: widget.controller,
            config: const QuillEditorConfig(
              minHeight: 150,
              maxHeight: 400,
              padding: EdgeInsets.all(12),
              placeholder: 'Description',
              embedBuilders: [StorageImageEmbedBuilder()],
            ),
          ),
        ],
      ),
    );
  }
}
