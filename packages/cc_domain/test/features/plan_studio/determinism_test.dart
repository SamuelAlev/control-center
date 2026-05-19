import 'dart:convert';

import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/orchestration/domain/services/orchestration_materializer.dart';
import 'package:cc_domain/features/orchestration/domain/value_objects/plan_annotations.dart';
import 'package:test/test.dart';

const _proposal = OrchestrationProposal(
  goal: 'Ship the feature',
  roles: [
    ProposedRole(roleKey: 'coder', title: 'Coder', existingAgentId: 'a1'),
    ProposedRole(roleKey: 'reviewer', title: 'Reviewer', existingAgentId: 'a2'),
  ],
  subTickets: [
    ProposedSubTicket(key: 't1', title: 'Do the work', roleKey: 'coder'),
    ProposedSubTicket(
      key: 't2',
      title: 'Review the work',
      roleKey: 'reviewer',
      dependsOn: ['t1'],
    ),
  ],
  research: ResearchSpec(
    enabled: true,
    prompt: 'Investigate',
    roleKey: 'coder',
  ),
  discussion: DiscussionSpec(enabled: true, prompt: 'Discuss'),
  synthesis: SynthesisSpec(
    roleKey: 'reviewer',
    prompt: 'Summarize',
    outputSchema: {
      'type': 'object',
      'required': ['summary'],
    },
  ),
  budget: BudgetSpec(maxCostCents: 1000),
);

void main() {
  group('OrchestrationMaterializer — determinism (PRD 17 acceptance)', () {
    final roleAgents = {'coder': 'agent-coder', 'reviewer': 'agent-reviewer'};

    test(
      'the same Orchestration instance compiles to an identical DAG twice',
      () {
        final orchestration = Orchestration(
          id: 'orch-1',
          workspaceId: 'ws-1',
          proposal: _proposal,
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        );
        const materializer = OrchestrationMaterializer();

        final def1 = materializer.buildDefinition(
          orchestration,
          roleAgents: roleAgents,
          spaceId: 'chan-1',
          parentTicketId: 'ticket-1',
          projectId: 'proj-1',
        );
        final def2 = materializer.buildDefinition(
          orchestration,
          roleAgents: roleAgents,
          spaceId: 'chan-1',
          parentTicketId: 'ticket-1',
          projectId: 'proj-1',
        );

        expect(jsonEncode(def1.toJson()), jsonEncode(def2.toJson()));
        expect(def1, def2);
      },
    );

    test('an identical proposal + role map on a FRESH Orchestration object '
        'compiles to the identical pipeline DAG', () {
      // Two independently constructed Orchestration objects: same id,
      // workspace and proposal CONTENT (separately built, not the same
      // instance) but different timestamps — those must not leak into the
      // generated pipeline.
      final orchestrationA = Orchestration(
        id: 'orch-1',
        workspaceId: 'ws-1',
        proposal: _proposal,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      final orchestrationB = Orchestration(
        id: 'orch-1',
        workspaceId: 'ws-1',
        proposal: OrchestrationProposal.fromJsonString(
          _proposal.toJsonString(),
        ),
        createdAt: DateTime.utc(2026, 6, 15),
        updatedAt: DateTime.utc(2026, 6, 15),
      );
      const materializer = OrchestrationMaterializer();

      final defA = materializer.buildDefinition(
        orchestrationA,
        roleAgents: roleAgents,
        spaceId: 'chan-1',
        parentTicketId: 'ticket-1',
        projectId: 'proj-1',
      );
      final defB = materializer.buildDefinition(
        orchestrationB,
        roleAgents: roleAgents,
        spaceId: 'chan-1',
        parentTicketId: 'ticket-1',
        projectId: 'proj-1',
      );

      expect(jsonEncode(defA.toJson()), jsonEncode(defB.toJson()));
    });

    test('a different roleAgents map changes the compiled DAG', () {
      final orchestration = Orchestration(
        id: 'orch-1',
        workspaceId: 'ws-1',
        proposal: _proposal,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      const materializer = OrchestrationMaterializer();
      final def1 = materializer.buildDefinition(
        orchestration,
        roleAgents: roleAgents,
        spaceId: 'chan-1',
        parentTicketId: 'ticket-1',
        projectId: 'proj-1',
      );
      final def2 = materializer.buildDefinition(
        orchestration,
        roleAgents: {'coder': 'agent-other', 'reviewer': 'agent-reviewer'},
        spaceId: 'chan-1',
        parentTicketId: 'ticket-1',
        projectId: 'proj-1',
      );
      expect(jsonEncode(def1.toJson()), isNot(jsonEncode(def2.toJson())));
    });
  });

  group(
    'OrchestrationProposal JSON round-trip — PRD 17 estimate/provenance',
    () {
      test('round-trip preserves node estimate and provenance fields', () {
        const proposal = OrchestrationProposal(
          goal: 'Ship the feature',
          roles: [
            ProposedRole(
              roleKey: 'coder',
              title: 'Coder',
              existingAgentId: 'a1',
            ),
          ],
          subTickets: [
            ProposedSubTicket(
              key: 't1',
              title: 'Do the work',
              roleKey: 'coder',
              estimate: PlanNodeEstimate(
                costCentsLow: 100,
                costCentsHigh: 300,
                durationMsLow: 1000,
                durationMsHigh: 3000,
                sampleSize: 4,
                blastRadiusFiles: 6,
                blastRadiusSymbols: 15,
              ),
              provenance: [
                PlanProvenanceRef(kind: 'file', ref: 'lib/a.dart', label: 'a'),
                PlanProvenanceRef(kind: 'symbol', ref: 'Foo.bar'),
              ],
            ),
          ],
          synthesis: SynthesisSpec(
            roleKey: 'coder',
            prompt: 'Summarize',
            outputSchema: {
              'type': 'object',
              'required': ['summary'],
            },
          ),
        );

        final restored = OrchestrationProposal.fromJsonString(
          proposal.toJsonString(),
        );

        // OrchestrationProposal equality is by canonical serialized form.
        expect(restored, proposal);

        final ticket = restored.subTickets.single;
        expect(ticket.estimate, isNotNull);
        expect(ticket.estimate!.costCentsLow, 100);
        expect(ticket.estimate!.costCentsHigh, 300);
        expect(ticket.estimate!.durationMsLow, 1000);
        expect(ticket.estimate!.durationMsHigh, 3000);
        expect(ticket.estimate!.sampleSize, 4);
        expect(ticket.estimate!.blastRadiusFiles, 6);
        expect(ticket.estimate!.blastRadiusSymbols, 15);
        expect(ticket.provenance, hasLength(2));
        expect(ticket.provenance[0].kind, 'file');
        expect(ticket.provenance[0].ref, 'lib/a.dart');
        expect(ticket.provenance[0].label, 'a');
        expect(ticket.provenance[1].kind, 'symbol');
        expect(ticket.provenance[1].ref, 'Foo.bar');
        expect(ticket.provenance[1].label, isNull);
      });

      test(
        'a sub-ticket with no estimate/provenance round-trips to null/empty',
        () {
          const proposal = OrchestrationProposal(
            goal: 'Ship the feature',
            roles: [
              ProposedRole(
                roleKey: 'coder',
                title: 'Coder',
                existingAgentId: 'a1',
              ),
            ],
            subTickets: [
              ProposedSubTicket(
                key: 't1',
                title: 'Do the work',
                roleKey: 'coder',
              ),
            ],
            synthesis: SynthesisSpec(
              roleKey: 'coder',
              prompt: 'Summarize',
              outputSchema: {
                'type': 'object',
                'required': ['summary'],
              },
            ),
          );
          final restored = OrchestrationProposal.fromJsonString(
            proposal.toJsonString(),
          );
          final ticket = restored.subTickets.single;
          expect(ticket.estimate, isNull);
          expect(ticket.provenance, isEmpty);
        },
      );
    },
  );
}
