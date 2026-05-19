import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/orchestration/domain/services/orchestration_proposal_validator.dart';
import 'package:flutter_test/flutter_test.dart';

OrchestrationProposal _valid() => const OrchestrationProposal(
      goal: 'Go-to-market plan for Europe',
      roles: [
        ProposedRole(
          roleKey: 'lead',
          title: 'Strategy lead',
          existingAgentId: 'agent-1',
        ),
        ProposedRole(
          roleKey: 'analyst',
          title: 'Market analyst',
          hireSpec: ProposedHire(name: 'eu-analyst', title: 'EU analyst'),
        ),
      ],
      subTickets: [
        ProposedSubTicket(
          key: 'research',
          title: 'Market research',
          roleKey: 'analyst',
          expectedOutputSchema: {
            'type': 'object',
            'required': ['summary'],
            'properties': {
              'summary': {'type': 'string'},
            },
          },
        ),
        ProposedSubTicket(
          key: 'plan',
          title: 'Draft plan',
          roleKey: 'lead',
          dependsOn: ['research'],
        ),
      ],
      synthesis: SynthesisSpec(
        roleKey: 'lead',
        prompt: 'Synthesize the plan.',
        outputSchema: {
          'type': 'object',
          'required': ['deliverable', 'gaps'],
          'properties': {
            'deliverable': {'type': 'string'},
            'gaps': {
              'type': 'array',
              'items': {'type': 'string'},
            },
          },
        },
      ),
    );

void main() {
  const validator = OrchestrationProposalValidator();

  test('accepts a well-formed proposal', () {
    expect(validator.validate(_valid()), isEmpty);
  });

  test('rejects an unknown role reference in a sub-ticket', () {
    final p = _valid().copyWith(
      subTickets: [
        const ProposedSubTicket(
          key: 'x',
          title: 'X',
          roleKey: 'ghost',
        ),
      ],
    );
    expect(
      validator.validate(p).any((v) => v.contains('unknown role')),
      isTrue,
    );
  });

  test('rejects a dependency cycle', () {
    final p = _valid().copyWith(
      subTickets: const [
        ProposedSubTicket(key: 'a', title: 'A', roleKey: 'lead', dependsOn: ['b']),
        ProposedSubTicket(key: 'b', title: 'B', roleKey: 'lead', dependsOn: ['a']),
      ],
    );
    expect(
      validator.validate(p).any((v) => v.contains('cycle')),
      isTrue,
    );
  });

  test('rejects a role with both existing agent and hire spec', () {
    final p = _valid().copyWith(
      roles: const [
        ProposedRole(
          roleKey: 'lead',
          title: 'Lead',
          existingAgentId: 'a',
          hireSpec: ProposedHire(name: 'x', title: 'X'),
        ),
      ],
    );
    expect(
      validator.validate(p).any((v) => v.contains('exactly one')),
      isTrue,
    );
  });

  test('enforces the sub-ticket count cap', () {
    final p = _valid().copyWith(
      subTickets: [
        for (var i = 0; i < OrchestrationProposalValidator.maxSubTickets + 1; i++)
          ProposedSubTicket(key: 's$i', title: 'S$i', roleKey: 'lead'),
      ],
    );
    expect(
      validator.validate(p).any((v) => v.contains('too many sub-tickets')),
      isTrue,
    );
  });
}
