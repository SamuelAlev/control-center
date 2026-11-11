import 'package:cc_connect/src/connect_log.dart';
import 'package:cc_connect/src/state_store.dart';
import 'package:cc_connect_core/cc_connect_core.dart';

/// One fixed-window counter in the shared state store: [limit] uses of
/// [bucket] for [key] per [window]. A quota with no [limit] only counts.
final class Quota {
  /// Creates the quota.
  const Quota(
    this.bucket,
    this.key, {
    required this.window,
    this.limit,
    this.logFields = const {},
  });

  /// The `ratelimit.hit` bucket name, and the refusal's reason.
  final String bucket;

  /// Whose budget (an account id, an address, an install id, `*`).
  final String key;

  /// Uses allowed per [window]; null counts without refusing.
  final int? limit;

  /// The window.
  final Duration window;

  /// Allowlisted log fields for a refusal (an `ip`, `install` or
  /// `github_user_id`).
  final Map<String, Object?> logFields;
}

/// Budgets that hold across instances: every counter lives in the
/// [StateStore], keyed by bucket, key and window.
///
/// [admit] reads every counter first and refuses (`rate_limited`, with the
/// bucket as its reason) before counting anything, so a refused call spends
/// no budget: nobody can exhaust a shared budget with calls that are
/// refused anyway.
final class QuotaGate {
  /// Creates the gate.
  QuotaGate(this._state, this._log, this._clock);

  final StateStore _state;
  final ConnectLog _log;
  final DateTime Function() _clock;

  String _key(Quota quota) {
    final now = _clock().toUtc().millisecondsSinceEpoch;
    final index = now ~/ quota.window.inMilliseconds;
    return 'quota:${quota.bucket}:${quota.key}:$index';
  }

  /// The use count of [quota] in its current window.
  Future<int> count(Quota quota) async =>
      int.tryParse(await _state.get(_key(quota)) ?? '') ?? 0;

  /// Refuses with `rate_limited` when any limited quota is spent, and
  /// otherwise counts one use against each of [quotas].
  Future<void> admit(List<Quota> quotas) async {
    for (final quota in quotas) {
      final limit = quota.limit;
      if (limit != null && await count(quota) >= limit) {
        _log.sampled('ratelimit.hit', '${quota.bucket}/${quota.key}', {
          'bucket': quota.bucket,
          ...quota.logFields,
        });
        throw ConnectException(
          ConnectErrorCode.rateLimited,
          reason: quota.bucket,
        );
      }
    }
    for (final quota in quotas) {
      await _state.increment(_key(quota), quota.window * 2);
    }
  }
}
