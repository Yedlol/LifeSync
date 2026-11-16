import 'package:flutter/foundation.dart';

import '../../../../../core/utils/image_processing.dart';
import '../../../data/task_image_repository.dart';

/// Tracks the image uploads made while one task form is open, so they can be
/// kept (on save) or cleaned up (on cancel).
class ImageUploadSession {
  ImageUploadSession({
    required this.repo,
    required this.taskId,
    required this.isNewTask,
  });

  final TaskImageRepository repo;
  final String taskId;

  /// New tasks have no DB row yet, so task_images rows are inserted after the
  /// task is created (see [commit]) instead of per upload.
  final bool isNewTask;

  /// Number of uploads currently running (drives the spinner).
  final ValueNotifier<int> uploading = ValueNotifier(0);

  final Set<String> uploaded = {};

  /// Uploads [raw] (resized/validated first) and returns its storage path.
  /// Throws on failure.
  Future<String> add(Uint8List raw) async {
    uploading.value++;
    try {
      final image = await prepareImage(raw);
      final path = await repo.upload(taskId, image, record: !isNewTask);
      uploaded.add(path);
      return path;
    } finally {
      uploading.value--;
    }
  }

  /// Form saved: delete removed images, register the new ones.
  Future<void> commit(Set<String> usedPaths) => repo.syncImages(
    taskId,
    usedPaths: usedPaths,
    uploadedThisSession: uploaded,
  );

  /// Form cancelled: drop everything uploaded in this session (none of it can
  /// be in the saved description). Best effort.
  Future<void> discard() async {
    if (uploaded.isEmpty) return;
    try {
      await repo.deletePaths(taskId, uploaded);
    } catch (e) {
      debugPrint('discard uploaded images failed: $e');
    }
  }

  void dispose() => uploading.dispose();
}
