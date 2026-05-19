import 'package:cc_domain/features/pr_review/domain/services/api_contract_differ.dart';
import 'package:cc_domain/features/pr_review/domain/services/cohort_grouper.dart';
import 'package:cc_domain/features/pr_review/domain/services/diagram_verifier.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/api_contract_diff.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_cohort.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_diagram.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_verdict.dart';
import 'package:test/test.dart';

void main() {
  group('CohortGrouper', () {
    const grouper = CohortGrouper();

    test(
      'groups connected files into one cohort, unconnected into another',
      () {
        final drafts = grouper.group(
          files: const [
            CohortFileInput(path: 'lib/features/auth/login.dart'),
            CohortFileInput(path: 'lib/features/auth/token.dart'),
            CohortFileInput(path: 'lib/features/billing/invoice.dart'),
          ],
          links: const [
            (
              a: 'lib/features/auth/login.dart',
              b: 'lib/features/auth/token.dart',
            ),
          ],
          derivation: CohortDerivation.graph,
        );
        // auth login+token connect into one cohort; billing stands alone.
        expect(drafts.length, 2);
        final auth = drafts.firstWhere((d) => d.filePaths.length == 2);
        expect(
          auth.filePaths,
          containsAll(<String>[
            'lib/features/auth/login.dart',
            'lib/features/auth/token.dart',
          ]),
        );
      },
    );

    test('cohort key is stable across pushes (same members, moved lines)', () {
      List<CohortDraft> run() => grouper.group(
        files: const [
          CohortFileInput(path: 'a.dart', dominantSymbol: 'Auth.login'),
          CohortFileInput(path: 'b.dart', dominantSymbol: 'Auth.token'),
        ],
        links: const [(a: 'a.dart', b: 'b.dart')],
        derivation: CohortDerivation.graph,
      );
      expect(run().single.cohortKey, run().single.cohortKey);
    });

    test('same-basename files in different dirs get distinct cohort keys', () {
      // Regression: golden-master PRs change many files that share a basename
      // across version directories. Each is its own (unindexed, unlinked)
      // cohort; keying on the basename alone collided them and failed the
      // `(prNodeId, cohortKey)` unique insert.
      final drafts = grouper.group(
        files: const [
          CohortFileInput(path: 'golden/v1/user/info/get_user_info.json'),
          CohortFileInput(path: 'golden/v2/user/info/get_user_info.json'),
        ],
        links: const [],
        derivation: CohortDerivation.graph,
      );
      expect(drafts, hasLength(2));
      expect(
        drafts.map((d) => d.cohortKey).toSet(),
        hasLength(2),
        reason: 'each cohort must have a unique key',
      );
    });

    test('same dominant symbol in unconnected files gets distinct keys', () {
      // Qualified names are not path-scoped (two files can each own a
      // top-level `main`), so symbol-derived keys collided too.
      final drafts = grouper.group(
        files: const [
          CohortFileInput(path: 'a/tool.dart', dominantSymbol: 'main'),
          CohortFileInput(path: 'b/tool.dart', dominantSymbol: 'main'),
        ],
        links: const [],
        derivation: CohortDerivation.graph,
      );
      expect(drafts, hasLength(2));
      expect(drafts.map((d) => d.cohortKey).toSet(), hasLength(2));
    });

    test('impact-ranks cohorts (highest impact reads first)', () {
      final drafts = grouper.group(
        files: const [
          CohortFileInput(path: 'low.dart', impactWeight: 1),
          CohortFileInput(path: 'high.dart', impactWeight: 50),
        ],
        links: const [],
        derivation: CohortDerivation.graph,
      );
      expect(drafts.first.filePaths, ['high.dart']);
      expect(drafts.first.orderIndex, 0);
    });

    test('path derivation is recorded honestly', () {
      final drafts = grouper.group(
        files: const [CohortFileInput(path: 'x/y.dart')],
        links: const [],
        derivation: CohortDerivation.path,
      );
      expect(drafts.single.derivation, CohortDerivation.path);
      expect(drafts.single.cohortKey, startsWith('p-'));
    });
  });

  group('DiagramVerifier', () {
    const verifier = DiagramVerifier();

    test('flags an edge the graph does not corroborate', () {
      const diagram = SequenceDiagram(
        title: 't',
        participants: ['A', 'B', 'C'],
        messages: [
          SequenceMessage(from: 'A', to: 'B', label: 'real'),
          SequenceMessage(from: 'B', to: 'C', label: 'hallucinated'),
        ],
      );
      final keys = {DiagramVerifier.edgeKey('A', 'B')};
      final verified = verifier.verify(diagram, keys) as SequenceDiagram;
      expect(verified.messages[0].corroborated, isTrue);
      expect(verified.messages[1].corroborated, isFalse);
      expect(verified.isFullyCorroborated, isFalse);
    });

    test('drops uncorroborated edges in strict mode', () {
      const diagram = SequenceDiagram(
        title: 't',
        participants: ['A', 'B'],
        messages: [SequenceMessage(from: 'A', to: 'B', label: 'ghost')],
      );
      final verified =
          verifier.verify(diagram, const {}, dropUncorroborated: true)
              as SequenceDiagram;
      expect(verified.messages, isEmpty);
    });
  });

  group('OpenApiContractDiffer', () {
    const differ = OpenApiContractDiffer();

    test('classifies a removed endpoint as breaking', () {
      final changes = differ.diff(
        {
          'paths': {
            '/users': {'get': <String, dynamic>{}},
          },
        },
        {'paths': <String, dynamic>{}},
      );
      expect(changes, hasLength(1));
      expect(changes.single.kind, ApiChangeKind.endpointRemoved);
      expect(changes.single.severity, ApiChangeSeverity.breaking);
    });

    test('a new required param is breaking; optional is not', () {
      final breaking = differ.diff(
        {
          'paths': {
            '/x': {'get': <String, dynamic>{}},
          },
        },
        {
          'paths': {
            '/x': {
              'get': {
                'parameters': [
                  {'name': 'q', 'in': 'query', 'required': true},
                ],
              },
            },
          },
        },
      );
      expect(breaking.single.severity, ApiChangeSeverity.breaking);

      final optional = differ.diff(
        {
          'paths': {
            '/x': {'get': <String, dynamic>{}},
          },
        },
        {
          'paths': {
            '/x': {
              'get': {
                'parameters': [
                  {'name': 'q', 'in': 'query', 'required': false},
                ],
              },
            },
          },
        },
      );
      expect(optional.single.severity, ApiChangeSeverity.nonBreaking);
    });

    test('a new endpoint is non-breaking', () {
      final changes = differ.diff(
        {'paths': <String, dynamic>{}},
        {
          'paths': {
            '/new': {'post': <String, dynamic>{}},
          },
        },
      );
      expect(changes.single.kind, ApiChangeKind.endpointAdded);
      expect(changes.single.severity, ApiChangeSeverity.nonBreaking);
    });
  });

  group('ReviewVerdict.withAxisResults (honest aggregation)', () {
    const shipBase = ReviewVerdict(
      overall: ReviewVerdictOverall.ship,
      confidence: 1,
      explanation: '',
      counts: {},
    );

    ReviewAxisResult axis(ReviewAxisVerdict v, {bool gated = true}) =>
        ReviewAxisResult(
          axis: ReviewAxis.visual,
          verdict: v,
          findingsCount: 0,
          gated: gated,
          confidence: 1,
        );

    test('a gated fail forces block', () {
      final r = shipBase.withAxisResults([axis(ReviewAxisVerdict.fail)]);
      expect(r.overall, ReviewVerdictOverall.block);
    });

    test('a gated unavailable holds (never greens)', () {
      final r = shipBase.withAxisResults([axis(ReviewAxisVerdict.unavailable)]);
      expect(r.overall, ReviewVerdictOverall.hold);
    });

    test('a gated partial holds', () {
      final r = shipBase.withAxisResults([axis(ReviewAxisVerdict.partial)]);
      expect(r.overall, ReviewVerdictOverall.hold);
    });

    test('a passing gated axis leaves ship', () {
      final r = shipBase.withAxisResults([axis(ReviewAxisVerdict.pass)]);
      expect(r.overall, ReviewVerdictOverall.ship);
    });

    test('an ungated unavailable axis does not hold', () {
      final r = shipBase.withAxisResults([
        axis(ReviewAxisVerdict.unavailable, gated: false),
      ]);
      expect(r.overall, ReviewVerdictOverall.ship);
    });
  });

  group('ApiContractDiff gate', () {
    test('an unresolved breaking change blocks the gate', () {
      const diff = ApiContractDiff(
        id: 'd',
        workspaceId: 'w',
        repoId: 'r',
        prNodeId: 'p',
        specPath: 'openapi.yaml',
        changes: [
          ApiContractChange(
            id: 'c',
            kind: ApiChangeKind.endpointRemoved,
            severity: ApiChangeSeverity.breaking,
            path: '/x',
          ),
        ],
      );
      expect(diff.blocksGate, isTrue);
      expect(
        diff.withChangeDecision('c', ApiChangeDecision.approved).blocksGate,
        isFalse,
      );
      expect(
        diff.withChangeDecision('c', ApiChangeDecision.rejected).blocksGate,
        isTrue,
      );
    });

    test('a derived contract never gates', () {
      const diff = ApiContractDiff(
        id: 'd',
        workspaceId: 'w',
        repoId: 'r',
        prNodeId: 'p',
        specPath: 'derived',
        derived: true,
        changes: [
          ApiContractChange(
            id: 'c',
            kind: ApiChangeKind.endpointRemoved,
            severity: ApiChangeSeverity.breaking,
            path: '/x',
          ),
        ],
      );
      expect(diff.blocksGate, isFalse);
    });
  });

  group('ReviewCohort round-trip', () {
    test('serializes and parses with diagrams + layers', () {
      const cohort = ReviewCohort(
        id: 'id',
        workspaceId: 'w',
        prNodeId: 'p',
        cohortKey: 'g-abc',
        title: 'Auth flow',
        orderIndex: 0,
        impactScore: 3,
        derivation: CohortDerivation.graph,
        filePaths: ['a.dart'],
        layers: [CohortLayer(title: 'a', filePath: 'a.dart')],
        diagrams: [
          SequenceDiagram(
            title: 'flow',
            participants: ['A', 'B'],
            messages: [SequenceMessage(from: 'A', to: 'B', label: 'x')],
          ),
        ],
      );
      final parsed = ReviewCohort.fromJson(cohort.toJson());
      expect(parsed, cohort);
      expect(parsed.diagrams.single, isA<SequenceDiagram>());
    });
  });
}
