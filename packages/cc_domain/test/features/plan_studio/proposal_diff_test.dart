import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/plan_studio/domain/services/proposal_diff.dart';
import 'package:test/test.dart';

OrchestrationProposal _proposal({
  String goal = 'Ship it',
  List<ProposedRole> roles = const [
    ProposedRole(roleKey: 'coder', title: 'Coder', existingAgentId: 'a1'),
  ],
  List<ProposedSubTicket> subTickets = const [
    ProposedSubTicket(key: 't1', title: 'Ticket 1', roleKey: 'coder'),
  ],
  BudgetSpec budget = const BudgetSpec(),
}) => OrchestrationProposal(
  goal: goal,
  roles: roles,
  subTickets: subTickets,
  synthesis: const SynthesisSpec(
    roleKey: 'coder',
    prompt: 'Summarize',
    outputSchema: {
      'type': 'object',
      'required': ['summary'],
    },
  ),
  budget: budget,
);

void main() {
  group('ProposalDiffService.diff — no-op', () {
    test('identical proposals produce an empty diff', () {
      final from = _proposal();
      final to = _proposal();
      final diff = ProposalDiffService.diff(from, to);
      expect(diff.isEmpty, isTrue);
      expect(diff.touchedNodeKeys, isEmpty);
    });
  });

  group('ProposalDiffService.diff — node add/remove', () {
    test('reports an added node', () {
      final from = _proposal(
        subTickets: const [
          ProposedSubTicket(key: 't1', title: 'Ticket 1', roleKey: 'coder'),
        ],
      );
      final to = _proposal(
        subTickets: const [
          ProposedSubTicket(key: 't1', title: 'Ticket 1', roleKey: 'coder'),
          ProposedSubTicket(key: 't2', title: 'Ticket 2', roleKey: 'coder'),
        ],
      );
      final diff = ProposalDiffService.diff(from, to);
      expect(diff.addedNodeKeys, ['t2']);
      expect(diff.removedNodeKeys, isEmpty);
      expect(diff.isEmpty, isFalse);
      expect(diff.touchedNodeKeys, contains('t2'));
    });

    test('reports a removed node', () {
      final from = _proposal(
        subTickets: const [
          ProposedSubTicket(key: 't1', title: 'Ticket 1', roleKey: 'coder'),
          ProposedSubTicket(key: 't2', title: 'Ticket 2', roleKey: 'coder'),
        ],
      );
      final to = _proposal(
        subTickets: const [
          ProposedSubTicket(key: 't1', title: 'Ticket 1', roleKey: 'coder'),
        ],
      );
      final diff = ProposalDiffService.diff(from, to);
      expect(diff.removedNodeKeys, ['t2']);
      expect(diff.addedNodeKeys, isEmpty);
    });
  });

  group('ProposalDiffService.diff — per-field node changes', () {
    test('detects a title change', () {
      final from = _proposal(
        subTickets: const [
          ProposedSubTicket(key: 't1', title: 'Old', roleKey: 'coder'),
        ],
      );
      final to = _proposal(
        subTickets: const [
          ProposedSubTicket(key: 't1', title: 'New', roleKey: 'coder'),
        ],
      );
      final diff = ProposalDiffService.diff(from, to);
      expect(diff.changedNodes, hasLength(1));
      expect(diff.changedNodes.single.key, 't1');
      expect(diff.changedNodes.single.changedFields, ['title']);
    });

    test('detects a description change', () {
      final from = _proposal(
        subTickets: const [
          ProposedSubTicket(
            key: 't1',
            title: 'T',
            roleKey: 'coder',
            description: 'old',
          ),
        ],
      );
      final to = _proposal(
        subTickets: const [
          ProposedSubTicket(
            key: 't1',
            title: 'T',
            roleKey: 'coder',
            description: 'new',
          ),
        ],
      );
      final diff = ProposalDiffService.diff(from, to);
      expect(diff.changedNodes.single.changedFields, ['description']);
    });

    test('detects a roleKey change', () {
      final from = _proposal(
        roles: const [
          ProposedRole(roleKey: 'coder', title: 'Coder', existingAgentId: 'a1'),
          ProposedRole(
            roleKey: 'reviewer',
            title: 'Reviewer',
            existingAgentId: 'a2',
          ),
        ],
        subTickets: const [
          ProposedSubTicket(key: 't1', title: 'T', roleKey: 'coder'),
        ],
      );
      final to = _proposal(
        roles: const [
          ProposedRole(roleKey: 'coder', title: 'Coder', existingAgentId: 'a1'),
          ProposedRole(
            roleKey: 'reviewer',
            title: 'Reviewer',
            existingAgentId: 'a2',
          ),
        ],
        subTickets: const [
          ProposedSubTicket(key: 't1', title: 'T', roleKey: 'reviewer'),
        ],
      );
      final diff = ProposalDiffService.diff(from, to);
      expect(diff.changedNodes.single.changedFields, ['roleKey']);
    });

    test(
      'detects an expectedOutputSchema change (including null -> value)',
      () {
        final from = _proposal(
          subTickets: const [
            ProposedSubTicket(key: 't1', title: 'T', roleKey: 'coder'),
          ],
        );
        final to = _proposal(
          subTickets: const [
            ProposedSubTicket(
              key: 't1',
              title: 'T',
              roleKey: 'coder',
              expectedOutputSchema: {'type': 'object'},
            ),
          ],
        );
        final diff = ProposalDiffService.diff(from, to);
        expect(diff.changedNodes.single.changedFields, [
          'expectedOutputSchema',
        ]);
      },
    );

    test('detects a priority change', () {
      final from = _proposal(
        subTickets: const [
          ProposedSubTicket(
            key: 't1',
            title: 'T',
            roleKey: 'coder',
            priority: 'none',
          ),
        ],
      );
      final to = _proposal(
        subTickets: const [
          ProposedSubTicket(
            key: 't1',
            title: 'T',
            roleKey: 'coder',
            priority: 'urgent',
          ),
        ],
      );
      final diff = ProposalDiffService.diff(from, to);
      expect(diff.changedNodes.single.changedFields, ['priority']);
    });

    test('reports multiple changed fields on the same node together', () {
      final from = _proposal(
        subTickets: const [
          ProposedSubTicket(
            key: 't1',
            title: 'Old',
            roleKey: 'coder',
            priority: 'none',
          ),
        ],
      );
      final to = _proposal(
        subTickets: const [
          ProposedSubTicket(
            key: 't1',
            title: 'New',
            roleKey: 'coder',
            priority: 'high',
          ),
        ],
      );
      final diff = ProposalDiffService.diff(from, to);
      expect(diff.changedNodes.single.changedFields, ['title', 'priority']);
    });

    test('a node with no field changes is not reported', () {
      final from = _proposal(
        subTickets: const [
          ProposedSubTicket(key: 't1', title: 'T', roleKey: 'coder'),
        ],
      );
      final to = _proposal(
        subTickets: const [
          ProposedSubTicket(key: 't1', title: 'T', roleKey: 'coder'),
        ],
      );
      expect(ProposalDiffService.diff(from, to).changedNodes, isEmpty);
    });
  });

  group('ProposalDiffService.diff — edges', () {
    test('reports an edge added between two surviving nodes', () {
      final from = _proposal(
        subTickets: const [
          ProposedSubTicket(key: 'a', title: 'A', roleKey: 'coder'),
          ProposedSubTicket(key: 'b', title: 'B', roleKey: 'coder'),
        ],
      );
      final to = _proposal(
        subTickets: const [
          ProposedSubTicket(key: 'a', title: 'A', roleKey: 'coder'),
          ProposedSubTicket(
            key: 'b',
            title: 'B',
            roleKey: 'coder',
            dependsOn: ['a'],
          ),
        ],
      );
      final diff = ProposalDiffService.diff(from, to);
      expect(diff.addedEdges, [(from: 'a', to: 'b')]);
      expect(diff.removedEdges, isEmpty);
      // No field change on 'b' — dependsOn is not a tracked field, only an
      // edge.
      expect(diff.changedNodes, isEmpty);
    });

    test('reports an edge removed between two surviving nodes', () {
      final from = _proposal(
        subTickets: const [
          ProposedSubTicket(key: 'a', title: 'A', roleKey: 'coder'),
          ProposedSubTicket(
            key: 'b',
            title: 'B',
            roleKey: 'coder',
            dependsOn: ['a'],
          ),
        ],
      );
      final to = _proposal(
        subTickets: const [
          ProposedSubTicket(key: 'a', title: 'A', roleKey: 'coder'),
          ProposedSubTicket(key: 'b', title: 'B', roleKey: 'coder'),
        ],
      );
      final diff = ProposalDiffService.diff(from, to);
      expect(diff.removedEdges, [(from: 'a', to: 'b')]);
      expect(diff.addedEdges, isEmpty);
    });

    test('edges hanging off an added/removed node are not double-reported', () {
      // 'b' depends on 'a' in `from`; in `to`, 'b' is gone and a NEW node
      // 'd' depends on 'a' instead. The only genuinely new/removed EDGE
      // between survivors should surface — 'd's edge must not appear
      // because 'd' itself is already reported as an added node.
      final from = _proposal(
        subTickets: const [
          ProposedSubTicket(key: 'a', title: 'A', roleKey: 'coder'),
          ProposedSubTicket(
            key: 'b',
            title: 'B',
            roleKey: 'coder',
            dependsOn: ['a'],
          ),
        ],
      );
      final to = _proposal(
        subTickets: const [
          ProposedSubTicket(key: 'a', title: 'A', roleKey: 'coder'),
          ProposedSubTicket(
            key: 'd',
            title: 'D',
            roleKey: 'coder',
            dependsOn: ['a'],
          ),
        ],
      );
      final diff = ProposalDiffService.diff(from, to);
      expect(diff.addedNodeKeys, ['d']);
      expect(diff.removedNodeKeys, ['b']);
      // No edge changes reported: both candidate edges involve a
      // non-surviving node.
      expect(diff.addedEdges, isEmpty);
      expect(diff.removedEdges, isEmpty);
    });
  });

  group('ProposalDiffService.diff — goal', () {
    test('goalChanged is true only when the goal text differs', () {
      expect(
        ProposalDiffService.diff(
          _proposal(goal: 'A'),
          _proposal(goal: 'A'),
        ).goalChanged,
        isFalse,
      );
      expect(
        ProposalDiffService.diff(
          _proposal(goal: 'A'),
          _proposal(goal: 'B'),
        ).goalChanged,
        isTrue,
      );
    });
  });

  group('ProposalDiffService.diff — roles', () {
    test('rolesAdded / rolesRemoved', () {
      final from = _proposal(
        roles: const [
          ProposedRole(roleKey: 'coder', title: 'Coder', existingAgentId: 'a1'),
        ],
      );
      final to = _proposal(
        roles: const [
          ProposedRole(roleKey: 'coder', title: 'Coder', existingAgentId: 'a1'),
          ProposedRole(
            roleKey: 'reviewer',
            title: 'Reviewer',
            existingAgentId: 'a2',
          ),
        ],
      );
      final diff = ProposalDiffService.diff(from, to);
      expect(diff.rolesAdded, ['reviewer']);
      expect(diff.rolesRemoved, isEmpty);

      final backDiff = ProposalDiffService.diff(to, from);
      expect(backDiff.rolesRemoved, ['reviewer']);
      expect(backDiff.rolesAdded, isEmpty);
    });

    test('rolesReassigned on an existingAgentId swap', () {
      final from = _proposal(
        roles: const [
          ProposedRole(roleKey: 'coder', title: 'Coder', existingAgentId: 'a1'),
        ],
      );
      final to = _proposal(
        roles: const [
          ProposedRole(roleKey: 'coder', title: 'Coder', existingAgentId: 'a2'),
        ],
      );
      final diff = ProposalDiffService.diff(from, to);
      expect(diff.rolesReassigned, ['coder']);
    });

    test('rolesReassigned on a hireSpec change', () {
      final from = _proposal(
        roles: const [
          ProposedRole(
            roleKey: 'coder',
            title: 'Coder',
            hireSpec: ProposedHire(name: 'Ada', title: 'Coder'),
          ),
        ],
      );
      final to = _proposal(
        roles: const [
          ProposedRole(
            roleKey: 'coder',
            title: 'Coder',
            hireSpec: ProposedHire(name: 'Grace', title: 'Coder'),
          ),
        ],
      );
      final diff = ProposalDiffService.diff(from, to);
      expect(diff.rolesReassigned, ['coder']);
    });

    test('an unchanged role is not reassigned', () {
      final from = _proposal();
      final to = _proposal();
      expect(ProposalDiffService.diff(from, to).rolesReassigned, isEmpty);
    });
  });

  group('ProposalDiffService.diff — budget', () {
    test('null -> value is a budget change', () {
      final from = _proposal(budget: const BudgetSpec());
      final to = _proposal(budget: const BudgetSpec(maxCostCents: 500));
      final diff = ProposalDiffService.diff(from, to);
      expect(diff.maxCostCentsFrom, isNull);
      expect(diff.maxCostCentsTo, 500);
      expect(diff.budgetChanged, isTrue);
      expect(diff.isEmpty, isFalse);
    });

    test('value -> null is a budget change', () {
      final from = _proposal(budget: const BudgetSpec(maxCostCents: 500));
      final to = _proposal(budget: const BudgetSpec());
      final diff = ProposalDiffService.diff(from, to);
      expect(diff.maxCostCentsFrom, 500);
      expect(diff.maxCostCentsTo, isNull);
      expect(diff.budgetChanged, isTrue);
    });

    test('value -> same value is NOT a budget change', () {
      final from = _proposal(budget: const BudgetSpec(maxCostCents: 500));
      final to = _proposal(budget: const BudgetSpec(maxCostCents: 500));
      final diff = ProposalDiffService.diff(from, to);
      expect(diff.budgetChanged, isFalse);
      expect(diff.isEmpty, isTrue);
    });

    test('null -> null is NOT a budget change', () {
      final diff = ProposalDiffService.diff(_proposal(), _proposal());
      expect(diff.budgetChanged, isFalse);
    });
  });

  group('PlanDiff.touchedNodeKeys', () {
    test('unions added/removed/changed nodes and edge endpoints', () {
      final from = _proposal(
        subTickets: const [
          ProposedSubTicket(key: 'a', title: 'A', roleKey: 'coder'),
          ProposedSubTicket(key: 'b', title: 'Old', roleKey: 'coder'),
          ProposedSubTicket(key: 'c', title: 'C', roleKey: 'coder'),
        ],
      );
      final to = _proposal(
        subTickets: const [
          ProposedSubTicket(key: 'a', title: 'A', roleKey: 'coder'),
          ProposedSubTicket(key: 'b', title: 'New', roleKey: 'coder'),
          ProposedSubTicket(
            key: 'c',
            title: 'C',
            roleKey: 'coder',
            dependsOn: ['a'],
          ),
          ProposedSubTicket(key: 'd', title: 'D', roleKey: 'coder'),
        ],
      );
      final diff = ProposalDiffService.diff(from, to);
      expect(diff.touchedNodeKeys, {'a', 'b', 'c', 'd'});
    });
  });
}
