import 'package:supabase_flutter/supabase_flutter.dart';

/// Values come from `--dart-define`; never hardcode keys.
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

bool get supabaseConfigured =>
    supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

Future<void> initSupabase() =>
    Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);

/// Only repositories should use this.
SupabaseClient get supabaseClient => Supabase.instance.client;
