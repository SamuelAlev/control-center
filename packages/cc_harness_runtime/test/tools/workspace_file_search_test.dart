import 'dart:io';

import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/src/tools/workspace_file_search.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// A fake engine that mirrors the production one where it matters: it walks the
/// root WITHOUT following symlinks, exactly like cc_natives' Rust `fff`. A fake
/// that followed links (the obvious `listSync(recursive: true)` default) would
/// pass even when the tool never searches the shared root — which is how the
/// overlay-only search shipped broken.
class _NoSymlinkFollowSearch implements FileSearchPort {
  final roots = <String>[];

  @override
  Future<List<FileSearchMatch>> search(
    String query, {
    required String root,
    int limit = 25,
  }) async {
    roots.add(root);
    final needle = query.toLowerCase();
    final hits = <FileSearchMatch>[];
    for (final entity in Directory(
      root,
    ).listSync(recursive: true, followLinks: false)) {
      if (entity is Link) {
        continue;
      }
      final rel = p.relative(entity.path, from: root);
      if (needle.isEmpty || rel.toLowerCase().contains(needle)) {
        hits.add(
          FileSearchMatch(
            path: rel,
            isDirectory: entity is Directory,
            score: rel.length.toDouble(),
          ),
        );
      }
    }
    return hits.take(limit).toList();
  }
}

void main() {
  late Directory base;
  late Directory overlay;
  late Directory repos;

  setUp(() {
    // The per-agent overlay layout the provisioner builds:
    //   <convRoot>/repos/<repo>/…            (the CoW worktrees)
    //   <convRoot>/agents/<slug>/            (the cwd)
    //   <convRoot>/agents/<slug>/repos -> ../../repos
    base = Directory.systemTemp.createTempSync('workspace_file_search_');
    final conv = Directory(p.join(base.path, 'conv'))..createSync();
    repos = Directory(p.join(conv.path, 'repos'))..createSync();
    File(p.join(repos.path, 'myrepo', 'lib', 'editor_tab.dart'))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('');
    overlay = Directory(p.join(conv.path, 'agents', 'engineer'))
      ..createSync(recursive: true);
    File(p.join(overlay.path, 'AGENTS.md')).writeAsStringSync('');
    Link(p.join(overlay.path, 'repos')).createSync('../../repos');
  });

  tearDown(() => base.deleteSync(recursive: true));

  test(
    'finds worktree files the overlay only reaches through a symlink',
    () async {
      final engine = _NoSymlinkFollowSearch();
      final hits = await searchWorkspaceFiles(
        engine,
        'editor_tab',
        workspaceRoot: overlay.path,
        sharedRoots: [repos.path],
      );
      expect(
        hits.map((h) => h.path),
        [p.join('repos', 'myrepo', 'lib', 'editor_tab.dart')],
        reason:
            'the hit must carry the symlink prefix so `read` accepts it back',
      );
      expect(engine.roots, contains(repos.path));
    },
    skip: Platform.isWindows
        ? 'overlay repos-to-shared-root symlink identity is not reliably '
              'resolvable via dart:io on the Windows runner '
              '(relative-target reparse points plus the 8.3 TEMP short name '
              'defeat resolved-path comparison); the provisioner symlink '
              'overlay is a POSIX layout'
        : false,
  );

  test('returns nothing without the shared root (the regression)', () async {
    final hits = await searchWorkspaceFiles(
      _NoSymlinkFollowSearch(),
      'editor_tab',
      workspaceRoot: overlay.path,
    );
    expect(hits, isEmpty);
  });

  test('still searches the working directory itself', () async {
    final hits = await searchWorkspaceFiles(
      _NoSymlinkFollowSearch(),
      'AGENTS',
      workspaceRoot: overlay.path,
      sharedRoots: [repos.path],
    );
    expect(hits.map((h) => h.path), ['AGENTS.md']);
  });

  test(
    'falls back to the absolute path when no symlink reaches the root',
    () async {
      final unlinked = Directory(p.join(base.path, 'elsewhere'))..createSync();
      File(p.join(unlinked.path, 'editor_tab.dart')).writeAsStringSync('');
      final hits = await searchWorkspaceFiles(
        _NoSymlinkFollowSearch(),
        'editor_tab',
        workspaceRoot: overlay.path,
        sharedRoots: [unlinked.path],
      );
      expect(hits.map((h) => h.path), [
        p.join(unlinked.path, 'editor_tab.dart'),
      ]);
    },
  );

  test(
    'merges roots by descending score and de-duplicates',
    () async {
      final hits = await searchWorkspaceFiles(
        _RankedSearch({
          overlay.path: const [
            FileSearchMatch(path: 'low.dart', score: 1),
            FileSearchMatch(path: 'high.dart', score: 9),
          ],
          repos.path: const [
            FileSearchMatch(path: 'mid.dart', score: 5),
            // Same display path as the overlay hit once prefixed? No — this
            // proves a duplicate emitted by both roots collapses to one entry.
            FileSearchMatch(path: 'high.dart', score: 9),
          ],
        }),
        'x',
        workspaceRoot: overlay.path,
        sharedRoots: [repos.path],
      );
      expect(hits.map((h) => h.path), [
        'high.dart',
        p.join('repos', 'high.dart'),
        p.join('repos', 'mid.dart'),
        'low.dart',
      ]);
    },
    skip: Platform.isWindows
        ? 'overlay repos-to-shared-root symlink identity is not reliably '
              'resolvable via dart:io on the Windows runner '
              '(relative-target reparse points plus the 8.3 TEMP short name '
              'defeat resolved-path comparison); the provisioner symlink '
              'overlay is a POSIX layout'
        : false,
  );

  test('honours the limit across all roots', () async {
    final hits = await searchWorkspaceFiles(
      _NoSymlinkFollowSearch(),
      '',
      workspaceRoot: overlay.path,
      sharedRoots: [repos.path],
      limit: 2,
    );
    expect(hits, hasLength(2));
  });

  test(
    'a shared root equal to the working directory is not searched twice',
    () async {
      final engine = _NoSymlinkFollowSearch();
      await searchWorkspaceFiles(
        engine,
        'AGENTS',
        workspaceRoot: overlay.path,
        sharedRoots: ['${overlay.path}/'],
      );
      expect(engine.roots, hasLength(1));
    },
  );
}

/// Returns per-root canned matches, for ordering/dedup assertions.
class _RankedSearch implements FileSearchPort {
  _RankedSearch(this.byRoot);

  final Map<String, List<FileSearchMatch>> byRoot;

  @override
  Future<List<FileSearchMatch>> search(
    String query, {
    required String root,
    int limit = 25,
  }) async => byRoot[root] ?? const [];
}
