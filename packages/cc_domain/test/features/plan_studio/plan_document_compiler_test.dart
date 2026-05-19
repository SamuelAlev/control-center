import 'package:cc_domain/features/orchestration/domain/services/orchestration_proposal_validator.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/plan_document.dart';
import 'package:cc_domain/features/plan_studio/domain/services/plan_document_compiler.dart';
import 'package:cc_domain/features/plan_studio/domain/value_objects/plan_graph.dart';
import 'package:test/test.dart';

final _now = DateTime.utc(2026, 1, 1);

PlanDocument _doc(PlanGraph graph) => PlanDocument(
  id: 'doc-1',
  workspaceId: 'ws-1',
  conversationId: 'conv-1',
  agentId: 'agent-author',
  goal: 'Ship the report',
  graph: graph,
  createdAt: _now,
  updatedAt: _now,
);

void main() {
  group('PlanDocumentCompiler.toProposal — roles', () {
    test('compiles to a single planner role bound to the given agentId', () {
      // Staffing is a decision the executing agent makes at run time (delegate /
      // hire), not one the compiler bakes in — so a plan compiles to exactly one
      // role no matter how many nodes it has.
      const graph = PlanGraph(
        nodes: [
          PlanNode(key: 'w1', title: 'Step 1', type: PlanNodeType.work),
          PlanNode(key: 'w2', title: 'Step 2', type: PlanNodeType.work),
        ],
      );
      final proposal = PlanDocumentCompiler.toProposal(
        _doc(graph),
        agentId: 'agent-xyz',
      );
      expect(proposal.roles, hasLength(1));
      expect(proposal.roles.single.roleKey, PlanDocumentCompiler.roleKey);
      expect(proposal.roles.single.roleKey, 'planner');
      expect(proposal.roles.single.existingAgentId, 'agent-xyz');
      expect(proposal.roles.single.hireSpec, isNull);
      expect(proposal.goal, 'Ship the report');
    });
  });

  group('PlanDocumentCompiler.toProposal — work nodes', () {
    test('work nodes become sub-tickets forced onto the planner role', () {
      const graph = PlanGraph(
        nodes: [
          PlanNode(
            key: 'w1',
            title: 'Step 1',
            type: PlanNodeType.work,
            roleKey: 'someone-else',
          ),
          PlanNode(
            key: 'w2',
            title: 'Step 2',
            type: PlanNodeType.work,
            roleKey: 'someone-else',
            dependsOn: ['w1'],
          ),
        ],
      );
      final proposal = PlanDocumentCompiler.toProposal(
        _doc(graph),
        agentId: 'agent-xyz',
      );
      expect(proposal.subTickets, hasLength(2));
      final w1 = proposal.subTickets.firstWhere((t) => t.key == 'w1');
      final w2 = proposal.subTickets.firstWhere((t) => t.key == 'w2');
      // roleKey is forced to 'planner', not the original node's roleKey.
      expect(w1.roleKey, 'planner');
      expect(w2.roleKey, 'planner');
      // dependsOn is preserved verbatim.
      expect(w1.dependsOn, isEmpty);
      expect(w2.dependsOn, ['w1']);
      expect(w2.title, 'Step 2');
    });

    test('structural nodes in the doc graph are never compiled as work', () {
      // PlanDocument graphs are documented as "work-only", but the compiler
      // itself only reads graph.workNodes, so a structural node sneaking in
      // is safely ignored rather than crashing.
      const graph = PlanGraph(
        nodes: [
          PlanNode(
            key: PlanGraph.synthesisKey,
            title: 'Should be ignored',
            type: PlanNodeType.synthesis,
          ),
          PlanNode(key: 'w1', title: 'Step 1', type: PlanNodeType.work),
        ],
      );
      final proposal = PlanDocumentCompiler.toProposal(
        _doc(graph),
        agentId: 'agent-xyz',
      );
      expect(proposal.subTickets.map((t) => t.key), ['w1']);
    });
  });

  group('PlanDocumentCompiler.toProposal — synthesis', () {
    test(
      'synthesis is present with a summary+gaps schema on the planner role',
      () {
        const graph = PlanGraph(
          nodes: [
            PlanNode(key: 'w1', title: 'Step 1', type: PlanNodeType.work),
          ],
        );
        final proposal = PlanDocumentCompiler.toProposal(
          _doc(graph),
          agentId: 'agent-xyz',
        );
        expect(proposal.synthesis.roleKey, 'planner');
        expect(proposal.synthesis.outputSchema['type'], 'object');
        final properties =
            proposal.synthesis.outputSchema['properties']
                as Map<String, dynamic>;
        expect(properties.containsKey('summary'), isTrue);
        expect(properties.containsKey('gaps'), isTrue);
        expect(proposal.synthesis.outputSchema['required'], [
          'summary',
          'gaps',
        ]);
      },
    );
  });

  group('PlanDocumentCompiler.toProposal — budget', () {
    test('threads the budget ceiling through when given', () {
      const graph = PlanGraph(
        nodes: [PlanNode(key: 'w1', title: 'Step 1', type: PlanNodeType.work)],
      );
      final proposal = PlanDocumentCompiler.toProposal(
        _doc(graph),
        agentId: 'agent-xyz',
        maxCostCents: 12345,
      );
      expect(proposal.budget.maxCostCents, 12345);
    });

    test('leaves the ceiling null when not given', () {
      const graph = PlanGraph(
        nodes: [PlanNode(key: 'w1', title: 'Step 1', type: PlanNodeType.work)],
      );
      final proposal = PlanDocumentCompiler.toProposal(
        _doc(graph),
        agentId: 'agent-xyz',
      );
      expect(proposal.budget.maxCostCents, isNull);
    });
  });

  group('PlanDocumentCompiler.toProposal — end-to-end validity', () {
    test('a compiled valid doc passes OrchestrationProposalValidator', () {
      const graph = PlanGraph(
        nodes: [
          PlanNode(key: 'w1', title: 'Research', type: PlanNodeType.work),
          PlanNode(
            key: 'w2',
            title: 'Write',
            type: PlanNodeType.work,
            dependsOn: ['w1'],
          ),
        ],
      );
      final proposal = PlanDocumentCompiler.toProposal(
        _doc(graph),
        agentId: 'agent-xyz',
      );
      final violations = const OrchestrationProposalValidator().validate(
        proposal,
      );
      expect(violations, isEmpty);
    });

    test('an empty work-node graph fails validation (no sub-tickets)', () {
      const graph = PlanGraph(nodes: []);
      final proposal = PlanDocumentCompiler.toProposal(
        _doc(graph),
        agentId: 'agent-xyz',
      );
      final violations = const OrchestrationProposalValidator().validate(
        proposal,
      );
      expect(violations, isNotEmpty);
      expect(violations, contains('at least one sub-ticket is required'));
    });
  });
}
