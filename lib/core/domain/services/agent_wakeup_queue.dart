import 'dart:collection';

import 'package:control_center/core/utils/app_log.dart';

/// A request to wake up an agent, enqueued with a reason and optional context.
class WakeupRequest {
  /// Creates a [WakeupRequest] with the given [agentId], [wakeReason],
  /// optional [contextSnapshot], and [enqueuedAt] timestamp.
  const WakeupRequest({
    required this.agentId,
    required this.wakeReason,
    this.contextSnapshot,
    required this.enqueuedAt,
  });

  /// The agent to wake up.
  final String agentId;
  /// The reason for the wakeup.
  final String wakeReason;
  /// Optional context snapshot associated with the wakeup.
  final Map<String, dynamic>? contextSnapshot;
  /// When the wakeup was enqueued.
  final DateTime enqueuedAt;

  /// Returns a new [WakeupRequest] merging this one with [other],
  /// combining contexts and wake reasons, using the earliest timestamp.
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
    if (identical(a, b)) {
      return true;
    }
    if (a == null || b == null) {
      return a == b;
    }
    if (a.length != b.length) {
      return false;
    }
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) {
        return false;
      }
    }
    return true;
  }

  @override
  String toString() =>
      'WakeupRequest(agentId: $agentId, wakeReason: $wakeReason, '
      'enqueuedAt: $enqueuedAt)';
}

/// A coalescing in-memory queue for agent wakeup requests.
class AgentWakeupQueue {
  static const _tag = 'AgentWakeupQueue';

  /// Requests within this window of the last enqueue are coalesced into one.
  static const coalescingWindow = Duration(seconds: 5);

  final _queues = HashMap<String, List<WakeupRequest>>();

  /// Enqueues a wakeup request for [agentId].
  ///
  /// If the last wakeup for this agent was within [coalescingWindow],
  /// the new request is merged into the previous one instead of being
  /// appended.
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

  /// Returns and removes all pending wakeups for [agentId], coalescing
  /// multiple requests into one merged [WakeupRequest].
  List<WakeupRequest>? flush(String agentId) {
    final requests = _queues.remove(agentId);
    if (requests == null || requests.isEmpty) {
      return null;
    }

    AppLog.d(_tag, 'Flushing ${requests.length} wakeups for $agentId');

    if (requests.length == 1) {
      return List<WakeupRequest>.unmodifiable(requests);
    }

    final merged = requests.reduce((a, b) => a.merge(b));
    return [merged];
  }

  /// Removes all pending wakeups for [agentId] without processing them.
  void purge(String agentId) {
    _queues.remove(agentId);
    AppLog.d(_tag, 'Purged wakeups for $agentId');
  }

  /// Whether the queue has no pending wakeups.
  bool get isEmpty => _queues.isEmpty;

  /// Whether the queue has any pending wakeups.
  bool get isNotEmpty => _queues.isNotEmpty;

  /// The number of agents with pending wakeups.
  int get length => _queues.length;

  /// The list of agent IDs that have pending wakeups.
  List<String> get pendingAgentIds => List<String>.unmodifiable(_queues.keys);

  /// Whether [agentId] has any pending wakeups.
  bool hasPending(String agentId) {
    final queue = _queues[agentId];
    return queue != null && queue.isNotEmpty;
  }

  /// The number of pending wakeups for [agentId].
  int pendingCount(String agentId) => _queues[agentId]?.length ?? 0;

  /// Removes all pending wakeups for all agents.
  void clear() {
    _queues.clear();
    AppLog.d(_tag, 'Cleared all wakeup queues');
  }
}
