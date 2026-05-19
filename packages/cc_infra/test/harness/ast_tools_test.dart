import 'dart:io';

import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/harness/ast_tools.dart';
import 'package:cc_natives/cc_natives.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Drives `ast_grep` / `ast_edit` end to end over real files with a real
/// grammar.
///
/// The matcher's own tests pin the algebra; this pins the two things only a
/// tool test can catch — that a rewrite splices at BYTE offsets (so a file with
/// an accent before the match is not corrupted), and that `ast_edit` writes
/// nothing until `resolve` says so.
void main() {
  String? findLib(String baseName) {
    for (final candidate in _devNativeCandidates(baseName)) {
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
    test('tree-sitter natives are built', () {
      // ignore: avoid_print
      print('tree-sitter natives not built — skipping ast tool e2e');
    }, skip: 'tree-sitter natives are not built here');
    return;
  }

  late Directory root;
  late TreeSitterParser parser;
  late StagedEditStore store;

  setUp(() {
    root = Directory.systemTemp.createTempSync('cc_ast');
    parser = TreeSitterParser(
      TreeSitterLoader(
        runtimePath: runtimePath,
        grammarPaths: {'dart': grammarPath},
      ),
    );
    store = StagedEditStore();
  });
  tearDown(() {
    parser.dispose();
    root.deleteSync(recursive: true);
  });

  String write(String name, String content) {
    final path = p.join(root.path, name);
    File(path).writeAsStringSync(content);
    return path;
  }

  HarnessToolContext ctx() => HarnessToolContext(workingDirectory: root.path);

  AstGrepTool grep() =>
      AstGrepTool(parser: parser, workingDirectory: root.path);
  AstEditTool edit() => AstEditTool(
    parser: parser,
    workingDirectory: root.path,
    store: store,
  );

  group('ast_grep', () {
    test('finds calls by shape and reports file:line', () async {
      write('a.dart', '''
void main() {
  dispose(controller);
}
''');
      final result = await grep().execute(
        {'pattern': r'dispose($X)', 'language': 'dart'},
        ctx(),
      );
      expect(result.isError, isFalse);
      expect(result.content, contains('a.dart:2'));
      expect(result.content, contains('1 match'));
    });

    test('says which languages it knows when it cannot tell', () async {
      final result = await grep().execute({'pattern': 'foo(x)'}, ctx());
      expect(result.isError, isTrue);
      expect(result.content, contains('Supported:'));
    });

    test('is read tier, so plan mode keeps structural search', () {
      expect(grep().approvalTier, ToolApprovalTier.read);
    });
  });

  group('ast_edit', () {
    test('stages instead of writing', () async {
      final path = write('a.dart', '''
void main() {
  dispose(controller);
}
''');
      final before = File(path).readAsStringSync();

      final result = await edit().execute({
        'pattern': r'dispose($X)',
        'rewrite': r'$X.dispose()',
        'language': 'dart',
      }, ctx());

      expect(result.isError, isFalse);
      expect(result.content, contains('(proposed)'));
      expect(result.content, contains('Nothing has been written'));
      expect(
        File(path).readAsStringSync(),
        before,
        reason: 'the whole point is that the first look happens before the '
            'write, not in a git diff afterwards',
      );
      expect(store.pending, hasLength(1));
    });

    test('resolve applies exactly what was staged', () async {
      final path = write('a.dart', '''
void main() {
  dispose(controller);
}
''');
      final staged = await edit().execute({
        'pattern': r'dispose($X)',
        'rewrite': r'$X.dispose()',
        'language': 'dart',
      }, ctx());
      expect(staged.isError, isFalse);

      final id = store.pending.single.id;
      final applied = await ResolveTool(
        store,
      ).execute({'edit_id': id, 'action': 'accept'}, ctx());

      expect(applied.isError, isFalse);
      expect(
        File(path).readAsStringSync(),
        contains('controller.dispose();'),
      );
    });

    test('splices at byte offsets, so an accent before the match survives',
        () async {
      // Tree-sitter reports BYTE offsets and a Dart string is UTF-16. Slicing
      // the string at those numbers corrupts any file with a non-ASCII
      // character before the match — a bug that only shows up on somebody
      // else's file.
      final path = write('a.dart', '''
// café éàü — accents before the match
void main() {
  dispose(controller);
}
''');
      await edit().execute({
        'pattern': r'dispose($X)',
        'rewrite': r'$X.dispose()',
        'language': 'dart',
      }, ctx());
      await ResolveTool(store).execute(
        {'edit_id': store.pending.single.id, 'action': 'accept'},
        ctx(),
      );

      final after = File(path).readAsStringSync();
      expect(after, contains('café éàü —'));
      expect(after, contains('controller.dispose();'));
    });

    test('rewrites several sites in one file without shifting offsets',
        () async {
      final path = write('a.dart', '''
void main() {
  dispose(a);
  dispose(bbbbbbbbbbbb);
  dispose(c);
}
''');
      await edit().execute({
        'pattern': r'dispose($X)',
        'rewrite': r'$X.dispose()',
        'language': 'dart',
      }, ctx());
      await ResolveTool(store).execute(
        {'edit_id': store.pending.single.id, 'action': 'accept'},
        ctx(),
      );

      final after = File(path).readAsStringSync();
      expect(after, contains('a.dispose();'));
      expect(after, contains('bbbbbbbbbbbb.dispose();'));
      expect(after, contains('c.dispose();'));
      expect(after, isNot(contains('dispose(a)')));
    });

    test('a pattern that matches nothing stages nothing', () async {
      write('a.dart', 'void main() {}\n');
      final result = await edit().execute({
        'pattern': r'dispose($X)',
        'rewrite': r'$X.dispose()',
        'language': 'dart',
      }, ctx());
      expect(result.isError, isFalse);
      expect(result.content, contains('nothing to rewrite'));
      expect(store.pending, isEmpty);
    });

    test('is write tier and declares a file write', () {
      final tool = edit();
      expect(tool.approvalTier, ToolApprovalTier.write);
      expect(
        tool.actionClasses,
        contains(ActionClass.fileWriteOutsideWorktree),
        reason: 'staging is the first half of rewriting files, and that is '
            'the question the operator is answering',
      );
    });
  });
}

/// Where a locally-built native lands, mirroring `cc_natives`' own test helper.
List<String> _devNativeCandidates(String baseName) {
  final home = Platform.environment['HOME'] ?? '';
  final ext = Platform.isMacOS
      ? 'dylib'
      : Platform.isWindows
      ? 'dll'
      : 'so';
  final fileName = Platform.isWindows ? '$baseName.$ext' : 'lib$baseName.$ext';
  return [
    if (home.isNotEmpty)
      p.join(
        home,
        'Library',
        'Application Support',
        'com.alev.control-center',
        fileName,
      ),
    if (home.isNotEmpty)
      p.join(home, '.local', 'share', 'control-center', fileName),
    p.join('build', 'natives', fileName),
    p.join('..', '..', 'build', 'natives', fileName),
  ];
}
