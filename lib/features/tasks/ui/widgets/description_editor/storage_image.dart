import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/offline/sync_service.dart';
import '../../../providers/tasks_notifier.dart';
import 'image_viewer.dart';

/// Shows an image from its storage path: signed URL (1h, cached) with a
/// loading placeholder and a broken-image icon on error (cloud icon while
/// offline; images already shown this session stay in Flutter's cache).
class StorageImage extends ConsumerStatefulWidget {
  const StorageImage({super.key, required this.path, this.fit = BoxFit.cover});
  final String path;
  final BoxFit fit;

  @override
  ConsumerState<StorageImage> createState() => _StorageImageState();
}

class _StorageImageState extends ConsumerState<StorageImage> {
  late Future<String> _url = _load();

  Future<String> _load() =>
      ref.read(taskImageRepositoryProvider).signedUrl(widget.path);

  @override
  void didUpdateWidget(StorageImage old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) _url = _load();
  }

  void _retry() => setState(() => _url = _load());

  @override
  Widget build(BuildContext context) {
    // Not viewed before + offline: placeholder, reload once back online.
    final online = ref.watch(isOnlineProvider);
    ref.listen<bool>(isOnlineProvider, (was, now) {
      if (now && was == false) _retry();
    });
    return FutureBuilder<String>(
      future: _url,
      builder: (context, snap) {
        if (snap.hasError) return _Broken(onRetry: _retry, offline: !online);
        if (!snap.hasData) return const _Loading();
        return Image.network(
          snap.data!,
          fit: widget.fit,
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : const _Loading(),
          errorBuilder: (context, _, _) =>
              _Broken(onRetry: _retry, offline: !online),
        );
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => Container(
    height: 120,
    color: Colors.grey.shade200,
    alignment: Alignment.center,
    child: const SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );
}

class _Broken extends StatelessWidget {
  const _Broken({required this.onRetry, this.offline = false});
  final VoidCallback onRetry;
  final bool offline;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onRetry,
    child: Container(
      height: 120,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Tooltip(
        message: offline ? 'Image available when online' : 'Tap to retry',
        child: Icon(
          offline
              ? PhosphorIconsRegular.cloudSlash
              : PhosphorIconsRegular.imageBroken,
          color: Colors.grey.shade600,
        ),
      ),
    ),
  );
}

/// Replaces flutter_quill's default 'image' embed so the Delta can hold a
/// storage path instead of a URL.
class StorageImageEmbedBuilder extends EmbedBuilder {
  const StorageImageEmbedBuilder();

  @override
  String get key => BlockEmbed.imageType;

  @override
  bool get expanded => false;

  @override
  String toPlainText(Embed node) => '[image]';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final path = embedContext.node.value.data as String;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 320),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => showImageViewer(context, path),
              child: StorageImage(path: path, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
