import 'package:cc_domain/core/domain/services/json_schema_validator.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_status.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_domain/features/orchestration/domain/services/orchestration_proposal_validator.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/orchestration_revision.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/plan_document.dart';
import 'package:cc_domain/features/plan_studio/domain/repositories/plan_studio_repositories.dart';
import 'package:cc_domain/features/plan_studio/domain/services/plan_document_compiler.dart';
import 'package:cc_domain/features/plan_studio/domain/value_objects/plan_graph.dart';
import 'package:cc_server_core/src/plan_studio/plan_document_approval_service.dart';
import 'package:test/test.dart';

const _ws = 'ws-1';
const _conversation = 'conv-plan';
const _space = 'space-room';

class _Plans implements PlanDocumentRepository {
  final docs = <String, PlanDocument>{};

  @override
  Future<PlanDocument?> getById(String workspaceId, String id) async =>
      docs[id];

  @override
  Future<void> upsert(PlanDocument doc) async => docs[doc.id] = doc;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Conversations implements ConversationRepository {
  final rows = <String, Conversation>{};

  @override
  Future<Conversation?> getById({
    required String workspaceId,
    required String conversationId,
  }) async => rows[conversationId];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Orchestrations implements OrchestrationRepository {
  final rows = <String, Orchestration>{};

  @override
  Future<Orchestration?> getById(String workspaceId, String id) async =>
      rows[id];

  @override
  Future<void> insert(Orchestration orchestration) async =>
      rows[orchestration.id] = orchestration;

  @override
  Future<void> update(Orchestration orchestration) async =>
      rows[orchestration.id] = orchestration;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Revisions implements OrchestrationRevisionRepository {
  @override
  Future<void> record(OrchestrationRevision revision) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PlanDocument _plan() => PlanDocument(
  id: 'p1',
  workspaceId: _ws,
  conversationId: _conversation,
  agentId: 'agent-1',
  goal: 'Ship the invoice importer',
  graph: const PlanGraph(
    nodes: [PlanNode(key: 'a', title: 'Parse', type: PlanNodeType.work)],
  ),
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  late _Plans plans;
  late _Conversations conversations;
  late _Orchestrations orchestrations;
  late List<Orchestration> approvedRows;
  late List<String> hookSpaces;
  late PlanDocumentApprovalService service;

  setUp(() {
    plans = _Plans();
    conversations = _Conversations();
    orchestrations = _Orchestrations();
    approvedRows = [];
    hookSpaces = [];
    plans.docs['p1'] = _plan();
    conversations.rows[_conversation] = Conversation(
      id: _conversation,
      workspaceId: _ws,
      spaceId: _space,
      title: 'Plan',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    service = PlanDocumentApprovalService(
      plans: plans,
      conversations: conversations,
      orchestrations: orchestrations,
      revisions: _Revisions(),
      validator: const OrchestrationProposalValidator(
        schemaValidator: JsonSchemaValidator(),
      ),
      approveOrchestration:
          ({
            required workspaceId,
            required orchestrationId,
            approvedNodeKeys,
          }) async {
            approvedRows.add(orchestrations.rows[orchestrationId]!);
          },
      onApproved: (plan, spaceId, orchestrationId) async =>
          hookSpaces.add(spaceId),
    );
  });

  final orchestrationId = PlanDocumentCompiler.orchestrationIdFor('p1');

  test('the plan runs in the space its conversation belongs to', () async {
    // Storing the conversation id as the room matched no space, so every step
    // of the run failed at once with "no conversation to work in".
    await service.approve(workspaceId: _ws, planId: 'p1');

    expect(orchestrations.rows[orchestrationId]?.spaceId, _space);
    expect(approvedRows.single.spaceId, _space);
    expect(hookSpaces, [_space], reason: 'mode and notice target the room');
  });

  test('a plan whose conversation is gone is refused', () async {
    conversations.rows.clear();

    await expectLater(
      service.approve(workspaceId: _ws, planId: 'p1'),
      throwsStateError,
    );
    expect(orchestrations.rows, isEmpty);
  });

  test('approving a failed plan again rebuilds its run in the room', () async {
    orchestrations.rows[orchestrationId] = Orchestration(
      id: orchestrationId,
      workspaceId: _ws,
      proposal: PlanDocumentCompiler.toProposal(_plan(), agentId: 'agent-1'),
      spaceId: _conversation,
      status: OrchestrationStatus.failed,
      approvedRevision: 1,
      pipelineTemplateId: 'orchestration_$orchestrationId',
      pipelineRunId: 'run-old',
      projectId: 'proj-1',
      errorMessage: 'no conversation to work in',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      completedAt: DateTime.utc(2026),
    );

    await service.approve(workspaceId: _ws, planId: 'p1');

    final row = approvedRows.single;
    expect(row.status, OrchestrationStatus.proposed);
    expect(row.spaceId, _space);
    expect(row.pipelineTemplateId, isNull, reason: 'regenerated, not reused');
    expect(row.pipelineRunId, isNull);
    expect(row.errorMessage, isNull);
    expect(row.completedAt, isNull);
    expect(row.projectId, 'proj-1', reason: 'materialized pieces are kept');
  });
}
