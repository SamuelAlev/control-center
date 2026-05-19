import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/orchestration/domain/services/orchestration_proposal_validator.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/playbook.dart';
import 'package:cc_domain/features/plan_studio/domain/services/playbook_instantiator.dart';
import 'package:test/test.dart';

final _now = DateTime.utc(2026, 1, 1);

Playbook _playbook({
  required List<PlaybookParam> params,
  required OrchestrationProposal sourceProposal,
}) => Playbook(
  id: 'pb-1',
  workspaceId: 'ws-1',
  name: 'Test playbook',
  params: params,
  sourceProposal: sourceProposal,
  createdAt: _now,
  updatedAt: _now,
);

void main() {
  group('PlaybookInstantiator — happy path', () {
    final playbook = _playbook(
      params: [
        PlaybookParam(name: 'client', description: 'Client name'),
        PlaybookParam(name: 'task', description: 'What to do'),
        PlaybookParam(
          name: 'reviewer_id',
          required: false,
          defaultValue: 'agent-default',
        ),
      ],
      sourceProposal: const OrchestrationProposal(
        goal: 'Do {{task}} for {{client}}',
        roles: [
          ProposedRole(
            roleKey: 'coder',
            title: 'Coder for {{client}}',
            existingAgentId: '{{reviewer_id}}',
          ),
        ],
        subTickets: [
          ProposedSubTicket(
            key: 't1',
            title: '{{task}} implementation',
            roleKey: 'coder',
            description: 'Implement {{task}} for {{client}}.',
          ),
        ],
        synthesis: SynthesisSpec(
          roleKey: 'coder',
          prompt: 'Summarize {{task}} for {{client}}.',
          outputSchema: {
            'type': 'object',
            'required': ['summary'],
          },
        ),
        budget: BudgetSpec(maxCostCents: 5000),
      ),
    );

    test('substitutes across goal/titles/descriptions/prompts', () {
      final result = PlaybookInstantiator.instantiate(playbook, {
        'client': 'Acme',
        'task': 'the migration',
      });
      expect(result.errors, isEmpty);
      expect(result.isValid, isTrue);
      final proposal = result.proposal!;
      expect(proposal.goal, 'Do the migration for Acme');
      expect(proposal.roles.single.title, 'Coder for Acme');
      expect(proposal.subTickets.single.title, 'the migration implementation');
      expect(
        proposal.subTickets.single.description,
        'Implement the migration for Acme.',
      );
      expect(proposal.synthesis.prompt, 'Summarize the migration for Acme.');
    });

    test('applies the default when an optional param is not supplied', () {
      final result = PlaybookInstantiator.instantiate(playbook, {
        'client': 'Acme',
        'task': 'the migration',
      });
      expect(result.errors, isEmpty);
      expect(result.proposal!.roles.single.existingAgentId, 'agent-default');
    });

    test('an explicit value overrides the optional default', () {
      final result = PlaybookInstantiator.instantiate(playbook, {
        'client': 'Acme',
        'task': 'the migration',
        'reviewer_id': 'agent-explicit',
      });
      expect(result.errors, isEmpty);
      expect(result.proposal!.roles.single.existingAgentId, 'agent-explicit');
    });

    test('ints (e.g. budget cents) pass through untouched', () {
      final result = PlaybookInstantiator.instantiate(playbook, {
        'client': 'Acme',
        'task': 'the migration',
      });
      expect(result.errors, isEmpty);
      expect(result.proposal!.budget.maxCostCents, 5000);
    });

    test('the result re-parses as a valid OrchestrationProposal', () {
      final result = PlaybookInstantiator.instantiate(playbook, {
        'client': 'Acme',
        'task': 'the migration',
      });
      expect(result.errors, isEmpty);
      final violations = const OrchestrationProposalValidator().validate(
        result.proposal!,
      );
      expect(violations, isEmpty);
    });
  });

  group('PlaybookInstantiator — required/optional param handling', () {
    test('a missing required parameter is an error', () {
      final playbook = _playbook(
        params: [PlaybookParam(name: 'client')],
        sourceProposal: const OrchestrationProposal(
          goal: 'Serve {{client}}',
          roles: [
            ProposedRole(
              roleKey: 'coder',
              title: 'Coder',
              existingAgentId: 'a1',
            ),
          ],
          subTickets: [
            ProposedSubTicket(key: 't1', title: 'T', roleKey: 'coder'),
          ],
          synthesis: SynthesisSpec(
            roleKey: 'coder',
            prompt: 'p',
            outputSchema: {'type': 'object'},
          ),
        ),
      );
      final result = PlaybookInstantiator.instantiate(playbook, {});
      expect(result.isValid, isFalse);
      expect(result.proposal, isNull);
      expect(result.errors, contains('Missing required parameter: client.'));
    });

    test('an optional param missing with no default leaves an unresolved '
        'placeholder error', () {
      final playbook = _playbook(
        params: [PlaybookParam(name: 'nickname', required: false)],
        sourceProposal: const OrchestrationProposal(
          goal: 'Hello {{nickname}}',
          roles: [
            ProposedRole(
              roleKey: 'coder',
              title: 'Coder',
              existingAgentId: 'a1',
            ),
          ],
          subTickets: [
            ProposedSubTicket(key: 't1', title: 'T', roleKey: 'coder'),
          ],
          synthesis: SynthesisSpec(
            roleKey: 'coder',
            prompt: 'p',
            outputSchema: {'type': 'object'},
          ),
        ),
      );
      final result = PlaybookInstantiator.instantiate(playbook, {});
      expect(result.isValid, isFalse);
      expect(result.proposal, isNull);
      expect(
        result.errors.single,
        contains('Unresolved placeholder {{nickname}}'),
      );
    });
  });

  group('PlaybookInstantiator — enumeration params', () {
    test('an invalid choice is an error', () {
      final playbook = _playbook(
        params: [
          PlaybookParam(
            name: 'priority',
            type: PlaybookParamType.enumeration,
            choices: const ['low', 'high'],
          ),
        ],
        sourceProposal: const OrchestrationProposal(
          goal: 'Do it at {{priority}} priority',
          roles: [
            ProposedRole(
              roleKey: 'coder',
              title: 'Coder',
              existingAgentId: 'a1',
            ),
          ],
          subTickets: [
            ProposedSubTicket(key: 't1', title: 'T', roleKey: 'coder'),
          ],
          synthesis: SynthesisSpec(
            roleKey: 'coder',
            prompt: 'p',
            outputSchema: {'type': 'object'},
          ),
        ),
      );
      final result = PlaybookInstantiator.instantiate(playbook, {
        'priority': 'medium',
      });
      expect(result.isValid, isFalse);
      expect(
        result.errors.single,
        'Parameter priority must be one of: low, high (got "medium").',
      );
    });

    test('a valid choice substitutes cleanly', () {
      final playbook = _playbook(
        params: [
          PlaybookParam(
            name: 'priority',
            type: PlaybookParamType.enumeration,
            choices: const ['low', 'high'],
          ),
        ],
        sourceProposal: const OrchestrationProposal(
          goal: 'Do it at {{priority}} priority',
          roles: [
            ProposedRole(
              roleKey: 'coder',
              title: 'Coder',
              existingAgentId: 'a1',
            ),
          ],
          subTickets: [
            ProposedSubTicket(key: 't1', title: 'T', roleKey: 'coder'),
          ],
          synthesis: SynthesisSpec(
            roleKey: 'coder',
            prompt: 'p',
            outputSchema: {'type': 'object'},
          ),
        ),
      );
      final result = PlaybookInstantiator.instantiate(playbook, {
        'priority': 'high',
      });
      expect(result.errors, isEmpty);
      expect(result.proposal!.goal, 'Do it at high priority');
    });
  });

  group('PlaybookInstantiator — unknown args', () {
    test('an arg not declared as a param is an error', () {
      final playbook = _playbook(
        params: [PlaybookParam(name: 'client')],
        sourceProposal: const OrchestrationProposal(
          goal: 'Serve {{client}}',
          roles: [
            ProposedRole(
              roleKey: 'coder',
              title: 'Coder',
              existingAgentId: 'a1',
            ),
          ],
          subTickets: [
            ProposedSubTicket(key: 't1', title: 'T', roleKey: 'coder'),
          ],
          synthesis: SynthesisSpec(
            roleKey: 'coder',
            prompt: 'p',
            outputSchema: {'type': 'object'},
          ),
        ),
      );
      final result = PlaybookInstantiator.instantiate(playbook, {
        'client': 'Acme',
        'bogus': 'value',
      });
      expect(result.isValid, isFalse);
      expect(result.errors, contains('Unknown parameter: bogus.'));
    });
  });

  group('PlaybookInstantiator.placeholdersIn', () {
    test('extracts every placeholder referenced anywhere in the proposal', () {
      const proposal = OrchestrationProposal(
        goal: 'Do {{task}} for {{client}}',
        roles: [
          ProposedRole(roleKey: 'coder', title: 'Coder', existingAgentId: 'a1'),
        ],
        subTickets: [
          ProposedSubTicket(
            key: 't1',
            title: '{{task}} phase 1',
            roleKey: 'coder',
            description: 'Details for {{client}}',
          ),
        ],
        synthesis: SynthesisSpec(
          roleKey: 'coder',
          prompt: 'p',
          outputSchema: {'type': 'object'},
        ),
      );
      expect(PlaybookInstantiator.placeholdersIn(proposal), {'task', 'client'});
    });

    test('returns an empty set when the proposal has no placeholders', () {
      const proposal = OrchestrationProposal(
        goal: 'Static goal',
        roles: [
          ProposedRole(roleKey: 'coder', title: 'Coder', existingAgentId: 'a1'),
        ],
        subTickets: [
          ProposedSubTicket(key: 't1', title: 'T', roleKey: 'coder'),
        ],
        synthesis: SynthesisSpec(
          roleKey: 'coder',
          prompt: 'p',
          outputSchema: {'type': 'object'},
        ),
      );
      expect(PlaybookInstantiator.placeholdersIn(proposal), isEmpty);
    });
  });
}
