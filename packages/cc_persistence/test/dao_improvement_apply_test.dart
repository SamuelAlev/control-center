import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/agent_working_memory.dart';
import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/features/dispatch/domain/entities/improvement_proposal.dart';
import 'package:cc_domain/features/dispatch/domain/ports/improvement_apply_port.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_values.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/seed_agents.dart';
import 'helpers/test_database.dart';

/// Embeds every text to the same unit vector and counts the texts.
class _FakeEmbedder extends EmbeddingPort {
  final List<String> texts = [];

  @override
  bool get isReady => true;

  @override
  int get dimension => 384;

  @override
  Future<Float32List> embed(String text) async {
    texts.add(text);
    return Float32List(384)..[0] = 1;
  }
}

/// [DaoImprovementApply]: the claim and the write of a text proposal are one
/// transaction, and the write lands only on the row the plan read.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoImprovementProposalRepository proposals;
  late DaoAgentWorkingMemoryRepository notes;
  late DaoMemoryPolicyRepository policies;
  late DaoImprovementApply apply;
  late _FakeEmbedder embedder;
  late DaoMemoryFactRepository facts;
  final t0 = DateTime.utc(2026, 5, 1, 12);

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    for (final ws in ['w-1', 'w-2']) {
      await seedTestWorkspace(global, dbs, ws);
      final db = dbs.of(ws);
      await seedParents(db, agents: ['agent-1'], spaces: ['sp-1']);
      await seedConversation(db, 'conv-1', spaceId: 'sp-1');
    }
    proposals = DaoImprovementProposalRepository(dbs);
    notes = DaoAgentWorkingMemoryRepository(dbs);
    policies = DaoMemoryPolicyRepository(dbs);
    embedder = _FakeEmbedder();
    facts = DaoMemoryFactRepository(dbs, embeddingService: embedder);
    apply = DaoImprovementApply(dbs, facts: facts);
    await proposals.insert(
      ImprovementProposal(
        id: 'p-1',
        workspaceId: 'w-1',
        agentId: 'agent-1',
        conversationId: 'conv-1',
        kind: ImprovementKind.agentNote,
        scope: ImprovementScope.agent,
        operation: ImprovementOperation.add,
        change: 'Rebase daily.',
        expected: 'Fewer conflicts.',
        createdAt: t0,
        expiresAt: t0.add(ImprovementProposal.lifetime),
      ),
    );
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  AgentWorkingMemory note(String content, {String agentId = 'agent-1'}) =>
      AgentWorkingMemory(
        id: 'n-$agentId',
        workspaceId: 'w-1',
        agentId: agentId,
        content: content,
        updatedAt: t0,
      );

  Future<ImprovementApplyOutcome> accept(ImprovementTextWrite write) =>
      apply.decideAndWrite(
        'w-1',
        id: 'p-1',
        from: ImprovementStatus.proposed,
        to: ImprovementStatus.accepted,
        decidedByUserId: 'user-1',
        beforeText: 'Prefer small commits.',
        afterText: 'Prefer small commits. Rebase daily.',
        appliedRef: 'agent_note:agent-1',
        now: t0.add(const Duration(minutes: 5)),
        write: write,
      );

  Future<ImprovementStatus> status() async =>
      (await proposals.getById('w-1', 'p-1'))!.status;

  test('claims and writes together', () async {
    await notes.upsert(note('Prefer small commits.'));
    final read = await notes.getByAgent('w-1', 'agent-1');
    expect(
      await accept(
        ImprovementNoteWrite(
          expected: read,
          note: read!.copyWith(
            content: 'Prefer small commits. Rebase daily.',
            updatedAt: t0.add(const Duration(minutes: 5)),
          ),
        ),
      ),
      ImprovementApplyOutcome.applied,
    );
    expect(await status(), ImprovementStatus.accepted);
    expect(
      (await notes.getByAgent('w-1', 'agent-1'))!.content,
      'Prefer small commits. Rebase daily.',
    );
  });

  test("the agent's own edit after the read is kept and the proposal does "
      'not move', () async {
    await notes.upsert(note('Prefer small commits.'));
    final read = await notes.getByAgent('w-1', 'agent-1');
    await notes.upsert(
      read!.copyWith(
        content: 'Prefer small commits. Squash before merge.',
        updatedAt: t0.add(const Duration(minutes: 1)),
      ),
    );
    expect(
      await accept(
        ImprovementNoteWrite(
          expected: read,
          note: read.copyWith(content: 'Prefer small commits. Rebase daily.'),
        ),
      ),
      ImprovementApplyOutcome.changedSince,
    );
    expect(await status(), ImprovementStatus.proposed);
    expect(
      (await notes.getByAgent('w-1', 'agent-1'))!.content,
      'Prefer small commits. Squash before merge.',
    );
  });

  test('a write that fails leaves the claim undone', () async {
    // The notes of an agent that does not exist: the foreign key refuses
    // the write after the claim was made, inside the transaction.
    await expectLater(
      accept(
        ImprovementNoteWrite(
          expected: null,
          note: note('Rebase daily.', agentId: 'agent-gone'),
        ),
      ),
      throwsA(anything),
    );
    expect(await status(), ImprovementStatus.proposed);
    expect(await notes.getByAgent('w-1', 'agent-gone'), isNull);
  });

  test('a lost claim writes nothing', () async {
    await proposals.decide(
      'w-1',
      id: 'p-1',
      from: ImprovementStatus.proposed,
      to: ImprovementStatus.rejected,
      decidedByUserId: 'user-2',
      now: t0,
    );
    final policy = MemoryPolicy(
      id: 'refine-p-1',
      workspaceId: 'w-1',
      domain: 'build',
      rule: 'Rebase daily.',
      sourceFactIds: const ['refine:p-1'],
      createdAt: t0,
      updatedAt: t0,
    );
    expect(
      await accept(ImprovementPolicyWrite(expected: null, policy: policy)),
      ImprovementApplyOutcome.alreadyDecided,
    );
    expect(await policies.getById('w-1', 'refine-p-1'), isNull);
    expect(await status(), ImprovementStatus.rejected);
  });

  test('a proposal of another workspace is not claimed', () async {
    final outcome = await apply.decideAndWrite(
      'w-2',
      id: 'p-1',
      from: ImprovementStatus.proposed,
      to: ImprovementStatus.accepted,
      decidedByUserId: 'user-1',
      beforeText: null,
      afterText: 'x',
      appliedRef: null,
      now: t0,
      write: ImprovementNoteWrite(expected: null, note: note('x')),
    );
    expect(outcome, ImprovementApplyOutcome.alreadyDecided);
    expect(await status(), ImprovementStatus.proposed);
  });

  test('an accepted fact is embedded once the transaction commits', () async {
    await proposals.insert(
      ImprovementProposal(
        id: 'p-fact',
        workspaceId: 'w-1',
        agentId: 'agent-1',
        conversationId: 'conv-1',
        kind: ImprovementKind.memoryFact,
        scope: ImprovementScope.agent,
        operation: ImprovementOperation.add,
        change: 'Run make gen first.',
        expected: 'Green builds.',
        createdAt: t0,
        expiresAt: t0.add(ImprovementProposal.lifetime),
      ),
    );
    final fact = MemoryFact(
      id: 'refine-p-fact',
      workspaceId: 'w-1',
      domain: 'lessons',
      topic: 'builds',
      content: 'Run make gen first.',
      createdAt: t0,
      updatedAt: t0,
    );
    expect(
      await apply.decideAndWrite(
        'w-1',
        id: 'p-fact',
        from: ImprovementStatus.proposed,
        to: ImprovementStatus.accepted,
        decidedByUserId: 'user-1',
        beforeText: null,
        afterText: fact.content,
        appliedRef: 'memory_fact:${fact.id}',
        now: t0,
        write: ImprovementFactWrite(expected: null, fact: fact),
      ),
      ImprovementApplyOutcome.applied,
    );
    expect(embedder.texts, ['builds Run make gen first.']);
    final stored = await dbs
        .of('w-1')
        .customSelect('SELECT fact_id FROM memory_fact_embeddings')
        .get();
    expect([for (final r in stored) r.read<String>('fact_id')], [fact.id]);
  });
}
