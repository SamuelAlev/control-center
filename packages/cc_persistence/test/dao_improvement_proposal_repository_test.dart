import 'package:cc_domain/features/dispatch/domain/entities/improvement_proposal.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verification.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_values.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/seed_agents.dart';
import 'helpers/test_database.dart';

/// [DaoImprovementProposalRepository] against in-memory databases: round
/// trips, reads, expiry, `SET NULL` on the conversation, the stored-value
/// checks and workspace isolation.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoImprovementProposalRepository repo;
  late List<String> warnings;
  // Whole seconds: drift stores a `dateTime()` column as whole seconds.
  final t0 = DateTime.utc(2026, 5, 1, 12);

  setUp(() async {
    global = createTestGlobalDatabase();
    warnings = [];
    dbs = createTestWorkspaceDatabases(
      global: global,
      onWarn: (_, message) => warnings.add(message),
    );
    repo = DaoImprovementProposalRepository(dbs);
    for (final ws in ['w-1', 'w-2']) {
      await seedTestWorkspace(global, dbs, ws);
      final db = dbs.of(ws);
      await seedParents(db, agents: ['agent-1'], spaces: ['sp-1']);
      await seedConversation(db, 'conv-1', spaceId: 'sp-1');
      await seedConversation(db, 'conv-2', spaceId: 'sp-1');
    }
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  ImprovementProposal proposal(
    String id, {
    String workspaceId = 'w-1',
    String? conversationId = 'conv-1',
    String? goalId,
    ImprovementStatus status = ImprovementStatus.proposed,
    DateTime? createdAt,
  }) {
    final created = createdAt ?? t0;
    return ImprovementProposal(
      id: id,
      workspaceId: workspaceId,
      agentId: 'agent-1',
      conversationId: conversationId,
      goalId: goalId,
      kind: ImprovementKind.memoryFact,
      scope: ImprovementScope.agent,
      operation: ImprovementOperation.add,
      change: 'Run the migrations before the tests.',
      expected: 'No failed first test run.',
      status: status,
      createdAt: created,
      expiresAt: created.add(ImprovementProposal.lifetime),
    );
  }

  test('every field round-trips', () async {
    final full = ImprovementProposal(
      id: 'p-1',
      workspaceId: 'w-1',
      agentId: 'agent-1',
      spaceId: 'sp-1',
      conversationId: 'conv-1',
      reviewRunId: 'run-1',
      kind: ImprovementKind.skillEdit,
      scope: ImprovementScope.repository,
      scopeRefId: 'repo-1',
      operation: ImprovementOperation.replace,
      targetRef: 'skill-1',
      change: 'Say which file.',
      evidence: ImprovementEvidence(
        runIds: const ['run-1'],
        messageIds: const ['m-1'],
        checkResults: [
          GoalCheckResult(
            run: 'make test',
            where: GoalCheckLocation.worktree,
            exitCode: 1,
            outputTail: 'boom',
          ),
        ],
      ),
      expected: 'Fewer wrong edits.',
      candidateRevisionId: 'rev-1',
      campaignId: 'camp-1',
      campaignState: ImprovementCampaignState.running,
      createdAt: t0,
      expiresAt: t0.add(ImprovementProposal.lifetime),
    );
    await repo.insert(full);
    expect(await repo.getById('w-1', 'p-1'), full);
    await expectLater(repo.insert(full), throwsA(anything));
  });

  group('decide', () {
    test('two people accepting at once apply it once', () async {
      await repo.insert(proposal('a'));
      final decidedAt = t0.add(const Duration(hours: 1));
      Future<bool> accept(String who) => repo.decide(
        'w-1',
        id: 'a',
        from: ImprovementStatus.proposed,
        to: ImprovementStatus.accepted,
        decidedByUserId: who,
        beforeText: 'old',
        afterText: 'new',
        appliedRef: 'fact-1',
        now: decidedAt,
      );
      final results = await Future.wait([accept('user-1'), accept('user-2')]);
      expect(results.where((r) => r), hasLength(1));
      final a = (await repo.getById('w-1', 'a'))!;
      expect(a.status, ImprovementStatus.accepted);
      expect(a.decidedAt, decidedAt);
      expect(a.beforeText, 'old');
      expect(a.afterText, 'new');
      expect(a.appliedRef, 'fact-1');
      expect(a.decidedByUserId, results.first ? 'user-1' : 'user-2');
    });

    test('an expired proposal cannot be accepted', () async {
      await repo.insert(proposal('a'));
      expect(
        await repo.expireDue(
          'w-1',
          now: t0.add(const Duration(days: 60)),
          except: const {},
        ),
        1,
      );
      expect(
        await repo.decide(
          'w-1',
          id: 'a',
          from: ImprovementStatus.proposed,
          to: ImprovementStatus.accepted,
          decidedByUserId: 'user-1',
          now: t0,
        ),
        isFalse,
      );
      expect(
        (await repo.getById('w-1', 'a'))!.status,
        ImprovementStatus.expired,
      );
    });

    test('a rollback moves an accepted proposal once', () async {
      await repo.insert(proposal('a'));
      await repo.decide(
        'w-1',
        id: 'a',
        from: ImprovementStatus.proposed,
        to: ImprovementStatus.accepted,
        decidedByUserId: 'user-1',
        appliedRef: 'fact-1',
        now: t0,
      );
      Future<bool> rollBack() => repo.decide(
        'w-1',
        id: 'a',
        from: ImprovementStatus.accepted,
        to: ImprovementStatus.rolledBack,
        decidedByUserId: 'user-2',
        now: t0.add(const Duration(hours: 1)),
      );
      expect(await rollBack(), isTrue);
      expect(await rollBack(), isFalse);
      final a = (await repo.getById('w-1', 'a'))!;
      expect(a.status, ImprovementStatus.rolledBack);
      expect(a.appliedRef, 'fact-1', reason: 'null leaves a field as it is');
      expect(a.decidedByUserId, 'user-2');
    });

    test('refuses a move to proposed or to the same status', () async {
      await repo.insert(proposal('a'));
      for (final (from, to) in [
        (ImprovementStatus.accepted, ImprovementStatus.proposed),
        (ImprovementStatus.proposed, ImprovementStatus.proposed),
        (ImprovementStatus.accepted, ImprovementStatus.accepted),
      ]) {
        expect(
          () => repo.decide(
            'w-1',
            id: 'a',
            from: from,
            to: to,
            decidedByUserId: null,
            now: t0,
          ),
          throwsArgumentError,
        );
      }
    });
  });

  group('setCampaign', () {
    const any = {
      ImprovementCampaignState.none,
      ImprovementCampaignState.staging,
      ImprovementCampaignState.running,
      ImprovementCampaignState.passed,
      ImprovementCampaignState.failed,
    };

    test('sets the campaign of a proposed proposal only', () async {
      await repo.insert(proposal('a'));
      expect(
        await repo.setCampaign(
          'w-1',
          id: 'a',
          from: any,
          campaignId: 'camp-1',
          state: ImprovementCampaignState.running,
          candidateRevisionId: 'rev-1',
        ),
        isTrue,
      );
      expect(
        await repo.setCampaign(
          'w-1',
          id: 'a',
          from: any,
          campaignId: 'camp-1',
          state: ImprovementCampaignState.passed,
          candidateRevisionId: 'rev-1',
        ),
        isTrue,
      );
      final a = (await repo.getById('w-1', 'a'))!;
      expect(a.campaignState, ImprovementCampaignState.passed);
      expect(a.campaignId, 'camp-1');
      expect(a.candidateRevisionId, 'rev-1');
      await repo.decide(
        'w-1',
        id: 'a',
        from: ImprovementStatus.proposed,
        to: ImprovementStatus.rejected,
        decidedByUserId: 'user-1',
        now: t0,
      );
      expect(
        await repo.setCampaign(
          'w-1',
          id: 'a',
          from: any,
          campaignId: 'camp-1',
          state: ImprovementCampaignState.failed,
          candidateRevisionId: null,
        ),
        isFalse,
      );
      expect(
        (await repo.getById('w-1', 'a'))!.campaignState,
        ImprovementCampaignState.passed,
      );
    });

    test(
      'claims from the named states only, and null drops the candidate',
      () async {
        await repo.insert(proposal('a'));
        const startable = {
          ImprovementCampaignState.none,
          ImprovementCampaignState.failed,
        };
        Future<bool> claim() => repo.setCampaign(
          'w-1',
          id: 'a',
          from: startable,
          campaignId: null,
          state: ImprovementCampaignState.staging,
          candidateRevisionId: null,
        );
        final claims = await Future.wait([claim(), claim()]);
        expect(claims.where((c) => c), hasLength(1));
        expect(
          (await repo.getById('w-1', 'a'))!.campaignState,
          ImprovementCampaignState.staging,
        );
        await repo.setCampaign(
          'w-1',
          id: 'a',
          from: const {ImprovementCampaignState.staging},
          campaignId: 'camp-1',
          state: ImprovementCampaignState.running,
          candidateRevisionId: 'rev-1',
        );
        await repo.setCampaign(
          'w-1',
          id: 'a',
          from: const {ImprovementCampaignState.running},
          campaignId: 'camp-1',
          state: ImprovementCampaignState.failed,
          candidateRevisionId: null,
        );
        final a = (await repo.getById('w-1', 'a'))!;
        expect(a.campaignState, ImprovementCampaignState.failed);
        expect(a.candidateRevisionId, isNull);
        expect(a.campaignId, 'camp-1');
        // A start from failed forgets the previous campaign.
        expect(await claim(), isTrue);
        final again = (await repo.getById('w-1', 'a'))!;
        expect(again.campaignState, ImprovementCampaignState.staging);
        expect(again.campaignId, isNull);
      },
    );
  });

  test('releaseStaging lets go of a start whatever the status, and only of '
      'a start', () async {
    await repo.insert(proposal('a'));
    expect(
      await repo.releaseStaging(
        'w-1',
        id: 'a',
        to: ImprovementCampaignState.none,
      ),
      isFalse,
      reason: 'not staging',
    );
    await repo.setCampaign(
      'w-1',
      id: 'a',
      from: const {ImprovementCampaignState.none},
      campaignId: null,
      state: ImprovementCampaignState.staging,
      candidateRevisionId: 'rev-1',
    );
    await repo.decide(
      'w-1',
      id: 'a',
      from: ImprovementStatus.proposed,
      to: ImprovementStatus.rejected,
      decidedByUserId: 'user-1',
      now: t0,
    );
    expect(
      await repo.releaseStaging(
        'w-1',
        id: 'a',
        to: ImprovementCampaignState.failed,
      ),
      isTrue,
    );
    final a = (await repo.getById('w-1', 'a'))!;
    expect(a.status, ImprovementStatus.rejected);
    expect(a.campaignState, ImprovementCampaignState.failed);
    expect(a.candidateRevisionId, isNull);
    expect(
      await repo.releaseStaging(
        'w-2',
        id: 'a',
        to: ImprovementCampaignState.none,
      ),
      isFalse,
      reason: 'another workspace',
    );
  });

  test('markApplied marks an accepted proposal once', () async {
    await repo.insert(proposal('a'));
    Future<bool> mark() =>
        repo.markApplied('w-1', id: 'a', appliedRef: 'skill:lint@rev-1');
    expect(await mark(), isFalse, reason: 'still proposed');
    await repo.decide(
      'w-1',
      id: 'a',
      from: ImprovementStatus.proposed,
      to: ImprovementStatus.accepted,
      decidedByUserId: 'user-1',
      now: t0,
    );
    expect(await mark(), isTrue);
    expect(await mark(), isFalse);
    expect(await repo.markApplied('w-2', id: 'a', appliedRef: 'x'), isFalse);
    expect((await repo.getById('w-1', 'a'))!.appliedRef, 'skill:lint@rev-1');
  });

  test('expireDue leaves the rows it is told to keep', () async {
    await repo.insert(proposal('a'));
    await repo.insert(proposal('b'));
    expect(
      await repo.expireDue(
        'w-1',
        now: t0.add(ImprovementProposal.lifetime),
        except: const {'b'},
      ),
      1,
    );
    expect(
      (await repo.getById('w-1', 'b'))!.status,
      ImprovementStatus.proposed,
    );
  });

  test('reads narrow and order newest first', () async {
    await repo.insert(proposal('a', createdAt: t0));
    await repo.insert(
      proposal(
        'b',
        status: ImprovementStatus.rejected,
        createdAt: t0.add(const Duration(minutes: 1)),
      ),
    );
    await repo.insert(
      proposal(
        'c',
        conversationId: 'conv-2',
        createdAt: t0.add(const Duration(minutes: 2)),
      ),
    );
    expect((await repo.listForWorkspace('w-1')).map((p) => p.id), [
      'c',
      'b',
      'a',
    ]);
    expect(
      (await repo.listForWorkspace(
        'w-1',
        statuses: {ImprovementStatus.proposed},
      )).map((p) => p.id),
      ['c', 'a'],
    );
    expect((await repo.latestForConversation('w-1', 'conv-1'))?.id, 'b');
    expect(await repo.watchForWorkspace('w-1').first, hasLength(3));
  });

  test('times come back in UTC, to the second', () async {
    final created = DateTime.utc(2026, 5, 1, 12, 0, 7, 345, 678);
    final decided = DateTime.utc(2026, 5, 2, 9, 30, 1, 999);
    await repo.insert(
      proposal(
        'p-utc',
        status: ImprovementStatus.accepted,
        createdAt: created,
      ).copyWith(decidedByUserId: 'u-1', decidedAt: decided),
    );
    final read = (await repo.getById('w-1', 'p-utc'))!;
    for (final (at, sent) in [
      (read.createdAt, created),
      (read.expiresAt, created.add(ImprovementProposal.lifetime)),
      (read.decidedAt!, decided),
    ]) {
      expect(at.isUtc, isTrue);
      expect(
        at.isAtSameMomentAs(
          DateTime.utc(
            sent.year,
            sent.month,
            sent.day,
            sent.hour,
            sent.minute,
            sent.second,
          ),
        ),
        isTrue,
        reason: '$at against $sent',
      );
    }
    // A local time given to the entity is the same instant, in UTC.
    final local = DateTime(2026, 5, 1, 12);
    final fromLocal = proposal('p-local', createdAt: local);
    expect(fromLocal.createdAt.isUtc, isTrue);
    expect(fromLocal.createdAt.isAtSameMomentAs(local), isTrue);
  });

  test('listByGoal and expireDue', () async {
    await dbs
        .of('w-1')
        .customStatement(
          'INSERT INTO agent_goal_runs (id, workspace_id, space_id, '
          'conversation_id, agent_id, user_text, cost_cap_micros) '
          "VALUES ('goal-1', 'w-1', 'sp-1', 'conv-1', 'agent-1', 'x', 10)",
        );
    await repo.insert(proposal('g', goalId: 'goal-1'));
    await repo.insert(proposal('done', status: ImprovementStatus.accepted));
    expect((await repo.listByGoal('w-1', 'goal-1')).map((p) => p.id), ['g']);
    expect(
      await repo.expireDue(
        'w-1',
        now: t0.add(ImprovementProposal.lifetime),
        except: const {},
      ),
      1,
    );
    expect((await repo.getById('w-1', 'g'))!.status, ImprovementStatus.expired);
    expect(
      (await repo.getById('w-1', 'done'))!.status,
      ImprovementStatus.accepted,
    );
  });

  test('a proposal outlives its conversation', () async {
    await repo.insert(proposal('a'));
    await dbs
        .of('w-1')
        .customStatement("DELETE FROM conversations WHERE id = 'conv-1'");
    final a = await repo.getById('w-1', 'a');
    expect(a, isNotNull);
    expect(a!.conversationId, isNull);
  });

  test('the stored-value checks refuse unknown values', () async {
    await repo.insert(proposal('a'));
    final db = dbs.of('w-1');
    for (final set in [
      "status = 'maybe'",
      "kind = 'vibe'",
      "scope = 'galaxy'",
      "operation = 'merge'",
      "campaign_state = 'paused'",
      "evidence = '[]'",
      "change = ''",
      "expected = '${'x' * 601}'",
      'expires_at = created_at - 1',
    ]) {
      await expectLater(
        db.customStatement(
          "UPDATE improvement_proposals SET $set WHERE id = 'a'",
        ),
        throwsA(anything),
        reason: set,
      );
    }
  });

  test('malformed evidence reads as empty', () async {
    await repo.insert(proposal('a'));
    await dbs
        .of('w-1')
        .customStatement(
          'UPDATE improvement_proposals SET evidence = \'{"runIds": 4}\' '
          "WHERE id = 'a'",
        );
    expect((await repo.getById('w-1', 'a'))!.evidence.runIds, isEmpty);
  });

  test('a refused proposed row expires so nobody can accept it', () async {
    await repo.insert(proposal('good'));
    await repo.insert(
      proposal('bad', createdAt: t0.add(const Duration(minutes: 1))),
    );
    // A blank change: a rule only the entity checks.
    await dbs
        .of('w-1')
        .customStatement(
          "UPDATE improvement_proposals SET change = '  ' WHERE id = 'bad'",
        );
    expect(
      (await repo.listForWorkspace(
        'w-1',
        statuses: {ImprovementStatus.proposed},
      )).map((p) => p.id),
      ['good'],
    );
    expect(warnings.single, contains('1 open ones settled as expired'));
    final row =
        (await dbs
                .of('w-1')
                .customSelect(
                  "SELECT status FROM improvement_proposals WHERE id = 'bad'",
                )
                .getSingle())
            .data;
    expect(row['status'], 'expired');
    expect(
      await repo.decide(
        'w-1',
        id: 'bad',
        from: ImprovementStatus.proposed,
        to: ImprovementStatus.accepted,
        decidedByUserId: 'user-1',
        now: t0,
      ),
      isFalse,
    );
  });

  test('a proposal in one workspace is invisible from another', () async {
    await repo.insert(proposal('a'));
    expect(await repo.getById('w-2', 'a'), isNull);
    expect(await repo.listForWorkspace('w-2'), isEmpty);
    expect(await repo.latestForConversation('w-2', 'conv-1'), isNull);
    expect(await repo.watchForWorkspace('w-2').first, isEmpty);
    expect(
      await repo.expireDue(
        'w-2',
        now: t0.add(const Duration(days: 60)),
        except: const {},
      ),
      0,
    );
    expect(
      await repo.decide(
        'w-2',
        id: 'a',
        from: ImprovementStatus.proposed,
        to: ImprovementStatus.accepted,
        decidedByUserId: 'u',
        now: t0,
      ),
      isFalse,
    );
    expect(
      await repo.setCampaign(
        'w-2',
        id: 'a',
        from: const {ImprovementCampaignState.none},
        campaignId: null,
        state: ImprovementCampaignState.running,
        candidateRevisionId: null,
      ),
      isFalse,
    );
    final a = (await repo.getById('w-1', 'a'))!;
    expect(a.status, ImprovementStatus.proposed);
    expect(a.campaignState, ImprovementCampaignState.none);
  });
}
