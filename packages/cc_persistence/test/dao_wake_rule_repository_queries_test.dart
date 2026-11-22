import 'package:cc_domain/features/dispatch/domain/entities/wake_rule.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_trigger.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/seed_agents.dart';
import 'helpers/test_database.dart';

/// The reads and writes the rule service added to [DaoWakeRuleRepository]:
/// the rules a run created, and a rule's note and busy behaviour.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoWakeRuleRepository repo;
  final t0 = DateTime(2026, 5, 1, 12);

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    repo = DaoWakeRuleRepository(dbs, clock: () => t0);
    for (final ws in ['w-1', 'w-2']) {
      await seedTestWorkspace(global, dbs, ws);
      final db = dbs.of(ws);
      await seedParents(db, agents: ['agent-1', 'agent-2'], spaces: ['sp-1']);
      await seedConversation(db, 'conv-1', spaceId: 'sp-1');
      await seedConversation(db, 'conv-2', spaceId: 'sp-1');
    }
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  WakeRule rule(
    String id, {
    String workspaceId = 'w-1',
    String conversationId = 'conv-1',
    String agentId = 'agent-1',
    String? createdByRunId,
    WakeTrigger? trigger,
    DateTime? createdAt,
  }) => WakeRule(
    id: id,
    workspaceId: workspaceId,
    spaceId: 'sp-1',
    conversationId: conversationId,
    agentId: agentId,
    trigger: trigger ?? Every(const Duration(hours: 1)),
    note: 'check the build',
    costCapMicros: 2000000,
    expiresAt: t0.add(const Duration(days: 7)),
    origin: WakeRuleOrigin.agent,
    createdByRunId: createdByRunId,
    createdAt: createdAt ?? t0,
    updatedAt: createdAt ?? t0,
  );

  Future<void> insert(WakeRule r) async {
    expect(
      await repo.insertWithinLimits(
        r,
        perConversation: 100,
        perAgent: 100,
        perWorkspace: 100,
        lineage: null,
      ),
      isNull,
    );
  }

  test(
    'lists the rules a run created, one-offs included, any status',
    () async {
      await insert(
        rule(
          'r-once',
          createdByRunId: 'run-1',
          trigger: OnceAt(t0.add(const Duration(hours: 1))),
        ),
      );
      await insert(
        rule(
          'r-every',
          createdByRunId: 'run-1',
          createdAt: t0.add(const Duration(seconds: 1)),
        ),
      );
      await insert(rule('r-other-run', createdByRunId: 'run-2'));
      await insert(
        rule('r-other-agent', agentId: 'agent-2', createdByRunId: 'run-1'),
      );
      await insert(
        rule('r-other-ws', workspaceId: 'w-2', createdByRunId: 'run-1'),
      );
      await repo.transition(
        'w-1',
        id: 'r-once',
        from: {WakeRuleStatus.active},
        to: WakeRuleStatus.ended,
        endReason: WakeRuleEndReason.fired,
        now: t0,
      );

      final made = await repo.listCreatedByRun(
        'w-1',
        conversationId: 'conv-1',
        agentId: 'agent-1',
        runId: 'run-1',
      );
      expect([for (final r in made) r.id], ['r-every', 'r-once']);
      expect(
        await repo.listCreatedByRun(
          'w-2',
          conversationId: 'conv-1',
          agentId: 'agent-1',
          runId: 'run-1',
        ),
        hasLength(1),
      );
    },
  );

  test(
    'sets the note and busy behaviour of a rule that has not ended',
    () async {
      await insert(rule('r-1'));
      expect(
        await repo.setTerms(
          'w-1',
          id: 'r-1',
          note: 'look at the flaky test first',
          whenBusy: WakeWhenBusy.queue,
          noteEditedByUserId: 'user-7',
          now: t0.add(const Duration(minutes: 1)),
        ),
        isTrue,
      );
      final read = await repo.getById('w-1', 'r-1');
      expect(read!.note, 'look at the flaky test first');
      expect(read.whenBusy, WakeWhenBusy.queue);
      expect(read.noteEditedByUserId, 'user-7');
      // A change of busy behaviour alone keeps whose words the note is.
      await repo.setTerms(
        'w-1',
        id: 'r-1',
        note: read.note,
        whenBusy: WakeWhenBusy.skip,
        noteEditedByUserId: null,
        now: t0.add(const Duration(minutes: 2)),
      );
      expect((await repo.getById('w-1', 'r-1'))!.noteEditedByUserId, 'user-7');

      await repo.transition(
        'w-1',
        id: 'r-1',
        from: {WakeRuleStatus.active},
        to: WakeRuleStatus.ended,
        endReason: WakeRuleEndReason.cancelled,
        now: t0,
      );
      expect(
        await repo.setTerms(
          'w-1',
          id: 'r-1',
          note: 'too late',
          whenBusy: WakeWhenBusy.skip,
          noteEditedByUserId: null,
          now: t0,
        ),
        isFalse,
      );
      expect(
        () => repo.setTerms(
          'w-1',
          id: 'r-1',
          note: 'x' * (WakeRule.maxNoteLength + 1),
          whenBusy: WakeWhenBusy.skip,
          noteEditedByUserId: null,
          now: t0,
        ),
        throwsArgumentError,
      );
    },
  );

  test('the other workspace\'s id writes nothing', () async {
    await insert(rule('r-1'));
    expect(
      await repo.setTerms(
        'w-2',
        id: 'r-1',
        note: 'not yours',
        whenBusy: WakeWhenBusy.queue,
        noteEditedByUserId: null,
        now: t0,
      ),
      isFalse,
    );
    expect((await repo.getById('w-1', 'r-1'))!.note, 'check the build');
  });
}
