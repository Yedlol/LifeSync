import 'package:supabase_flutter/supabase_flutter.dart';

/// network = try again later (stop the queue); rejected = the server said no
/// (move to the failed list and continue).
enum OpErrorKind { network, rejected }

OpErrorKind classifyError(Object e) {
  if (e is PostgrestException) {
    return _retryable(e.code) ? OpErrorKind.network : OpErrorKind.rejected;
  }
  if (e is StorageException) {
    return _retryable(e.statusCode) ? OpErrorKind.network : OpErrorKind.rejected;
  }
  // Session refresh failed (usually offline) - retry after reconnecting.
  if (e is AuthException) return OpErrorKind.network;
  // Bugs / bad data won't fix themselves by retrying.
  if (e is TypeError ||
      e is ArgumentError ||
      e is FormatException ||
      e is UnsupportedError ||
      e is StateError) {
    return OpErrorKind.rejected;
  }
  // SocketException, ClientException, TimeoutException, ...
  return OpErrorKind.network;
}

/// HTTP statuses (3 digits) and Postgres/PostgREST codes worth retrying.
bool _retryable(String? code) {
  if (code == null || code.isEmpty) return true;
  final http = code.length == 3 ? int.tryParse(code) : null;
  if (http != null) {
    return http >= 500 || http == 401 || http == 408 || http == 429;
  }
  return code.startsWith('PGRST3') || // JWT expired / invalid
      code.startsWith('08') || // connection exception
      code == '40001' || // serialization failure
      code == '40P01' || // deadlock
      code == '57P01'; // admin shutdown
}

/// Readable error for the failed-changes list.
String describeError(Object e) {
  if (e is PostgrestException) {
    final extra = [e.details, e.hint]
        .whereType<Object>()
        .map((x) => '$x')
        .where((s) => s.isNotEmpty)
        .join(' ');
    return [
      e.message,
      if (extra.isNotEmpty) extra,
      if (e.code != null) '(${e.code})',
    ].join(' ');
  }
  if (e is StorageException) return '${e.message} (${e.statusCode})';
  return '$e';
}
