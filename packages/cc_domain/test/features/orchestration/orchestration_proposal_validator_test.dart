import 'package:cc_domain/core/domain/ports/schema_validator_port.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/orchestration/domain/services/orchestration_proposal_validator.dart';
import 'package:test/test.dart';

/// Exhaustive branch coverage for [OrchestrationProposalValidator.validate]:
/// every violation message, the cycle detector (Kahn), the schema-validator
/// injection paths, and the happy path (empty violations list).
void main() {
  // A minimal valid proposal used as the edit base.
  OrchestrationProposal valid() => const OrchestrationProposal(
    goal: 'ship it',
    roles: [
      ProposedRole(roleKey: 'lead', title: 'Lead', existingAgentId: 'a1'),
    ],
    subTickets: [
      ProposedSubTicket(key: 's1', title: 'Do', roleKey: 'lead', dependsOn: []),
    ],
    synthesis: SynthesisSpec(
      roleKey: 'lead',
      prompt: 'combine',
      outputSchema: {'type': 'object'},
    ),
  );

  group('OrchestrationProposalValidator.validate', () {
    test('valid proposal → no issues', () {
      expect(const OrchestrationProposalValidator().validate(valid()), isEmpty);
    });

    test('empty goal', () {
      final p = valid().copyWith(goal: '   ');
      expect(
        const OrchestrationProposalValidator().validate(p),
        contains('goal must not be empty'),
      );
    });

    test('no roles + no sub-tickets', () {
      const p = OrchestrationProposal(
        goal: 'g',
        roles: [],
        subTickets: [],
        synthesis: SynthesisSpec(
          roleKey: 'x',
          prompt: 'p',
          outputSchema: {'type': 'object'},
        ),
      );
      final issues = const OrchestrationProposalValidator().validate(p);
      expect(issues, contains('at least one role is required'));
      expect(issues, contains('at least one sub-ticket is required'));
    });

    test('too many roles + too many sub-tickets', () {
      final p = valid().copyWith(
        roles: [
          for (var i = 0; i <= OrchestrationProposalValidator.maxRoles; i++)
            ProposedRole(roleKey: 'r$i', title: 'R', existingAgentId: 'a'),
        ],
        subTickets: [
          for (
            var i = 0;
            i <= OrchestrationProposalValidator.maxSubTickets;
            i++
          )
            ProposedSubTicket(key: 'k$i', title: 'K', roleKey: 'r0'),
        ],
      );
      final issues = const OrchestrationProposalValidator().validate(p);
      expect(
        issues,
        contains(
          'too many roles (${OrchestrationProposalValidator.maxRoles + 1}); '
          'max is ${OrchestrationProposalValidator.maxRoles}',
        ),
      );
      expect(
        issues,
        contains(
          'too many sub-tickets (${OrchestrationProposalValidator.maxSubTickets + 1}); '
          'max is ${OrchestrationProposalValidator.maxSubTickets}',
        ),
      );
    });

    test('empty roleKey + duplicate roleKey', () {
      final p = valid().copyWith(
        roles: [
          const ProposedRole(roleKey: '  ', title: 'T', existingAgentId: 'a'),
          const ProposedRole(
            roleKey: 'lead',
            title: 'Dup',
            existingAgentId: 'a2',
          ),
          const ProposedRole(
            roleKey: 'dup',
            title: 'D1',
            existingAgentId: 'a3',
          ),
          const ProposedRole(
            roleKey: 'dup',
            title: 'D2',
            existingAgentId: 'a4',
          ),
        ],
      );
      final issues = const OrchestrationProposalValidator().validate(p);
      expect(issues, contains('a role has an empty roleKey'));
      expect(issues, contains('duplicate roleKey "dup"'));
    });

    test('role with neither existing nor hire, and role with both', () {
      final p = valid().copyWith(
        roles: [
          const ProposedRole(roleKey: 'lead', title: 'L'),
          const ProposedRole(
            roleKey: 'r2',
            title: 'R2',
            existingAgentId: 'a',
            hireSpec: ProposedHire(name: 'n', title: 't'),
          ),
        ],
      );
      final issues = const OrchestrationProposalValidator().validate(p);
      expect(
        issues,
        contains(
          'role "lead" must set exactly one of existingAgentId or '
          'hireSpec',
        ),
      );
      expect(
        issues,
        contains(
          'role "r2" must set exactly one of existingAgentId or '
          'hireSpec',
        ),
      );
    });

    test('hire spec with empty name', () {
      final p = valid().copyWith(
        roles: [
          const ProposedRole(
            roleKey: 'lead',
            title: 'L',
            hireSpec: ProposedHire(name: '  ', title: 't'),
          ),
        ],
      );
      expect(
        const OrchestrationProposalValidator().validate(p),
        contains('role "lead" hire spec has an empty name'),
      );
    });

    test('sub-ticket empty key + duplicate key', () {
      final p = valid().copyWith(
        subTickets: [
          const ProposedSubTicket(key: '  ', title: 'T', roleKey: 'lead'),
          const ProposedSubTicket(key: 's1', title: 'First', roleKey: 'lead'),
          const ProposedSubTicket(key: 'dup', title: 'D1', roleKey: 'lead'),
          const ProposedSubTicket(key: 'dup', title: 'D2', roleKey: 'lead'),
        ],
      );
      final issues = const OrchestrationProposalValidator().validate(p);
      expect(issues, contains('a sub-ticket has an empty key'));
      expect(issues, contains('duplicate sub-ticket key "dup"'));
    });

    test('sub-ticket references unknown role + unknown dependency', () {
      final p = valid().copyWith(
        subTickets: [
          const ProposedSubTicket(
            key: 's1',
            title: 'T',
            roleKey: 'ghost',
            dependsOn: ['nope'],
          ),
        ],
      );
      final issues = const OrchestrationProposalValidator().validate(p);
      expect(
        issues,
        contains('sub-ticket "s1" references unknown role "ghost"'),
      );
      expect(issues, contains('sub-ticket "s1" depends on unknown "nope"'));
    });

    test('detects a dependency cycle', () {
      final p = valid().copyWith(
        subTickets: [
          const ProposedSubTicket(
            key: 'a',
            title: 'A',
            roleKey: 'lead',
            dependsOn: ['b'],
          ),
          const ProposedSubTicket(
            key: 'b',
            title: 'B',
            roleKey: 'lead',
            dependsOn: ['a'],
          ),
        ],
      );
      expect(
        const OrchestrationProposalValidator().validate(p),
        contains('sub-ticket dependencies contain a cycle'),
      );
    });

    test('synthesis with unknown role + empty schema', () {
      const p = OrchestrationProposal(
        goal: 'g',
        roles: [
          ProposedRole(roleKey: 'lead', title: 'L', existingAgentId: 'a'),
        ],
        subTickets: [ProposedSubTicket(key: 's1', title: 'T', roleKey: 'lead')],
        synthesis: SynthesisSpec(
          roleKey: 'ghost',
          prompt: 'p',
          outputSchema: {},
        ),
      );
      final issues = const OrchestrationProposalValidator().validate(p);
      expect(issues, contains('synthesis references unknown role "ghost"'));
      expect(issues, contains('synthesis must declare an output schema'));
    });

    test('research references unknown role', () {
      final p = valid().copyWith(
        research: const ResearchSpec(enabled: true, roleKey: 'ghost'),
      );
      expect(
        const OrchestrationProposalValidator().validate(p),
        contains('research references unknown role "ghost"'),
      );
    });

    test('schemaValidator hooks into sub-ticket + synthesis schemas', () {
      final p = valid().copyWith(
        subTickets: [
          const ProposedSubTicket(
            key: 's1',
            title: 'T',
            roleKey: 'lead',
            expectedOutputSchema: {'bad': true},
          ),
        ],
        synthesis: const SynthesisSpec(
          roleKey: 'lead',
          prompt: 'p',
          outputSchema: {'also': 'bad'},
        ),
      );
      final issues = const OrchestrationProposalValidator(
        schemaValidator: _Boom(),
      ).validate(p);
      expect(
        issues.any((m) => m.startsWith('sub-ticket "s1" output schema')),
        isTrue,
      );
      expect(
        issues.any((m) => m.startsWith('synthesis output schema')),
        isTrue,
      );
    });
  });
}

/// A [SchemaValidatorPort] that always reports one canned problem, so the
/// schema-validation injection paths fire.
class _Boom implements SchemaValidatorPort {
  const _Boom();

  @override
  List<String> validate(Object? value, Map<String, dynamic> schema) => const [
    'nope',
  ];

  @override
  List<String> validateSchema(Map<String, dynamic> schema) => const [
    'malformed',
  ];
}
