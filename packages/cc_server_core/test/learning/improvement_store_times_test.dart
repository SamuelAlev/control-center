import 'package:cc_domain/cc_domain.dart' show ImprovementRefusedException;
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/dispatch/domain/entities/improvement_proposal.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_values.dart';
import 'package:cc_domain/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_infra/cc_infra.dart'
    show ImprovementReviewService, WakeQueueService, improvementReviewCooldown;
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/learning/improvement_adoption_service.dart';
import 'package:test/test.dart';

import '../helpers/test_database.dart';

/// The review cooldown and the expiry sweep against the real proposal store:
/// drift keeps whole seconds and reads a time back as local time, and neither
/// may turn that into an early or a missed decision.
const _ws = 'ws-1';
const _other = 'ws-2';

/// Sub-second on purpose: the store keeps whole seconds.
final _created = DateTime.utc(2026, 11, 19, 14, 0, 0, 250, 125);

class _Queue implements WakeQueueService {
  final List<Wake> enqueued = [];

  @override
  Future<bool> enqueue(Wake wake) async {
    enqueued.add(wake);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _Agents implements AgentRepository {
  @override
  Future<Agent?> getById(String workspaceId, String id) async =>
      workspaceId == _ws && id == 'agent-1'
      ? Agent(
          id: 'agent-1',
          name: 'builder',
          title: 'Builder',
          agentMdPath: 'agents/builder.md',
          workspaceId: _ws,
          skills: AgentSkills(const []),
          createdAt: _created,
        )
      : null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

// Stand-ins for the dependencies neither path reaches.

class _NoAgentRunLogRepository implements AgentRunLogRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _NoMessagingRepository implements MessagingRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _NoConversationRepository implements ConversationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _NoMemoryFactRepository implements MemoryFactRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _NoMemoryPolicyRepository implements MemoryPolicyRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _NoAgentWorkingMemoryRepository implements AgentWorkingMemoryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _NoRepoRepository implements RepoRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _NoWorkspaceFilesystemPort implements WorkspaceFilesystemPort {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

ImprovementProposal _proposal(
  String id, {
  String workspaceId = _ws,
  DateTime? createdAt,
}) {
  final created = createdAt ?? _created;
  return ImprovementProposal(
    id: id,
    workspaceId: workspaceId,
    agentId: 'agent-1',
    conversationId: 'conv-1',
    kind: ImprovementKind.memoryFact,
    scope: ImprovementScope.agent,
    operation: ImprovementOperation.add,
    change: 'Run the migrations before the tests.',
    expected: 'No failed first test run.',
    createdAt: created,
    expiresAt: created.add(ImprovementProposal.lifetime),
  );
}

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoImprovementProposalRepository proposals;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    for (final ws in [_ws, _other]) {
      await seedTestWorkspace(global, dbs, ws);
      // The rows reference an agent and a conversation this test does not
      // need.
      await dbs.of(ws).customStatement('PRAGMA foreign_keys = OFF');
    }
    proposals = DaoImprovementProposalRepository(dbs);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  test('the review cooldown reads the stored proposal time', () async {
    await proposals.insert(_proposal('p-1'));
    final queue = _Queue();
    late DateTime now;
    // A fresh service (as after a restart) has only the stored row.
    final review = ImprovementReviewService(
      wakeQueue: () => queue,
      wakes: DaoWakeRepository(dbs),
      goals: DaoAgentGoalRunRepository(dbs),
      agents: _Agents(),
      runLogs: _NoAgentRunLogRepository(),
      proposals: proposals,
      messages: _NoMessagingRepository(),
      conversations: _NoConversationRepository(),
      facts: _NoMemoryFactRepository(),
      policies: _NoMemoryPolicyRepository(),
      resolveRepository: (ws, spaceId, reference) async => null,
      skillExists: (ws, slug) async => false,
      eventBus: DomainEventBus(),
      now: () => now,
    );
    Future<void> refine() => review.refine(
      workspaceId: _ws,
      spaceId: 'space-1',
      conversationId: 'conv-1',
      agentId: 'agent-1',
      requestedByUserId: 'user-1',
    );

    // A clock in local time and one a second short of the cooldown are
    // both inside it.
    for (final at in [
      _created.add(const Duration(minutes: 10)).toLocal(),
      _created.add(improvementReviewCooldown - const Duration(seconds: 1)),
    ]) {
      now = at;
      await expectLater(
        refine(),
        throwsA(
          isA<ImprovementRefusedException>().having(
            (e) => e.code,
            'kind',
            ImprovementRefusedException.cooldownKind,
          ),
        ),
        reason: '$at',
      );
    }
    expect(queue.enqueued, isEmpty);

    now = _created.add(improvementReviewCooldown).toLocal();
    await refine();
    expect(queue.enqueued, hasLength(1));
  });

  test('the expiry sweep expires what is due, in its workspace', () async {
    await proposals.insert(_proposal('due'));
    await proposals.insert(
      _proposal('fresh', createdAt: _created.add(const Duration(days: 1))),
    );
    await proposals.insert(_proposal('elsewhere', workspaceId: _other));
    late DateTime now;
    final adoption = ImprovementAdoptionService(
      proposals: proposals,
      apply: DaoImprovementApply(dbs, facts: DaoMemoryFactRepository(dbs)),
      facts: _NoMemoryFactRepository(),
      policies: _NoMemoryPolicyRepository(),
      notes: _NoAgentWorkingMemoryRepository(),
      repos: _NoRepoRepository(),
      filesystem: _NoWorkspaceFilesystemPort(),
      scanner: null,
      evaluation: () => null,
      now: () => now,
      recoveryWait: kImprovementRecoveryWait,
    )..markRecovered();

    // A second before the stored expiry, in local time: nothing is due.
    now = _created
        .add(ImprovementProposal.lifetime)
        .subtract(const Duration(seconds: 1))
        .toLocal();
    expect(await adoption.sweep(_ws), 0);

    now = _created.add(ImprovementProposal.lifetime);
    expect(await adoption.sweep(_ws), 1);
    final read = (await proposals.getById(_ws, 'due'))!;
    expect(read.status, ImprovementStatus.expired);
    expect(read.expiresAt.isUtc, isTrue);
    expect(
      (await proposals.getById(_ws, 'fresh'))!.status,
      ImprovementStatus.proposed,
    );
    expect(
      (await proposals.getById(_other, 'elsewhere'))!.status,
      ImprovementStatus.proposed,
    );
  });
}
