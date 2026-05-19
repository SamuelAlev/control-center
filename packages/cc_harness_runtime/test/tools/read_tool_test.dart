import 'dart:io';

import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/src/tools/read_tool.dart';
import 'package:test/test.dart';

HarnessToolContext _ctx(String dir) =>
    HarnessToolContext(workingDirectory: dir);

void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('read_tool_test_');
  });

  tearDown(() {
    if (temp.existsSync()) {
      temp.deleteSync(recursive: true);
    }
  });

  File write(String name, String content) {
    final f = File('${temp.path}/$name');
    f.writeAsStringSync(content);
    return f;
  }

  group('ReadTool', () {
    test('name/description/approvalTier/inputSchema', () {
      final tool = ReadTool();
      expect(tool.name, 'read');
      expect(tool.description, isNotEmpty);
      expect(tool.approvalTier, ToolApprovalTier.read);
      expect(tool.inputSchema['required'], ['path']);
    });

    test('errors when path is missing', () async {
      final tool = ReadTool();
      final result = await tool.execute({}, _ctx(temp.path));
      expect(result.isError, isTrue);
      expect(result.content, contains('path'));
    });

    test('errors when path is empty', () async {
      final tool = ReadTool();
      final result = await tool.execute({'path': ''}, _ctx(temp.path));
      expect(result.isError, isTrue);
    });

    test('errors when path escapes the workspace', () async {
      final tool = ReadTool();
      final result = await tool.execute({
        'path': '../outside.txt',
      }, _ctx(temp.path));
      expect(result.isError, isTrue);
      expect(result.content, contains('outside the workspace'));
    });

    test('errors when file does not exist', () async {
      final tool = ReadTool();
      final result = await tool.execute({
        'path': 'missing.txt',
      }, _ctx(temp.path));
      expect(result.isError, isTrue);
      expect(result.content, contains('not found'));
    });

    test(
      'missing file suggests fuzzy matches when fileSearch is wired',
      () async {
        final tool = ReadTool(
          fileSearch: const _StubFileSearch([
            FileSearchMatch(path: 'lib/read_tool.dart', score: 9),
            FileSearchMatch(path: 'lib', isDirectory: true, score: 5),
            FileSearchMatch(path: 'test/read_tool_test.dart', score: 3),
          ]),
        );
        final result = await tool.execute({
          'path': 'src/read_tool.dart',
        }, _ctx(temp.path));
        expect(result.isError, isTrue);
        expect(result.content, contains('File not found: src/read_tool.dart'));
        expect(result.content, contains('Did you mean'));
        expect(result.content, contains('lib/read_tool.dart'));
        expect(result.content, contains('test/read_tool_test.dart'));
        // Directories are not readable — never suggested.
        expect(result.content, isNot(contains('\n  lib\n')));
      },
    );

    test('missing file with no fuzzy matches keeps the bare error', () async {
      final tool = ReadTool(fileSearch: const _StubFileSearch([]));
      final result = await tool.execute({
        'path': 'missing.txt',
      }, _ctx(temp.path));
      expect(result.isError, isTrue);
      expect(result.content, 'File not found: missing.txt');
    });

    test(
      'did-you-mean covers the conversation worktrees',
      () async {
        // A stale path (from the code index or the agent's memory) points into a
        // repo worktree, which lives in a shared root the overlay cwd only
        // reaches through a symlink. Suggesting nothing there is what turns one
        // not-found into a guess-and-retry loop.
        final conv = Directory('${temp.path}/conv')..createSync();
        final repos = Directory('${conv.path}/repos')..createSync();
        File('${repos.path}/myrepo/lib/editor_tab_bar.dart')
          ..parent.createSync(recursive: true)
          ..writeAsStringSync('');
        final overlay = Directory('${conv.path}/agents/engineer')
          ..createSync(recursive: true);
        Link('${overlay.path}/repos').createSync('../../repos');

        final result = await ReadTool(fileSearch: _NoLinkFollowSearch())
            .execute(
              {'path': 'repos/myrepo/lib/editor_tab.dart'},
              HarnessToolContext(
                workingDirectory: overlay.path,
                sharedRoots: [repos.path],
              ),
            );
        expect(result.isError, isTrue);
        expect(result.content, contains('Did you mean'));
        expect(
          result.content,
          contains('repos/myrepo/lib/editor_tab_bar.dart'),
        );
      },
      skip: Platform.isWindows
          ? 'overlay repos-to-shared-root symlink identity is not reliably resolvable via dart:io on the Windows runner (relative-target reparse points plus the 8.3 TEMP short name defeat resolved-path comparison); the provisioner symlink overlay is a POSIX layout'
          : false,
    );

    test('a fileSearch failure never masks the not-found error', () async {
      final tool = ReadTool(fileSearch: _ThrowingFileSearch());
      final result = await tool.execute({
        'path': 'missing.txt',
      }, _ctx(temp.path));
      expect(result.isError, isTrue);
      expect(result.content, 'File not found: missing.txt');
    });

    test('reads a file with line numbers', () async {
      write('a.txt', 'first\nsecond\nthird');
      final tool = ReadTool();
      final result = await tool.execute({'path': 'a.txt'}, _ctx(temp.path));
      expect(result.isError, isFalse);
      expect(result.content, contains('1\tfirst'));
      expect(result.content, contains('2\tsecond'));
      expect(result.content, contains('3\tthird'));
    });

    test('respects offset', () async {
      write('a.txt', 'l1\nl2\nl3\nl4\nl5');
      final tool = ReadTool();
      final result = await tool.execute({
        'path': 'a.txt',
        'offset': 3,
      }, _ctx(temp.path));
      expect(result.isError, isFalse);
      expect(result.content, contains('3\tl3'));
      expect(result.content, contains('4\tl4'));
      expect(result.content, contains('5\tl5'));
      expect(result.content, isNot(contains('l1')));
    });

    test('respects limit', () async {
      write('a.txt', 'l1\nl2\nl3\nl4\nl5');
      final tool = ReadTool();
      final result = await tool.execute({
        'path': 'a.txt',
        'offset': 1,
        'limit': 2,
      }, _ctx(temp.path));
      expect(result.content, contains('l1'));
      expect(result.content, contains('l2'));
      expect(result.content, isNot(contains('l3')));
    });

    test('reports past-end offset', () async {
      write('a.txt', 'only');
      final tool = ReadTool();
      final result = await tool.execute({
        'path': 'a.txt',
        'offset': 999,
      }, _ctx(temp.path));
      expect(result.isError, isFalse);
      expect(result.content, contains('past the end'));
    });

    test('sel "N" reads a single line', () async {
      write('a.txt', 'l1\nl2\nl3');
      final tool = ReadTool();
      final result = await tool.execute({
        'path': 'a.txt',
        'sel': '2',
      }, _ctx(temp.path));
      expect(result.content, contains('2\tl2'));
      expect(result.content, isNot(contains('l1')));
      expect(result.content, isNot(contains('l3')));
    });

    test('sel "A-B" reads a closed range', () async {
      write('a.txt', 'l1\nl2\nl3\nl4\nl5');
      final tool = ReadTool();
      final result = await tool.execute({
        'path': 'a.txt',
        'sel': '2-4',
      }, _ctx(temp.path));
      expect(result.content, contains('l2'));
      expect(result.content, contains('l3'));
      expect(result.content, contains('l4'));
      expect(result.content, isNot(contains('l1')));
      expect(result.content, isNot(contains('l5')));
    });

    test('sel "A+N" reads N lines from A', () async {
      write('a.txt', 'l1\nl2\nl3\nl4\nl5');
      final tool = ReadTool();
      final result = await tool.execute({
        'path': 'a.txt',
        'sel': '2+2',
      }, _ctx(temp.path));
      expect(result.content, contains('l2'));
      expect(result.content, contains('l3'));
      expect(result.content, isNot(contains('l4')));
    });

    test('rejects binary files', () async {
      final f = File('${temp.path}/bin.dat');
      f.writeAsBytesSync([0x41, 0x00, 0x42, 0x00]);
      final tool = ReadTool();
      final result = await tool.execute({'path': 'bin.dat'}, _ctx(temp.path));
      expect(result.isError, isTrue);
      expect(result.content, contains('binary'));
    });

    test('calls onRead with the file content', () async {
      write('a.txt', 'hello');
      String? captured;
      final tool = ReadTool(onRead: (path, content) => captured = content);
      await tool.execute({'path': 'a.txt'}, _ctx(temp.path));
      expect(captured, 'hello');
    });

    test('emits the hash header when hashOf is provided', () async {
      write('a.txt', 'hello');
      final tool = ReadTool(hashOf: (c) => 'HASH${c.length}');
      final result = await tool.execute({'path': 'a.txt'}, _ctx(temp.path));
      expect(result.content, contains('hash=HASH5'));
      expect(result.content, contains('lines=1'));
    });

    test('accepts an absolute path inside the workspace', () async {
      write('a.txt', 'hi');
      final tool = ReadTool();
      final result = await tool.execute({
        'path': '${temp.path}/a.txt',
      }, _ctx(temp.path));
      expect(result.isError, isFalse);
      expect(result.content, contains('hi'));
    });
  });
}

/// Returns a canned match list for any query.
class _StubFileSearch implements FileSearchPort {
  const _StubFileSearch(this.matches);

  final List<FileSearchMatch> matches;

  @override
  Future<List<FileSearchMatch>> search(
    String query, {
    required String root,
    int limit = 25,
  }) async => matches;
}

/// Substring-matches file names without following symlinks, mirroring the
/// production engine (cc_natives' Rust `fff`).
class _NoLinkFollowSearch implements FileSearchPort {
  @override
  Future<List<FileSearchMatch>> search(
    String query, {
    required String root,
    int limit = 25,
  }) async {
    final stem = query.replaceAll(RegExp(r'\.dart$'), '').toLowerCase();
    return [
      for (final entity in Directory(
        root,
      ).listSync(recursive: true, followLinks: false))
        if (entity is File &&
            entity.uri.pathSegments.last.toLowerCase().contains(stem))
          FileSearchMatch(path: entity.path.substring(root.length + 1)),
    ];
  }
}

/// Always fails, proving suggestions are best-effort.
class _ThrowingFileSearch implements FileSearchPort {
  @override
  Future<List<FileSearchMatch>> search(
    String query, {
    required String root,
    int limit = 25,
  }) => throw StateError('search backend unavailable');
}
