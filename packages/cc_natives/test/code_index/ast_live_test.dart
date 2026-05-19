import 'dart:io';

import 'package:cc_natives/cc_natives.dart';
import 'package:test/test.dart';

import '../helpers/dev_native_layout.dart';

/// Drives the structural matcher against a REAL Dart grammar.
///
/// The hand-built-tree tests pin the matching algebra; this pins the part that
/// can only be wrong against a live grammar — that a pattern typed the way a
/// model would type it actually parses to the node the file parses to. A
/// matcher that is correct on synthetic trees and finds nothing in real Dart
/// is not a feature.
void main() {
  String? findLib(String baseName) {
    for (final candidate in devNativeCandidates(baseName)) {
      final file = File(candidate);
      if (file.existsSync()) {
        return file.absolute.path;
      }
    }
    return null;
  }

  final runtimePath = findLib('tree-sitter');
  final grammarPath = findLib('tree-sitter-dart');
  if (runtimePath == null || grammarPath == null) {
    test(
      'tree-sitter natives are built',
      () => fail(
        'tree-sitter natives not found — run '
        'scripts/natives/build_tree_sitter.sh. They are REQUIRED natives.',
      ),
      skip: skipIfMissingInCi(
        false,
        'tree-sitter natives are not built on CI runners',
      ),
    );
    return;
  }

  TreeSitterParser makeParser() => TreeSitterParser(
    TreeSitterLoader(
      runtimePath: runtimePath,
      grammarPaths: {'dart': grammarPath},
    ),
  );

  late TreeSitterParser parser;
  setUp(() => parser = makeParser());
  tearDown(() => parser.dispose());

  AstNode parse(String source) {
    final tree = parser.parseTree(languageId: 'dart', source: source);
    expect(tree, isNotNull, reason: 'the grammar failed to parse at all');
    return tree!;
  }

  CompiledAstPattern compile(String pattern) {
    final compiled = compileAstPattern(
      parser: parser,
      languageId: 'dart',
      pattern: pattern,
    );
    expect(compiled, isNotNull, reason: 'no scaffold accepted the pattern');
    return compiled!;
  }

  List<AstMatch> find(String pattern, String source) {
    final compiled = compile(pattern);
    return AstPatternMatcher(
      compiled.node,
      sequenceMode: compiled.sequenceMode,
    ).findAll(parse(source));
  }

  group('parseTree', () {
    test('materializes a tree with real node types', () {
      final tree = parse('void main() {}\n');
      final types = tree.descendants.map((n) => n.type).toSet();
      expect(types, contains('function_signature'));
      expect(tree.startLine, 1);
    });

    test('reports 1-indexed lines', () {
      final tree = parse('void a() {}\nvoid b() {}\n');
      final second = tree.descendants.firstWhere(
        (n) => n.type == 'identifier' && n.text == 'b',
      );
      expect(second.startLine, 2);
    });

    test('keeps parsing a fragment the grammar considers incomplete', () {
      // A pattern is a fragment by nature — `foo($X)` is not a Dart file. The
      // matcher needs the structure anyway, and tree-sitter is error-tolerant
      // by design, so a tree with ERROR nodes in it is still a tree.
      final tree = parser.parseTree(languageId: 'dart', source: 'foo(bar)');
      expect(tree, isNotNull);
      expect(
        tree!.descendants.any((n) => n.text == 'bar'),
        isTrue,
        reason: 'the call is present even though the fragment is not a file',
      );
    });
  });

  group('compileAstPattern', () {
    test('a bare call needs a scaffold, and says so', () {
      // Parsed bare, `dispose(x)` is a valid Dart FUNCTION SIGNATURE. A
      // matcher built on that parse looks for declarations and silently finds
      // no calls, with nothing in the result saying it went wrong.
      final compiled = compile('dispose(x)');
      expect(compiled.context, isNot('%s'));
      expect(compiled.sequenceMode, isTrue);
      expect(
        compiled.node.namedChildren.map((c) => c.type),
        contains('selector'),
        reason: 'the run is the call, not the scaffold variable definition',
      );
    });

    test('a declaration parses bare and matches as a node', () {
      final compiled = compile(r'class $X {}');
      expect(compiled.context, '%s');
      expect(compiled.sequenceMode, isFalse);
      expect(compiled.node.type, 'class_definition');
    });

    test('an unparseable fragment is null, not a silent no-match', () {
      expect(
        compileAstPattern(parser: parser, languageId: 'dart', pattern: '(((('),
        isNull,
      );
    });
  });

  group('matching real Dart', () {
    test('finds a call however it is spaced and line-broken', () {
      final matches = find('dispose(x)', '''
void main() {
  dispose(x);
  dispose(
    x,
  );
  dispose(y);
}
''');
      expect(matches, hasLength(2));
    });

    test('does not match the same characters inside a string', () {
      // The property a textual grep cannot have.
      final matches = find('dispose(x)', '''
void main() {
  final s = "dispose(x)";
  print(s);
}
''');
      expect(matches, isEmpty);
    });

    test('does not match inside a comment', () {
      final matches = find('dispose(x)', '''
void main() {
  // dispose(x);
  print(1);
}
''');
      expect(matches, isEmpty);
    });

    test('a metavariable binds the argument', () {
      final matches = find(r'dispose($X)', '''
void main() {
  dispose(controller);
}
''');
      expect(matches, hasLength(1));
      expect(matches.single[r'X'], 'controller');
    });

    test(r'$$$ matches a call of any arity', () {
      final matches = find(r'log($$$ARGS)', '''
void main() {
  log();
  log(a);
  log(a, b, c);
}
''');
      expect(matches, hasLength(3));
    });
  });
}
