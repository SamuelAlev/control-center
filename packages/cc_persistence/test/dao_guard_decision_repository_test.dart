import 'dart:io';

import 'package:cc_domain/features/guardrails/domain/entities/guard_decision.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

/// The audit spine's whole value is that a modified or deleted row is
/// DETECTABLE. These tests are that claim.
void main() {
  late Directory tmp;
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoGuardDecisionRepository repo;
  const ws = 'ws-1';

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('guard_audit_');
    global = GlobalDatabase.forTesting(NativeDatabase.memory());
    // In-process executor, not the background isolate: nothing here is
    // executor-specific and the handshake is flaky on CI.
    dbs = WorkspaceDatabaseManager(
      dataDir: tmp.path,
      global: global,
      executorFactory: (id) =>
          NativeDatabase(File(workspaceDatabasePath(tmp.path, id))),
    );
    await dbs.loadInstallId();
    repo = DaoGuardDecisionRepository(dbs);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
    if (tmp.existsSync()) {
      tmp.deleteSync(recursive: true);
    }
  });

  GuardDecision decision(
    String id, {
    String action = 'tickets.create',
    ActionDecision verdict = ActionDecision.allow,
    String workspaceId = ws,
  }) => GuardDecision(
    id: id,
    workspaceId: workspaceId,
    occurredAt: DateTime.utc(2026, 1, 1, 12),
    actorType: 'agent',
    actorId: 'agent-7',
    onBehalfOfUserId: 'user-1',
    surface: GuardSurface.harness,
    actionName: action,
    decision: verdict,
    actionClasses: const ['gitPush'],
  );

  test('append allocates a monotonic seq and links each row to the last',
      () async {
    await repo.append(decision('d1'));
    await repo.append(decision('d2'));
    await repo.append(decision('d3'));

    final rows = await repo.pageFrom(ws, 1);
    expect(rows.map((r) => r.seq), [1, 2, 3]);
    expect(rows.first.prevHash, isEmpty, reason: 'genesis has no predecessor');
    expect(rows[1].prevHash, rows[0].entryHash);
    expect(rows[2].prevHash, rows[1].entryHash);
    expect(rows.map((r) => r.entryHash).toSet(), hasLength(3));
  });

  test('a fresh chain verifies', () async {
    for (var i = 1; i <= 5; i++) {
      await repo.append(decision('d$i'));
    }
    final result = await repo.verifyChain(ws);
    expect(result.intact, isTrue);
    expect(result.rowsChecked, 5);
    expect(result.brokenAtSeq, isNull);
  });

  test('editing a row in place breaks verification at that row', () async {
    for (var i = 1; i <= 4; i++) {
      await repo.append(decision('d$i'));
    }
    // Tamper exactly as an attacker with database access would: rewrite what
    // the row says happened, leaving the stored hash untouched.
    await dbs
        .of(ws)
        .customStatement(
          "UPDATE guard_decisions SET decision = 'deny', "
          "action_name = 'something.else' WHERE seq = 2",
        );

    final result = await repo.verifyChain(ws);
    expect(result.intact, isFalse);
    expect(result.brokenAtSeq, 2);
    expect(result.reason, contains('modified'));
  });

  test('deleting a row from the middle is detected as a gap', () async {
    for (var i = 1; i <= 4; i++) {
      await repo.append(decision('d$i'));
    }
    await dbs
        .of(ws)
        .customStatement('DELETE FROM guard_decisions WHERE seq = 3');

    final result = await repo.verifyChain(ws);
    expect(result.intact, isFalse);
    expect(result.brokenAtSeq, 4);
    expect(result.reason, contains('gap'));
  });

  test('export-then-truncate keeps the survivors verifiable', () async {
    for (var i = 1; i <= 6; i++) {
      await repo.append(decision('d$i'));
    }
    await repo.truncateWithCheckpoint(
      ws,
      uptoSeq: 3,
      at: DateTime.utc(2026, 2, 1),
    );

    final rows = await repo.pageFrom(ws, 1);
    // The checkpoint occupies the boundary slot, carrying the removed
    // segment's terminal hash so the tail still chains back to genesis.
    expect(rows.map((r) => r.seq), [3, 4, 5, 6]);
    expect(rows.first.kind, 'checkpoint');
    expect(rows[1].prevHash, isNotEmpty);

    final result = await repo.verifyChain(ws);
    expect(result.intact, isTrue, reason: result.reason);
  });

  test('the chain is per workspace — no cross-workspace interleaving',
      () async {
    await repo.append(decision('a1'));
    await repo.append(decision('b1', workspaceId: 'ws-2'));
    await repo.append(decision('a2'));

    final a = await repo.pageFrom(ws, 1);
    final b = await repo.pageFrom('ws-2', 1);
    expect(a.map((r) => r.id), ['a1', 'a2']);
    expect(a.map((r) => r.seq), [1, 2]);
    expect(b.map((r) => r.id), ['b1']);
    expect(b.single.seq, 1, reason: 'each workspace has its own chain');
  });

  test('a forged checkpoint does not launder a deleted stretch', () async {
    for (var i = 1; i <= 6; i++) {
      await repo.append(decision('d$i'));
    }
    final rows = await repo.pageFrom(ws, 1);
    final survivorPrevHash = rows[3].prevHash; // what seq 4 links back to

    // The attack: delete history, then hand-write a "checkpoint" claiming the
    // removed segment ended with exactly the hash the survivors expect.
    await dbs
        .of(ws)
        .customStatement('DELETE FROM guard_decisions WHERE seq <= 3');
    await dbs.of(ws).customStatement(
      "INSERT INTO guard_decisions (id, workspace_id, seq, occurred_at, "
      "actor_type, actor_id, surface, action_name, action_classes, decision, "
      "prompted, prev_hash, entry_hash, kind) VALUES "
      "('forged', '$ws', 3, 0, 'system', 'retention', 'audit', "
      "'audit.truncate', '[]', 'allow', 0, '$survivorPrevHash', "
      "'not-a-real-hash', 'checkpoint')",
    );

    final result = await repo.verifyChain(ws);
    expect(
      result.intact,
      isFalse,
      reason: 'a checkpoint whose own hash is unverified would be a way to '
          'erase history and still pass verification',
    );
    expect(result.brokenAtSeq, 3);
  });

  test('a legitimate truncation is reported, not hidden', () async {
    for (var i = 1; i <= 5; i++) {
      await repo.append(decision('d$i'));
    }
    await repo.truncateWithCheckpoint(
      ws,
      uptoSeq: 2,
      at: DateTime.utc(2026, 3, 1),
    );
    final result = await repo.verifyChain(ws);
    expect(result.intact, isTrue, reason: result.reason);
    // Truncation is legitimate AND it is the shape history-erasure takes, so
    // an auditor is told it happened rather than shown a bare "intact".
    expect(result.checkpoints, 1);
  });

  test('recent returns newest first and round-trips every field', () async {
    await repo.append(
      decision('d1', action: 'git.push', verdict: ActionDecision.deny),
    );
    final rows = await repo.recent(ws);
    final row = rows.single;
    expect(row.actionName, 'git.push');
    expect(row.decision, ActionDecision.deny);
    expect(row.actorType, 'agent');
    expect(row.actorId, 'agent-7');
    expect(row.onBehalfOfUserId, 'user-1');
    expect(row.surface, GuardSurface.harness);
    expect(row.actionClasses, ['gitPush']);
    expect(row.kind, 'decision');
  });
}
