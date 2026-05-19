import 'dart:io';

import 'package:cc_natives/cc_natives.dart';
import 'package:test/test.dart';

import '../helpers/dev_native_layout.dart';

/// Compiling the `;;;`-separated query patterns costs more than parsing a
/// typical file, and every file of a language uses the SAME query — so
/// recompiling per file was the dominant native cost once parses moved to a
/// long-lived worker isolate. These tests pin the cache: compile once per
/// (language, query source), recompile when the source changes, and free the
/// cached handles on dispose (an isolate's death does not reclaim native
/// allocations).
///
/// Fails (does not skip) when the tree-sitter natives aren't built locally:
/// they are REQUIRED natives — `cc_server` refuses to boot without them — so
/// an absent dylib is a broken tree. CI runners do not build natives and skip.
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
  // libtree-sitter + its grammars are REQUIRED natives on every platform, so an
  // absent dylib is a broken tree rather than an environment to skip around.
  // Fail loudly locally (the `pty_test.dart` philosophy); skip on CI.
  if (runtimePath == null || grammarPath == null) {
    test(
      'tree-sitter natives are built',
      () {
        fail(
          'tree-sitter natives not found (runtime=$runtimePath, '
          'grammar=$grammarPath) — run scripts/natives/build_tree_sitter.sh (on '
          'Windows scripts/release/windows_natives.sh). They are REQUIRED '
          'natives; cc_server refuses to boot without them.',
        );
      },
      skip: skipIfMissingInCi(
        false,
        'tree-sitter natives are not built on CI runners',
      ),
    );
    return;
  }

  const query = '''
(class_definition name: (identifier) @class.name) @class.def
;;;
(function_signature name: (identifier) @function.name) @function.def
''';

  TreeSitterParser makeParser() => TreeSitterParser(
    TreeSitterLoader(
      runtimePath: runtimePath,
      grammarPaths: {'dart': grammarPath},
    ),
  );

  test('compiles a language\'s patterns ONCE across many files', () {
    final parser = makeParser();
    addTearDown(parser.dispose);

    parser.parseMatches(
      languageId: 'dart',
      source: 'class A {}',
      querySource: query,
    );
    final afterFirst = parser.compileCount;
    expect(afterFirst, greaterThan(0));

    for (var i = 0; i < 5; i++) {
      parser.parseMatches(
        languageId: 'dart',
        source: 'class B$i {}',
        querySource: query,
      );
    }
    expect(
      parser.compileCount,
      afterFirst,
      reason: 'five more files must reuse the compiled patterns',
    );
  });

  test('a changed query source recompiles', () {
    final parser = makeParser();
    addTearDown(parser.dispose);

    parser.parseMatches(
      languageId: 'dart',
      source: 'class A {}',
      querySource: query,
    );
    final afterFirst = parser.compileCount;

    parser.parseMatches(
      languageId: 'dart',
      source: 'class A {}',
      // A dev editing a `.scm` mid-run must not keep the stale compilation.
      querySource: '(class_definition) @class.def',
    );
    expect(parser.compileCount, greaterThan(afterFirst));
  });

  test('results are identical across cached and fresh compilations', () {
    const source = 'class Widget {}\nvoid build() {}\n';
    final cached = makeParser();
    addTearDown(cached.dispose);
    final first = cached.parseMatches(
      languageId: 'dart',
      source: source,
      querySource: query,
    );
    final second = cached.parseMatches(
      languageId: 'dart',
      source: source,
      querySource: query,
    );

    expect(second.length, first.length);
    expect(
      [
        for (final m in second)
          for (final c in m) '${c.name}:${c.text}',
      ],
      [
        for (final m in first)
          for (final c in m) '${c.name}:${c.text}',
      ],
      reason: 'the cache must not change what a parse yields',
    );
  });

  test('dispose is safe and idempotent after caching', () {
    final parser = makeParser();
    parser.parseMatches(
      languageId: 'dart',
      source: 'class A {}',
      querySource: query,
    );
    parser.dispose();
    parser.dispose();
  });
}
