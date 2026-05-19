import 'dart:collection';

import 'package:control_center/core/utils/app_log.dart';

class WakeupRequest {
  const WakeupRequest({
    required this.agentId,
    required this.wakeReason,
    this.contextSnapshot,
    required this.enqueuedAt,
  });

  final String agentId;
  final String wakeReason;
  final Map<String, dynamic>? contextSnapshot;
  final DateTime enqueuedAt;

  WakeupRequest merge(WakeupRequest other) {
    final mergedContext = <String, dynamic>{};
    if (contextSnapshot != null) {
      mergedContext.addAll(contextSnapshot!);
    }
    if (other.contextSnapshot != null) {
      mergedContext.addAll(other.contextSnapshot!);
    }

    final earliest = enqueuedAt.isBefore(other.enqueuedAt) ? enqueuedAt : other.enqueuedAt;

    return WakeupRequest(
      agentId: agentId,
      wakeReason: '$wakeReason; ${other.wakeReason}',
      contextSnapshot: mergedContext.isEmpty ? null : mergedContext,
      enqueuedAt: earliest,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WakeupRequest &&
          runtimeType == other.runtimeType &&
          agentId == other.agentId &&
          wakeReason == other.wakeReason &&
          _mapEquals(contextSnapshot, other.contextSnapshot) &&
          enqueuedAt == other.enqueuedAt;

  @override
  int get hashCode => Object.hash(
    agentId,
    wakeReason,
    Object.hashAll(contextSnapshot?.entries.map((e) => Object.hash(e.key, e.value)) ?? const <int>[]),
    enqueuedAt,
  );

  static bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'WakeupRequest(agentId: $agentId, wakeReason: $wakeReason, '
      'enqueuedAt: $enqueuedAt)';
}

class AgentWakeupQueue {
  static const _tag = 'AgentWakeupQueue';

  static const coalescingWindow = Duration(seconds: 5);

  final _queues = HashMap<String, List<WakeupRequest>>();

  void enqueue(
    String agentId,
    String wakeReason, {
    Map<String, dynamic>? contextSnapshot,
  }) {
    final now = DateTime.now();
    final request = WakeupRequest(
      agentId: agentId,
      wakeReason: wakeReason,
      contextSnapshot: contextSnapshot,
      enqueuedAt: now,
    );

    final existing = _queues[agentId];
    if (existing != null && existing.isNotEmpty) {
      final last = existing.last;
      final timeSinceLast = now.difference(last.enqueuedAt);
      if (timeSinceLast <= coalescingWindow) {
        AppLog.d(
          _tag,
          'Coalescing wakeup for $agentId (${timeSinceLast.inMilliseconds}ms since last)',
        );
        existing[existing.length - 1] = last.merge(request);
        return;
      }
    }

    _queues.putIfAbsent(agentId, () => []).add(request);
    AppLog.d(_tag, 'Enqueued wakeup for $agentId: $wakeReason');
  }

  List<WakeupRequest>? flush(String agentId) {
    final requests = _queues.remove(agentId);
    if (requests == null || requests.isEmpty) return null;

    AppLog.d(_tag, 'Flushing ${requests.length} wakeups for $agentId');

    if (requests.length == 1) {
      return List<WakeupRequest>.unmodifiable(requests);
    }

    final merged = requests.reduce((a, b) => a.merge(b));
    return [merged];
  }

  void purge(String agentId) {
    _queues.remove(agentId);
    AppLog.d(_tag, 'Purged wakeups for $agentId');
  }

  bool get isEmpty => _queues.isEmpty;

  bool get isNotEmpty => _queues.isNotEmpty;

  int get length => _queues.length;

  List<String> get pendingAgentIds => List<String>.unmodifiable(_queues.keys);

  bool hasPending(String agentId) {
    final queue = _queues[agentId];
    return queue != null && queue.isNotEmpty;
  }

  int pendingCount(String agentId) => _queues[agentId]?.length ?? 0;

  void clear() {
    _queues.clear();
    AppLog.d(_tag, 'Cleared all wakeup queues');
  }
}
