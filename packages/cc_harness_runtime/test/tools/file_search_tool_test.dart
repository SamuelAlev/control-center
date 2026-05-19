import 'dart:io';

import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/src/tools/file_search_tool.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// A minimal pure-Dart [FileSearchPort] for tests: walks the root and
/// substring-matches relative paths (case-insensitive), mirroring the
/// behavior of the production cc_natives-backed adapter closely enough to
/// exercise the tool's argument handling and rendering.
class _WalkingFileSearch implements FileSearchPort {
  @override
  Future<List<FileSearchMatch>> search(
    String query, {
    required String root,
    int limit = 25,
  }) async {
    final needle = query.toLowerCase();
    final hits = <FileSearchMatch>[];
    for (final entity in Directory(root).listSync(recursive: true)) {
      final rel = p.relative(entity.path, from: root);
      if (rel.toLowerCase().contains(needle)) {
        hits.add(FileSearchMatch(path: rel, isDirectory: entity is Directory));
        if (hits.length >= limit) {
          break;
        }
      }
    }
    return hits;
  }
}

void main() {
  late Directory dir;
  late HarnessToolContext ctx;

  FileSearchTool tool() => FileSearchTool(fileSearch: _WalkingFileSearch());

  setUp(() {
    dir = Directory.systemTemp.createTempSync('file_search_');
    ctx = HarnessToolContext(workingDirectory: dir.path);
    File(p.join(dir.path, 'auth_service.dart')).writeAsStringSync('');
    File(p.join(dir.path, 'readme.md')).writeAsStringSync('');
    Directory(p.join(dir.path, 'lib')).createSync();
    File(p.join(dir.path, 'lib', 'auth_widget.dart')).writeAsStringSync('');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('fuzzy-matches file names by relevance', () async {
    final result = await tool().execute({'query': 'auth'}, ctx);
    expect(result.isError, isFalse);
    expect(result.content, contains('auth_service.dart'));
    expect(result.content, contains(p.join('lib', 'auth_widget.dart')));
    expect(result.content, isNot(contains('readme.md')));
  });

  test('reports no matches cleanly', () async {
    final result = await tool().execute({'query': 'zzznomatch'}, ctx);
    expect(result.isError, isFalse);
    expect(result.content, contains('No files match'));
  });

  test('directories render with a trailing slash', () async {
    final result = await tool().execute({'query': 'lib'}, ctx);
    expect(result.isError, isFalse);
    expect(result.content, contains('lib/'));
  });

  test('rejects a missing query', () async {
    final result = await tool().execute(const {}, ctx);
    expect(result.isError, isTrue);
  });

  group('per-agent overlay cwd', () {
    late Directory conv;
    late Directory overlay;
    late Directory repos;

    setUp(() {
      conv = Directory(p.join(dir.path, 'conv'))..createSync();
      repos = Directory(p.join(conv.path, 'repos'))..createSync();
      File(p.join(repos.path, 'myrepo', 'lib', 'editor_tab.dart'))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('');
      overlay = Directory(p.join(conv.path, 'agents', 'engineer'))
        ..createSync(recursive: true);
      Link(p.join(overlay.path, 'repos')).createSync('../../repos');
    });

    test(
      'searches the conversation worktrees, not just the overlay',
      () async {
        // The engine here does NOT follow symlinks — like the production Rust
        // `fff` — so this only passes if the tool searches the shared root.
        final result = await FileSearchTool(fileSearch: _NoLinkFollowSearch())
            .execute(
              {'query': 'editor_tab'},
              HarnessToolContext(
                workingDirectory: overlay.path,
                sharedRoots: [repos.path],
              ),
            );
        expect(result.isError, isFalse);
        expect(
          result.content,
          p.join('repos', 'myrepo', 'lib', 'editor_tab.dart'),
        );
      },
      skip: Platform.isWindows
          ? 'overlay repos-to-shared-root symlink identity is not reliably resolvable via dart:io on the Windows runner (relative-target reparse points plus the 8.3 TEMP short name defeat resolved-path comparison); the provisioner symlink overlay is a POSIX layout'
          : false,
    );
  });
}

/// Walks the root without following symlinks, mirroring the production engine.
class _NoLinkFollowSearch implements FileSearchPort {
  @override
  Future<List<FileSearchMatch>> search(
    String query, {
    required String root,
    int limit = 25,
  }) async {
    final needle = query.toLowerCase();
    return [
      for (final entity in Directory(
        root,
      ).listSync(recursive: true, followLinks: false))
        if (entity is! Link &&
            p.relative(entity.path, from: root).toLowerCase().contains(needle))
          FileSearchMatch(
            path: p.relative(entity.path, from: root),
            isDirectory: entity is Directory,
          ),
    ];
  }
}
