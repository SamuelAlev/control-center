import 'package:cc_domain/core/domain/value_objects/code_edge_kind.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_edge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CodeEdge createEdge({
    String id = 'edge-1',
    String workspaceId = 'ws-1',
    String repoId = 'repo-1',
    String sourceSymbolId = 'sym-1',
    String sourceFilePath = 'lib/main.dart',
    CodeEdgeKind kind = CodeEdgeKind.calls,
    String? targetSymbolId = 'sym-2',
    String? targetName,
    Map<String, dynamic>? metadata,
  }) {
    return CodeEdge(
      id: id,
      workspaceId: workspaceId,
      repoId: repoId,
      sourceSymbolId: sourceSymbolId,
      sourceFilePath: sourceFilePath,
      kind: kind,
      targetSymbolId: targetSymbolId,
      targetName: targetName,
      metadata: metadata,
    );
  }

  group('CodeEdge', () {
    group('constructor', () {
      test('creates edge with resolved target', timeout: const Timeout.factor(2), () {
        final e = createEdge();
        expect(e.id, 'edge-1');
        expect(e.workspaceId, 'ws-1');
        expect(e.repoId, 'repo-1');
        expect(e.sourceSymbolId, 'sym-1');
        expect(e.sourceFilePath, 'lib/main.dart');
        expect(e.kind, CodeEdgeKind.calls);
        expect(e.targetSymbolId, 'sym-2');
        expect(e.targetName, isNull);
        expect(e.metadata, isNull);
      });

      test('creates edge with targetName only', timeout: const Timeout.factor(2), () {
        final e = createEdge(targetSymbolId: null, targetName: 'myFunction');
        expect(e.targetSymbolId, isNull);
        expect(e.targetName, 'myFunction');
      });

      test('creates edge with metadata', timeout: const Timeout.factor(2), () {
        final e = createEdge(metadata: {'callCount': 5});
        expect(e.metadata, {'callCount': 5});
      });

      test('asserts id is not empty', timeout: const Timeout.factor(2), () {
        expect(
          () => CodeEdge(
            id: '',
            workspaceId: 'ws',
            repoId: 'r',
            sourceSymbolId: 's',
            sourceFilePath: 'f.dart',
            kind: CodeEdgeKind.calls,
            targetSymbolId: 't',
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('asserts workspaceId is not empty', timeout: const Timeout.factor(2), () {
        expect(
          () => CodeEdge(
            id: 'e',
            workspaceId: '',
            repoId: 'r',
            sourceSymbolId: 's',
            sourceFilePath: 'f.dart',
            kind: CodeEdgeKind.calls,
            targetSymbolId: 't',
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('asserts repoId is not empty', timeout: const Timeout.factor(2), () {
        expect(
          () => CodeEdge(
            id: 'e',
            workspaceId: 'ws',
            repoId: '',
            sourceSymbolId: 's',
            sourceFilePath: 'f.dart',
            kind: CodeEdgeKind.calls,
            targetSymbolId: 't',
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('asserts sourceSymbolId is not empty', timeout: const Timeout.factor(2), () {
        expect(
          () => CodeEdge(
            id: 'e',
            workspaceId: 'ws',
            repoId: 'r',
            sourceSymbolId: '',
            sourceFilePath: 'f.dart',
            kind: CodeEdgeKind.calls,
            targetSymbolId: 't',
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('asserts either targetSymbolId or targetName is provided', timeout: const Timeout.factor(2), () {
        expect(
          () => CodeEdge(
            id: 'e',
            workspaceId: 'ws',
            repoId: 'r',
            sourceSymbolId: 's',
            sourceFilePath: 'f.dart',
            kind: CodeEdgeKind.calls,
            targetSymbolId: null,
            targetName: null,
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('isResolved', () {
      test('returns true when targetSymbolId is set', timeout: const Timeout.factor(2), () {
        final e = createEdge(targetSymbolId: 'sym-2');
        expect(e.isResolved, isTrue);
      });

      test('returns false when targetSymbolId is null', timeout: const Timeout.factor(2), () {
        final e = createEdge(targetSymbolId: null, targetName: 'foo');
        expect(e.isResolved, isFalse);
      });
    });

    group('== and hashCode', () {
      test('== returns true for identical values', timeout: const Timeout.factor(2), () {
        final e1 = createEdge();
        final e2 = createEdge();
        expect(e1, equals(e2));
      });

      test('== returns true for same reference', timeout: const Timeout.factor(2), () {
        final e = createEdge();
        expect(e, equals(e));
      });

      test('== returns false for different id', timeout: const Timeout.factor(2), () {
        final e1 = createEdge(id: 'e1');
        final e2 = createEdge(id: 'e2');
        expect(e1, isNot(equals(e2)));
      });

      test('== returns false for different kind', timeout: const Timeout.factor(2), () {
        final e1 = createEdge(kind: CodeEdgeKind.calls);
        final e2 = createEdge(kind: CodeEdgeKind.imports);
        expect(e1, isNot(equals(e2)));
      });

      test('== returns false for different targetSymbolId', timeout: const Timeout.factor(2), () {
        final e1 = createEdge(targetSymbolId: 'a');
        final e2 = createEdge(targetSymbolId: 'b');
        expect(e1, isNot(equals(e2)));
      });

      test('== returns false for different metadata', timeout: const Timeout.factor(2), () {
        final e1 = createEdge(metadata: {'a': 1});
        final e2 = createEdge(metadata: {'a': 2});
        expect(e1, isNot(equals(e2)));
      });

      test('== returns false for different runtime type', timeout: const Timeout.factor(2), () {
        final e = createEdge();
        expect(e, isNot(equals('not an edge')));
      });

      test('hashCode matches for equal edges', timeout: const Timeout.factor(2), () {
        final e1 = createEdge();
        final e2 = createEdge();
        expect(e1.hashCode, equals(e2.hashCode));
      });

      test('hashCode differs for different edges', timeout: const Timeout.factor(2), () {
        final e1 = createEdge(id: 'e1');
        final e2 = createEdge(id: 'e2');
        expect(e1.hashCode, isNot(equals(e2.hashCode)));
      });
    });
  });
}
