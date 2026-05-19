import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_persistence/database/daos/cache_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';

/// The checker-agent role (PRD 16 §13): one agent works, another reviews it,
/// both visible in-thread.
///
/// A channel may name a **checker** (a Caches row, kind `channel_checker`,
/// key = channel id, value `{agent_id}`). When any OTHER agent's main run
/// completes in that channel, the checker is auto-dispatched into the same
/// conversation with a review brief — its turn streams into the thread like
/// any participant's. Loop-safe: the checker's own completions never
/// re-trigger it and a per-channel cooldown absorbs completion bursts.
class CheckerDispatchListener {
  /// Creates the listener. Call [start].
  CheckerDispatchListener({
    required DomainEventBus eventBus,
    required WorkspaceDatabaseManager workspaceDbs,
    required AgentRunLogRepository runLogs,
    required Future<void> Function({
      required String channelId,
      required String agentId,
      required String prompt,
      required String workspaceId,
    })
    dispatchChecker,
    this.cooldown = const Duration(minutes: 2),
    DateTime Function()? now,
  }) : _eventBus = eventBus,
       _dbs = workspaceDbs,
       _runLogs = runLogs,
       _dispatchChecker = dispatchChecker,
       _now = now ?? DateTime.now;

  /// The Caches kind naming a channel's checker agent.
  static const String cacheKind = 'channel_checker';

  final DomainEventBus _eventBus;
  final WorkspaceDatabaseManager _dbs;
  final AgentRunLogRepository _runLogs;
  final Future<void> Function({
    required String channelId,
    required String agentId,
    required String prompt,
    required String workspaceId,
  })
  _dispatchChecker;

  /// A channel's checker row lives in that channel's workspace database file.
  CacheDao _cache(String workspaceId) => _dbs.of(workspaceId).cacheDao;

  /// Minimum spacing between checker dispatches per channel.
  final Duration cooldown;

  final DateTime Function() _now;
  final Map<String, DateTime> _lastDispatch = {};
  StreamSubscription<AgentRunCompleted>? _sub;

  /// Begins listening for completed runs.
  void start() {
    _sub ??= _eventBus.on<AgentRunCompleted>().listen(
      (event) => unawaited(_onRunCompleted(event)),
    );
  }

  Future<void> _onRunCompleted(AgentRunCompleted event) async {
    final workspaceId = event.workspaceId;
    final channelId = event.conversationId;
    if (workspaceId == null ||
        workspaceId.isEmpty ||
        channelId == null ||
        channelId.isEmpty) {
      return;
    }
    final raw = await _cache(
      workspaceId,
    ).read(workspaceId, cacheKind, channelId);
    if (raw == null) {
      return;
    }
    String? checkerId;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        checkerId = decoded['agent_id'] as String?;
      }
    } catch (_) {
      return;
    }
    if (checkerId == null || checkerId.isEmpty) {
      return;
    }
    // Never review yourself — that is the loop guard, not a heuristic.
    if (event.agentId == checkerId) {
      return;
    }
    // Only MAIN runs trigger a review (subagents/advisors are internals).
    if (event.runId != null) {
      final run = await _runLogs.getById(workspaceId, event.runId!);
      if (run != null && run.role != AgentRunRole.main) {
        return;
      }
    }
    final last = _lastDispatch[channelId];
    if (last != null && _now().difference(last) < cooldown) {
      return;
    }
    _lastDispatch[channelId] = _now();
    await _dispatchChecker(
      channelId: channelId,
      agentId: checkerId,
      workspaceId: workspaceId,
      prompt:
          'You are this channel\'s checker (second pair of eyes). Another '
          'agent just finished a run in this conversation. Re-read the '
          'recent messages and its transcript, review the work critically '
          '(correctness, missed requirements, risky changes) and post a '
          'concise review. If everything is sound, say so briefly — do not '
          'invent problems.',
    );
  }

  /// Stops listening.
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }
}
