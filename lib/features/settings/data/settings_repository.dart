import '../../../core/offline/cached_table.dart';
import '../../../core/offline/local_store.dart';
import '../../../core/supabase/supabase_config.dart';
import '../models/user_settings.dart';

class SettingsRepository {
  static const _table = Tables.userSettings;
  static const _w = OfflineWriter(_table);

  String? get _uid => supabaseClient.auth.currentUser?.id;

  /// Inserts a user_settings row (all defaults) if this user has none.
  /// Online only; failures are ignored by the caller.
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

  /// Raw row(s): initial fetch + realtime changes (written into the cache).
  Stream<List<Map<String, dynamic>>> watchRows() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return supabaseClient
        .from(_table)
        .stream(primaryKey: ['user_id'])
        .eq('user_id', uid);
  }

  /// Cached settings (only the signed-in user's row is ever cached).
  UserSettings? cached() {
    final rows = LocalStore.instance.rows(_table);
    return rows.isEmpty ? null : UserSettings.fromJson(rows.first);
  }

  /// Saved to the cache and upserted on user_id during sync.
  Future<UserSettings> update(UserSettings s) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not signed in');
    final row = await _w.upsert(uid, s.toJson(), onConflict: 'user_id');
    return UserSettings.fromJson(row);
  }
}
