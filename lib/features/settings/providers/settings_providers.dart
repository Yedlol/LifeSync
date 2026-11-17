import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/offline/local_store.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/user_settings.dart';

/// The signed-in user's salary / overtime settings, from the offline cache
/// (kept live by Supabase realtime).
final userSettingsProvider =
    NotifierProvider<UserSettingsNotifier, AsyncValue<UserSettings>>(
      UserSettingsNotifier.new,
    );

class UserSettingsNotifier extends Notifier<AsyncValue<UserSettings>> {
  StreamSubscription<void>? _local;
  StreamSubscription<List<Map<String, dynamic>>>? _remote;

  static const _table = Tables.userSettings;

  @override
  AsyncValue<UserSettings> build() {
    ref.watch(currentEmailProvider.select((v) => v.value));
    final repo = ref.read(settingsRepositoryProvider);
    final store = LocalStore.instance;
    AsyncValue<UserSettings> read() =>
        AsyncData(repo.cached() ?? const UserSettings());

    ref.onDispose(() {
      _local?.cancel();
      _remote?.cancel();
    });
    _local = store.changes(_table).listen((_) {
      if (ref.mounted && store.isLoaded(_table)) state = read();
    });
    _remote = repo.watchRows().listen(
      (rows) => store.applySnapshot(_table, rows),
      onError: (Object e, StackTrace st) async {
        debugPrint('settings stream error: $e');
        if (!ref.mounted || state.hasValue) return;
        try {
          final s = await repo.get();
          if (ref.mounted && !state.hasValue) state = AsyncData(s);
        } catch (e2, st2) {
          if (ref.mounted && !state.hasValue) state = AsyncError(e2, st2);
        }
      },
    );
    return store.isLoaded(_table) ? read() : const AsyncLoading();
  }

  Future<void> save(UserSettings s) =>
      ref.read(settingsRepositoryProvider).update(s);
}
