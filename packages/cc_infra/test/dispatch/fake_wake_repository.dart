import 'dart:async';

import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/ports/wake_run_ledger.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';

/// An in-memory [WakeRepository] with the stored one's semantics: one map
/// per workspace (a foreign id is not found), a dedup key per workspace, and
/// every state change conditional on the states it leaves.
class FakeWakeRepository implements WakeRepository {
  final Map<String, Map<String, Wake>> _byWs = {};
  final _changes = StreamController<void>.broadcast();

  Map<String, Wake> _ws(String workspaceId) =>
      _byWs.putIfAbsent(workspaceId, () => {});

  /// Every wake of [workspaceId].
  List<Wake> all(String workspaceId) => _ws(workspaceId).values.toList();

  void _put(Wake wake) {
    _ws(wake.workspaceId)[wake.id] = wake;
    _changes.add(null);
  }

  int _move(
    String workspaceId,
    List<String> ids,
    Set<WakeState> from,
    Wake Function(Wake wake) to,
  ) {
    var moved = 0;
    for (final id in ids.toSet()) {
      final wake = _ws(workspaceId)[id];
      if (wake != null && from.contains(wake.state)) {
        _put(to(wake));
        moved++;
      }
    }
    return moved;
  }

  static const _open = {WakeState.pending, WakeState.held, WakeState.claimed};

  static int _order(Wake a, Wake b) {
    final byTime = a.notBefore.compareTo(b.notBefore);
    if (byTime != 0) {
      return byTime;
    }
    final byCreated = a.createdAt.compareTo(b.createdAt);
    return byCreated != 0 ? byCreated : a.id.compareTo(b.id);
  }

  @override
  Future<bool> insertIfAbsent(Wake wake) async {
    if (_ws(wake.workspaceId).values.any((w) => w.dedupKey == wake.dedupKey)) {
      return false;
    }
    _put(wake);
    return true;
  }

  @override
  Future<Wake?> getById(String workspaceId, String id) async =>
      _ws(workspaceId)[id];

  @override
  Future<Wake?> getByDedupKey(String workspaceId, String dedupKey) async =>
      _ws(workspaceId).values.where((w) => w.dedupKey == dedupKey).firstOrNull;

  @override
  Future<List<Wake>> listDue(
    String workspaceId, {
    required DateTime now,
    int limit = 100,
  }) async =>
      (_ws(workspaceId).values
              .where(
                (w) =>
                    w.state == WakeState.pending && !w.notBefore.isAfter(now),
              )
              .toList()
            ..sort(_order))
          .take(limit)
          .toList();

  @override
  Future<DateTime?> earliestPendingNotBefore(String workspaceId) async {
    final pending = _ws(
      workspaceId,
    ).values.where((w) => w.state == WakeState.pending).toList()..sort(_order);
    return pending.firstOrNull?.notBefore;
  }

  @override
  Future<List<Wake>> listForConversation(
    String workspaceId,
    String conversationId, {
    Set<WakeState>? states,
  }) async => [
    for (final w in _ws(workspaceId).values)
      if (w.conversationId == conversationId &&
          (states == null || states.contains(w.state)))
        w,
  ];

  @override
  Future<List<Wake>> listForRule(
    String workspaceId, {
    required String conversationId,
    required String ruleId,
    required int limit,
    ({DateTime createdAt, String id})? before,
  }) async {
    int newestFirst(Wake a, Wake b) {
      final at = b.createdAt.compareTo(a.createdAt);
      return at != 0 ? at : b.id.compareTo(a.id);
    }

    final rows = [
      for (final w in _ws(workspaceId).values)
        if (w.conversationId == conversationId &&
            w.detail.ruleId == ruleId &&
            (before == null ||
                w.createdAt.isBefore(before.createdAt) ||
                (w.createdAt == before.createdAt &&
                    w.id.compareTo(before.id) < 0)))
          w,
    ]..sort(newestFirst);
    return rows.take(limit).toList();
  }

  @override
  Future<List<Wake>> listPendingFor(
    String workspaceId, {
    required String conversationId,
    required String agentId,
  }) async =>
      _ws(workspaceId).values
          .where(
            (w) =>
                w.conversationId == conversationId &&
                w.agentId == agentId &&
                w.state == WakeState.pending,
          )
          .toList()
        ..sort(_order);

  @override
  Stream<List<Wake>> watchForConversation(
    String workspaceId,
    String conversationId,
  ) async* {
    List<Wake> open() =>
        _ws(workspaceId).values
            .where(
              (w) =>
                  w.conversationId == conversationId &&
                  (w.state == WakeState.pending || w.state == WakeState.held),
            )
            .toList()
          ..sort(_order);
    yield open();
    await for (final _ in _changes.stream) {
      yield open();
    }
  }

  /// Runs after a claim was written and before the call returns (a race's
  /// other side, in the claim's await); cleared after one use.
  Future<void> Function()? duringClaim;

  @override
  Future<List<String>> claim(
    String workspaceId, {
    required List<String> ids,
    required DateTime now,
  }) async {
    final claimed = <String>[];
    for (final id in ids.toSet()) {
      if (_move(
            workspaceId,
            [id],
            {WakeState.pending},
            (w) => w.copyWith(
              state: WakeState.claimed,
              claimedAt: now,
              attempt: w.attempt + 1,
            ),
          ) ==
          1) {
        claimed.add(id);
      }
    }
    final during = duringClaim;
    duringClaim = null;
    await during?.call();
    return claimed;
  }

  @override
  Future<int> markDelivered(
    String workspaceId, {
    required List<String> ids,
    required String? runId,
    required DateTime now,
  }) async => _move(
    workspaceId,
    ids,
    {WakeState.pending, WakeState.claimed},
    (w) => w.copyWith(
      state: WakeState.delivered,
      deliveredRunId: runId,
      settledAt: now,
    ),
  );

  int _settle(
    String workspaceId,
    List<String> ids,
    WakeState state,
    String reason,
    DateTime now,
  ) => _move(
    workspaceId,
    ids,
    _open,
    (w) => w.copyWith(state: state, stateReason: reason, settledAt: now),
  );

  @override
  Future<int> markSkipped(
    String workspaceId, {
    required List<String> ids,
    required String reason,
    required DateTime now,
  }) async => _settle(workspaceId, ids, WakeState.skipped, reason, now);

  @override
  Future<int> markExpired(
    String workspaceId, {
    required List<String> ids,
    required String reason,
    required DateTime now,
  }) async => _settle(workspaceId, ids, WakeState.expired, reason, now);

  @override
  Future<int> cancel(
    String workspaceId, {
    required List<String> ids,
    required String reason,
    required DateTime now,
  }) async => _settle(workspaceId, ids, WakeState.cancelled, reason, now);

  @override
  Future<int> hold(
    String workspaceId, {
    required List<String> ids,
    required String reason,
  }) async => _move(workspaceId, ids, {
    WakeState.pending,
  }, (w) => w.copyWith(state: WakeState.held, stateReason: reason));

  @override
  Future<int> release(String workspaceId, {required List<String> ids}) async =>
      _move(workspaceId, ids, {
        WakeState.held,
      }, (w) => w.copyWith(state: WakeState.pending, removeStateReason: true));

  @override
  Future<int> releaseClaim(
    String workspaceId, {
    required List<String> ids,
  }) async => _move(workspaceId, ids, {
    WakeState.claimed,
  }, (w) => w.copyWith(state: WakeState.pending, removeClaimedAt: true));

  @override
  Future<List<Wake>> reclaimStaleClaims(
    String workspaceId, {
    required DateTime claimedBefore,
  }) async {
    final stale = [
      for (final w in _ws(workspaceId).values)
        if (w.state == WakeState.claimed &&
            w.claimedAt != null &&
            w.claimedAt!.isBefore(claimedBefore))
          w,
    ];
    _move(
      workspaceId,
      [for (final w in stale) w.id],
      {WakeState.claimed},
      (w) => w.copyWith(state: WakeState.pending, removeClaimedAt: true),
    );
    return [for (final w in stale) _ws(workspaceId)[w.id]!];
  }

  @override
  Future<List<Wake>> expireDue(
    String workspaceId, {
    required DateTime now,
  }) async {
    final due = [
      for (final w in _ws(workspaceId).values)
        if ((w.state == WakeState.pending || w.state == WakeState.held) &&
            w.expiresAt != null &&
            !w.expiresAt!.isAfter(now))
          w.id,
    ];
    _move(
      workspaceId,
      due,
      {WakeState.pending, WakeState.held},
      (w) => w.copyWith(
        state: WakeState.expired,
        stateReason: 'expires_at_passed',
        settledAt: now,
      ),
    );
    return [for (final id in due) _ws(workspaceId)[id]!];
  }

  @override
  Future<int> defer(
    String workspaceId, {
    required List<String> ids,
    required DateTime until,
    required String reason,
  }) async => _move(
    workspaceId,
    ids,
    {WakeState.pending, WakeState.claimed},
    (w) => w.copyWith(
      state: WakeState.pending,
      notBefore: until,
      stateReason: reason,
      removeClaimedAt: true,
    ),
  );

  @override
  Future<int> deferWaiting(
    String workspaceId, {
    required String id,
    required DateTime until,
    required String reason,
    required DateTime expiresAt,
  }) async => _move(
    workspaceId,
    [id],
    {WakeState.pending, WakeState.claimed},
    (w) => w.copyWith(
      state: WakeState.pending,
      notBefore: until,
      stateReason: reason,
      removeClaimedAt: true,
      expiresAt: expiresAt,
    ),
  );

  @override
  Future<List<Wake>> expireWaiting(
    String workspaceId, {
    required DateTime now,
    required Set<String> reasons,
  }) async {
    final due = [
      for (final w in _ws(workspaceId).values)
        if (w.state == WakeState.pending &&
            reasons.contains(w.stateReason) &&
            w.expiresAt != null &&
            !w.expiresAt!.isAfter(now))
          w.id,
    ];
    _move(workspaceId, due, {
      WakeState.pending,
    }, (w) => w.copyWith(state: WakeState.expired, settledAt: now));
    return [for (final id in due) _ws(workspaceId)[id]!];
  }

  @override
  Future<int> refreshClaims(
    String workspaceId, {
    required List<String> ids,
    required DateTime now,
  }) async => _move(workspaceId, ids, {
    WakeState.claimed,
  }, (w) => w.copyWith(claimedAt: now));

  @override
  Future<int> reopenDelivered(
    String workspaceId, {
    required List<String> ids,
    required String reason,
  }) async => _move(
    workspaceId,
    ids,
    {WakeState.delivered},
    (w) => w.copyWith(
      state: WakeState.pending,
      stateReason: reason,
      removeDeliveredRunId: true,
      removeClaimedAt: true,
      removeSettledAt: true,
    ),
  );

  @override
  Future<int> deleteSettledBefore(
    String workspaceId, {
    required DateTime cutoff,
  }) async {
    final old = [
      for (final w in _ws(workspaceId).values)
        if (w.state.isSettled &&
            w.settledAt != null &&
            w.settledAt!.isBefore(cutoff))
          w.id,
    ];
    for (final id in old) {
      _ws(workspaceId).remove(id);
    }
    return old.length;
  }

  @override
  Future<int> countDeliveredRunsSince(
    String workspaceId, {
    required DateTime since,
    String? conversationId,
  }) async => {
    for (final w in _ws(workspaceId).values)
      if (w.state == WakeState.delivered &&
          w.deliveredRunId != null &&
          w.settledAt != null &&
          !w.settledAt!.isBefore(since) &&
          (conversationId == null || w.conversationId == conversationId))
        w.deliveredRunId,
  }.length;

  @override
  Future<List<Wake>> cancelWhere(
    String workspaceId, {
    String? goalId,
    String? ruleId,
    String? askId,
    String? requestedByUserId,
    String? conversationId,
    required String reason,
    required DateTime now,
  }) async {
    final hits = [
      for (final w in _ws(workspaceId).values)
        if ((w.state == WakeState.pending || w.state == WakeState.held) &&
            (goalId == null || w.detail.goalId == goalId) &&
            (ruleId == null || w.detail.ruleId == ruleId) &&
            (askId == null || w.detail.askId == askId) &&
            (requestedByUserId == null ||
                w.requestedByUserId == requestedByUserId) &&
            (conversationId == null || w.conversationId == conversationId))
          w.id,
    ];
    _settle(workspaceId, hits, WakeState.cancelled, reason, now);
    return [for (final id in hits) _ws(workspaceId)[id]!];
  }

  @override
  Future<bool> hasExpiringHeld(String workspaceId) async => _ws(
    workspaceId,
  ).values.any((w) => w.state == WakeState.held && w.expiresAt != null);

  @override
  Future<List<String>> workspacesWithOpenWakes() async => [
    for (final entry in _byWs.entries)
      if (entry.value.values.any(
            (w) => w.state == WakeState.pending || w.state == WakeState.claimed,
          ) ||
          await hasExpiringHeld(entry.key))
        entry.key,
  ];
}

/// An in-memory [WakeRunLedger]: run id → wake ids, per workspace.
class FakeWakeRunLedger implements WakeRunLedger {
  /// workspace → run → wake ids, oldest run first.
  final Map<String, Map<String, List<String>>> runs = {};

  /// How each run ended (absent: live).
  final Map<String, RunEndReason> ended = {};

  @override
  Future<WakeLedgerRun?> runForWake(String workspaceId, String wakeId) async {
    String? newest;
    for (final entry in (runs[workspaceId] ?? const {}).entries) {
      if (entry.value.contains(wakeId)) {
        newest = entry.key;
      }
    }
    if (newest == null) {
      return null;
    }
    final endReason = ended[newest];
    return WakeLedgerRun(
      runId: newest,
      live: endReason == null,
      endReason: endReason,
    );
  }

  @override
  Future<void> addWakeIds(
    String workspaceId,
    String runId,
    List<String> wakeIds,
  ) async {
    final ids = runs
        .putIfAbsent(workspaceId, () => {})
        .putIfAbsent(runId, () => []);
    for (final id in wakeIds) {
      if (!ids.contains(id)) {
        ids.add(id);
      }
    }
  }
}
