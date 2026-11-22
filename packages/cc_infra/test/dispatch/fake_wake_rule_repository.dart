import 'dart:async';

import 'package:cc_domain/features/dispatch/domain/entities/wake_rule.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_trigger.dart';

/// An in-memory [WakeRuleRepository] with the stored one's conditional
/// writes: fires and skips only move an active rule, limits count active and
/// paused rules, every read is workspace-scoped.
class FakeWakeRuleRepository implements WakeRuleRepository {
  final Map<String, Map<String, WakeRule>> _byWs = {};
  final _changes = StreamController<void>.broadcast();

  Map<String, WakeRule> _ws(String workspaceId) =>
      _byWs.putIfAbsent(workspaceId, () => {});

  /// Every rule of [workspaceId].
  List<WakeRule> all(String workspaceId) => _ws(workspaceId).values.toList();

  /// Puts [rule] as it is (a test's starting state).
  void put(WakeRule rule) {
    _ws(rule.workspaceId)[rule.id] = rule;
    _changes.add(null);
  }

  static const _open = {WakeRuleStatus.active, WakeRuleStatus.paused};

  List<WakeRule> _newest(Iterable<WakeRule> rules) =>
      rules.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  bool _write(
    String ws,
    String id,
    bool Function(WakeRule r) when,
    WakeRule Function(WakeRule r) change,
  ) {
    final rule = _ws(ws)[id];
    if (rule == null || !when(rule)) {
      return false;
    }
    _ws(ws)[id] = change(rule);
    _changes.add(null);
    return true;
  }

  @override
  Future<WakeRuleLimit?> insertWithinLimits(
    WakeRule rule, {
    required int perConversation,
    required int perAgent,
    required int perWorkspace,
    required WakeLineageCap? lineage,
  }) async {
    final open = [
      for (final r in _ws(rule.workspaceId).values)
        if (_open.contains(r.status)) r,
    ];
    if (open
            .where(
              (r) =>
                  r.agentId == rule.agentId &&
                  r.conversationId == rule.conversationId,
            )
            .length >=
        perConversation) {
      return WakeRuleLimit.conversation;
    }
    if (open.where((r) => r.agentId == rule.agentId).length >= perAgent) {
      return WakeRuleLimit.agent;
    }
    if (open.length >= perWorkspace) {
      return WakeRuleLimit.workspace;
    }
    if (lineage != null) {
      final spent = await lineageTotals(rule.workspaceId, lineage.rootRuleId);
      if (spent.runs >= lineage.maxRuns ||
          spent.costMicros >= lineage.costCapMicros) {
        return WakeRuleLimit.lineage;
      }
    }
    if (_ws(rule.workspaceId).containsKey(rule.id)) {
      throw StateError('rule ${rule.id} exists');
    }
    put(rule);
    return null;
  }

  @override
  Future<WakeLineageTotals> lineageTotals(
    String workspaceId,
    String rootRuleId,
  ) async {
    var runs = 0;
    var cost = 0;
    for (final r in _ws(workspaceId).values) {
      if (r.id == rootRuleId || r.rootRuleId == rootRuleId) {
        runs += r.runCount;
        cost += r.costMicros;
      }
    }
    return (runs: runs, costMicros: cost);
  }

  @override
  Future<bool> recordFire(
    String workspaceId, {
    required String id,
    required int costMicrosDelta,
    required DateTime? nextFireAt,
    required DateTime firedAt,
  }) async => _write(
    workspaceId,
    id,
    (r) => r.isActive,
    (r) => r.copyWith(
      runCount: r.runCount + 1,
      costMicros: r.costMicros + costMicrosDelta,
      lastFiredAt: firedAt,
      nextFireAt: nextFireAt,
      removeNextFireAt: nextFireAt == null,
      updatedAt: firedAt,
    ),
  );

  @override
  Future<bool> recordLoopFire(
    String workspaceId, {
    required String id,
    required DateTime firedAt,
  }) async => _write(
    workspaceId,
    id,
    (r) => r.isActive && r.trigger is SelfPaced,
    (r) => r.copyWith(
      runCount: r.runCount + 1,
      lastFiredAt: firedAt,
      updatedAt: firedAt,
    ),
  );

  @override
  Future<bool> setNextAfterRun(
    String workspaceId, {
    required String id,
    required DateTime? delivered,
    required DateTime nextFireAt,
    required DateTime now,
  }) async => _write(
    workspaceId,
    id,
    (r) =>
        r.isActive &&
        r.trigger is SelfPaced &&
        (r.nextFireAt == null ||
            (delivered != null && r.nextFireAt!.isAtSameMomentAs(delivered))),
    (r) => r.copyWith(
      nextFireAt: nextFireAt,
      removeNextDelaySeconds: true,
      updatedAt: now,
    ),
  );

  @override
  Future<bool> recordSkip(
    String workspaceId, {
    required String id,
    required DateTime? nextFireAt,
    required DateTime now,
  }) async => _write(
    workspaceId,
    id,
    (r) => r.isActive,
    (r) => r.copyWith(
      skipCount: r.skipCount + 1,
      nextFireAt: nextFireAt,
      removeNextFireAt: nextFireAt == null,
      updatedAt: now,
    ),
  );

  @override
  Future<int?> addCost(
    String workspaceId, {
    required String id,
    required int micros,
    required DateTime now,
  }) async {
    final moved = _write(
      workspaceId,
      id,
      (_) => true,
      (r) => r.copyWith(costMicros: r.costMicros + micros, updatedAt: now),
    );
    return moved ? _ws(workspaceId)[id]!.costMicros : null;
  }

  @override
  Future<bool> setNext(
    String workspaceId, {
    required String id,
    required DateTime? nextFireAt,
    required int? nextDelaySeconds,
    required DateTime now,
  }) async => _write(
    workspaceId,
    id,
    (r) =>
        _open.contains(r.status) &&
        (nextDelaySeconds == null || r.trigger is SelfPaced),
    (r) => r.copyWith(
      nextFireAt: nextFireAt,
      removeNextFireAt: nextFireAt == null,
      nextDelaySeconds: nextDelaySeconds,
      removeNextDelaySeconds: nextDelaySeconds == null,
      updatedAt: now,
    ),
  );

  @override
  Future<bool> transition(
    String workspaceId, {
    required String id,
    required Set<WakeRuleStatus> from,
    required WakeRuleStatus to,
    required WakeRuleEndReason? endReason,
    required DateTime now,
  }) async => _write(
    workspaceId,
    id,
    (r) => from.contains(r.status),
    (r) => r.copyWith(
      status: to,
      endReason: endReason,
      removeEndReason: endReason == null,
      updatedAt: now,
    ),
  );

  @override
  Future<bool> setTerms(
    String workspaceId, {
    required String id,
    required String note,
    required WakeWhenBusy whenBusy,
    required String? noteEditedByUserId,
    required DateTime now,
  }) async => _write(
    workspaceId,
    id,
    (r) => _open.contains(r.status),
    (r) => r.copyWith(
      note: note,
      whenBusy: whenBusy,
      noteEditedByUserId: noteEditedByUserId,
      updatedAt: now,
    ),
  );

  @override
  Future<bool> setLimits(
    String workspaceId, {
    required String id,
    required DateTime expiresAt,
    required int? maxRuns,
    required int costCapMicros,
    required DateTime now,
  }) async => _write(
    workspaceId,
    id,
    (r) => _open.contains(r.status),
    (r) => r.copyWith(
      expiresAt: expiresAt,
      maxRuns: maxRuns,
      removeMaxRuns: maxRuns == null,
      costCapMicros: costCapMicros,
      updatedAt: now,
    ),
  );

  @override
  Future<WakeRule?> getById(String workspaceId, String id) async =>
      _ws(workspaceId)[id];

  @override
  Future<List<WakeRule>> listForConversation(
    String workspaceId,
    String conversationId, {
    Set<WakeRuleStatus>? statuses,
  }) async => _newest(
    _ws(workspaceId).values.where(
      (r) =>
          r.conversationId == conversationId &&
          (statuses == null || statuses.contains(r.status)),
    ),
  );

  @override
  Future<List<WakeRule>> listForAgent(
    String workspaceId,
    String agentId, {
    Set<WakeRuleStatus>? statuses,
  }) async => _newest(
    _ws(workspaceId).values.where(
      (r) =>
          r.agentId == agentId &&
          (statuses == null || statuses.contains(r.status)),
    ),
  );

  @override
  Future<List<WakeRule>> listActiveByEvent(
    String workspaceId,
    WakeEventKind kind,
  ) async =>
      _ws(workspaceId).values
          .where(
            (r) =>
                r.isActive &&
                r.trigger is OnEvent &&
                (r.trigger as OnEvent).eventKind == kind,
          )
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  Future<List<WakeRule>> listCreatedByRun(
    String workspaceId, {
    required String conversationId,
    required String agentId,
    required String runId,
  }) async => _newest(
    _ws(workspaceId).values.where(
      (r) =>
          r.conversationId == conversationId &&
          r.agentId == agentId &&
          r.createdByRunId == runId,
    ),
  );

  @override
  Future<List<WakeRule>> listByGoal(String workspaceId, String goalId) async =>
      _newest(_ws(workspaceId).values.where((r) => r.goalId == goalId));

  @override
  Future<List<WakeRule>> listByRoot(
    String workspaceId,
    String rootRuleId,
  ) async => _newest(
    _ws(workspaceId).values.where((r) => r.rootRuleId == rootRuleId),
  );

  @override
  Future<List<WakeRule>> listByRequester(
    String workspaceId,
    String userId,
  ) async => _newest(
    _ws(workspaceId).values.where((r) => r.requestedByUserId == userId),
  );

  @override
  Future<List<WakeRule>> listActive(String workspaceId) async =>
      _ws(workspaceId).values.where((r) => r.isActive).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  Future<int> countActive(
    String workspaceId, {
    String? agentId,
    String? conversationId,
  }) async => _ws(workspaceId).values
      .where(
        (r) =>
            r.isActive &&
            (agentId == null || r.agentId == agentId) &&
            (conversationId == null || r.conversationId == conversationId),
      )
      .length;

  @override
  Stream<List<WakeRule>> watchForConversation(
    String workspaceId,
    String conversationId,
  ) async* {
    List<WakeRule> read() => _newest(
      _ws(workspaceId).values.where(
        (r) => r.conversationId == conversationId && _open.contains(r.status),
      ),
    );
    yield read();
    await for (final _ in _changes.stream) {
      yield read();
    }
  }

  @override
  Stream<List<WakeRule>> watchForWorkspace(String workspaceId) async* {
    yield _newest(_ws(workspaceId).values);
    await for (final _ in _changes.stream) {
      yield _newest(_ws(workspaceId).values);
    }
  }

  @override
  Future<bool> delete(String workspaceId, String id) async {
    final removed = _ws(workspaceId).remove(id) != null;
    if (removed) {
      _changes.add(null);
    }
    return removed;
  }

  @override
  Future<List<String>> workspacesWithActiveRules() async => [
    for (final entry in _byWs.entries)
      if (entry.value.values.any((r) => r.isActive)) entry.key,
  ];
}
