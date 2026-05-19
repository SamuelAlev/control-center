import 'package:cc_domain/core/domain/value_objects/code_edge_kind.dart';
import 'package:cc_domain/core/domain/value_objects/code_symbol_kind.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_edge.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_subgraph.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_symbol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = CodeSymbol(
    id: 'sym-root',
    workspaceId: 'ws-1',
    repoId: 'repo-1',
    kind: CodeSymbolKind.classKind,
    name: 'MyClass',
    qualifiedName: 'MyClass',
    filePath: 'lib/my_class.dart',
    language: 'dart',
    startLine: 1,
    endLine: 50,
  );

  final child = CodeSymbol(
    id: 'sym-child',
    workspaceId: 'ws-1',
    repoId: 'repo-1',
    kind: CodeSymbolKind.method,
    name: 'myMethod',
    qualifiedName: 'MyClass.myMethod',
    filePath: 'lib/my_class.dart',
    language: 'dart',
    startLine: 10,
    endLine: 20,
  );

  final edge = CodeEdge(
    id: 'edge-1',
    workspaceId: 'ws-1',
    repoId: 'repo-1',
    sourceSymbolId: 'sym-root',
    sourceFilePath: 'lib/my_class.dart',
    kind: CodeEdgeKind.calls,
    targetSymbolId: 'sym-child',
  );

  CodeSubgraph createSubgraph({
    CodeSymbol? root,
    List<CodeSymbol>? nodes,
    List<CodeEdge>? edges,
    Map<String, int>? depthById,
  }) {
    return CodeSubgraph(
      root: root,
      nodes: nodes ?? [],
      edges: edges ?? [],
      depthById: depthById ?? {},
    );
  }

  group('CodeSubgraph', () {
    group('constructor', () {
      test('creates subgraph with all fields', timeout: const Timeout.factor(2), () {
        final sg = CodeSubgraph(
          root: root,
          nodes: [root, child],
          edges: [edge],
          depthById: {'sym-root': 0, 'sym-child': 1},
        );
        expect(sg.root, root);
        expect(sg.nodes, hasLength(2));
        expect(sg.edges, hasLength(1));
        expect(sg.depthById, {'sym-root': 0, 'sym-child': 1});
      });

      test('creates subgraph with null root', timeout: const Timeout.factor(2), () {
        final sg = createSubgraph();
        expect(sg.root, isNull);
        expect(sg.nodes, isEmpty);
        expect(sg.edges, isEmpty);
      });
    });

    group('empty constructor', () {
      test('creates empty subgraph', timeout: const Timeout.factor(2), () {
        const sg = CodeSubgraph.empty();
        expect(sg.root, isNull);
        expect(sg.nodes, isEmpty);
        expect(sg.edges, isEmpty);
        expect(sg.depthById, isEmpty);
      });
    });

    group('isEmpty', () {
      test('returns true when nodes is empty', timeout: const Timeout.factor(2), () {
        final sg = createSubgraph(root: root, nodes: []);
        expect(sg.isEmpty, isTrue);
      });

      test('returns false when nodes is non-empty', timeout: const Timeout.factor(2), () {
        final sg = createSubgraph(root: root, nodes: [root]);
        expect(sg.isEmpty, isFalse);
      });

      test('empty constructor yields isEmpty true', timeout: const Timeout.factor(2), () {
        const sg = CodeSubgraph.empty();
        expect(sg.isEmpty, isTrue);
      });
    });

    group('== and hashCode', () {
      test('== returns true for identical values', timeout: const Timeout.factor(2), () {
        final sg1 = CodeSubgraph(
          root: root,
          nodes: [root],
          edges: [edge],
          depthById: {'sym-root': 0},
        );
        final sg2 = CodeSubgraph(
          root: root,
          nodes: [root],
          edges: [edge],
          depthById: {'sym-root': 0},
        );
        expect(sg1, equals(sg2));
      });

      test('== returns true for same reference', timeout: const Timeout.factor(2), () {
        final sg = CodeSubgraph(
          root: root,
          nodes: [root],
          edges: [],
          depthById: {},
        );
        expect(sg, equals(sg));
      });

      test('== returns false for different root', timeout: const Timeout.factor(2), () {
        final sg1 = createSubgraph(root: root);
        final sg2 = createSubgraph(root: child);
        expect(sg1, isNot(equals(sg2)));
      });

      test('== returns false for different nodes', timeout: const Timeout.factor(2), () {
        final sg1 = createSubgraph(nodes: [root]);
        final sg2 = createSubgraph(nodes: [child]);
        expect(sg1, isNot(equals(sg2)));
      });

      test('== returns false for different depthById', timeout: const Timeout.factor(2), () {
        final sg1 = createSubgraph(depthById: {'a': 0});
        final sg2 = createSubgraph(depthById: {'a': 1});
        expect(sg1, isNot(equals(sg2)));
      });

      test('== returns false for different runtime type', timeout: const Timeout.factor(2), () {
        final sg = createSubgraph();
        expect(sg, isNot(equals('not a subgraph')));
      });

      test('hashCode matches for equal subgraphs', timeout: const Timeout.factor(2), () {
        final sg1 = CodeSubgraph(
          root: root,
          nodes: [root],
          edges: [edge],
          depthById: {'sym-root': 0},
        );
        final sg2 = CodeSubgraph(
          root: root,
          nodes: [root],
          edges: [edge],
          depthById: {'sym-root': 0},
        );
        expect(sg1.hashCode, equals(sg2.hashCode));
      });

      test('two empty subgraphs are equal', timeout: const Timeout.factor(2), () {
        const sg1 = CodeSubgraph.empty();
        const sg2 = CodeSubgraph.empty();
        expect(sg1, equals(sg2));
      });
    });
  });
}
