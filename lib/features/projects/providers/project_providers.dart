import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/live_list_notifier.dart';
import '../../../core/offline/cached_table.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/project_repository.dart';
import '../models/project.dart';

final projectRepositoryProvider = Provider<ProjectRepository>(
  (_) => ProjectRepository(),
);

/// All projects (including archived), from the offline cache.
final projectsProvider =
    NotifierProvider<ProjectsNotifier, AsyncValue<List<Project>>>(
      ProjectsNotifier.new,
    );

class ProjectsNotifier extends LiveListNotifier<Project> {
  ProjectRepository get _repo => ref.read(projectRepositoryProvider);

  @override
  AsyncValue<List<Project>> build() {
    // Resubscribe when the logged-in user changes.
    ref.watch(currentEmailProvider.select((v) => v.value));
    return startLive();
  }

  @override
  CachedTable<Project> get table => ProjectRepository.cache;

  @override
  Stream<List<Map<String, dynamic>>> watchRows() => _repo.watchRows();

  Future<Project> create(String name, String color) =>
      _repo.create(name: name, color: color);

  Future<void> save(Project p) => _repo.update(p);

  Future<void> setArchived(Project p, bool archived) =>
      _repo.archive(p.id, archived: archived);
}

/// id -> project, including archived (so task tags still render).
final projectMapProvider = Provider<Map<String, Project>>((ref) {
  final list = ref.watch(projectsProvider).value ?? const [];
  return {for (final p in list) p.id: p};
});

/// Non-archived projects for dropdowns.
final activeProjectsProvider = Provider<List<Project>>((ref) {
  final list = ref.watch(projectsProvider).value ?? const [];
  return list.where((p) => !p.isArchived).toList();
});
