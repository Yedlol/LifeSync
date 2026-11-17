import 'package:supabase_flutter/supabase_flutter.dart';

/// Values come from `--dart-define`; never hardcode keys.
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

bool get supabaseConfigured =>
    supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

bool _ready = false;

/// True once Supabase is initialised (false in widget tests).
bool get supabaseReady => _ready;

Future<void> initSupabase() async {
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
  _ready = true;
}

/// Only repositories should use this.
SupabaseClient get supabaseClient => Supabase.instance.client;
