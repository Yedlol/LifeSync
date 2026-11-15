import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/data/settings_repository.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (_) => AuthRepository(),
);
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (_) => SettingsRepository(),
);

/// Emits the current email whenever auth state changes.
final currentEmailProvider = StreamProvider<String?>((ref) async* {
  final repo = ref.watch(authRepositoryProvider);
  yield repo.currentEmail;
  await for (final _ in repo.authChanges) {
    yield repo.currentEmail;
  }
});
