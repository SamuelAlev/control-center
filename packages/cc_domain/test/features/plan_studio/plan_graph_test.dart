import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/orchestration/domain/value_objects/plan_annotations.dart';
import 'package:cc_domain/features/plan_studio/domain/value_objects/plan_graph.dart';
import 'package:test/test.dart';

void main() {
  group('PlanNode', () {
    test('JSON round-trip preserves plain fields', () {
      const node = PlanNode(
        key: 'n1',
        title: 'Do the thing',
        type: PlanNodeType.work,
        roleKey: 'coder',
        description: 'Implement the feature',
        dependsOn: ['n0'],
        expectedOutputSchema: {
          'type': 'object',
          'properties': {'ok': 'bool'},
        },
        priority: 'high',
      );
      final restored = PlanNode.fromJson(node.toJson());
      expect(restored.key, node.key);
      expect(restored.title, node.title);
      expect(restored.type, node.type);
      expect(restored.roleKey, node.roleKey);
      expect(restored.description, node.description);
      expect(restored.dependsOn, node.dependsOn);
      expect(restored.expectedOutputSchema, node.expectedOutputSchema);
      expect(restored.priority, node.priority);
    });

    test('JSON round-trip preserves estimate and provenance', () {
      const node = PlanNode(
        key: 'n1',
        title: 'Do the thing',
        type: PlanNodeType.work,
        estimate: PlanNodeEstimate(
          costCentsLow: 100,
          costCentsHigh: 200,
          durationMsLow: 1000,
          durationMsHigh: 2000,
          sampleSize: 3,
          blastRadiusFiles: 5,
          blastRadiusSymbols: 9,
        ),
        provenance: [
          PlanProvenanceRef(kind: 'file', ref: 'lib/a.dart', label: 'a.dart'),
          PlanProvenanceRef(kind: 'symbol', ref: 'Foo.bar'),
        ],
      );
      final restored = PlanNode.fromJson(node.toJson());
      expect(restored.estimate?.costCentsLow, 100);
      expect(restored.estimate?.costCentsHigh, 200);
      expect(restored.estimate?.durationMsLow, 1000);
      expect(restored.estimate?.durationMsHigh, 2000);
      expect(restored.estimate?.sampleSize, 3);
      expect(restored.estimate?.blastRadiusFiles, 5);
      expect(restored.estimate?.blastRadiusSymbols, 9);
      expect(restored.provenance, hasLength(2));
      expect(restored.provenance[0], node.provenance[0]);
      expect(restored.provenance[1], node.provenance[1]);
    });

    test('JSON round-trip with no estimate/provenance omits the keys', () {
      const node = PlanNode(key: 'n1', title: 't', type: PlanNodeType.work);
      final json = node.toJson();
      expect(json.containsKey('estimate'), isFalse);
      expect(json.containsKey('provenance'), isFalse);
      final restored = PlanNode.fromJson(json);
      expect(restored.estimate, isNull);
      expect(restored.provenance, isEmpty);
    });

    test('fromJson defaults missing/malformed fields', () {
      final restored = PlanNode.fromJson(const {});
      expect(restored.key, '');
      expect(restored.title, '');
      expect(restored.type, PlanNodeType.work);
      expect(restored.roleKey, isNull);
      expect(restored.description, '');
      expect(restored.dependsOn, isEmpty);
      expect(restored.priority, 'none');
    });

    test('toSubTicket throws for a structural (non-work) node', () {
      const node = PlanNode(
        key: PlanGraph.researchKey,
        title: 'Research',
        type: PlanNodeType.research,
      );
      expect(() => node.toSubTicket(), throwsStateError);
    });

    test('toSubTicket/fromSubTicket round-trip for a work node', () {
      const ticket = ProposedSubTicket(
        key: 'k1',
        title: 'Ticket 1',
        roleKey: 'coder',
        description: 'desc',
        dependsOn: ['k0'],
        priority: 'urgent',
      );
      final node = PlanNode.fromSubTicket(ticket);
      expect(node.isWork, isTrue);
      final back = node.toSubTicket();
      expect(back.key, ticket.key);
      expect(back.title, ticket.title);
      expect(back.roleKey, ticket.roleKey);
      expect(back.description, ticket.description);
      expect(back.dependsOn, ticket.dependsOn);
      expect(back.priority, ticket.priority);
    });

    test('copyWith preserves identity (key/type) and applies edits', () {
      const node = PlanNode(key: 'n1', title: 't', type: PlanNodeType.work);
      final edited = node.copyWith(title: 't2', priority: 'low');
      expect(edited.key, 'n1');
      expect(edited.type, PlanNodeType.work);
      expect(edited.title, 't2');
      expect(edited.priority, 'low');
    });
  });

  group('PlanNodeType.fromName', () {
    test('parses known names', () {
      expect(PlanNodeType.fromName('research'), PlanNodeType.research);
      expect(PlanNodeType.fromName('work'), PlanNodeType.work);
      expect(PlanNodeType.fromName('discussion'), PlanNodeType.discussion);
      expect(PlanNodeType.fromName('synthesis'), PlanNodeType.synthesis);
    });

    test('defaults to work for unknown/null names', () {
      expect(PlanNodeType.fromName('bogus'), PlanNodeType.work);
      expect(PlanNodeType.fromName(null), PlanNodeType.work);
    });
  });

  group('PlanGraph.edges', () {
    test('derives edges from dependsOn', () {
      const graph = PlanGraph(
        nodes: [
          PlanNode(key: 'a', title: 'A', type: PlanNodeType.work),
          PlanNode(
            key: 'b',
            title: 'B',
            type: PlanNodeType.work,
            dependsOn: ['a'],
          ),
          PlanNode(
            key: 'c',
            title: 'C',
            type: PlanNodeType.work,
            dependsOn: ['a', 'b'],
          ),
        ],
      );
      final edges = graph.edges;
      expect(edges, hasLength(3));
      expect(edges, contains((from: 'a', to: 'b')));
      expect(edges, contains((from: 'a', to: 'c')));
      expect(edges, contains((from: 'b', to: 'c')));
    });

    test('is empty for a graph with no dependencies', () {
      const graph = PlanGraph(
        nodes: [PlanNode(key: 'a', title: 'A', type: PlanNodeType.work)],
      );
      expect(graph.edges, isEmpty);
    });
  });

  group('PlanGraph JSON round-trip', () {
    test('round-trips a multi-node graph', () {
      const graph = PlanGraph(
        nodes: [
          PlanNode(key: 'a', title: 'A', type: PlanNodeType.work),
          PlanNode(
            key: 'b',
            title: 'B',
            type: PlanNodeType.work,
            dependsOn: ['a'],
            estimate: PlanNodeEstimate(sampleSize: 2, costCentsLow: 1),
          ),
        ],
      );
      final restored = PlanGraph.fromJson(graph.toJson());
      expect(restored.nodes, hasLength(2));
      expect(restored.node('a')?.key, 'a');
      expect(restored.node('b')?.dependsOn, ['a']);
      expect(restored.node('b')?.estimate?.sampleSize, 2);
    });

    test('fromJson defaults to an empty node list', () {
      expect(PlanGraph.fromJson(const {}).nodes, isEmpty);
    });
  });

  group('PlanGraph.node', () {
    test('finds an existing node, returns null otherwise', () {
      const graph = PlanGraph(
        nodes: [PlanNode(key: 'a', title: 'A', type: PlanNodeType.work)],
      );
      expect(graph.node('a'), isNotNull);
      expect(graph.node('missing'), isNull);
    });
  });

  group('PlanGraph.workNodes', () {
    test('excludes structural nodes', () {
      const graph = PlanGraph(
        nodes: [
          PlanNode(
            key: PlanGraph.researchKey,
            title: 'Research',
            type: PlanNodeType.research,
          ),
          PlanNode(key: 'w1', title: 'Work 1', type: PlanNodeType.work),
          PlanNode(
            key: PlanGraph.synthesisKey,
            title: 'Synthesis',
            type: PlanNodeType.synthesis,
          ),
        ],
      );
      expect(graph.workNodes.map((n) => n.key), ['w1']);
    });
  });

  group('PlanGraph.subtree', () {
    test('returns the node plus its transitive dependents only', () {
      // a -> b -> c, plus an unrelated node d.
      const graph = PlanGraph(
        nodes: [
          PlanNode(key: 'a', title: 'A', type: PlanNodeType.work),
          PlanNode(
            key: 'b',
            title: 'B',
            type: PlanNodeType.work,
            dependsOn: ['a'],
          ),
          PlanNode(
            key: 'c',
            title: 'C',
            type: PlanNodeType.work,
            dependsOn: ['b'],
          ),
          PlanNode(key: 'd', title: 'D', type: PlanNodeType.work),
        ],
      );
      expect(graph.subtree('a'), {'a', 'b', 'c'});
      expect(graph.subtree('b'), {'b', 'c'});
      expect(graph.subtree('c'), {'c'});
      expect(graph.subtree('d'), {'d'});
    });

    test('does not pull in ancestors, only descendants', () {
      const graph = PlanGraph(
        nodes: [
          PlanNode(key: 'a', title: 'A', type: PlanNodeType.work),
          PlanNode(
            key: 'b',
            title: 'B',
            type: PlanNodeType.work,
            dependsOn: ['a'],
          ),
        ],
      );
      expect(graph.subtree('b'), {'b'});
    });

    test('handles a diamond without duplicating shared descendants', () {
      // a -> b, a -> c, b -> d, c -> d
      const graph = PlanGraph(
        nodes: [
          PlanNode(key: 'a', title: 'A', type: PlanNodeType.work),
          PlanNode(
            key: 'b',
            title: 'B',
            type: PlanNodeType.work,
            dependsOn: ['a'],
          ),
          PlanNode(
            key: 'c',
            title: 'C',
            type: PlanNodeType.work,
            dependsOn: ['a'],
          ),
          PlanNode(
            key: 'd',
            title: 'D',
            type: PlanNodeType.work,
            dependsOn: ['b', 'c'],
          ),
        ],
      );
      expect(graph.subtree('a'), {'a', 'b', 'c', 'd'});
    });
  });

  group('PlanGraph.validate', () {
    test('passes a valid DAG', () {
      const graph = PlanGraph(
        nodes: [
          PlanNode(key: 'a', title: 'A', type: PlanNodeType.work),
          PlanNode(
            key: 'b',
            title: 'B',
            type: PlanNodeType.work,
            dependsOn: ['a'],
          ),
        ],
      );
      expect(graph.validate(), isEmpty);
    });

    test('flags an empty key', () {
      const graph = PlanGraph(
        nodes: [PlanNode(key: '', title: 'A', type: PlanNodeType.work)],
      );
      expect(graph.validate(), contains('A node has an empty key.'));
    });

    test('flags a duplicate key', () {
      const graph = PlanGraph(
        nodes: [
          PlanNode(key: 'a', title: 'A', type: PlanNodeType.work),
          PlanNode(key: 'a', title: 'A again', type: PlanNodeType.work),
        ],
      );
      expect(graph.validate(), contains('Duplicate node key: a.'));
    });

    test('flags a dangling dependency', () {
      const graph = PlanGraph(
        nodes: [
          PlanNode(
            key: 'a',
            title: 'A',
            type: PlanNodeType.work,
            dependsOn: ['ghost'],
          ),
        ],
      );
      expect(
        graph.validate(),
        contains('Node a depends on unknown node ghost.'),
      );
    });

    test('flags a self-dependency', () {
      const graph = PlanGraph(
        nodes: [
          PlanNode(
            key: 'a',
            title: 'A',
            type: PlanNodeType.work,
            dependsOn: ['a'],
          ),
        ],
      );
      expect(graph.validate(), contains('Node a depends on itself.'));
    });

    test('flags a cycle in an otherwise well-formed graph', () {
      const graph = PlanGraph(
        nodes: [
          PlanNode(
            key: 'a',
            title: 'A',
            type: PlanNodeType.work,
            dependsOn: ['b'],
          ),
          PlanNode(
            key: 'b',
            title: 'B',
            type: PlanNodeType.work,
            dependsOn: ['a'],
          ),
        ],
      );
      expect(
        graph.validate(),
        contains('The dependency graph contains a cycle.'),
      );
    });

    test('a longer cycle (a -> b -> c -> a) is also caught', () {
      const graph = PlanGraph(
        nodes: [
          PlanNode(
            key: 'a',
            title: 'A',
            type: PlanNodeType.work,
            dependsOn: ['c'],
          ),
          PlanNode(
            key: 'b',
            title: 'B',
            type: PlanNodeType.work,
            dependsOn: ['a'],
          ),
          PlanNode(
            key: 'c',
            title: 'C',
            type: PlanNodeType.work,
            dependsOn: ['b'],
          ),
        ],
      );
      expect(
        graph.validate(),
        contains('The dependency graph contains a cycle.'),
      );
    });

    test('does not run the cycle check when structural errors exist', () {
      // Dangling dep short-circuits the cycle check (errors.isEmpty guard).
      const graph = PlanGraph(
        nodes: [
          PlanNode(
            key: 'a',
            title: 'A',
            type: PlanNodeType.work,
            dependsOn: ['ghost'],
          ),
        ],
      );
      final errors = graph.validate();
      expect(errors, isNot(contains('The dependency graph contains a cycle.')));
    });
  });

  group('PlanGraph.fromProposal', () {
    OrchestrationProposal buildProposal({
      bool researchEnabled = false,
      bool discussionEnabled = false,
    }) => OrchestrationProposal(
      goal: 'Ship the feature',
      roles: const [
        ProposedRole(
          roleKey: 'coder',
          title: 'Coder',
          existingAgentId: 'agent-coder',
        ),
        ProposedRole(
          roleKey: 'reviewer',
          title: 'Reviewer',
          existingAgentId: 'agent-reviewer',
        ),
      ],
      subTickets: const [
        // Root: no explicit deps -> should be gated by research.
        ProposedSubTicket(key: 'root1', title: 'Root 1', roleKey: 'coder'),
        // Another root.
        ProposedSubTicket(key: 'root2', title: 'Root 2', roleKey: 'coder'),
        // Depends on root1 -> a REAL edge, never touched by gating.
        ProposedSubTicket(
          key: 'dependent',
          title: 'Dependent',
          roleKey: 'reviewer',
          dependsOn: ['root1'],
        ),
      ],
      research: ResearchSpec(
        enabled: researchEnabled,
        prompt: 'Investigate',
        roleKey: 'coder',
      ),
      discussion: DiscussionSpec(enabled: discussionEnabled, prompt: 'Discuss'),
      synthesis: const SynthesisSpec(
        roleKey: 'reviewer',
        prompt: 'Summarize',
        outputSchema: {
          'type': 'object',
          'required': ['summary'],
        },
      ),
    );

    test('with research: gates dependency-less work nodes only', () {
      final graph = PlanGraph.fromProposal(
        buildProposal(researchEnabled: true),
      );

      final research = graph.node(PlanGraph.researchKey);
      expect(research, isNotNull);
      expect(research!.type, PlanNodeType.research);

      final root1 = graph.node('root1')!;
      final root2 = graph.node('root2')!;
      expect(root1.dependsOn, [PlanGraph.researchKey]);
      expect(root2.dependsOn, [PlanGraph.researchKey]);

      // The real work-to-work edge is untouched by gating.
      final dependent = graph.node('dependent')!;
      expect(dependent.dependsOn, ['root1']);
    });

    test('synthesis depends on ALL work nodes, not just roots', () {
      final graph = PlanGraph.fromProposal(
        buildProposal(researchEnabled: true),
      );
      final synthesis = graph.node(PlanGraph.synthesisKey)!;
      expect(synthesis.type, PlanNodeType.synthesis);
      expect(synthesis.dependsOn.toSet(), {'root1', 'root2', 'dependent'});
    });

    test('discussion nodes (one per role) depend on research when enabled', () {
      final graph = PlanGraph.fromProposal(
        buildProposal(researchEnabled: true, discussionEnabled: true),
      );
      final coderDiscussion = graph.node(
        '${PlanGraph.discussionKeyPrefix}coder',
      )!;
      final reviewerDiscussion = graph.node(
        '${PlanGraph.discussionKeyPrefix}reviewer',
      )!;
      expect(coderDiscussion.type, PlanNodeType.discussion);
      expect(coderDiscussion.dependsOn, [PlanGraph.researchKey]);
      expect(reviewerDiscussion.dependsOn, [PlanGraph.researchKey]);
    });

    test('no research -> no gating and no research node', () {
      final graph = PlanGraph.fromProposal(buildProposal());
      expect(graph.node(PlanGraph.researchKey), isNull);

      final root1 = graph.node('root1')!;
      final root2 = graph.node('root2')!;
      expect(root1.dependsOn, isEmpty);
      expect(root2.dependsOn, isEmpty);

      final dependent = graph.node('dependent')!;
      expect(dependent.dependsOn, ['root1']);
    });

    test(
      'no research, discussion enabled -> discussion nodes have no deps',
      () {
        final graph = PlanGraph.fromProposal(
          buildProposal(discussionEnabled: true),
        );
        final coderDiscussion = graph.node(
          '${PlanGraph.discussionKeyPrefix}coder',
        )!;
        expect(coderDiscussion.dependsOn, isEmpty);
      },
    );

    test('discussion disabled -> no discussion nodes are added', () {
      final graph = PlanGraph.fromProposal(
        buildProposal(researchEnabled: true),
      );
      expect(
        graph.nodes.where((n) => n.type == PlanNodeType.discussion),
        isEmpty,
      );
    });
  });

  group('PlanGraph.applyToProposal', () {
    test(
      'round-trips work nodes and strips the injected research gating edge',
      () {
        const original = OrchestrationProposal(
          goal: 'Ship the feature',
          roles: [
            ProposedRole(
              roleKey: 'coder',
              title: 'Coder',
              existingAgentId: 'agent-coder',
            ),
          ],
          subTickets: [
            ProposedSubTicket(key: 'root1', title: 'Root 1', roleKey: 'coder'),
            ProposedSubTicket(
              key: 'dependent',
              title: 'Dependent',
              roleKey: 'coder',
              dependsOn: ['root1'],
            ),
          ],
          research: ResearchSpec(
            enabled: true,
            prompt: 'Investigate',
            roleKey: 'coder',
          ),
          synthesis: SynthesisSpec(
            roleKey: 'coder',
            prompt: 'Summarize',
            outputSchema: {
              'type': 'object',
              'required': ['summary'],
            },
          ),
        );

        final graph = PlanGraph.fromProposal(original);
        // Sanity: research gating was injected on the root.
        expect(graph.node('root1')!.dependsOn, [PlanGraph.researchKey]);

        final result = graph.applyToProposal(original);

        expect(result.subTickets, hasLength(2));
        final root1 = result.subTickets.firstWhere((t) => t.key == 'root1');
        final dependent = result.subTickets.firstWhere(
          (t) => t.key == 'dependent',
        );

        // The injected __research edge must be gone.
        expect(root1.dependsOn, isEmpty);
        // The real work-to-work edge must survive.
        expect(dependent.dependsOn, ['root1']);

        // The frame (research/discussion/synthesis) is untouched by apply.
        expect(result.research.enabled, original.research.enabled);
        expect(result.synthesis.roleKey, original.synthesis.roleKey);
        expect(result.goal, original.goal);
        expect(result.roles, original.roles);
      },
    );

    test('without research, applyToProposal is a clean pass-through', () {
      const original = OrchestrationProposal(
        goal: 'Ship the feature',
        roles: [
          ProposedRole(
            roleKey: 'coder',
            title: 'Coder',
            existingAgentId: 'agent-coder',
          ),
        ],
        subTickets: [
          ProposedSubTicket(key: 'root1', title: 'Root 1', roleKey: 'coder'),
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
      final graph = PlanGraph.fromProposal(original);
      final result = graph.applyToProposal(original);
      expect(result.subTickets, hasLength(1));
      expect(result.subTickets.single.dependsOn, isEmpty);
    });
  });
}
