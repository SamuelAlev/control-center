import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/orchestration/domain/services/orchestration_materializer.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/plan_document.dart';
import 'package:cc_domain/features/plan_studio/domain/services/plan_document_compiler.dart';
import 'package:cc_domain/features/plan_studio/domain/value_objects/plan_graph.dart';
import 'package:test/test.dart';

PlanDocument _plan() => PlanDocument(
  id: 'p1',
  workspaceId: 'ws-1',
  conversationId: 'chan-plan',
  agentId: 'agent-1',
  goal: 'Ship the invoice importer',
  graph: const PlanGraph(
    nodes: [
      PlanNode(key: 'a', title: 'Parse', type: PlanNodeType.work),
      PlanNode(
        key: 'b',
        title: 'Import',
        type: PlanNodeType.work,
        dependsOn: ['a'],
      ),
    ],
  ),
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

/// The pipeline an approved plan actually executes as.
///
/// `roleAgents` mirrors what `ApproveOrchestrationUseCase` resolves: the
/// authoring agent for the plan's single role.
PipelineDefinition _generatedPipeline() {
  final doc = _plan();
  final proposal = PlanDocumentCompiler.toProposal(doc, agentId: doc.agentId);
  final orchestration = Orchestration(
    id: PlanDocumentCompiler.orchestrationIdFor(doc.id),
    workspaceId: doc.workspaceId,
    proposal: proposal,
    channelId: doc.conversationId,
    orchestratorAgentId: doc.agentId,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
  return const OrchestrationMaterializer().buildDefinition(
    orchestration,
    roleAgents: {PlanDocumentCompiler.roleKey: doc.agentId},
    channelId: doc.conversationId,
    parentTicketId: '',
    projectId: 'proj-1',
  );
}

Map<String, Map<String, dynamic>> _generatedExtras() => {
  for (final step in _generatedPipeline().steps) step.id: step.config.extras,
};

void main() {
  test('the compiled orchestration id is derivable from the plan id', () {
    // The client follows (and cancels) an approved plan's execution through this
    // derivation, so it is a contract, not an implementation detail.
    expect(PlanDocumentCompiler.orchestrationIdFor('p1'), 'plan_p1');
  });

  group('an approved plan executes visibly and with write access', () {
    test('every agent step runs in the plan\'s own conversation', () {
      final extras = _generatedExtras();

      for (final id in ['sub_a', 'sub_b', 'synthesis']) {
        expect(
          extras[id]?['channelId'],
          'chan-plan',
          reason: '$id must run where the operator is watching',
        );
      }
    });

    test('every step is dispatched to the authoring agent', () {
      // The plan runs as the agent that wrote it; bringing in help is that
      // agent's call mid-run (delegate_task / hire_agent), not the compiler's.
      final steps = {
        for (final step in _generatedPipeline().steps) step.id: step.config,
      };

      expect(steps['sub_a']?.agentId, 'agent-1');
      expect(steps['sub_b']?.agentId, 'agent-1');
      expect(steps['synthesis']?.agentId, 'agent-1');
    });

    test('work and synthesis steps are read-write, not read-only', () {
      // The bodies read `extras['mode']`. Writing any other key (this used to say
      // `conversationMode`) silently left every step in read-only review mode, so
      // an approved plan could not change a single file.
      final extras = _generatedExtras();

      expect(extras['sub_a']?['mode'], 'chat');
      expect(extras['sub_b']?['mode'], 'chat');
      expect(extras['synthesis']?['mode'], 'chat');
      expect(
        extras.values.any((e) => e.containsKey('conversationMode')),
        isFalse,
        reason: 'the dead key must not come back',
      );
    });
  });
}
