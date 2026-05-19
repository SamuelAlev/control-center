import 'dart:async';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/ports/session_diff_port.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
// The pure-Dart engine is now injected explicitly: `fileSearch` is a required
// parameter so a missing `libfff_c` can never silently degrade in production.
import 'package:cc_natives/cc_natives.dart' show DartFileSearch;
import 'package:cc_server_core/src/repo_ide_data_service.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('repo_ide_data_test_');
  });

  tearDown(() {
    if (tmp.existsSync()) {
      tmp.deleteSync(recursive: true);
    }
  });

  Repo repo(String id, String path) => Repo(
    id: id,
    name: id,
    path: path,
    remoteOwner: 'owner',
    remoteName: id,
    createdAt: DateTime(2025),
    updatedAt: DateTime(2025),
  );

  String makeRepoDir(String name, Map<String, String> files) {
    final root = Directory(p.join(tmp.path, name))..createSync(recursive: true);
    files.forEach((rel, contents) {
      final f = File(p.join(root.path, rel))..createSync(recursive: true);
      f.writeAsStringSync(contents);
    });
    return root.path;
  }

  group('searchFiles', () {
    test(
      'lists a workspace\'s linked repos, tagging each hit with its repoId',
      () async {
        final rootA = makeRepoDir('a', {
          'lib/main.dart': '//',
          'README.md': '#',
        });
        final rootB = makeRepoDir('b', {'src/util.ts': '//'});
        final ws = _FakeWorkspaceRepo()
          ..reposByWorkspace['ws'] = [repo('a', rootA), repo('b', rootB)];
        final svc = RepoIdeDataService(
          repoRepository: _FakeRepoRepo(),
          workspaceRepository: ws,
          isolatedRepoRepository: _FakeIsolatedRepoRepo(),
          fileSearch: DartFileSearch(),
        );

        final hits = await svc.searchFiles('ws', '');

        final byRepo = <String, Set<String>>{};
        for (final h in hits) {
          byRepo
              .putIfAbsent(h['repoId'] as String, () => {})
              .add(h['relativePath'] as String);
        }
        expect(
          byRepo['a'],
          containsAll(<String>['lib/main.dart', 'README.md']),
        );
        expect(byRepo['b'], contains('src/util.ts'));
        // No hit is left without a resolved repo.
        expect(hits.every((h) => (h['repoId'] as String).isNotEmpty), isTrue);
      },
    );

    test('a non-empty query returns a scored subset', () async {
      final root = makeRepoDir('a', {
        'lib/widget.dart': '//',
        'lib/service.dart': '//',
        'docs/guide.md': '#',
      });
      final ws = _FakeWorkspaceRepo()
        ..reposByWorkspace['ws'] = [repo('a', root)];
      final svc = RepoIdeDataService(
        repoRepository: _FakeRepoRepo(),
        workspaceRepository: ws,
        isolatedRepoRepository: _FakeIsolatedRepoRepo(),
        fileSearch: DartFileSearch(),
      );

      final hits = await svc.searchFiles('ws', 'widget');

      final paths = hits.map((h) => h['relativePath'] as String).toList();
      expect(paths, contains('lib/widget.dart'));
      expect(paths, isNot(contains('docs/guide.md')));
    });

    test(
      'pages with offset: consecutive pages are disjoint and exhaustive',
      () async {
        final root = makeRepoDir('a', {
          for (var i = 0; i < 6; i++) 'lib/file_$i.dart': '//',
        });
        final ws = _FakeWorkspaceRepo()
          ..reposByWorkspace['ws'] = [repo('a', root)];
        final svc = RepoIdeDataService(
          repoRepository: _FakeRepoRepo(),
          workspaceRepository: ws,
          isolatedRepoRepository: _FakeIsolatedRepoRepo(),
          fileSearch: DartFileSearch(),
        );

        final page0 = await svc.searchFiles('ws', 'file_', offset: 0, limit: 4);
        final page1 = await svc.searchFiles('ws', 'file_', offset: 4, limit: 4);

        expect(page0, hasLength(4));
        // Only the remainder — the offset skipped the first page's ranks.
        expect(page1, hasLength(2));
        final paths = [
          for (final h in [...page0, ...page1]) h['relativePath'] as String,
        ];
        expect(paths.toSet(), hasLength(paths.length));
        expect(
          paths.toSet(),
          equals({for (var i = 0; i < 6; i++) 'lib/file_$i.dart'}),
        );
      },
    );

    test('an empty query is bounded to one page, not the full tree', () async {
      final root = makeRepoDir('a', {
        for (var i = 0; i < 5; i++) 'lib/file_$i.dart': '//',
      });
      final ws = _FakeWorkspaceRepo()
        ..reposByWorkspace['ws'] = [repo('a', root)];
      final svc = RepoIdeDataService(
        repoRepository: _FakeRepoRepo(),
        workspaceRepository: ws,
        isolatedRepoRepository: _FakeIsolatedRepoRepo(),
        fileSearch: DartFileSearch(),
      );

      // The unbounded full-tree mode is gone: an empty query is a page like
      // any other, so a legacy caller can no longer pull a whole monorepo in
      // one frame.
      final page = await svc.searchFiles('ws', '', limit: 2);
      expect(page, hasLength(2));
    });

    test(
      'is workspace-scoped: another workspace sees none of these repos',
      () async {
        final root = makeRepoDir('a', {'lib/main.dart': '//'});
        final ws = _FakeWorkspaceRepo()
          ..reposByWorkspace['ws'] = [repo('a', root)];
        final svc = RepoIdeDataService(
          repoRepository: _FakeRepoRepo(),
          workspaceRepository: ws,
          isolatedRepoRepository: _FakeIsolatedRepoRepo(),
          fileSearch: DartFileSearch(),
        );

        expect(await svc.searchFiles('other-ws', ''), isEmpty);
      },
    );
  });

  group('listDirectory', () {
    RepoIdeDataService svcWith(String root) => RepoIdeDataService(
      repoRepository: _FakeRepoRepo({'a': repo('a', root)}),
      workspaceRepository: _FakeWorkspaceRepo()..linked['ws'] = {'a'},
      isolatedRepoRepository: _FakeIsolatedRepoRepo(),
      fileSearch: DartFileSearch(),
    );

    List<(String, bool)> entriesOf(Map<String, dynamic> page) => [
      for (final e in (page['entries'] as List).whereType<Map>())
        (e['relativePath'] as String, e['isDirectory'] as bool),
    ];

    test('lists one level of the repo root, marking directories', () async {
      final root = makeRepoDir('a', {'lib/main.dart': '//', 'README.md': '#'});
      final svc = svcWith(root);

      final page = await svc.listDirectory('ws', 'a');
      final entries = entriesOf(page);

      expect(entries, contains(('README.md', false)));
      expect(entries, contains(('lib', true)));
      // One level deep — the file inside lib/ is NOT in the root listing.
      expect(
        entries,
        isNot(contains(predicate((e) => '$e'.contains('main.dart')))),
      );
      expect(page['has_more'], isFalse);
    });

    test('lists a subdirectory with repo-relative paths', () async {
      final root = makeRepoDir('a', {
        'lib/deep/widget.dart': '//',
        'lib/util.dart': '//',
      });
      final svc = svcWith(root);

      final page = await svc.listDirectory('ws', 'a', path: 'lib');
      final entries = entriesOf(page);

      expect(
        entries,
        containsAll(<(String, bool)>[
          ('lib/util.dart', false),
          ('lib/deep', true),
        ]),
      );
    });

    test('hides .git unconditionally', () async {
      final root = makeRepoDir('a', {'README.md': '#'});
      await _gitInit(root);
      final svc = svcWith(root);

      final entries = entriesOf(await svc.listDirectory('ws', 'a'));
      expect(entries.where((e) => e.$1 == '.git'), isEmpty);
    });

    test('honors .gitignore — ignored children are hidden', () async {
      final root = makeRepoDir('a', {
        '.gitignore': 'ignored/\n*.log\n',
        'lib/main.dart': '//',
        'ignored/secret.txt': 'x',
        'debug.log': 'x',
      });
      await _gitInit(root);
      final svc = svcWith(root);

      final entries = entriesOf(await svc.listDirectory('ws', 'a'));

      // What git ignores, the tree hides (parity with the fff-ranked list).
      expect(entries.where((e) => e.$1.contains('ignored')), isEmpty);
      expect(entries.where((e) => e.$1 == 'debug.log'), isEmpty);
      // Everything else survives — including the .gitignore itself.
      expect(
        entries,
        containsAll(<(String, bool)>[('.gitignore', false), ('lib', true)]),
      );
    });

    test('cursor pages are ordered, disjoint and exhaustive', () async {
      final root = makeRepoDir('a', {
        for (var i = 0; i < 6; i++) 'f0$i.txt': 'x',
      });
      final svc = svcWith(root);

      final page1 = await svc.listDirectory('ws', 'a', limit: 4);
      // `has_more`, snake — the key the client's decoder actually reads, and
      // the one every other paged op on this transport uses. Asserted as
      // `hasMore` here, it agreed with a server nothing could page through:
      // the flag never reached the tree, so every directory stopped at its
      // first page with no sign that it had.
      expect(page1['has_more'], isTrue);
      final first = entriesOf(page1);
      expect(first, hasLength(4));
      // Path-ordered.
      expect([
        for (final e in first) e.$1,
      ], equals(['f00.txt', 'f01.txt', 'f02.txt', 'f03.txt']));

      final page2 = await svc.listDirectory(
        'ws',
        'a',
        cursor: first.last.$1,
        limit: 4,
      );
      expect(page2['has_more'], isFalse);
      final second = entriesOf(page2);
      expect([for (final e in second) e.$1], equals(['f04.txt', 'f05.txt']));

      // Union = the whole directory, each entry exactly once.
      final union = [
        ...[for (final e in first) e.$1],
        ...[for (final e in second) e.$1],
      ];
      expect(union.toSet(), hasLength(6));
    });

    test('rejects traversal outside the repo root', () async {
      final other = makeRepoDir('other', {'secret.txt': 'x'});
      final root = makeRepoDir('a', {'README.md': '#'});
      final svc = svcWith(root);

      for (final escape in ['../other', '../../etc']) {
        final page = await svc.listDirectory('ws', 'a', path: escape);
        expect(page['entries'] as List, isEmpty, reason: 'path: $escape');
        expect(page['has_more'], isFalse, reason: 'path: $escape');
      }
      // Sanity: the sibling directory exists but is unreachable through the
      // service.
      expect(File(p.join(other, 'secret.txt')).existsSync(), isTrue);
    });

    test('a file (not a directory) path lists nothing', () async {
      final root = makeRepoDir('a', {'README.md': '#'});
      final svc = svcWith(root);

      final page = await svc.listDirectory('ws', 'a', path: 'README.md');
      expect(page['entries'] as List, isEmpty);
      expect(page['has_more'], isFalse);
    });

    test('is workspace-scoped: a foreign repo is simply not found', () async {
      final root = makeRepoDir('a', {'README.md': '#'});
      // Workspace 'other-ws' has NOT linked repo 'a'.
      final svc = RepoIdeDataService(
        repoRepository: _FakeRepoRepo({'a': repo('a', root)}),
        workspaceRepository: _FakeWorkspaceRepo()..linked['other-ws'] = {},
        isolatedRepoRepository: _FakeIsolatedRepoRepo(),
        fileSearch: DartFileSearch(),
      );

      final page = await svc.listDirectory('other-ws', 'a');
      expect(page['entries'] as List, isEmpty);
      expect(page['has_more'], isFalse);
    });
  });

  group('readFile', () {
    test('reads a linked repo\'s text file', () async {
      final root = makeRepoDir('a', {'lib/main.dart': 'void main() {}'});
      final svc = RepoIdeDataService(
        repoRepository: _FakeRepoRepo({'a': repo('a', root)}),
        workspaceRepository: _FakeWorkspaceRepo()..linked['ws'] = {'a'},
        isolatedRepoRepository: _FakeIsolatedRepoRepo(),
        fileSearch: DartFileSearch(),
      );

      final res = await svc.readFile('ws', 'a', 'lib/main.dart');

      expect(res.content, 'void main() {}');
      expect(res.binary, isFalse);
    });

    test('flags a file with a NUL byte as binary (no content)', () async {
      final root = Directory(p.join(tmp.path, 'a'))..createSync();
      File(p.join(root.path, 'blob.bin')).writeAsBytesSync([1, 2, 0, 3, 4]);
      final svc = RepoIdeDataService(
        repoRepository: _FakeRepoRepo({'a': repo('a', root.path)}),
        workspaceRepository: _FakeWorkspaceRepo()..linked['ws'] = {'a'},
        isolatedRepoRepository: _FakeIsolatedRepoRepo(),
        fileSearch: DartFileSearch(),
      );

      final res = await svc.readFile('ws', 'a', 'blob.bin');

      expect(res.binary, isTrue);
      expect(res.content, isEmpty);
    });

    test('rejects path traversal outside the repo root', () async {
      final root = makeRepoDir('a', {'ok.txt': 'ok'});
      // A secret sitting next to (outside) the repo root.
      File(p.join(tmp.path, 'secret.txt')).writeAsStringSync('TOP SECRET');
      final svc = RepoIdeDataService(
        repoRepository: _FakeRepoRepo({'a': repo('a', root)}),
        workspaceRepository: _FakeWorkspaceRepo()..linked['ws'] = {'a'},
        isolatedRepoRepository: _FakeIsolatedRepoRepo(),
        fileSearch: DartFileSearch(),
      );

      final res = await svc.readFile('ws', 'a', '../secret.txt');

      expect(res.content, isEmpty);
      expect(res.binary, isFalse);
    });

    test('returns empty for a repo not linked to the workspace', () async {
      final root = makeRepoDir('a', {'lib/main.dart': 'x'});
      final svc = RepoIdeDataService(
        repoRepository: _FakeRepoRepo({'a': repo('a', root)}),
        // 'a' is NOT in ws's linked set.
        workspaceRepository: _FakeWorkspaceRepo()..linked['ws'] = {},
        isolatedRepoRepository: _FakeIsolatedRepoRepo(),
        fileSearch: DartFileSearch(),
      );

      final res = await svc.readFile('ws', 'a', 'lib/main.dart');

      expect(res.content, isEmpty);
    });
  });

  group('repoChanges', () {
    test('diffs the linked repo\'s checkout against HEAD', () async {
      final diff = _FakeSessionDiff({
        '/repos/a': [_prFile('lib/main.dart')],
      });
      final svc = RepoIdeDataService(
        repoRepository: _FakeRepoRepo({'a': repo('a', '/repos/a')}),
        workspaceRepository: _FakeWorkspaceRepo()..linked['ws'] = {'a'},
        isolatedRepoRepository: _FakeIsolatedRepoRepo(),
        fileSearch: DartFileSearch(),
        diff: diff,
      );

      final files = await svc.repoChanges('ws', 'a');

      expect(files.single.filename, 'lib/main.dart');
      expect(diff.calls, [('/repos/a', 'HEAD')]);
    });

    test(
      'never touches the checkout of a repo from another workspace',
      () async {
        final diff = _FakeSessionDiff({
          '/repos/a': [_prFile('x')],
        });
        final svc = RepoIdeDataService(
          repoRepository: _FakeRepoRepo({'a': repo('a', '/repos/a')}),
          // 'a' linked to ws, but caller asks as 'intruder'.
          workspaceRepository: _FakeWorkspaceRepo()..linked['ws'] = {'a'},
          isolatedRepoRepository: _FakeIsolatedRepoRepo(),
          fileSearch: DartFileSearch(),
          diff: diff,
        );

        final files = await svc.repoChanges('intruder', 'a');

        expect(files, isEmpty);
        expect(diff.calls, isEmpty, reason: 'must not diff a foreign checkout');
      },
    );

    // The IDE Source Control panel is per-conversation: with a spaceId, the
    // diff must run against the conversation's isolated CoW worktree (the tree
    // agents/code-server edit), NOT the original linked-repo checkout. This is
    // the regression test for "Source shows the original repo, not the CoW
    // worktree".
    test('with a spaceId, diffs the conversation\'s CoW worktree', () async {
      final diff = _FakeSessionDiff({
        // Both the linked checkout and the worktree report a change, but with
        // DIFFERENT files — so the assertion can tell which one was diffed.
        '/repos/a': [_prFile('linked-only.txt')],
        '/wt/a': [_prFile('worktree-only.txt')],
      });
      final iso = _FakeIsolatedRepoRepo()
        ..bySpace['ws:ch'] = [_worktree('a', '/wt/a')];
      final svc = RepoIdeDataService(
        repoRepository: _FakeRepoRepo({'a': repo('a', '/repos/a')}),
        workspaceRepository: _FakeWorkspaceRepo()..linked['ws'] = {'a'},
        isolatedRepoRepository: iso,
        fileSearch: DartFileSearch(),
        diff: diff,
      );

      final files = await svc.repoChanges('ws', 'a', spaceId: 'ch');

      // The worktree's change — NOT the linked checkout's.
      expect(files.single.filename, 'worktree-only.txt');
      expect(diff.calls.single, ('/wt/a', 'HEAD'));
    });

    // With a spaceId, an unprovisioned worktree must NOT fall back to the
    // linked checkout: that would surface the ORIGINAL repo's changes (which
    // the conversation's write ops never touch), so the diff would silently
    // disagree with what a commit would stage. The client gates on the
    // space's provisioning status and shows a "preparing" state instead.
    test(
      'with a spaceId and no worktree, returns empty (no fallback)',
      () async {
        final diff = _FakeSessionDiff({
          '/repos/a': [_prFile('linked-only.txt')],
        });
        final svc = RepoIdeDataService(
          repoRepository: _FakeRepoRepo({'a': repo('a', '/repos/a')}),
          workspaceRepository: _FakeWorkspaceRepo()..linked['ws'] = {'a'},
          isolatedRepoRepository: _FakeIsolatedRepoRepo(), // no worktree for ch
          fileSearch: DartFileSearch(),
          diff: diff,
        );

        final files = await svc.repoChanges('ws', 'a', spaceId: 'ch');

        expect(files, isEmpty);
        expect(
          diff.calls,
          isEmpty,
          reason: 'must not diff the original checkout for a channel',
        );
      },
    );

    // The no-space case (the IDE panel with no open conversation) still
    // diffs the linked checkout directly.
    test('with no spaceId, diffs the linked checkout', () async {
      final diff = _FakeSessionDiff({
        '/repos/a': [_prFile('linked-only.txt')],
      });
      final svc = RepoIdeDataService(
        repoRepository: _FakeRepoRepo({'a': repo('a', '/repos/a')}),
        workspaceRepository: _FakeWorkspaceRepo()..linked['ws'] = {'a'},
        isolatedRepoRepository: _FakeIsolatedRepoRepo(),
        fileSearch: DartFileSearch(),
        diff: diff,
      );

      final files = await svc.repoChanges('ws', 'a');

      expect(files.single.filename, 'linked-only.txt');
      expect(diff.calls.single, ('/repos/a', 'HEAD'));
    });
  });

  group('conversationChanges', () {
    test(
      'aggregates diffs across the conversation\'s isolated worktrees',
      () async {
        final diff = _FakeSessionDiff({
          '/wt/a': [_prFile('a.dart')],
          '/wt/b': [_prFile('b.dart')],
        });
        final isolated = _FakeIsolatedRepoRepo()
          ..bySpace['ws:ch'] = [
            _worktree('a', '/wt/a'),
            _worktree('b', '/wt/b'),
          ];
        final svc = RepoIdeDataService(
          repoRepository: _FakeRepoRepo(),
          workspaceRepository: _FakeWorkspaceRepo(),
          isolatedRepoRepository: isolated,
          fileSearch: DartFileSearch(),
          diff: diff,
        );

        final files = await svc.conversationChanges('ws', 'ch');

        expect(files.map((f) => f.filename), containsAll(['a.dart', 'b.dart']));
      },
    );

    test('sees no worktrees for a different workspace', () async {
      final diff = _FakeSessionDiff({
        '/wt/a': [_prFile('a.dart')],
      });
      final isolated = _FakeIsolatedRepoRepo()
        ..bySpace['ws:ch'] = [_worktree('a', '/wt/a')];
      final svc = RepoIdeDataService(
        repoRepository: _FakeRepoRepo(),
        workspaceRepository: _FakeWorkspaceRepo(),
        isolatedRepoRepository: isolated,
        fileSearch: DartFileSearch(),
        diff: diff,
      );

      expect(await svc.conversationChanges('other', 'ch'), isEmpty);
    });
  });

  group('searchContent', () {
    Future<void> git(List<String> args, String dir) async {
      final r = await Process.run('git', args, workingDirectory: dir);
      if (r.exitCode != 0 && !args.contains('grep')) {
        throw StateError('git ${args.join(' ')} failed: ${r.stderr}');
      }
    }

    Future<String> gitRepo(String name, Map<String, String> files) async {
      final root = makeRepoDir(name, files);
      await git(['init', '-q'], root);
      await git(['config', 'core.autocrlf', 'false'], root);
      await git(['config', 'user.email', 'test@example.com'], root);
      await git(['config', 'user.name', 'Test'], root);
      await git(['config', 'commit.gpgsign', 'false'], root);
      await git(['add', '-A'], root);
      await git(['commit', '-q', '-m', 'init'], root);
      return root;
    }

    test('groups literal matches per file with line numbers', () async {
      final root = await gitRepo('a', {
        'lib/service.dart': 'class Service {}\n// needle here\nfinal x = 1;\n',
        'docs/guide.md': 'no match in this file\n',
        'lib/util.dart': 'final needle = true;\n',
      });
      final ws = _FakeWorkspaceRepo()
        ..reposByWorkspace['ws'] = [repo('a', root)];
      final svc = RepoIdeDataService(
        repoRepository: _FakeRepoRepo(),
        workspaceRepository: ws,
        isolatedRepoRepository: _FakeIsolatedRepoRepo(),
        fileSearch: DartFileSearch(),
      );

      final hits = await svc.searchContent('ws', 'needle');

      final byPath = {for (final h in hits) h['relativePath'] as String: h};
      expect(byPath.keys, containsAll(['lib/service.dart', 'lib/util.dart']));
      expect(byPath.keys, isNot(contains('docs/guide.md')));
      final serviceMatches = (byPath['lib/service.dart']!['matches'] as List)
          .cast<Map>();
      expect(serviceMatches.single['line'], 2);
      expect(serviceMatches.single['text'], contains('needle'));
      expect(hits.every((h) => h['repoId'] == 'a'), isTrue);
    });

    test('is case-insensitive and includes untracked files', () async {
      final root = await gitRepo('a', {'tracked.dart': 'final Needle = 1;\n'});
      // Untracked (added after the commit, never staged).
      File(p.join(root, 'fresh.dart')).writeAsStringSync('var NEEDLE = 2;\n');
      final ws = _FakeWorkspaceRepo()
        ..reposByWorkspace['ws'] = [repo('a', root)];
      final svc = RepoIdeDataService(
        repoRepository: _FakeRepoRepo(),
        workspaceRepository: ws,
        isolatedRepoRepository: _FakeIsolatedRepoRepo(),
        fileSearch: DartFileSearch(),
      );

      final paths = (await svc.searchContent(
        'ws',
        'needle',
      )).map((h) => h['relativePath'] as String).toSet();

      expect(paths, containsAll(['tracked.dart', 'fresh.dart']));
    });

    test('empty query and foreign workspace both yield nothing', () async {
      final root = await gitRepo('a', {'a.dart': 'needle\n'});
      final ws = _FakeWorkspaceRepo()
        ..reposByWorkspace['ws'] = [repo('a', root)];
      final svc = RepoIdeDataService(
        repoRepository: _FakeRepoRepo(),
        workspaceRepository: ws,
        isolatedRepoRepository: _FakeIsolatedRepoRepo(),
        fileSearch: DartFileSearch(),
      );

      expect(await svc.searchContent('ws', '   '), isEmpty);
      expect(await svc.searchContent('other-ws', 'needle'), isEmpty);
    });
  });

  group('searchContentWithOptions', () {
    Future<String> gitRepo(String name, Map<String, String> files) async {
      final root = makeRepoDir(name, files);
      await _gitInit(root);
      return root;
    }

    test('case-sensitive matches only the exact case', () async {
      final root = await gitRepo('a', {
        'a.dart': 'final Needle = 1;\nvar needle = 2;\n',
      });
      final ws = _FakeWorkspaceRepo()
        ..reposByWorkspace['ws'] = [repo('a', root)];
      final svc = RepoIdeDataService(
        repoRepository: _FakeRepoRepo(),
        workspaceRepository: ws,
        isolatedRepoRepository: _FakeIsolatedRepoRepo(),
        fileSearch: DartFileSearch(),
      );

      final sensitive = await svc.searchContentWithOptions(
        'ws',
        'Needle',
        options: const {'case_sensitive': true},
      );
      final insensitive = await svc.searchContentWithOptions(
        'ws',
        'needle',
        options: const {},
      );

      // Case-sensitive finds only the line with the matching case.
      expect(sensitive.length, 1);
      // Default (legacy) finds both regardless of case.
      expect(insensitive.length, 1);
      final lines = (insensitive.single['matches'] as List)
          .cast<Map>()
          .map((m) => m['line'] as int)
          .toSet();
      expect(lines, containsAll([1, 2]));
    });

    test('regex matches a pattern', () async {
      final root = await gitRepo('a', {
        'a.dart': 'final foo123 = 1;\nfinal bar = 2;\n',
      });
      final ws = _FakeWorkspaceRepo()
        ..reposByWorkspace['ws'] = [repo('a', root)];
      final svc = RepoIdeDataService(
        repoRepository: _FakeRepoRepo(),
        workspaceRepository: ws,
        isolatedRepoRepository: _FakeIsolatedRepoRepo(),
        fileSearch: DartFileSearch(),
      );

      final hits = await svc.searchContentWithOptions(
        'ws',
        r'foo[0-9]+',
        options: const {'regex': true},
      );

      expect(hits.length, 1);
      expect(hits.single['relativePath'], 'a.dart');
    });

    test('exclude glob filters files out', () async {
      final root = await gitRepo('a', {
        'lib/keep.dart': 'needle\n',
        'lib/skip.dart': 'needle\n',
      });
      final ws = _FakeWorkspaceRepo()
        ..reposByWorkspace['ws'] = [repo('a', root)];
      final svc = RepoIdeDataService(
        repoRepository: _FakeRepoRepo(),
        workspaceRepository: ws,
        isolatedRepoRepository: _FakeIsolatedRepoRepo(),
        fileSearch: DartFileSearch(),
      );

      final hits = await svc.searchContentWithOptions(
        'ws',
        'needle',
        options: const {'exclude': '*skip.dart'},
      );

      final paths = hits.map((h) => h['relativePath'] as String).toSet();
      expect(paths, contains('lib/keep.dart'));
      expect(paths, isNot(contains('lib/skip.dart')));
    });
  });

  group('searchContentInWorktree', () {
    Future<String> gitRepo(String name, Map<String, String> files) async {
      final root = makeRepoDir(name, files);
      await _gitInit(root);
      return root;
    }

    test('greps the conversation worktree (tracked + untracked)', () async {
      final wt = await gitRepo('wt', {
        'lib/service.dart': 'class Service {}\n// needle here\n',
      });
      // An untracked file added after the commit must still match.
      File(p.join(wt, 'fresh.dart')).writeAsStringSync('var needle = 1;\n');
      final iso = _FakeIsolatedRepoRepo()
        ..bySpace['ws:ch'] = [_worktree('repo1', wt)];
      final svc = RepoIdeDataService(
        repoRepository: _FakeRepoRepo(),
        workspaceRepository: _FakeWorkspaceRepo()..linked['ws'] = {'repo1'},
        isolatedRepoRepository: iso,
        fileSearch: DartFileSearch(),
      );

      final hits = await svc.searchContentInWorktree(
        'ws',
        'ch',
        'repo1',
        'needle',
      );

      final paths = hits.map((h) => h['relativePath'] as String).toSet();
      expect(paths, containsAll(['lib/service.dart', 'fresh.dart']));
      // Every group is attributed to the searched repo.
      expect(hits.every((h) => h['repoId'] == 'repo1'), isTrue);
    });

    test('a foreign/unprovisioned space yields nothing (no leak)', () async {
      final wt = await gitRepo('wt', {'a.dart': 'needle\n'});
      final iso = _FakeIsolatedRepoRepo()
        ..bySpace['ws:ch'] = [_worktree('repo1', wt)];
      final svc = RepoIdeDataService(
        repoRepository: _FakeRepoRepo(),
        workspaceRepository: _FakeWorkspaceRepo()..linked['ws'] = {'repo1'},
        isolatedRepoRepository: iso,
        fileSearch: DartFileSearch(),
      );

      // Wrong workspace, wrong space, or wrong repo → no worktree → empty.
      expect(
        await svc.searchContentInWorktree('other', 'ch', 'repo1', 'needle'),
        isEmpty,
      );
      expect(
        await svc.searchContentInWorktree('ws', 'other-ch', 'repo1', 'needle'),
        isEmpty,
      );
      expect(
        await svc.searchContentInWorktree('ws', 'ch', 'repo2', 'needle'),
        isEmpty,
      );
    });

    test('an empty query yields nothing', () async {
      final wt = await gitRepo('wt', {'a.dart': 'needle\n'});
      final iso = _FakeIsolatedRepoRepo()
        ..bySpace['ws:ch'] = [_worktree('repo1', wt)];
      final svc = RepoIdeDataService(
        repoRepository: _FakeRepoRepo(),
        workspaceRepository: _FakeWorkspaceRepo()..linked['ws'] = {'repo1'},
        isolatedRepoRepository: iso,
        fileSearch: DartFileSearch(),
      );

      expect(
        await svc.searchContentInWorktree('ws', 'ch', 'repo1', '   '),
        isEmpty,
      );
    });
  });

  group('searchFilesInWorktree', () {
    Future<String> gitRepo(String name, Map<String, String> files) async {
      final root = makeRepoDir(name, files);
      await _gitInit(root);
      return root;
    }

    test(
      'finds files in the conversation worktree (tracked + untracked)',
      () async {
        final wt = await gitRepo('wt', {
          'lib/service.dart': 'class Service {}\n',
        });
        // An untracked file created in the worktree must still list.
        File(
          p.join(wt, 'lib', 'fresh_service.dart'),
        ).writeAsStringSync('var x = 1;\n');
        final iso = _FakeIsolatedRepoRepo()
          ..bySpace['ws:ch'] = [_worktree('repo1', wt)];
        final svc = RepoIdeDataService(
          repoRepository: _FakeRepoRepo(),
          workspaceRepository: _FakeWorkspaceRepo()..linked['ws'] = {'repo1'},
          isolatedRepoRepository: iso,
          fileSearch: DartFileSearch(),
        );

        final hits = await svc.searchFilesInWorktree(
          'ws',
          'ch',
          'repo1',
          'service',
        );

        final paths = hits.map((h) => h['relativePath'] as String).toSet();
        expect(
          paths,
          containsAll(['lib/service.dart', 'lib/fresh_service.dart']),
        );
        // Every hit is attributed to the searched repo.
        expect(hits.every((h) => h['repoId'] == 'repo1'), isTrue);
      },
    );

    test('a foreign/unprovisioned space yields nothing (no leak)', () async {
      final wt = await gitRepo('wt', {'a.dart': 'x\n'});
      final iso = _FakeIsolatedRepoRepo()
        ..bySpace['ws:ch'] = [_worktree('repo1', wt)];
      final svc = RepoIdeDataService(
        repoRepository: _FakeRepoRepo(),
        workspaceRepository: _FakeWorkspaceRepo()..linked['ws'] = {'repo1'},
        isolatedRepoRepository: iso,
        fileSearch: DartFileSearch(),
      );

      // Wrong workspace, wrong space, or wrong repo → no worktree → empty.
      expect(
        await svc.searchFilesInWorktree('other', 'ch', 'repo1', 'a'),
        isEmpty,
      );
      expect(
        await svc.searchFilesInWorktree('ws', 'other-ch', 'repo1', 'a'),
        isEmpty,
      );
      expect(
        await svc.searchFilesInWorktree('ws', 'ch', 'repo2', 'a'),
        isEmpty,
      );
    });
  });

  // The IDE Explorer inside a conversation: the tree, the fuzzy finder, the
  // grep and the quick view all read that conversation's ISOLATED CoW
  // worktrees. Reading the shared linked checkout instead would list files the
  // conversation never wrote (and hide the ones it did).
  group('space-scoped Explorer reads', () {
    List<String> pathsOf(Map<String, dynamic> page) => [
      for (final e in (page['entries'] as List).whereType<Map>())
        e['relativePath'] as String,
    ];

    RepoIdeDataService svcWith({
      required Map<String, Repo> linkedRepos,
      required Map<String, String> worktreesByRepoId,
    }) => RepoIdeDataService(
      repoRepository: _FakeRepoRepo(linkedRepos),
      workspaceRepository: _FakeWorkspaceRepo()
        ..linked['ws'] = linkedRepos.keys.toSet()
        ..reposByWorkspace['ws'] = linkedRepos.values.toList(),
      isolatedRepoRepository: _FakeIsolatedRepoRepo()
        ..bySpace['ws:ch'] = [
          for (final e in worktreesByRepoId.entries) _worktree(e.key, e.value),
        ],
      fileSearch: DartFileSearch(),
    );

    test('listDirectory lists the worktree, not the linked checkout', () async {
      final checkout = makeRepoDir('linked', {'in_checkout.dart': '//'});
      final worktree = makeRepoDir('wt', {'in_worktree.dart': '//'});
      final svc = svcWith(
        linkedRepos: {'a': repo('a', checkout)},
        worktreesByRepoId: {'a': worktree},
      );

      final scoped = await svc.listDirectory('ws', 'a', spaceId: 'ch');
      expect(pathsOf(scoped), contains('in_worktree.dart'));
      expect(pathsOf(scoped), isNot(contains('in_checkout.dart')));

      // No space id → the linked checkout, unchanged.
      expect(
        pathsOf(await svc.listDirectory('ws', 'a')),
        contains('in_checkout.dart'),
      );
    });

    test('a repo the space never cloned lists nothing (no fallback)', () async {
      final checkout = makeRepoDir('linked', {'in_checkout.dart': '//'});
      final svc = svcWith(
        linkedRepos: {'a': repo('a', checkout)},
        worktreesByRepoId: const {},
      );

      // Falling back to the checkout here would show a tree the conversation
      // cannot write to — the whole reason the panel hides uncloned repos.
      expect(
        pathsOf(await svc.listDirectory('ws', 'a', spaceId: 'ch')),
        isEmpty,
      );
    });

    test('searchFiles ranks only the repos the space cloned', () async {
      final checkoutA = makeRepoDir('linked_a', {'in_checkout.dart': '//'});
      final checkoutB = makeRepoDir('linked_b', {'other_repo.dart': '//'});
      final worktreeA = makeRepoDir('wt_a', {'in_worktree.dart': '//'});
      final svc = svcWith(
        linkedRepos: {'a': repo('a', checkoutA), 'b': repo('b', checkoutB)},
        worktreesByRepoId: {'a': worktreeA},
      );

      final hits = await svc.searchFiles('ws', '', spaceId: 'ch');

      final paths = {for (final h in hits) h['relativePath'] as String};
      expect(paths, contains('in_worktree.dart'));
      expect(paths, isNot(contains('in_checkout.dart')));
      // Repo b is linked to the workspace but not checked out here.
      expect(paths, isNot(contains('other_repo.dart')));
      expect({for (final h in hits) h['repoId']}, {'a'});
    });

    test('searchContent greps the worktree copy', () async {
      final checkout = makeRepoDir('linked', {
        'a.dart': 'needle in checkout\n',
      });
      await _gitInit(checkout);
      final worktree = makeRepoDir('wt', {'b.dart': 'needle in worktree\n'});
      await _gitInit(worktree);
      final svc = svcWith(
        linkedRepos: {'a': repo('a', checkout)},
        worktreesByRepoId: {'a': worktree},
      );

      final hits = await svc.searchContent('ws', 'needle', spaceId: 'ch');

      expect({for (final h in hits) h['relativePath'] as String}, {'b.dart'});
      expect(hits.every((h) => h['repoId'] == 'a'), isTrue);
    });

    test('readFile reads the worktree copy of the file', () async {
      final checkout = makeRepoDir('linked', {'app.dart': 'old\n'});
      final worktree = makeRepoDir('wt', {
        'app.dart': 'rewritten by an agent\n',
      });
      final svc = svcWith(
        linkedRepos: {'a': repo('a', checkout)},
        worktreesByRepoId: {'a': worktree},
      );

      final scoped = await svc.readFile('ws', 'a', 'app.dart', spaceId: 'ch');
      expect(scoped.content, 'rewritten by an agent\n');
      expect((await svc.readFile('ws', 'a', 'app.dart')).content, 'old\n');
      // An unprovisioned space has no copy to read — never the checkout's.
      expect(
        (await svc.readFile('ws', 'a', 'app.dart', spaceId: 'nope')).content,
        isEmpty,
      );
    });
  });

  group('writeFile + revertFiles', () {
    Future<String> gitRepo(String name) async {
      final root = makeRepoDir(name, {'src/app.dart': 'void main() {}\n'});
      await _gitInit(root);
      return root;
    }

    test('writeFile writes a confined file into the worktree', () async {
      final wt = await gitRepo('wt');
      final iso = _FakeIsolatedRepoRepo()
        ..bySpace['ws:ch'] = [_worktree('repo1', wt)];
      final svc = RepoIdeDataService(
        repoRepository: _FakeRepoRepo(),
        workspaceRepository: _FakeWorkspaceRepo()..linked['ws'] = {'repo1'},
        isolatedRepoRepository: iso,
        fileSearch: DartFileSearch(),
      );

      final result = await svc.writeFile(
        'ws',
        'ch',
        'repo1',
        'notes/new.md',
        '# hi',
      );

      expect(result, isNotNull);
      expect(result!.path, 'notes/new.md');
      expect(File(p.join(wt, 'notes', 'new.md')).readAsStringSync(), '# hi');
    });

    test('writeFile rejects a path escaping the worktree root', () async {
      final wt = await gitRepo('wt');
      final iso = _FakeIsolatedRepoRepo()
        ..bySpace['ws:ch'] = [_worktree('repo1', wt)];
      final svc = RepoIdeDataService(
        repoRepository: _FakeRepoRepo(),
        workspaceRepository: _FakeWorkspaceRepo()..linked['ws'] = {'repo1'},
        isolatedRepoRepository: iso,
        fileSearch: DartFileSearch(),
      );

      final result = await svc.writeFile(
        'ws',
        'ch',
        'repo1',
        '../../../etc/evil',
        'x',
      );

      expect(result, isNull);
    });

    test('writeFile returns null when no worktree is provisioned', () async {
      final svc = RepoIdeDataService(
        repoRepository: _FakeRepoRepo(),
        workspaceRepository: _FakeWorkspaceRepo(),
        isolatedRepoRepository: _FakeIsolatedRepoRepo(),
        fileSearch: DartFileSearch(),
      );

      final result = await svc.writeFile('ws', 'ch', 'repo1', 'a.md', 'x');
      expect(result, isNull);
    });

    test('revertFiles restores a tracked modified file to HEAD', () async {
      final wt = await gitRepo('wt');
      // Modify the tracked file so it differs from HEAD.
      File(p.join(wt, 'src/app.dart')).writeAsStringSync('MODIFIED\n');
      final iso = _FakeIsolatedRepoRepo()
        ..bySpace['ws:ch'] = [_worktree('repo1', wt)];
      final svc = RepoIdeDataService(
        repoRepository: _FakeRepoRepo(),
        workspaceRepository: _FakeWorkspaceRepo()..linked['ws'] = {'repo1'},
        isolatedRepoRepository: iso,
        fileSearch: DartFileSearch(),
      );

      final result = await svc.revertFiles('ws', 'ch', 'repo1', [
        'src/app.dart',
      ]);

      expect(result, isNotNull);
      expect(result!.reverted, 1);
      expect(result.skipped, isEmpty);
      // The file is back to its committed content.
      expect(
        File(p.join(wt, 'src/app.dart')).readAsStringSync(),
        'void main() {}\n',
      );
    });

    test('revertFiles reports an untracked file as skipped', () async {
      final wt = await gitRepo('wt');
      // Add an untracked file (never staged/committed).
      File(p.join(wt, 'fresh.dart')).writeAsStringSync('new\n');
      final iso = _FakeIsolatedRepoRepo()
        ..bySpace['ws:ch'] = [_worktree('repo1', wt)];
      final svc = RepoIdeDataService(
        repoRepository: _FakeRepoRepo(),
        workspaceRepository: _FakeWorkspaceRepo()..linked['ws'] = {'repo1'},
        isolatedRepoRepository: iso,
        fileSearch: DartFileSearch(),
      );

      final result = await svc.revertFiles('ws', 'ch', 'repo1', ['fresh.dart']);

      expect(result, isNotNull);
      expect(result!.reverted, 0);
      expect(result.skipped, contains('fresh.dart'));
    });

    test('syncToPrHead no-ops (dirty:true) with uncommitted edits, never '
        'clobbering them', () async {
      final wt = await gitRepo('wt');
      // Uncommitted edit — sync must NOT touch it.
      File(p.join(wt, 'src/app.dart')).writeAsStringSync('WIP edit\n');
      final iso = _FakeIsolatedRepoRepo()
        ..bySpace['ws:ch'] = [_worktree('repo1', wt)];
      final svc = RepoIdeDataService(
        repoRepository: _FakeRepoRepo(),
        workspaceRepository: _FakeWorkspaceRepo()..linked['ws'] = {'repo1'},
        isolatedRepoRepository: iso,
        fileSearch: DartFileSearch(),
      );

      final res = await svc.syncToPrHead(
        'ws',
        'ch',
        'repo1',
        headRef: 'refs/pull/1/head',
        branch: 'pr/1',
      );

      expect(res, isNotNull);
      expect(res!['dirty'], isTrue);
      expect(res['synced'], isFalse);
      // The uncommitted edit survived (no fetch/checkout ran).
      expect(File(p.join(wt, 'src/app.dart')).readAsStringSync(), 'WIP edit\n');
    });

    test('syncToPrHead returns null when the space owns no worktree', () async {
      final svc = RepoIdeDataService(
        repoRepository: _FakeRepoRepo(),
        workspaceRepository: _FakeWorkspaceRepo(),
        isolatedRepoRepository: _FakeIsolatedRepoRepo(),
        fileSearch: DartFileSearch(),
      );
      expect(
        await svc.syncToPrHead(
          'ws',
          'ch',
          'repo1',
          headRef: 'refs/pull/1/head',
          branch: 'pr/1',
        ),
        isNull,
      );
    });
  });

  // A push a human clicks must ride THAT human's credential (the per-actor
  // lane), so GitHub attributes it to them and not to the server's App. These
  // pin that the service threads the acting user into every token lookup on
  // the push paths — dropping the argument would silently revert pushes to
  // the app identity and no behavioural test would notice, because the token
  // is only an auth header.
  group('commitAndPush / publishBranch acting-user credential', () {
    Future<void> git(List<String> args, String root) async {
      final r = await Process.run('git', args, workingDirectory: root);
      if (r.exitCode != 0) {
        throw StateError('git ${args.join(' ')} failed: ${r.stderr}');
      }
    }

    // A real worktree on branch `main` with a local bare `origin`, so the
    // push actually runs (a null token adds no auth env and a filesystem
    // remote needs none).
    Future<String> gitWorktreeWithOrigin(String name) async {
      final root = makeRepoDir(name, {'src/app.dart': 'void main() {}\n'});
      await git(['init', '-q'], root);
      await git(['checkout', '-q', '-b', 'main'], root);
      await git(['config', 'core.autocrlf', 'false'], root);
      await git(['config', 'user.email', 'test@example.com'], root);
      await git(['config', 'user.name', 'Test'], root);
      await git(['config', 'commit.gpgsign', 'false'], root);
      await git(['add', '-A'], root);
      await git(['commit', '-q', '-m', 'init'], root);
      final origin = Directory(p.join(tmp.path, '$name-origin.git'))
        ..createSync(recursive: true);
      await git(['init', '-q', '--bare'], origin.path);
      await git(['remote', 'add', 'origin', origin.path], root);
      return root;
    }

    RepoIdeDataService svcWith(String wt, List<String?> seenActingUserIds) =>
        RepoIdeDataService(
          repoRepository: _FakeRepoRepo(),
          workspaceRepository: _FakeWorkspaceRepo()..linked['ws'] = {'repo1'},
          isolatedRepoRepository: _FakeIsolatedRepoRepo()
            ..bySpace['ws:ch'] = [_worktree('repo1', wt)],
          fileSearch: DartFileSearch(),
          githubToken: ({actingUserId}) async {
            seenActingUserIds.add(actingUserId);
            return null;
          },
        );

    test('commitAndPush resolves the token as the acting user', () async {
      final wt = await gitWorktreeWithOrigin('wt');
      File(p.join(wt, 'src/app.dart')).writeAsStringSync('// edited\n');
      final seen = <String?>[];
      final svc = svcWith(wt, seen);

      final res = await svc.commitAndPush(
        workspaceId: 'ws',
        spaceId: 'ch',
        repoId: 'repo1',
        message: 'edit app',
        paths: ['src/app.dart'],
        actingUserId: 'user-9',
      );

      expect(res, isNotNull);
      expect(res!['committed'], isTrue);
      expect(res['pushed'], isTrue);
      expect(seen, ['user-9']);
    });

    test('publishBranch resolves the token as the acting user', () async {
      final wt = await gitWorktreeWithOrigin('wt2');
      final seen = <String?>[];
      final svc = svcWith(wt, seen);

      final res = await svc.publishBranch(
        workspaceId: 'ws',
        spaceId: 'ch',
        repoId: 'repo1',
        actingUserId: 'user-9',
      );

      expect(res, isNotNull);
      expect(res!['pushed'], isTrue);
      expect(seen, ['user-9']);
    });
  });
}

Future<void> _gitInit(String root) async {
  Future<void> git(List<String> args) async {
    final r = await Process.run('git', args, workingDirectory: root);
    if (r.exitCode != 0) {
      throw StateError('git ${args.join(' ')} failed: ${r.stderr}');
    }
  }

  await git(['init', '-q']);
  // Byte-faithful restores: the Windows runner's global
  // core.autocrlf=true rewrites LF as CRLF on checkout-index, so the
  // round-trip assertions would compare platform-mangled content.
  await git(['config', 'core.autocrlf', 'false']);
  await git(['config', 'user.email', 'test@example.com']);
  await git(['config', 'user.name', 'Test']);
  // Never inherit the developer's global signing config: with gpg signing on
  // (e.g. 1Password op-ssh-sign), fixture commits hang on the signing prompt.
  await git(['config', 'commit.gpgsign', 'false']);
  await git(['add', '-A']);
  await git(['commit', '-q', '-m', 'init']);
}

PrFile _prFile(String name) => PrFile(
  filename: name,
  status: PrFileStatus.modified,
  additions: 1,
  deletions: 0,
  patch: '',
);

IsolatedRepo _worktree(String repoId, String path) => IsolatedRepo(
  id: 'wt-$repoId',
  workspaceId: 'ws',
  spaceId: 'ch',
  repoId: repoId,
  backend: RepoIsolationBackend.gitWorktree,
  path: path,
  branch: 'main',
  sourcePath: '/src/$repoId',
  createdAt: DateTime(2025),
);

class _FakeRepoRepo implements RepoRepository {
  _FakeRepoRepo([this._byId = const {}]);
  final Map<String, Repo> _byId;

  @override
  Future<Repo?> getById(String workspaceId, String id) =>
      Future.value(_byId[id]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWorkspaceRepo implements WorkspaceRepository {
  final Map<String, List<Repo>> reposByWorkspace = {};
  final Map<String, Set<String>> linked = {};

  @override
  Stream<List<Repo>> watchReposForWorkspace(String workspaceId) =>
      Stream.value(reposByWorkspace[workspaceId] ?? const []);

  @override
  Future<bool> isRepoLinkedToWorkspace(String workspaceId, String repoId) =>
      Future.value(linked[workspaceId]?.contains(repoId) ?? false);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeIsolatedRepoRepo implements IsolatedRepoRepository {
  final Map<String, List<IsolatedRepo>> bySpace = {};

  @override
  Future<List<IsolatedRepo>> forSpace(String workspaceId, String spaceId) =>
      Future.value(bySpace['$workspaceId:$spaceId'] ?? const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSessionDiff implements SessionDiffPort {
  _FakeSessionDiff(this._byPath);
  final Map<String, List<PrFile>> _byPath;
  final List<(String, String)> calls = [];

  @override
  Future<List<PrFile>> changedFiles(
    String worktreePath,
    String baseRef, {
    String? headRef,
  }) async {
    calls.add((worktreePath, baseRef));
    return _byPath[worktreePath] ?? const [];
  }

  @override
  Future<({List<PrFile> staged, List<PrFile> unstaged})> groupedChanges(
    String worktreePath,
  ) async {
    calls.add((worktreePath, 'grouped'));
    return (
      staged: const <PrFile>[],
      unstaged: _byPath[worktreePath] ?? const [],
    );
  }
}
