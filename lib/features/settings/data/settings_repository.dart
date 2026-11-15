import '../../../core/supabase/supabase_config.dart';

class SettingsRepository {
  /// Inserts a user_settings row (all defaults) if this user has none.
  Future<void> ensureUserSettings() async {
    final uid = supabaseClient.auth.currentUser?.id;
    if (uid == null) return;
    final existing = await supabaseClient
        .from('user_settings')
        .select('user_id')
        .eq('user_id', uid)
        .maybeSingle();
    if (existing == null) {
      await supabaseClient.from('user_settings').insert({'user_id': uid});
    }
  }
}
