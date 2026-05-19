import 'package:cc_domain/features/pr_review/domain/services/impact_mermaid_builder.dart';
import 'package:test/test.dart';

final labels = ImpactGraphLabels(
  changed: 'Changed in this PR',
  hop: (h) => '$h hop(s) away',
  more: (file, hidden) => '$hidden more in $file',
);

CohortImpactGraph graph({
  required List<Map<String, dynamic>> nodes,
  List<Map<String, dynamic>> edges = const [],
  List<String> roots = const [],
  bool indexed = true,
}) => CohortImpactGraph.fromWire({
  'indexed': indexed,
  'roots': roots,
  'nodes': nodes,
  'edges': edges,
});

void main() {
  const builder = ImpactMermaidBuilder();

  group('ImpactMermaidBuilder', () {
    test('renders nothing for an empty graph', () {
      expect(
        builder.buildFlowchart(graph(nodes: const []), labels: labels),
        isEmpty,
      );
    });

    test('emits a right-to-left flowchart with hop subgraphs', () {
      final source = builder.buildFlowchart(
        graph(
          roots: const ['s1'],
          nodes: const [
            {
              'id': 's1',
              'name': 'refresh',
              'filePath': 'lib/auth.dart',
              'depth': 0,
            },
            {
              'id': 's2',
              'name': 'login',
              'filePath': 'lib/ui.dart',
              'depth': 1,
            },
          ],
          edges: const [
            {'source': 's2', 'target': 's1', 'kind': 'calls'},
          ],
        ),
        labels: labels,
      );
      expect(source, startsWith('flowchart RL'));
      expect(source, contains('Changed in this PR'));
      expect(source, contains('1 hop(s) away'));
      expect(source, contains('refresh'));
      expect(source, contains('-->'));
    });

    test('gives root nodes a distinct shape rather than a color', () {
      final source = builder.buildFlowchart(
        graph(
          roots: const ['s1'],
          nodes: const [
            {
              'id': 's1',
              'name': 'refresh',
              'filePath': 'lib/a.dart',
              'depth': 0,
            },
            {
              'id': 's2',
              'name': 'caller',
              'filePath': 'lib/b.dart',
              'depth': 1,
            },
          ],
        ),
        labels: labels,
      );
      // Stadium shape for the root, plain box for the dependent.
      expect(source, contains('(["refresh'));
      expect(source, contains('["caller'));
      // No theming directives — CcMermaidView ignores them by design.
      expect(source, isNot(contains('classDef')));
      expect(source, isNot(contains('style ')));
    });

    test('is deterministic across equivalent inputs', () {
      final a = builder.buildFlowchart(
        graph(
          nodes: const [
            {'id': 's2', 'name': 'b', 'filePath': 'lib/b.dart', 'depth': 1},
            {'id': 's1', 'name': 'a', 'filePath': 'lib/a.dart', 'depth': 0},
          ],
        ),
        labels: labels,
      );
      final b = builder.buildFlowchart(
        graph(
          nodes: const [
            {'id': 's1', 'name': 'a', 'filePath': 'lib/a.dart', 'depth': 0},
            {'id': 's2', 'name': 'b', 'filePath': 'lib/b.dart', 'depth': 1},
          ],
        ),
        labels: labels,
      );
      expect(a, b);
    });

    test('escapes characters that would break a node label', () {
      final source = builder.buildFlowchart(
        graph(
          nodes: const [
            {
              'id': 's1',
              'name': 'Map<String, List[int]>',
              'filePath': 'lib/a.dart',
              'depth': 0,
            },
          ],
        ),
        labels: labels,
      );
      expect(source, isNot(contains('List[int]')));
      expect(source, isNot(contains('<String')));
      // The label still renders its two lines via a break, not a raw newline.
      expect(source, contains('<br/>'));
    });

    test('collapses the overflow by file instead of truncating silently', () {
      final nodes = [
        for (var i = 0; i < 8; i++)
          {
            'id': 's$i',
            'name': 'sym$i',
            'filePath': i < 2 ? 'lib/kept.dart' : 'lib/overflow.dart',
            'depth': i < 2 ? 0 : 2,
          },
      ];
      final source = builder.buildFlowchart(
        graph(nodes: nodes),
        labels: labels,
        maxNodes: 2,
      );
      expect(source, contains('6 more in overflow.dart'));
      expect(source, contains('sym0'));
      expect(source, isNot(contains('sym7')));
    });

    test('drops edges that point into the collapsed remainder', () {
      final source = builder.buildFlowchart(
        graph(
          nodes: const [
            {'id': 's1', 'name': 'a', 'filePath': 'lib/a.dart', 'depth': 0},
            {'id': 's2', 'name': 'b', 'filePath': 'lib/b.dart', 'depth': 1},
          ],
          edges: const [
            {'source': 's2', 'target': 's1'},
          ],
        ),
        labels: labels,
        maxNodes: 1,
      );
      expect(source, isNot(contains('-->')));
    });

    test('parses a malformed wire payload without throwing', () {
      final parsed = CohortImpactGraph.fromWire({
        'indexed': true,
        'nodes': [
          {'id': 's1'},
          'garbage',
          {'id': 's2', 'name': 'ok'},
        ],
        'edges': [
          {'source': 's1'},
          42,
        ],
      });
      expect(parsed.nodes, hasLength(1));
      expect(parsed.edges, isEmpty);
    });
  });
}
