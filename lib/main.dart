import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart'
    show FlutterQuillLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/offline/local_store.dart';
import 'core/router/app_router.dart';
import 'core/supabase/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'core/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!supabaseConfigured) {
    runApp(const _MissingConfigApp());
    return;
  }
  await initSupabase();
  await _openOfflineCache();
  await LocalNotificationService.instance.init();
  runApp(const ProviderScope(child: LifeSyncApp()));
}

/// Opens the Hive cache (falls back to memory if the disk store fails) and
/// makes sure it belongs to the signed-in account.
Future<void> _openOfflineCache() async {
  try {
    LocalStore.instance = await LocalStore.openHive();
  } catch (e) {
    debugPrint('offline cache unavailable, using memory: $e');
  }
  await LocalStore.instance.ensureOwner(supabaseClient.auth.currentUser?.id);
}

class LifeSyncApp extends ConsumerWidget {
  const LifeSyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'LifeSync',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ref.watch(themeModeProvider),
      // Needed by the rich text toolbar (flutter_quill).
      localizationsDelegates: FlutterQuillLocalizations.localizationsDelegates,
      supportedLocales: FlutterQuillLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
    );
  }
}

class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildAppTheme(),
      home: const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Missing SUPABASE_URL / SUPABASE_ANON_KEY.\n'
              'Run with --dart-define (see README.md).',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
