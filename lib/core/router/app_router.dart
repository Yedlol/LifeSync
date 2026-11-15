import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/ui/login_screen.dart';
import '../../features/auth/ui/register_screen.dart';
import '../../features/dashboard/ui/dashboard_screen.dart';
import '../../features/finance/ui/finance_screen.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/settings/ui/settings_screen.dart';
import '../../features/tasks/ui/tasks_screen.dart';
import '../widgets/app_shell.dart';

/// Bridges Supabase auth changes to go_router and ensures user_settings exists.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(this._auth, this._settings) {
    if (_auth.currentSession != null) _ensureSettings();
    _sub = _auth.authChanges.listen((state) {
      if (state.session != null) _ensureSettings();
      notifyListeners();
    });
  }

  final AuthRepository _auth;
  final SettingsRepository _settings;
  late final StreamSubscription<dynamic> _sub;

  Future<void> _ensureSettings() async {
    try {
      await _settings.ensureUserSettings();
    } catch (e) {
      debugPrint('ensureUserSettings failed: $e');
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final refresh = _AuthRefresh(auth, ref.watch(settingsRepositoryProvider));
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = auth.currentSession != null;
      final loc = state.matchedLocation;
      final onAuthPage = loc == '/login' || loc == '/register';
      if (!loggedIn) return onAuthPage ? null : '/login';
      if (onAuthPage) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      StatefulShellRoute.indexedStack(
        builder: (c, s, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (c, s) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/tasks', builder: (c, s) => const TasksScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/finance',
                builder: (c, s) => const FinanceScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (c, s) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
