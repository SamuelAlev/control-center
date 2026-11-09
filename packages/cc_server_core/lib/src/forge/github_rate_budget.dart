import 'package:cc_host/cc_host.dart' show CcHostLog;

/// How much of GitHub's request quota the server's own traffic has left,
/// learned from the `x-ratelimit-*` headers GitHub puts on every response.
///
/// GitHub budgets per credential and per resource (`core`, `graphql`,
/// `search`, ...). Background work in a workspace rides that workspace's
/// accountable human (Connect: their personal 5,000 an hour), so readings are
/// kept per `(workspace, person)` and per resource. The pollers ask [isLow]
/// before a sweep and skip it while any resource of their quota is under
/// [lowWatermark] of its limit; a reading stops counting once its window
/// resets, so a quiet poller recovers without needing fresh traffic.
class GitHubRateBudget {
  /// Creates an empty budget.
  GitHubRateBudget({this.lowWatermark = 0.15, DateTime Function()? now})
    : _now = now ?? (() => DateTime.now().toUtc());

  /// The remaining fraction of a limit below which pollers back off.
  final double lowWatermark;

  final DateTime Function() _now;

  /// GitHub's quota window, used to age a reading that came without a reset.
  static const Duration _window = Duration(hours: 1);

  final Map<String, Map<String, _Reading>> _readings = {};

  /// Records the rate-limit headers of one response sent for [workspaceId]
  /// (and [userId], when it rode that person's own quota). Responses without
  /// the headers (most non-API hosts) are ignored.
  void observe(
    String workspaceId,
    Map<String, String> headers, {
    String? userId,
  }) {
    String? header(String name) {
      for (final entry in headers.entries) {
        if (entry.key.toLowerCase() == name) {
          return entry.value.trim();
        }
      }
      return null;
    }

    final remaining = int.tryParse(header('x-ratelimit-remaining') ?? '');
    final limit = int.tryParse(header('x-ratelimit-limit') ?? '');
    if (remaining == null || limit == null) {
      return;
    }
    final reset = int.tryParse(header('x-ratelimit-reset') ?? '');
    final resource = header('x-ratelimit-resource') ?? '';
    record(
      workspaceId,
      userId: userId,
      resource: resource.isEmpty ? 'core' : resource,
      remaining: remaining,
      limit: limit,
      resetAt: reset == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(reset * 1000, isUtc: true),
    );
  }

  /// Records one reading directly (tests, non-header sources).
  void record(
    String workspaceId, {
    required String resource,
    required int remaining,
    required int limit,
    String? userId,
    DateTime? resetAt,
  }) {
    if (workspaceId.isEmpty || limit <= 0) {
      return;
    }
    (_readings[_key(workspaceId, userId)] ??= {})[resource] = _Reading(
      remaining: remaining,
      limit: limit,
      validUntil: resetAt ?? _now().add(_window),
    );
  }

  /// Whether any resource of the quota behind [workspaceId] (and [userId])
  /// is below [lowWatermark] in its current window.
  bool isLow(String workspaceId, {String? userId}) {
    final buckets = _readings[_key(workspaceId, userId)];
    if (buckets == null) {
      return false;
    }
    final now = _now();
    buckets.removeWhere((_, reading) => !reading.validUntil.isAfter(now));
    return buckets.values.any(
      (reading) => reading.remaining < reading.limit * lowWatermark,
    );
  }

  /// [isLow] for [workspaceId]'s quota, logging once per low spell that
  /// [poller] backs off its GitHub work there.
  bool backsOff(String workspaceId, {required String poller}) {
    final key = '$poller\u0000$workspaceId';
    if (!isLow(workspaceId)) {
      _backingOff.remove(key);
      return false;
    }
    if (_backingOff.add(key)) {
      CcHostLog.info(
        '$poller: backing off GitHub in workspace $workspaceId — its rate '
        'limit is under ${(lowWatermark * 100).round()}% until '
        '${lowUntil(workspaceId)?.toIso8601String() ?? 'the window resets'}.',
      );
    }
    return true;
  }

  final Set<String> _backingOff = {};

  /// When the earliest low resource of that quota resets, or null when none
  /// is low.
  DateTime? lowUntil(String workspaceId, {String? userId}) {
    if (!isLow(workspaceId, userId: userId)) {
      return null;
    }
    DateTime? earliest;
    for (final reading in _readings[_key(workspaceId, userId)]!.values) {
      if (reading.remaining < reading.limit * lowWatermark &&
          (earliest == null || reading.validUntil.isBefore(earliest))) {
        earliest = reading.validUntil;
      }
    }
    return earliest;
  }

  /// Forgets everything recorded for [workspaceId] (deletion, lane change).
  void forgetWorkspace(String workspaceId) => _readings.removeWhere(
    (key, _) => key == workspaceId || key.startsWith('$workspaceId\u0000'),
  );

  static String _key(String workspaceId, String? userId) =>
      userId == null || userId.isEmpty
      ? workspaceId
      : '$workspaceId\u0000$userId';
}

final class _Reading {
  const _Reading({
    required this.remaining,
    required this.limit,
    required this.validUntil,
  });

  final int remaining;
  final int limit;
  final DateTime validUntil;
}
