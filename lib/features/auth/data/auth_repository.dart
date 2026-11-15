import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_config.dart';

class AuthRepository {
  GoTrueClient get _auth => supabaseClient.auth;

  Session? get currentSession => _auth.currentSession;
  String? get currentEmail => _auth.currentUser?.email;
  Stream<AuthState> get authChanges => _auth.onAuthStateChange;

  Future<void> signIn(String email, String password) =>
      _auth.signInWithPassword(email: email, password: password);

  /// Returns true if a session was created (false => email confirmation needed).
  Future<bool> signUp(String email, String password) async {
    final res = await _auth.signUp(email: email, password: password);
    return res.session != null;
  }

  Future<void> signOut() => _auth.signOut();

  /// Turns Supabase/network errors into readable messages.
  static String friendlyError(Object e) {
    if (e is AuthException) {
      final m = e.message.toLowerCase();
      if (m.contains('invalid login')) return 'Incorrect email or password.';
      if (m.contains('already registered')) {
        return 'An account with this email already exists.';
      }
      if (m.contains('email not confirmed')) {
        return 'Please confirm your email first, then log in.';
      }
      return e.message;
    }
    return 'Network error. Check your connection and try again.';
  }
}
