import 'op_errors.dart';
import 'outbox.dart';

class FlushResult {
  const FlushResult({this.sent = 0, this.failed = 0, this.networkError});
  final int sent;
  final int failed;

  /// Set when the run stopped because the server was unreachable.
  final Object? networkError;
}

/// Sends pending ops in order, one by one.
/// Success -> removed. Network error -> stop (retry later).
/// Server rejection -> moved to the failed list, carry on with the rest.
Future<FlushResult> flushOutbox(
  Outbox outbox,
  Future<void> Function(OutboxOp op) send,
) async {
  var sent = 0;
  var failed = 0;
  final tried = <String>{};
  while (true) {
    OutboxOp? next;
    for (final o in outbox.pending) {
      if (!tried.contains(o.id)) {
        next = o;
        break;
      }
    }
    if (next == null) break;
    tried.add(next.id);
    try {
      await send(next);
      await outbox.complete(next);
      sent++;
    } catch (e) {
      if (classifyError(e) == OpErrorKind.network) {
        return FlushResult(sent: sent, failed: failed, networkError: e);
      }
      await outbox.fail(next, describeError(e));
      failed++;
    }
  }
  return FlushResult(sent: sent, failed: failed);
}

/// Retry delay after [attempt] consecutive network failures: 2s, 4s … 60s.
Duration backoffFor(int attempt) {
  final s = 2 << (attempt.clamp(1, 6) - 1);
  return Duration(seconds: s > 60 ? 60 : s);
}
