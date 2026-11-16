import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../core/utils/image_processing.dart';

/// Storage bucket 'task-images' (private) + the task_images table.
///
/// Object path is `{user_id}/{task_id}/{uuid}.{ext}`; the first folder MUST be
/// the user id (Storage policy). Descriptions store this path, never a URL.
class TaskImageRepository {
  static const bucket = 'task-images';
  static const _table = 'task_images';
  static const _urlTtl = Duration(hours: 1);
  // Refresh a bit early so a URL never expires while it is being loaded.
  static const _urlReuse = Duration(minutes: 50);

  final _uuid = const Uuid();
  final _urlCache = <String, ({String url, DateTime at})>{};
  final _urlInFlight = <String, Future<String>>{};

  StorageFileApi get _storage => supabaseClient.storage.from(bucket);

  String get _uid {
    final id = supabaseClient.auth.currentUser?.id;
    if (id == null) throw StateError('Not signed in');
    return id;
  }

  String folderFor(String taskId) => '$_uid/$taskId';

  /// Uploads [image] and returns its storage path. For an existing task
  /// ([record] = true) the task_images row is inserted straight away; for a
  /// new task use [registerImages] once the task row exists.
  Future<String> upload(
    String taskId,
    PreparedImage image, {
    required bool record,
  }) async {
    final path = '${folderFor(taskId)}/${_uuid.v4()}.${image.ext}';
    await _storage.uploadBinary(
      path,
      image.bytes,
      fileOptions: FileOptions(contentType: image.mime, upsert: false),
    );
    if (record) {
      try {
        await registerImages(taskId, [path]);
      } catch (_) {
        await _storage.remove([path]).catchError((_) => <FileObject>[]);
        rethrow;
      }
    }
    return path;
  }

  /// Inserts task_images rows (the task must already exist).
  Future<void> registerImages(String taskId, Iterable<String> paths) async {
    final rows = [
      for (final p in paths) {'task_id': taskId, 'storage_path': p},
    ];
    if (rows.isNotEmpty) await supabaseClient.from(_table).insert(rows);
  }

  Future<Set<String>> _recordedPaths(String taskId) async {
    final rows = await supabaseClient
        .from(_table)
        .select('storage_path')
        .eq('task_id', taskId);
    return {for (final r in rows) r['storage_path'] as String};
  }

  /// Brings Storage + task_images in line with [usedPaths] (the images that are
  /// in the saved Delta): removed images are deleted from both, and images that
  /// are used but have no row yet (new tasks) get one.
  /// [uploadedThisSession] covers uploads that never got a row.
  Future<void> syncImages(
    String taskId, {
    required Set<String> usedPaths,
    Set<String> uploadedThisSession = const {},
  }) async {
    final recorded = await _recordedPaths(taskId);
    final prefix = '${folderFor(taskId)}/';
    final unused = {...recorded, ...uploadedThisSession}.difference(usedPaths);
    final missing = usedPaths
        .where((p) => p.startsWith(prefix) && !recorded.contains(p))
        .toList();
    if (missing.isNotEmpty) await registerImages(taskId, missing);
    if (unused.isNotEmpty) await deletePaths(taskId, unused);
  }

  /// Removes [paths] from Storage first, then their task_images rows.
  Future<void> deletePaths(String taskId, Iterable<String> paths) async {
    final list = paths.toList();
    if (list.isEmpty) return;
    await _storage.remove(list);
    await supabaseClient
        .from(_table)
        .delete()
        .eq('task_id', taskId)
        .inFilter('storage_path', list);
    for (final p in list) {
      _urlCache.remove(p);
    }
  }

  /// Deletes every file of a task (recorded or orphaned) and its rows.
  Future<void> deleteAllForTask(String taskId) async {
    final recorded = await _recordedPaths(taskId);
    final folder = folderFor(taskId);
    final inFolder = await _storage.list(path: folder);
    final all = {
      ...recorded,
      for (final f in inFolder)
        if (f.id != null) '$folder/${f.name}',
    };
    await deletePaths(taskId, all);
  }

  /// Signed URL (valid 1 hour), cached in memory. Plain http(s) values are
  /// returned as-is.
  Future<String> signedUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Future.value(path);
    }
    final hit = _urlCache[path];
    if (hit != null && DateTime.now().difference(hit.at) < _urlReuse) {
      return Future.value(hit.url);
    }
    return _urlInFlight[path] ??= () async {
      try {
        final url = await _storage.createSignedUrl(path, _urlTtl.inSeconds);
        _urlCache[path] = (url: url, at: DateTime.now());
        return url;
      } finally {
        _urlInFlight.remove(path);
      }
    }();
  }
}
