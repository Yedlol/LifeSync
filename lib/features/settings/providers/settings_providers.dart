import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../models/user_settings.dart';

/// The signed-in user's salary / overtime settings, live.
final userSettingsProvider =
    NotifierProvider<UserSettingsNotifier, AsyncValue<UserSettings>>(
      UserSettingsNotifier.new,
    );

class UserSettingsNotifier extends Notifier<AsyncValue<UserSettings>> {
  StreamSubscription<UserSettings>? _sub;

  @override
  AsyncValue<UserSettings> build() {
    ref.watch(currentEmailProvider.select((v) => v.value));
    final repo = ref.read(settingsRepositoryProvider);
    ref.onDispose(() => _sub?.cancel());
    _sub = repo.watch().listen(
      (s) {
        if (ref.mounted) state = AsyncData(s);
      },
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
    return const AsyncLoading();
  }

  Future<void> save(UserSettings s) async {
    final saved = await ref.read(settingsRepositoryProvider).update(s);
    if (ref.mounted) state = AsyncData(saved);
  }
}
