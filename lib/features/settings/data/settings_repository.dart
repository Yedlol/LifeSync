import '../../../core/supabase/supabase_config.dart';
import '../models/user_settings.dart';

class SettingsRepository {
  static const _table = 'user_settings';

  String? get _uid => supabaseClient.auth.currentUser?.id;

  /// Inserts a user_settings row (all defaults) if this user has none.
  Future<void> ensureUserSettings() async {
    final uid = _uid;
    if (uid == null) return;
    final existing = await supabaseClient
        .from(_table)
        .select('user_id')
        .eq('user_id', uid)
        .maybeSingle();
    if (existing == null) {
      await supabaseClient.from(_table).insert({'user_id': uid});
    }
  }

  Future<UserSettings> get() async {
    final uid = _uid;
    if (uid == null) return const UserSettings();
    final row = await supabaseClient
        .from(_table)
        .select()
        .eq('user_id', uid)
        .maybeSingle();
    return row == null ? const UserSettings() : UserSettings.fromJson(row);
  }

  /// Live settings (initial fetch + changes from other devices).
  Stream<UserSettings> watch() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return supabaseClient
        .from(_table)
        .stream(primaryKey: ['user_id'])
        .eq('user_id', uid)
        .map(
          (rows) => rows.isEmpty
              ? const UserSettings()
              : UserSettings.fromJson(rows.first),
        );
  }

  Future<UserSettings> update(UserSettings s) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not signed in');
    await ensureUserSettings();
    final row = await supabaseClient
        .from(_table)
        .update(s.toJson())
        .eq('user_id', uid)
        .select()
        .single();
    return UserSettings.fromJson(row);
  }
}
