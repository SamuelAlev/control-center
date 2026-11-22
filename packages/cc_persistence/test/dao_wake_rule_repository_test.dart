import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake_rule.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_trigger.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:test/test.dart';

import 'helpers/seed_agents.dart';
import 'helpers/test_database.dart';

/// [DaoWakeRuleRepository] against in-memory databases: every trigger kind
/// round-trips through the flat columns, the reads and counts, the table
/// checks, cascades and workspace isolation.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoWakeRuleRepository repo;
  late List<String> warnings;
  final t0 = DateTime.utc(2026, 5, 1, 12);

  setUp(() async {
    global = createTestGlobalDatabase();
    warnings = [];
    dbs = createTestWorkspaceDatabases(
      global: global,
      onWarn: (_, message) => warnings.add(message),
    );
    repo = DaoWakeRuleRepository(dbs, clock: () => t0);
    for (final ws in ['w-1', 'w-2']) {
      await seedTestWorkspace(global, dbs, ws);
      final db = dbs.of(ws);
      await seedParents(db, agents: ['agent-1', 'agent-2'], spaces: ['sp-1']);
      await seedConversation(db, 'conv-1', spaceId: 'sp-1');
      await seedConversation(db, 'conv-2', spaceId: 'sp-1');
    }
    await DaoAgentGoalRunRepository(dbs).upsert(
      AgentGoalRun(
        id: 'goal-1',
        workspaceId: 'w-1',
        spaceId: 'sp-1',
        conversationId: 'conv-1',
        agentId: 'agent-1',
        userText: 'ship it',
        costCapMicros: 1000,
        createdAt: t0,
        updatedAt: t0,
      ),
    );
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
    WakeTrigger? trigger,
    WakeRuleStatus status = WakeRuleStatus.active,
    WakeRuleEndReason? endReason,
    String? goalId,
    String? requestedByUserId,
    int? nextDelaySeconds,
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
    status: status,
    endReason: endReason,
    goalId: goalId,
    requestedByUserId: requestedByUserId,
    nextDelaySeconds: nextDelaySeconds,
    createdAt: createdAt ?? t0,
    updatedAt: createdAt ?? t0,
  );

  /// Inserts [r] under limits it never reaches.
  Future<void> insert(WakeRule r) async {
    expect(
      await repo.insertWithinLimits(
        r,
        perConversation: 1000,
        perAgent: 1000,
        perWorkspace: 1000,
        lineage: null,
      ),
      isNull,
    );
  }

  Future<Map<String, Object?>> raw(String id) async =>
      (await dbs
              .of('w-1')
              .customSelect(
                'SELECT * FROM wake_rules WHERE id = ?',
                variables: [Variable.withString(id)],
              )
              .getSingle())
          .data;

  group('round trip', () {
    test('every trigger kind round-trips', () async {
      final rules = [
        rule('at', trigger: OnceAt(t0.add(const Duration(hours: 2)))),
        rule('every', trigger: Every(const Duration(minutes: 90))),
        rule('cron', trigger: Cron('0 9 * * 1-5', 'Europe/Berlin')),
        rule('self', trigger: const SelfPaced(), nextDelaySeconds: 600),
        rule('pr', trigger: OnEvent(WakeEventKind.prChecks)),
        rule(
          'ticket',
          trigger: OnEvent(WakeEventKind.ticket, targetId: 'tk-1'),
        ),
      ];
      for (final r in rules) {
        await insert(r);
      }
      for (final r in rules) {
        expect(await repo.getById('w-1', r.id), r, reason: r.id);
      }
    });

    test('every field round-trips', () async {
      final r = WakeRule(
        id: 'r-1',
        workspaceId: 'w-1',
        spaceId: 'sp-1',
        conversationId: 'conv-1',
        agentId: 'agent-1',
        trigger: Every(const Duration(hours: 1)),
        note: 'note',
        deliver: WakeDeliver.notify,
        whenBusy: WakeWhenBusy.queue,
        maxRuns: 5,
        costCapMicros: 900,
        expiresAt: t0.add(const Duration(days: 1)),
        runCount: 2,
        skipCount: 1,
        costMicros: 300,
        lastFiredAt: t0,
        nextFireAt: t0.add(const Duration(hours: 1)),
        goalId: 'goal-1',
        origin: WakeRuleOrigin.person,
        createdByRunId: 'run-1',
        createdByUserId: 'user-1',
        requestedByUserId: 'user-1',
        noteEditedByUserId: 'user-2',
        createdAt: t0,
        updatedAt: t0,
      );
      await insert(r);
      expect(await repo.getById('w-1', 'r-1'), r);
      await insert(rule('r-2').copyWith(rootRuleId: 'r-0'));
      expect((await repo.getById('w-1', 'r-2'))!.rootRuleId, 'r-0');
    });

    test('times come back in UTC, in the whole seconds stored', () async {
      final at = DateTime.utc(2026, 5, 1, 12, 0, 5, 123, 456);
      final r = WakeRule(
        id: 'r-utc',
        workspaceId: 'w-1',
        spaceId: 'sp-1',
        conversationId: 'conv-1',
        agentId: 'agent-1',
        trigger: OnceAt(at.add(const Duration(minutes: 20))),
        note: 'note',
        costCapMicros: 900,
        expiresAt: at.add(const Duration(days: 1)),
        lastFiredAt: at,
        nextFireAt: at.add(const Duration(minutes: 20)),
        origin: WakeRuleOrigin.agent,
        createdAt: at,
        updatedAt: at,
      );
      // The slot is cut where it is made: the entity keeps whole seconds.
      expect(r.nextFireAt, DateTime.utc(2026, 5, 1, 12, 20, 5));
      await insert(r);
      final read = (await repo.getById('w-1', 'r-utc'))!;
      final whole = DateTime.utc(2026, 5, 1, 12, 0, 5);
      for (final (value, name) in [
        (read.expiresAt, 'expiresAt'),
        (read.lastFiredAt!, 'lastFiredAt'),
        (read.nextFireAt!, 'nextFireAt'),
        (read.createdAt, 'createdAt'),
        (read.updatedAt, 'updatedAt'),
        ((read.trigger as OnceAt).at, 'trigger at'),
      ]) {
        expect(value.isUtc, isTrue, reason: name);
        expect(value.millisecond + value.microsecond, 0, reason: name);
      }
      expect(read.nextFireAt, r.nextFireAt);
      expect((read.trigger as OnceAt).at, DateTime.utc(2026, 5, 1, 12, 20, 5));
      expect(read.expiresAt, whole.add(const Duration(days: 1)));
      expect(read.createdAt, whole);
      expect((await raw('r-utc'))['next_fire_at'], 1777638005);
    });

    test('insert refuses an existing id', () async {
      await insert(rule('r-1'));
      await expectLater(
        repo.insertWithinLimits(
          rule('r-1'),
          perConversation: 10,
          perAgent: 10,
          perWorkspace: 10,
          lineage: null,
        ),
        throwsA(anything),
      );
    });
  });

  group('insertWithinLimits', () {
    Future<WakeRuleLimit?> limited(WakeRule r) => repo.insertWithinLimits(
      r,
      perConversation: 2,
      perAgent: 3,
      perWorkspace: 4,
      lineage: null,
    );

    test('names the first limit that refuses, in order', () async {
      expect(await limited(rule('a')), isNull);
      expect(
        await limited(rule('b', status: WakeRuleStatus.paused)),
        isNull,
        reason: 'a paused rule counts, it can resume',
      );
      expect(await limited(rule('c')), WakeRuleLimit.conversation);
      expect(await limited(rule('d', conversationId: 'conv-2')), isNull);
      expect(
        await limited(rule('e', conversationId: 'conv-2')),
        WakeRuleLimit.agent,
      );
      expect(await limited(rule('f', agentId: 'agent-2')), isNull);
      expect(
        await limited(rule('g', agentId: 'agent-2', conversationId: 'conv-2')),
        WakeRuleLimit.workspace,
      );
      for (final id in ['c', 'e', 'g']) {
        expect(await repo.getById('w-1', id), isNull, reason: id);
      }
    });

    test('an ended rule does not count', () async {
      await insert(
        rule(
          'old',
          status: WakeRuleStatus.ended,
          endReason: WakeRuleEndReason.fired,
        ),
      );
      expect(
        await repo.insertWithinLimits(
          rule('new'),
          perConversation: 1,
          perAgent: 1,
          perWorkspace: 1,
          lineage: null,
        ),
        isNull,
      );
    });

    test('creates at once never pass a limit together', () async {
      final results = await Future.wait([
        for (final id in ['a', 'b', 'c'])
          repo.insertWithinLimits(
            rule(id),
            perConversation: 1,
            perAgent: 10,
            perWorkspace: 10,
            lineage: null,
          ),
      ]);
      expect(results.where((r) => r == null), hasLength(1));
      expect(await repo.countActive('w-1'), 1);
    });

    test("a lineage counts its root's and its rules' runs and cost, in any "
        'status, and refuses a rule past its caps', () async {
      WakeRule ended(String id) => rule(
        id,
        status: WakeRuleStatus.ended,
        endReason: WakeRuleEndReason.fired,
      );
      await insert(ended('root').copyWith(runCount: 1, costMicros: 300));
      await insert(
        ended('c-1').copyWith(rootRuleId: 'root', runCount: 1, costMicros: 200),
      );
      await insert(
        rule('c-2').copyWith(rootRuleId: 'root', runCount: 2, costMicros: 100),
      );
      // Another lineage, and another workspace's rows, count nothing.
      await insert(rule('other').copyWith(runCount: 9, costMicros: 900));
      await insert(
        rule(
          'c-9',
          workspaceId: 'w-2',
        ).copyWith(rootRuleId: 'root', runCount: 9, costMicros: 900),
      );
      expect(await repo.lineageTotals('w-1', 'root'), (
        runs: 4,
        costMicros: 600,
      ));
      expect(await repo.lineageTotals('w-1', 'none'), (runs: 0, costMicros: 0));
      Future<WakeRuleLimit?> join(String id, int maxRuns, int cost) =>
          repo.insertWithinLimits(
            rule(id).copyWith(rootRuleId: 'root'),
            perConversation: 100,
            perAgent: 100,
            perWorkspace: 100,
            lineage: (
              rootRuleId: 'root',
              maxRuns: maxRuns,
              costCapMicros: cost,
            ),
          );
      expect(await join('c-3', 4, 10000), WakeRuleLimit.lineage);
      expect(await join('c-3', 50, 600), WakeRuleLimit.lineage);
      expect(await join('c-3', 5, 601), isNull);
      expect((await repo.getById('w-1', 'c-3'))!.rootRuleId, 'root');
    });
  });

  group('conditional changes', () {
    test('recordFire counts on an active rule only', () async {
      await insert(rule('a'));
      final next = t0.add(const Duration(hours: 1));
      expect(
        await repo.recordFire(
          'w-1',
          id: 'a',
          costMicrosDelta: 250,
          nextFireAt: next,
          firedAt: t0,
        ),
        isTrue,
      );
      final fired = (await repo.getById('w-1', 'a'))!;
      expect(fired.runCount, 1);
      expect(fired.costMicros, 250);
      expect(fired.lastFiredAt, t0);
      expect(fired.nextFireAt, next);
      // A person pauses it; a fire decided before is refused and the pause
      // stands.
      expect(
        await repo.transition(
          'w-1',
          id: 'a',
          from: {WakeRuleStatus.active},
          to: WakeRuleStatus.paused,
          endReason: null,
          now: t0,
        ),
        isTrue,
      );
      expect(
        await repo.recordFire(
          'w-1',
          id: 'a',
          costMicrosDelta: 1,
          nextFireAt: null,
          firedAt: t0,
        ),
        isFalse,
      );
      final paused = (await repo.getById('w-1', 'a'))!;
      expect(paused.status, WakeRuleStatus.paused);
      expect(paused.runCount, 1);
      expect(
        () => repo.recordFire(
          'w-1',
          id: 'a',
          costMicrosDelta: -1,
          nextFireAt: null,
          firedAt: t0,
        ),
        throwsArgumentError,
      );
    });

    test('concurrent fires all count', () async {
      await insert(rule('a'));
      await Future.wait([
        for (var i = 0; i < 5; i++)
          repo.recordFire(
            'w-1',
            id: 'a',
            costMicrosDelta: 10,
            nextFireAt: null,
            firedAt: t0,
          ),
      ]);
      final a = (await repo.getById('w-1', 'a'))!;
      expect(a.runCount, 5);
      expect(a.costMicros, 50);
    });

    test('recordSkip counts a skipped slot', () async {
      await insert(rule('a'));
      final next = t0.add(const Duration(hours: 2));
      expect(
        await repo.recordSkip('w-1', id: 'a', nextFireAt: next, now: t0),
        isTrue,
      );
      final a = (await repo.getById('w-1', 'a'))!;
      expect(a.skipCount, 1);
      expect(a.nextFireAt, next);
      expect(
        await repo.recordSkip('w-1', id: 'none', nextFireAt: null, now: t0),
        isFalse,
      );
    });

    test('addCost returns the new total in any status', () async {
      await insert(
        rule(
          'a',
          status: WakeRuleStatus.ended,
          endReason: WakeRuleEndReason.fired,
        ),
      );
      expect(await repo.addCost('w-1', id: 'a', micros: 40, now: t0), 40);
      final totals = await Future.wait([
        for (var i = 0; i < 3; i++)
          repo.addCost('w-1', id: 'a', micros: 10, now: t0),
      ]);
      expect(totals.toSet(), {50, 60, 70});
      expect(await repo.addCost('w-1', id: 'none', micros: 1, now: t0), isNull);
      expect(
        () => repo.addCost('w-1', id: 'a', micros: -1, now: t0),
        throwsArgumentError,
      );
    });

    test('setNext takes a chosen delay only on a self-paced rule', () async {
      await insert(rule('self', trigger: const SelfPaced()));
      await insert(rule('every'));
      final next = t0.add(const Duration(minutes: 10));
      expect(
        await repo.setNext(
          'w-1',
          id: 'self',
          nextFireAt: next,
          nextDelaySeconds: 600,
          now: t0,
        ),
        isTrue,
      );
      final self = (await repo.getById('w-1', 'self'))!;
      expect(self.nextFireAt, next);
      expect(self.nextDelaySeconds, 600);
      expect(
        await repo.setNext(
          'w-1',
          id: 'every',
          nextFireAt: next,
          nextDelaySeconds: 600,
          now: t0,
        ),
        isFalse,
      );
      expect(
        await repo.setNext(
          'w-1',
          id: 'every',
          nextFireAt: next,
          nextDelaySeconds: null,
          now: t0,
        ),
        isTrue,
      );
      expect(
        () => repo.setNext(
          'w-1',
          id: 'self',
          nextFireAt: next,
          nextDelaySeconds: 30,
          now: t0,
        ),
        throwsArgumentError,
      );
    });

    test('transition moves only from the given states, once', () async {
      await insert(rule('a'));
      Future<bool> end(Set<WakeRuleStatus> from) => repo.transition(
        'w-1',
        id: 'a',
        from: from,
        to: WakeRuleStatus.ended,
        endReason: WakeRuleEndReason.cancelled,
        now: t0,
      );
      expect(await end({WakeRuleStatus.paused}), isFalse);
      final racers = await Future.wait([
        end({WakeRuleStatus.active, WakeRuleStatus.paused}),
        end({WakeRuleStatus.active, WakeRuleStatus.paused}),
      ]);
      expect(racers.where((r) => r), hasLength(1));
      final a = (await repo.getById('w-1', 'a'))!;
      expect(a.status, WakeRuleStatus.ended);
      expect(a.endReason, WakeRuleEndReason.cancelled);
      expect(
        () => repo.transition(
          'w-1',
          id: 'a',
          from: {WakeRuleStatus.active},
          to: WakeRuleStatus.ended,
          endReason: null,
          now: t0,
        ),
        throwsArgumentError,
      );
      expect(
        () => repo.transition(
          'w-1',
          id: 'a',
          from: {WakeRuleStatus.active},
          to: WakeRuleStatus.paused,
          endReason: WakeRuleEndReason.cancelled,
          now: t0,
        ),
        throwsArgumentError,
      );
    });

    test('setLimits replaces the limits until the rule ends', () async {
      await insert(rule('a'));
      final until = t0.add(const Duration(days: 2));
      Future<bool> limits({DateTime? expiresAt, int? maxRuns}) =>
          repo.setLimits(
            'w-1',
            id: 'a',
            expiresAt: expiresAt ?? until,
            maxRuns: maxRuns,
            costCapMicros: 77,
            now: t0,
          );
      expect(await limits(maxRuns: 3), isTrue);
      final a = (await repo.getById('w-1', 'a'))!;
      expect(a.expiresAt, until);
      expect(a.maxRuns, 3);
      expect(a.costCapMicros, 77);
      expect(
        await limits(expiresAt: t0.subtract(const Duration(days: 1))),
        isFalse,
      );
      expect(() => limits(maxRuns: 0), throwsArgumentError);
      await repo.transition(
        'w-1',
        id: 'a',
        from: {WakeRuleStatus.active},
        to: WakeRuleStatus.ended,
        endReason: WakeRuleEndReason.expired,
        now: t0,
      );
      expect(await limits(), isFalse);
    });
  });

  group('reads', () {
    test('conversation and agent reads narrow by status', () async {
      await insert(rule('a', createdAt: t0));
      await insert(
        rule(
          'b',
          status: WakeRuleStatus.ended,
          endReason: WakeRuleEndReason.cancelled,
          createdAt: t0.add(const Duration(minutes: 1)),
        ),
      );
      await insert(rule('c', conversationId: 'conv-2', agentId: 'agent-2'));
      expect(
        (await repo.listForConversation('w-1', 'conv-1')).map((r) => r.id),
        ['b', 'a'],
      );
      expect(
        (await repo.listForConversation(
          'w-1',
          'conv-1',
          statuses: {WakeRuleStatus.active},
        )).map((r) => r.id),
        ['a'],
      );
      expect((await repo.listForAgent('w-1', 'agent-2')).map((r) => r.id), [
        'c',
      ]);
    });

    test('listActiveByEvent returns active watches of the kind', () async {
      await insert(rule('w1', trigger: OnEvent(WakeEventKind.prMerged)));
      await insert(
        rule(
          'w2',
          trigger: OnEvent(WakeEventKind.prMerged),
          status: WakeRuleStatus.paused,
        ),
      );
      await insert(rule('w3', trigger: OnEvent(WakeEventKind.prReview)));
      expect(
        (await repo.listActiveByEvent(
          'w-1',
          WakeEventKind.prMerged,
        )).map((r) => r.id),
        ['w1'],
      );
    });

    test('goal, requester and count reads', () async {
      await insert(rule('g', goalId: 'goal-1', requestedByUserId: 'u-1'));
      await insert(rule('x', agentId: 'agent-2'));
      await insert(rule('y', conversationId: 'conv-2'));
      expect((await repo.listByGoal('w-1', 'goal-1')).map((r) => r.id), ['g']);
      expect((await repo.listByRequester('w-1', 'u-1')).map((r) => r.id), [
        'g',
      ]);
      expect(await repo.countActive('w-1'), 3);
      expect(await repo.countActive('w-1', agentId: 'agent-1'), 2);
      expect(
        await repo.countActive(
          'w-1',
          agentId: 'agent-1',
          conversationId: 'conv-1',
        ),
        1,
      );
    });

    test('watches hide ended rules from the conversation', () async {
      await insert(rule('a'));
      await insert(
        rule(
          'b',
          status: WakeRuleStatus.ended,
          endReason: WakeRuleEndReason.expired,
        ),
      );
      expect(
        (await repo.watchForConversation('w-1', 'conv-1').first).map(
          (r) => r.id,
        ),
        ['a'],
      );
      expect(await repo.watchForWorkspace('w-1').first, hasLength(2));
    });

    test('delete and the boot listing', () async {
      expect(await repo.workspacesWithActiveRules(), isEmpty);
      await insert(rule('a', workspaceId: 'w-2'));
      expect(await repo.workspacesWithActiveRules(), ['w-2']);
      expect(await repo.delete('w-2', 'a'), isTrue);
      expect(await repo.delete('w-2', 'a'), isFalse);
    });
  });

  group('storage', () {
    test('the table checks keep each trigger kind whole', () async {
      await insert(rule('a'));
      final db = dbs.of('w-1');
      for (final set in [
        'interval_seconds = 30',
        "trigger_kind = 'at'",
        "trigger_kind = 'cron'",
        "trigger_kind = 'event'",
        "trigger_kind = 'event', event_kind = 'ticket'",
        "trigger_kind = 'sometimes'",
        "status = 'ended'",
        "end_reason = 'fired'",
        "deliver = 'shout'",
        'cost_cap_micros = 0',
        'max_runs = 0',
        'run_count = -1',
        "note = '${'x' * 4001}'",
        'expires_at = created_at - 1',
      ]) {
        await expectLater(
          db.customStatement("UPDATE wake_rules SET $set WHERE id = 'a'"),
          throwsA(anything),
          reason: set,
        );
      }
    });

    test('a rule ends with its goal and its conversation', () async {
      await insert(rule('g', goalId: 'goal-1'));
      await insert(rule('c', conversationId: 'conv-2'));
      final db = dbs.of('w-1');
      await db.customStatement(
        "DELETE FROM agent_goal_runs WHERE id = 'goal-1'",
      );
      await db.customStatement("DELETE FROM conversations WHERE id = 'conv-2'");
      expect(await repo.getById('w-1', 'g'), isNull);
      expect(await repo.getById('w-1', 'c'), isNull);
    });

    test('an unreadable rule is left out, ended and never counted', () async {
      await insert(rule('good'));
      await insert(rule('bad'));
      // A delay out of range: a rule only the entity refuses.
      await dbs
          .of('w-1')
          .customStatement(
            "UPDATE wake_rules SET next_delay_seconds = 5 WHERE id = 'bad'",
          );
      expect(await repo.countActive('w-1'), 1);
      expect(warnings.single, contains('1 open ones settled as ended'));
      expect(await raw('bad'), containsPair('status', 'ended'));
      expect(await raw('bad'), containsPair('end_reason', 'invalid_row'));
      expect(
        (await repo.listForConversation('w-1', 'conv-1')).map((r) => r.id),
        ['good'],
      );
      expect(await repo.listActive('w-1'), hasLength(1));
    });
  });

  group('workspace isolation', () {
    test('a rule in one workspace is invisible from another', () async {
      await insert(rule('a', goalId: 'goal-1', requestedByUserId: 'u'));
      expect(await repo.getById('w-2', 'a'), isNull);
      expect(await repo.listForConversation('w-2', 'conv-1'), isEmpty);
      expect(await repo.listForAgent('w-2', 'agent-1'), isEmpty);
      expect(await repo.listByGoal('w-2', 'goal-1'), isEmpty);
      expect(await repo.listByRequester('w-2', 'u'), isEmpty);
      expect(await repo.countActive('w-2'), 0);
      expect(await repo.watchForWorkspace('w-2').first, isEmpty);
      expect(await repo.listActive('w-2'), isEmpty);
      expect(await repo.delete('w-2', 'a'), isFalse);
      expect(
        await repo.recordFire(
          'w-2',
          id: 'a',
          costMicrosDelta: 1,
          nextFireAt: null,
          firedAt: t0,
        ),
        isFalse,
      );
      expect(
        await repo.recordSkip('w-2', id: 'a', nextFireAt: null, now: t0),
        isFalse,
      );
      expect(await repo.addCost('w-2', id: 'a', micros: 1, now: t0), isNull);
      expect(
        await repo.setNext(
          'w-2',
          id: 'a',
          nextFireAt: null,
          nextDelaySeconds: null,
          now: t0,
        ),
        isFalse,
      );
      expect(
        await repo.transition(
          'w-2',
          id: 'a',
          from: {WakeRuleStatus.active},
          to: WakeRuleStatus.paused,
          endReason: null,
          now: t0,
        ),
        isFalse,
      );
      expect(
        await repo.setLimits(
          'w-2',
          id: 'a',
          expiresAt: t0.add(const Duration(days: 1)),
          maxRuns: null,
          costCapMicros: 1,
          now: t0,
        ),
        isFalse,
      );
      // The limits count the workspace's own rules only.
      expect(
        await repo.insertWithinLimits(
          rule('b', workspaceId: 'w-2'),
          perConversation: 1,
          perAgent: 1,
          perWorkspace: 1,
          lineage: null,
        ),
        isNull,
      );
      final a = (await repo.getById('w-1', 'a'))!;
      expect(a.runCount, 0);
      expect(a.status, WakeRuleStatus.active);
    });
  });
}
