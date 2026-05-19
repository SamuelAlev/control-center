import 'package:cc_domain/core/domain/value_objects/code_symbol_kind.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_symbol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CodeSymbol createSymbol({
    String id = 'sym-1',
    String workspaceId = 'ws-1',
    String repoId = 'repo-1',
    CodeSymbolKind kind = CodeSymbolKind.function,
    String name = 'myFunction',
    String qualifiedName = 'MyClass.myFunction',
    String filePath = 'lib/main.dart',
    String language = 'dart',
    int startLine = 1,
    int endLine = 10,
    String signature = 'void myFunction()',
    String? docstring,
    String? parentName,
  }) {
    return CodeSymbol(
      id: id,
      workspaceId: workspaceId,
      repoId: repoId,
      kind: kind,
      name: name,
      qualifiedName: qualifiedName,
      filePath: filePath,
      language: language,
      startLine: startLine,
      endLine: endLine,
      signature: signature,
      docstring: docstring,
      parentName: parentName,
    );
  }

  group('CodeSymbol', () {
    group('constructor', () {
      test('creates symbol with all fields', timeout: const Timeout.factor(2), () {
        final s = createSymbol();
        expect(s.id, 'sym-1');
        expect(s.workspaceId, 'ws-1');
        expect(s.repoId, 'repo-1');
        expect(s.kind, CodeSymbolKind.function);
        expect(s.name, 'myFunction');
        expect(s.qualifiedName, 'MyClass.myFunction');
        expect(s.filePath, 'lib/main.dart');
        expect(s.language, 'dart');
        expect(s.startLine, 1);
        expect(s.endLine, 10);
        expect(s.signature, 'void myFunction()');
        expect(s.docstring, isNull);
        expect(s.parentName, isNull);
      });

      test('creates symbol with optional fields', timeout: const Timeout.factor(2), () {
        final s = createSymbol(docstring: 'A docstring', parentName: 'MyClass');
        expect(s.docstring, 'A docstring');
        expect(s.parentName, 'MyClass');
      });

      test('asserts id is not empty', timeout: const Timeout.factor(2), () {
        expect(
          () => createSymbol(id: ''),
          throwsA(isA<AssertionError>()),
        );
      });

      test('asserts workspaceId is not empty', timeout: const Timeout.factor(2), () {
        expect(
          () => createSymbol(workspaceId: ''),
          throwsA(isA<AssertionError>()),
        );
      });

      test('asserts repoId is not empty', timeout: const Timeout.factor(2), () {
        expect(
          () => createSymbol(repoId: ''),
          throwsA(isA<AssertionError>()),
        );
      });

      test('asserts qualifiedName is not empty', timeout: const Timeout.factor(2), () {
        expect(
          () => createSymbol(qualifiedName: ''),
          throwsA(isA<AssertionError>()),
        );
      });

      test('asserts filePath is not empty', timeout: const Timeout.factor(2), () {
        expect(
          () => createSymbol(filePath: ''),
          throwsA(isA<AssertionError>()),
        );
      });

      test('asserts startLine <= endLine', timeout: const Timeout.factor(2), () {
        expect(
          () => createSymbol(startLine: 10, endLine: 5),
          throwsA(isA<AssertionError>()),
        );
      });

      test('allows startLine == endLine', timeout: const Timeout.factor(2), () {
        final s = createSymbol(startLine: 5, endLine: 5);
        expect(s.startLine, 5);
        expect(s.endLine, 5);
      });
    });

    group('copyWith', () {
      test('returns identical symbol with no arguments', timeout: const Timeout.factor(2), () {
        final s = createSymbol();
        final copy = s.copyWith();
        expect(copy.id, s.id);
        expect(copy.name, s.name);
        expect(copy.qualifiedName, s.qualifiedName);
      });

      test('updates individual fields', timeout: const Timeout.factor(2), () {
        final s = createSymbol();
        final copy = s.copyWith(name: 'newName', startLine: 20, endLine: 30);
        expect(copy.name, 'newName');
        expect(copy.startLine, 20);
        expect(copy.endLine, 30);
        expect(copy.id, s.id);
      });

      test('updates docstring and parentName', timeout: const Timeout.factor(2), () {
        final s = createSymbol();
        final copy = s.copyWith(docstring: 'new doc', parentName: 'Parent');
        expect(copy.docstring, 'new doc');
        expect(copy.parentName, 'Parent');
      });
    });

    group('== and hashCode', () {
      test('== returns true for identical values', timeout: const Timeout.factor(2), () {
        final s1 = createSymbol();
        final s2 = createSymbol();
        expect(s1, equals(s2));
      });

      test('== returns true for same reference', timeout: const Timeout.factor(2), () {
        final s = createSymbol();
        expect(s, equals(s));
      });

      test('== returns false for different id', timeout: const Timeout.factor(2), () {
        final s1 = createSymbol(id: 'sym-1');
        final s2 = createSymbol(id: 'sym-2');
        expect(s1, isNot(equals(s2)));
      });

      test('== returns false for different kind', timeout: const Timeout.factor(2), () {
        final s1 = createSymbol(kind: CodeSymbolKind.function);
        final s2 = createSymbol(kind: CodeSymbolKind.classKind);
        expect(s1, isNot(equals(s2)));
      });

      test('== returns false for different name', timeout: const Timeout.factor(2), () {
        final s1 = createSymbol(name: 'a');
        final s2 = createSymbol(name: 'b');
        expect(s1, isNot(equals(s2)));
      });

      test('== returns false for different docstring', timeout: const Timeout.factor(2), () {
        final s1 = createSymbol(docstring: 'a');
        final s2 = createSymbol(docstring: 'b');
        expect(s1, isNot(equals(s2)));
      });

      test('== returns false for different parentName', timeout: const Timeout.factor(2), () {
        final s1 = createSymbol(parentName: 'A');
        final s2 = createSymbol(parentName: 'B');
        expect(s1, isNot(equals(s2)));
      });

      test('== returns false for different runtime type', timeout: const Timeout.factor(2), () {
        final s = createSymbol();
        expect(s, isNot(equals('not a symbol')));
      });

      test('hashCode matches for equal symbols', timeout: const Timeout.factor(2), () {
        final s1 = createSymbol();
        final s2 = createSymbol();
        expect(s1.hashCode, equals(s2.hashCode));
      });

      test('hashCode differs for different symbols', timeout: const Timeout.factor(2), () {
        final s1 = createSymbol(id: 'sym-1');
        final s2 = createSymbol(id: 'sym-2');
        expect(s1.hashCode, isNot(equals(s2.hashCode)));
      });
    });
  });
}
