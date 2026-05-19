import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_status.dart';
import 'package:test/test.dart';

/// Coverage for Orchestration: construction defaults, the partial-approval
/// gate (isNodeApproved), copyWith field preservation + the
/// clearApprovedNodeKeys flag and the identity-by-(id,status,revision,updatedAt)
/// equality.
const _proposal = OrchestrationProposal(
  goal: 'g',
  roles: [],
  subTickets: [],
  synthesis: SynthesisSpec(roleKey: 'lead', prompt: 'p', outputSchema: {}),
);

final _created = DateTime(2025, 1, 1);
final _updated = DateTime(2025, 1, 2);

void main() {
  group('Orchestration construction', () {
    test('applies the documented defaults', () {
      final o = Orchestration(
        id: 'o1',
        workspaceId: 'ws-1',
        proposal: _proposal,
        createdAt: _created,
        updatedAt: _updated,
      );
      expect(o.status, OrchestrationStatus.proposed);
      expect(o.revision, 1);
      expect(o.approvedRevision, isNull);
      expect(o.pipelineTemplateId, isNull);
      expect(o.pipelineRunId, isNull);
      expect(o.teamId, isNull);
      expect(o.projectId, isNull);
      expect(o.estimatedCostCents, isNull);
      expect(o.maxCostCents, isNull);
      expect(o.hiredAgentIds, isEmpty);
      expect(o.approvedNodeKeys, isNull);
      expect(o.errorMessage, isNull);
      expect(o.completedAt, isNull);
      expect(o.parentTicketId, isNull);
      expect(o.channelId, isNull);
      expect(o.orchestratorAgentId, isNull);
    });

    test('accepts all optional fields', () {
      final o = Orchestration(
        id: 'o1',
        workspaceId: 'ws-1',
        proposal: _proposal,
        createdAt: _created,
        updatedAt: _updated,
        parentTicketId: 't1',
        channelId: 'c1',
        orchestratorAgentId: 'a1',
        status: OrchestrationStatus.executing,
        revision: 3,
        approvedRevision: 2,
        pipelineTemplateId: 'tpl',
        pipelineRunId: 'run',
        teamId: 'team',
        projectId: 'proj',
        estimatedCostCents: 100,
        maxCostCents: 500,
        hiredAgentIds: const ['h1', 'h2'],
        approvedNodeKeys: const ['k1'],
        errorMessage: 'boom',
        completedAt: DateTime(2025, 1, 3),
      );
      expect(o.parentTicketId, 't1');
      expect(o.channelId, 'c1');
      expect(o.orchestratorAgentId, 'a1');
      expect(o.status, OrchestrationStatus.executing);
      expect(o.revision, 3);
      expect(o.approvedRevision, 2);
      expect(o.pipelineTemplateId, 'tpl');
      expect(o.pipelineRunId, 'run');
      expect(o.teamId, 'team');
      expect(o.projectId, 'proj');
      expect(o.estimatedCostCents, 100);
      expect(o.maxCostCents, 500);
      expect(o.hiredAgentIds, ['h1', 'h2']);
      expect(o.approvedNodeKeys, ['k1']);
      expect(o.errorMessage, 'boom');
      expect(o.completedAt, DateTime(2025, 1, 3));
    });
  });

  group('Orchestration isNodeApproved (partial-approval gate)', () {
    test('approves every node when approvedNodeKeys is null', () {
      final o = Orchestration(
        id: 'o1',
        workspaceId: 'ws-1',
        proposal: _proposal,
        createdAt: _created,
        updatedAt: _updated,
      );
      expect(o.approvedNodeKeys, isNull);
      expect(o.isNodeApproved('anything'), isTrue);
      expect(o.isNodeApproved('k1'), isTrue);
    });

    test('approves only the listed nodes when approvedNodeKeys is set', () {
      final o = Orchestration(
        id: 'o1',
        workspaceId: 'ws-1',
        proposal: _proposal,
        createdAt: _created,
        updatedAt: _updated,
        approvedNodeKeys: const ['k1', 'k2'],
      );
      expect(o.isNodeApproved('k1'), isTrue);
      expect(o.isNodeApproved('k2'), isTrue);
      expect(o.isNodeApproved('k3'), isFalse);
    });
  });

  group('Orchestration copyWith', () {
    final base = Orchestration(
      id: 'o1',
      workspaceId: 'ws-1',
      proposal: _proposal,
      createdAt: _created,
      updatedAt: _updated,
      parentTicketId: 't1',
      status: OrchestrationStatus.proposed,
      revision: 1,
      approvedNodeKeys: const ['k1'],
    );

    test('a single-field copy preserves every other field', () {
      final next = base.copyWith(status: OrchestrationStatus.approved);
      expect(next.status, OrchestrationStatus.approved);
      // Preserved.
      expect(next.id, 'o1');
      expect(next.workspaceId, 'ws-1');
      expect(next.proposal, base.proposal);
      expect(next.createdAt, _created);
      expect(next.updatedAt, _updated);
      expect(next.parentTicketId, 't1');
      expect(next.revision, 1);
      expect(next.approvedNodeKeys, ['k1']);
    });

    test('overrides every copyWith parameter', () {
      const newProposal = OrchestrationProposal(
        goal: 'new',
        roles: [],
        subTickets: [],
        synthesis: SynthesisSpec(
          roleKey: 'lead',
          prompt: 'p',
          outputSchema: {},
        ),
      );
      final next = base.copyWith(
        proposal: newProposal,
        parentTicketId: 't2',
        channelId: 'c2',
        orchestratorAgentId: 'a2',
        status: OrchestrationStatus.completed,
        revision: 5,
        approvedRevision: 4,
        pipelineTemplateId: 'tpl',
        pipelineRunId: 'run',
        teamId: 'team',
        projectId: 'proj',
        estimatedCostCents: 7,
        maxCostCents: 9,
        hiredAgentIds: const ['h1'],
        approvedNodeKeys: const ['k1', 'k2'],
        errorMessage: 'err',
        updatedAt: DateTime(2025, 1, 9),
        completedAt: DateTime(2025, 1, 10),
      );
      expect(next.proposal.goal, 'new');
      expect(next.parentTicketId, 't2');
      expect(next.channelId, 'c2');
      expect(next.orchestratorAgentId, 'a2');
      expect(next.status, OrchestrationStatus.completed);
      expect(next.revision, 5);
      expect(next.approvedRevision, 4);
      expect(next.pipelineTemplateId, 'tpl');
      expect(next.pipelineRunId, 'run');
      expect(next.teamId, 'team');
      expect(next.projectId, 'proj');
      expect(next.estimatedCostCents, 7);
      expect(next.maxCostCents, 9);
      expect(next.hiredAgentIds, ['h1']);
      expect(next.approvedNodeKeys, ['k1', 'k2']);
      expect(next.errorMessage, 'err');
      expect(next.updatedAt, DateTime(2025, 1, 9));
      expect(next.completedAt, DateTime(2025, 1, 10));
      // id/workspaceId/createdAt are immutable via copyWith.
      expect(next.id, 'o1');
      expect(next.workspaceId, 'ws-1');
      expect(next.createdAt, _created);
    });

    test('clearApprovedNodeKeys resets approvedNodeKeys to null', () {
      final next = base.copyWith(clearApprovedNodeKeys: true);
      expect(next.approvedNodeKeys, isNull);
      // With null, every node is approved again.
      expect(next.isNodeApproved('anything'), isTrue);
    });

    test(
      'clearApprovedNodeKeys wins over an explicit approvedNodeKeys arg',
      () {
        // Per the source: clearApprovedNodeKeys is checked first.
        final next = base.copyWith(
          approvedNodeKeys: const ['new'],
          clearApprovedNodeKeys: true,
        );
        expect(next.approvedNodeKeys, isNull);
      },
    );

    test('a no-op copy is equal to the original', () {
      expect(base.copyWith(), base);
    });
  });

  group('Orchestration == / hashCode', () {
    test('identity is by id + status + revision + updatedAt', () {
      final a = Orchestration(
        id: 'o1',
        workspaceId: 'ws-1',
        proposal: _proposal,
        createdAt: _created,
        updatedAt: _updated,
      );
      final b = Orchestration(
        id: 'o1',
        workspaceId: 'ws-99', // different workspace — NOT part of identity
        proposal: const OrchestrationProposal(
          goal: 'other',
          roles: [],
          subTickets: [],
          synthesis: SynthesisSpec(
            roleKey: 'lead',
            prompt: 'p',
            outputSchema: {},
          ),
        ),
        createdAt: DateTime(1900), // different createdAt — NOT part of identity
        updatedAt: _updated,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('a different id breaks equality', () {
      final a = Orchestration(
        id: 'o1',
        workspaceId: 'ws-1',
        proposal: _proposal,
        createdAt: _created,
        updatedAt: _updated,
      );
      final b = Orchestration(
        id: 'o2',
        workspaceId: 'ws-1',
        proposal: _proposal,
        createdAt: _created,
        updatedAt: _updated,
      );
      expect(a == b, isFalse);
    });

    test('a different status, revision, or updatedAt breaks equality', () {
      Orchestration make({
        OrchestrationStatus? status,
        int? revision,
        DateTime? updatedAt,
      }) => Orchestration(
        id: 'o1',
        workspaceId: 'ws-1',
        proposal: _proposal,
        createdAt: _created,
        updatedAt: updatedAt ?? _updated,
        status: status ?? OrchestrationStatus.proposed,
        revision: revision ?? 1,
      );
      final base = make();
      expect(base == make(status: OrchestrationStatus.executing), isFalse);
      expect(base == make(revision: 2), isFalse);
      expect(base == make(updatedAt: DateTime(2025, 1, 8)), isFalse);
    });

    test('is not equal to an unrelated type', () {
      final a = Orchestration(
        id: 'o1',
        workspaceId: 'ws-1',
        proposal: _proposal,
        createdAt: _created,
        updatedAt: _updated,
      );
      expect(a == Object(), isFalse);
    });
  });
}
