import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/orchestration/domain/value_objects/plan_annotations.dart';
import 'package:test/test.dart';

/// Round-trip + copyWith coverage for the orchestration proposal value
/// objects. Value identity for the top-level [OrchestrationProposal] is by
/// canonical JSON string, so each block is also exercised through JSON.
ProposedRole _role({
  String roleKey = 'analyst',
  String title = 'Analyst',
  String? existingAgentId,
  ProposedHire? hireSpec,
}) => ProposedRole(
  roleKey: roleKey,
  title: title,
  existingAgentId: existingAgentId,
  hireSpec: hireSpec,
);

void main() {
  group('ProposedRole', () {
    test('toJson omits null existingAgentId / hireSpec', () {
      final json = _role().toJson();
      expect(json, {'roleKey': 'analyst', 'title': 'Analyst'});
      expect(json.containsKey('existingAgentId'), isFalse);
      expect(json.containsKey('hireSpec'), isFalse);
    });

    test('fromJson defaults missing strings to empty', () {
      final r = ProposedRole.fromJson({});
      expect(r.roleKey, '');
      expect(r.title, '');
      expect(r.existingAgentId, isNull);
      expect(r.hireSpec, isNull);
    });

    test('fromJson rebuilds an embedded hireSpec', () {
      final r = ProposedRole.fromJson({
        'roleKey': 'dev',
        'title': 'Dev',
        'hireSpec': {
          'name': 'Sam',
          'title': 'Engineer',
          'skills': ['dart'],
          'role': 'coder',
        },
      });
      expect(r.hireSpec?.name, 'Sam');
      expect(r.hireSpec?.role, 'coder');
    });

    test('copyWith swaps fields and clears on flag', () {
      final base = _role(
        existingAgentId: 'a1',
        hireSpec: const ProposedHire(name: 'n', title: 't'),
      );
      final swapped = base.copyWith(
        title: 'Edited',
        existingAgentId: 'a2',
        hireSpec: const ProposedHire(name: 'n2', title: 't2'),
      );
      expect(swapped.title, 'Edited');
      expect(swapped.existingAgentId, 'a2');
      expect(swapped.hireSpec?.name, 'n2');
      // roleKey is immutable.
      expect(swapped.roleKey, 'analyst');

      final cleared = base.copyWith(
        clearExistingAgentId: true,
        clearHireSpec: true,
      );
      expect(cleared.existingAgentId, isNull);
      expect(cleared.hireSpec, isNull);
    });
  });

  group('ProposedHire', () {
    test('round-trips through JSON, including an optional role', () {
      const hire = ProposedHire(
        name: 'Sam',
        title: 'Engineer',
        skills: ['dart', 'rust'],
        persona: 'A focused builder.',
        role: 'coder',
      );
      final json = hire.toJson();
      expect(json['name'], 'Sam');
      expect(json['skills'], ['dart', 'rust']);
      expect(json['role'], 'coder');
      final rebuilt = ProposedHire.fromJson(json);
      expect(rebuilt.name, 'Sam');
      expect(rebuilt.skills, ['dart', 'rust']);
      expect(rebuilt.persona, 'A focused builder.');
      expect(rebuilt.role, 'coder');
    });

    test('toJson omits a null role', () {
      const hire = ProposedHire(name: 'n', title: 't');
      expect(hire.toJson().containsKey('role'), isFalse);
    });

    test('fromJson tolerates a non-String skills list', () {
      final rebuilt = ProposedHire.fromJson({
        'name': 'n',
        'title': 't',
        'skills': [1, 'ok'],
      });
      expect(rebuilt.skills, ['ok']);
    });
  });

  group('ProposedSubTicket', () {
    const sub = ProposedSubTicket(
      key: 'k1',
      title: 'Do thing',
      roleKey: 'dev',
      description: 'desc',
      dependsOn: ['k0'],
      expectedOutputSchema: {'type': 'object'},
      priority: 'high',
      estimate: PlanNodeEstimate(
        costCentsLow: 10,
        costCentsHigh: 20,
        sampleSize: 5,
        blastRadiusFiles: 3,
      ),
      provenance: [PlanProvenanceRef(kind: 'file', ref: 'a.dart', label: 'A')],
    );

    test('round-trips through JSON', () {
      final rebuilt = ProposedSubTicket.fromJson(sub.toJson());
      expect(rebuilt.key, 'k1');
      expect(rebuilt.title, 'Do thing');
      expect(rebuilt.dependsOn, ['k0']);
      expect(rebuilt.expectedOutputSchema, {'type': 'object'});
      expect(rebuilt.priority, 'high');
      expect(rebuilt.estimate?.costCentsHigh, 20);
      expect(rebuilt.estimate?.blastRadiusFiles, 3);
      expect(rebuilt.provenance.single.kind, 'file');
      expect(rebuilt.provenance.single.ref, 'a.dart');
    });

    test('fromJson defaults missing scalars', () {
      final rebuilt = ProposedSubTicket.fromJson({'key': 'k'});
      expect(rebuilt.title, '');
      expect(rebuilt.description, '');
      expect(rebuilt.dependsOn, isEmpty);
      expect(rebuilt.expectedOutputSchema, isNull);
      expect(rebuilt.priority, 'none');
      expect(rebuilt.estimate, isNull);
      expect(rebuilt.provenance, isEmpty);
    });

    test(
      'toJson omits null expectedOutputSchema / estimate / empty provenance',
      () {
        final json = const ProposedSubTicket(
          key: 'k',
          title: 't',
          roleKey: 'r',
        ).toJson();
        expect(json.containsKey('expectedOutputSchema'), isFalse);
        expect(json.containsKey('estimate'), isFalse);
        expect(json.containsKey('provenance'), isFalse);
      },
    );

    test('copyWith overrides + clears estimate and schema', () {
      final edited = sub.copyWith(
        title: 'Edited',
        roleKey: 'qa',
        description: 'new',
        dependsOn: ['k9'],
        expectedOutputSchema: {'type': 'string'},
        priority: 'urgent',
        provenance: const [PlanProvenanceRef(kind: 'symbol', ref: 's')],
      );
      expect(edited.title, 'Edited');
      expect(edited.roleKey, 'qa');
      expect(edited.dependsOn, ['k9']);
      expect(edited.expectedOutputSchema, {'type': 'string'});
      expect(edited.priority, 'urgent');
      expect(edited.provenance.single.kind, 'symbol');
      // key is immutable.
      expect(edited.key, 'k1');

      final cleared = edited.copyWith(
        clearExpectedOutputSchema: true,
        clearEstimate: true,
      );
      expect(cleared.expectedOutputSchema, isNull);
      expect(cleared.estimate, isNull);
    });
  });

  group('ResearchSpec / DiscussionSpec / SynthesisSpec / BudgetSpec', () {
    test('ResearchSpec round-trips and omits a null roleKey', () {
      const spec = ResearchSpec(enabled: true, prompt: 'go', roleKey: 'lead');
      expect(spec.toJson(), {
        'enabled': true,
        'prompt': 'go',
        'roleKey': 'lead',
      });
      final rebuilt = ResearchSpec.fromJson(spec.toJson());
      expect(rebuilt.enabled, isTrue);
      expect(rebuilt.prompt, 'go');
      expect(rebuilt.roleKey, 'lead');
      // null roleKey omitted.
      expect(
        const ResearchSpec(enabled: false).toJson().containsKey('roleKey'),
        isFalse,
      );
      // fromJson defaults.
      expect(ResearchSpec.fromJson({}).enabled, isFalse);
      expect(ResearchSpec.fromJson({}).prompt, '');
    });

    test('DiscussionSpec round-trips', () {
      const spec = DiscussionSpec(enabled: true, prompt: 'discuss');
      expect(spec.toJson(), {'enabled': true, 'prompt': 'discuss'});
      final rebuilt = DiscussionSpec.fromJson(spec.toJson());
      expect(rebuilt.enabled, isTrue);
      expect(rebuilt.prompt, 'discuss');
      expect(DiscussionSpec.fromJson({}).enabled, isFalse);
    });

    test('SynthesisSpec round-trips and defaults an absent schema to {}', () {
      const spec = SynthesisSpec(
        roleKey: 'lead',
        prompt: 'synthesize',
        outputSchema: {'type': 'object', 'gaps': <String>[]},
      );
      final rebuilt = SynthesisSpec.fromJson(spec.toJson());
      expect(rebuilt.roleKey, 'lead');
      expect(rebuilt.prompt, 'synthesize');
      expect(rebuilt.outputSchema['gaps'], <String>[]);
      // absent schema → empty map, not null.
      final defaulted = SynthesisSpec.fromJson({'roleKey': 'r', 'prompt': 'p'});
      expect(defaulted.outputSchema, isEmpty);
    });

    test('BudgetSpec round-trips and omits null amounts', () {
      const budget = BudgetSpec(estimatedCostCents: 100, maxCostCents: 500);
      expect(budget.toJson(), {'estimatedCostCents': 100, 'maxCostCents': 500});
      final rebuilt = BudgetSpec.fromJson(budget.toJson());
      expect(rebuilt.estimatedCostCents, 100);
      expect(rebuilt.maxCostCents, 500);
      // Null amounts produce an empty object.
      expect(const BudgetSpec().toJson(), isEmpty);
      expect(BudgetSpec.fromJson({}).estimatedCostCents, isNull);
    });
  });

  group('PlanDriftPolicy', () {
    test('fromName parses known names and defaults unknown to annotate', () {
      expect(PlanDriftPolicy.fromName('annotate'), PlanDriftPolicy.annotate);
      expect(
        PlanDriftPolicy.fromName('stopAndAsk'),
        PlanDriftPolicy.stopAndAsk,
      );
      expect(PlanDriftPolicy.fromName('weird'), PlanDriftPolicy.annotate);
      expect(PlanDriftPolicy.fromName(null), PlanDriftPolicy.annotate);
    });
  });

  group('OrchestrationProposal', () {
    final proposal = OrchestrationProposal(
      goal: 'Ship the feature',
      roles: [
        _role(existingAgentId: 'a1'),
        _role(
          roleKey: 'dev',
          title: 'Dev',
          hireSpec: const ProposedHire(name: 'n', title: 't'),
        ),
      ],
      subTickets: const [
        ProposedSubTicket(key: 'k1', title: 'one', roleKey: 'dev'),
        ProposedSubTicket(
          key: 'k2',
          title: 'two',
          roleKey: 'analyst',
          dependsOn: ['k1'],
        ),
      ],
      research: const ResearchSpec(enabled: true, prompt: 'go'),
      discussion: const DiscussionSpec(enabled: false),
      synthesis: const SynthesisSpec(
        roleKey: 'lead',
        prompt: 'synth',
        outputSchema: {'gaps': <String>[]},
      ),
      budget: const BudgetSpec(estimatedCostCents: 50, maxCostCents: 500),
      driftPolicy: PlanDriftPolicy.stopAndAsk,
    );

    test('hireCount counts only roles with a hireSpec', () {
      expect(proposal.hireCount, 1);
    });

    test('JSON string round-trips losslessly', () {
      final rebuilt = OrchestrationProposal.fromJsonString(
        proposal.toJsonString(),
      );
      expect(rebuilt, proposal);
      expect(rebuilt.hashCode, proposal.hashCode);
      expect(rebuilt.goal, 'Ship the feature');
      expect(rebuilt.driftPolicy, PlanDriftPolicy.stopAndAsk);
      expect(rebuilt.roles.length, 2);
      expect(rebuilt.subTickets.length, 2);
    });

    test('fromJson tolerates missing nested maps with defaults', () {
      final rebuilt = OrchestrationProposal.fromJson({'goal': 'g'});
      expect(rebuilt.goal, 'g');
      expect(rebuilt.roles, isEmpty);
      expect(rebuilt.subTickets, isEmpty);
      expect(rebuilt.research.enabled, isFalse);
      expect(rebuilt.discussion.enabled, isFalse);
      expect(rebuilt.synthesis.outputSchema, isEmpty);
      expect(rebuilt.budget.estimatedCostCents, isNull);
      expect(rebuilt.driftPolicy, PlanDriftPolicy.annotate);
    });

    test('equality is by canonical serialized form', () {
      final copy = OrchestrationProposal.fromJsonString(
        proposal.toJsonString(),
      );
      expect(copy == proposal, isTrue);
      expect(copy.hashCode, proposal.hashCode);
      final different = proposal.copyWith(goal: 'Other goal');
      expect(different == proposal, isFalse);
    });

    test('copyWith overrides each parameter', () {
      final next = proposal.copyWith(
        goal: 'new goal',
        roles: [_role(roleKey: 'solo', title: 'Solo')],
        subTickets: const [
          ProposedSubTicket(key: 'only', title: 'one', roleKey: 'solo'),
        ],
        synthesis: const SynthesisSpec(
          roleKey: 'lead',
          prompt: 'new',
          outputSchema: {},
        ),
        budget: const BudgetSpec(maxCostCents: 1),
        research: const ResearchSpec(enabled: false),
        discussion: const DiscussionSpec(enabled: true, prompt: 'now'),
        driftPolicy: PlanDriftPolicy.annotate,
      );
      expect(next.goal, 'new goal');
      expect(next.roles.single.roleKey, 'solo');
      expect(next.subTickets.single.key, 'only');
      expect(next.synthesis.prompt, 'new');
      expect(next.budget.maxCostCents, 1);
      expect(next.research.enabled, isFalse);
      expect(next.discussion.enabled, isTrue);
      expect(next.driftPolicy, PlanDriftPolicy.annotate);
      // hireCount recomputed.
      expect(next.hireCount, 0);
    });

    test('a no-op copy is equal to the original', () {
      expect(proposal.copyWith(), proposal);
    });
  });

  group('PlanNodeEstimate / PlanProvenanceRef', () {
    test('PlanNodeEstimate.hasHistory is sampleSize > 0', () {
      expect(const PlanNodeEstimate().hasHistory, isFalse);
      expect(const PlanNodeEstimate(sampleSize: 3).hasHistory, isTrue);
    });

    test('PlanNodeEstimate omits null numeric fields', () {
      final json = const PlanNodeEstimate(
        costCentsLow: 1,
        sampleSize: 2,
      ).toJson();
      expect(json['costCentsLow'], 1);
      expect(json['sampleSize'], 2);
      expect(json.containsKey('costCentsHigh'), isFalse);
      expect(json.containsKey('blastRadiusFiles'), isFalse);
    });

    test('PlanProvenanceRef equality + JSON round-trip', () {
      const ref = PlanProvenanceRef(kind: 'file', ref: 'a.dart', label: 'A');
      const same = PlanProvenanceRef(kind: 'file', ref: 'a.dart', label: 'A');
      expect(ref, same);
      expect(ref.hashCode, same.hashCode);
      expect(ref.toJson(), {'kind': 'file', 'ref': 'a.dart', 'label': 'A'});
      // null label omitted.
      expect(
        const PlanProvenanceRef(
          kind: 'k',
          ref: 'r',
        ).toJson().containsKey('label'),
        isFalse,
      );
      final rebuilt = PlanProvenanceRef.fromJson({
        'kind': 'file',
        'ref': 'a.dart',
        'label': 'A',
      });
      expect(rebuilt, ref);
    });
  });
}
