import 'package:cc_domain/core/domain/value_objects/code_edge_kind.dart';
import 'package:cc_domain/core/domain/value_objects/code_symbol_kind.dart';
import 'package:cc_infra/src/code_graph/code_extractor.dart';
import 'package:cc_natives/cc_natives.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const extractor = CodeExtractor();
  const workspaceId = 'ws1';
  const repoId = 'repo1';
  const filePath = 'lib/a.dart';

  // Simulated tree-sitter matches for:
  //   import 'package:x/x.dart';        (byte 10)
  //   class A extends Base {            (class 50..400, name@56, extends@64)
  //     void foo() { bar(); }           (method 100..200, name@110, call@150)
  //     void bar() {}                   (method 220..300, name@230)
  //   }
  final matches = <QueryMatch>[
    [
      const QueryCapture(
        name: 'class.def',
        text: 'class A ...',
        startLine: 3,
        endLine: 30,
        startByte: 50,
        endByte: 400,
      ),
      const QueryCapture(
        name: 'class.name',
        text: 'A',
        startLine: 3,
        endLine: 3,
        startByte: 56,
        endByte: 57,
      ),
    ],
    [
      const QueryCapture(
        name: 'extends.name',
        text: 'Base',
        startLine: 3,
        endLine: 3,
        startByte: 64,
        endByte: 68,
      ),
    ],
    [
      const QueryCapture(
        name: 'method.def',
        text: 'void foo() {...}',
        startLine: 5,
        endLine: 12,
        startByte: 100,
        endByte: 200,
      ),
      const QueryCapture(
        name: 'method.name',
        text: 'foo',
        startLine: 5,
        endLine: 5,
        startByte: 110,
        endByte: 113,
      ),
    ],
    [
      const QueryCapture(
        name: 'method.def',
        text: 'void bar() {}',
        startLine: 14,
        endLine: 20,
        startByte: 220,
        endByte: 300,
      ),
      const QueryCapture(
        name: 'method.name',
        text: 'bar',
        startLine: 14,
        endLine: 14,
        startByte: 230,
        endByte: 233,
      ),
    ],
    [
      const QueryCapture(
        name: 'call.name',
        text: 'bar',
        startLine: 7,
        endLine: 7,
        startByte: 150,
        endByte: 153,
      ),
    ],
    [
      const QueryCapture(
        name: 'import.uri',
        text: "'package:x/x.dart'",
        startLine: 1,
        endLine: 1,
        startByte: 10,
        endByte: 30,
      ),
    ],
  ];

  final result = extractor.extractFromMatches(
    workspaceId: workspaceId,
    repoId: repoId,
    filePath: filePath,
    languageId: 'dart',
    matches: matches,
  );

  group('CodeExtractor', () {
    test('extracts the class and its two methods', () {
      expect(result.symbols.length, 3);
      final classA = result.symbols.firstWhere((s) => s.name == 'A');
      expect(classA.kind, CodeSymbolKind.classKind);
      expect(classA.parentName, isNull);
      expect(classA.qualifiedName, 'A');
    });

    test('resolves method parents and qualified names by containment', () {
      final foo = result.symbols.firstWhere((s) => s.name == 'foo');
      expect(foo.kind, CodeSymbolKind.method);
      expect(foo.parentName, 'A');
      expect(foo.qualifiedName, 'A.foo');
    });

    test('resolves an intra-file call to the target symbol id', () {
      final fooId = codeSymbolId(workspaceId, repoId, filePath, 'A.foo');
      final barId = codeSymbolId(workspaceId, repoId, filePath, 'A.bar');
      final call = result.edges.firstWhere(
        (e) => e.kind == CodeEdgeKind.calls,
      );
      expect(call.sourceSymbolId, fooId);
      expect(call.targetSymbolId, barId);
      expect(call.targetName, isNull);
    });

    test('emits an unresolved extends edge from the class', () {
      final classId = codeSymbolId(workspaceId, repoId, filePath, 'A');
      final ext = result.edges.firstWhere(
        (e) => e.kind == CodeEdgeKind.extendsType,
      );
      expect(ext.sourceSymbolId, classId);
      expect(ext.targetName, 'Base');
      expect(ext.targetSymbolId, isNull);
    });

    test('emits an import edge with a cleaned URI from the file node', () {
      final import = result.edges.firstWhere(
        (e) => e.kind == CodeEdgeKind.imports,
      );
      expect(import.sourceSymbolId, codeFileNodeId(workspaceId, repoId, filePath));
      expect(import.targetName, 'package:x/x.dart');
    });
  });
}
