import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/offline/local_store.dart';
import '../../../core/supabase/supabase_config.dart';

class AuthRepository {
  GoTrueClient get _auth => supabaseClient.auth;

  Session? get currentSession => _auth.currentSession;
  String? get currentEmail => _auth.currentUser?.email;
  Stream<AuthState> get authChanges => _auth.onAuthStateChange;

  Future<void> signIn(String email, String password) async {
    final res = await _auth.signInWithPassword(
      email: email,
      password: password,
    );
    // Another account's cache (if any) must not show up.
    await LocalStore.instance.ensureOwner(res.user?.id);
  }

  /// Returns true if a session was created (false => email confirmation needed).
  Future<bool> signUp(String email, String password) async {
    final res = await _auth.signUp(email: email, password: password);
    if (res.session != null) {
      await LocalStore.instance.ensureOwner(res.user?.id);
    }
    return res.session != null;
  }

  /// Signs out (the local session is dropped even offline) and clears the
  /// offline cache, including unsynced changes.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('signOut (server part) failed: $e');
    } finally {
      await LocalStore.instance.clearAll();
    }
  }

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
