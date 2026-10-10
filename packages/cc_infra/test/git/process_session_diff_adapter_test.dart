import 'dart:io';

import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_infra/src/git/process_session_diff_adapter.dart';
import 'package:cc_infra/src/git/working_tree_capture.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

Future<int> _git(List<String> args, String dir) async {
  final r = await Process.run('git', args, workingDirectory: dir);
  return r.exitCode;
}

void main() {
  late Directory repo;

  setUp(() async {
    repo = Directory.systemTemp.createTempSync('cc_sessiondiff_repo');
    await _git(['init', '-q'], repo.path);
    await _git(['config', 'user.email', 'test@example.com'], repo.path);
    await _git(['config', 'user.name', 'Test'], repo.path);
    File(p.join(repo.path, 'tracked.txt')).writeAsStringSync('original\n');
    await _git(['add', '-A'], repo.path);
    await _git(['commit', '-q', '-m', 'init'], repo.path);
  });

  tearDown(() async {
    await discardWorkingTreeCapture(repo.path);
    repo.deleteSync(recursive: true);
  });

  test(
    'reports a modified tracked file and a new untracked file vs HEAD',
    () async {
      const adapter = ProcessSessionDiffAdapter();
      File(p.join(repo.path, 'tracked.txt')).writeAsStringSync('changed\n');
      File(p.join(repo.path, 'fresh.txt')).writeAsStringSync('brand new\n');

      final files = await adapter.changedFiles(repo.path, 'HEAD');

      final byName = {for (final f in files) f.filename: f};
      expect(byName.keys, containsAll(<String>['tracked.txt', 'fresh.txt']));
      expect(byName['tracked.txt']!.status, PrFileStatus.modified);
      expect(byName['fresh.txt']!.status, PrFileStatus.added);
      // Patches are sliced per file from the full diff.
      expect(byName['tracked.txt']!.patch, contains('changed'));
    },
  );

  test('returns empty for a clean working tree', () async {
    const adapter = ProcessSessionDiffAdapter();
    expect(await adapter.changedFiles(repo.path, 'HEAD'), isEmpty);
  });

  test('detects a change made right after a commit', () async {
    const adapter = ProcessSessionDiffAdapter();
    File(p.join(repo.path, 'tracked.txt')).writeAsStringSync('edited again\n');

    final files = await adapter.changedFiles(repo.path, 'HEAD');

    expect(files.single.filename, 'tracked.txt');
    expect(files.single.status, PrFileStatus.modified);
  });

  test(
    'detects a same-size edit even when the file mtime is unchanged',
    () async {
      // The working-tree capture must reflect disk content, not a git stat cache.
      // A cold temp index re-hashes every path, so a same-size edit whose mtime
      // still matches the committed stat (the copy-on-write + editor case that
      // showed the WRONG lines) is still captured — where a stat-cache-trusting
      // `git add -A` would skip re-hashing and diff the stale blob.
      const adapter = ProcessSessionDiffAdapter();
      final file = File(p.join(repo.path, 'tracked.txt'));
      final committedMtime = file.lastModifiedSync();
      // 'original\n' and 'changed!\n' are both 9 bytes.
      file.writeAsStringSync('changed!\n');
      file.setLastModifiedSync(committedMtime);

      final files = await adapter.changedFiles(repo.path, 'HEAD');

      expect(files.single.filename, 'tracked.txt');
      expect(files.single.status, PrFileStatus.modified);
      expect(files.single.patch, contains('changed!'));
    },
  );

  test(
    'a warm capture still sees a same-size edit with the mtime put back',
    () async {
      // The second capture reuses the first one's private index and stat
      // cache; the edit rewrites the file's ctime, so it is re-hashed anyway.
      const adapter = ProcessSessionDiffAdapter();
      final file = File(p.join(repo.path, 'tracked.txt'));
      expect(await adapter.changedFiles(repo.path, 'HEAD'), isEmpty);

      final mtime = file.lastModifiedSync();
      file.writeAsStringSync('changed!\n');
      file.setLastModifiedSync(mtime);
      final edited = await adapter.changedFiles(repo.path, 'HEAD');
      expect(edited.single.patch, contains('changed!'));

      file.writeAsStringSync('original\n');
      file.setLastModifiedSync(mtime);
      expect(await adapter.changedFiles(repo.path, 'HEAD'), isEmpty);
    },
  );

  test(
    'a warm capture follows HEAD and drops removed untracked files',
    () async {
      const adapter = ProcessSessionDiffAdapter();
      final fresh = File(p.join(repo.path, 'fresh.txt'))
        ..writeAsStringSync('new\n');
      expect(
        (await adapter.changedFiles(repo.path, 'HEAD')).map((f) => f.filename),
        ['fresh.txt'],
      );

      await _git(['add', '-A'], repo.path);
      await _git(['commit', '-q', '-m', 'add fresh'], repo.path);
      expect(await adapter.changedFiles(repo.path, 'HEAD'), isEmpty);

      fresh.deleteSync();
      final removed = await adapter.changedFiles(repo.path, 'HEAD');
      expect(removed.single.filename, 'fresh.txt');
      expect(removed.single.status, PrFileStatus.removed);
    },
  );

  test('concurrent captures of one worktree all succeed', () async {
    const adapter = ProcessSessionDiffAdapter();
    File(p.join(repo.path, 'tracked.txt')).writeAsStringSync('changed\n');

    final results = await Future.wait([
      for (var i = 0; i < 4; i++) adapter.changedFiles(repo.path, 'HEAD'),
    ]);

    for (final files in results) {
      expect(files.single.filename, 'tracked.txt');
    }
  });

  test(
    'a tracked file that .gitignore also matches is not a phantom deletion',
    () async {
      // web-app tracks `.vscode/launch.json.example` and ignores `.vscode/*`.
      // The un-ignore rule names `launch.example.json`, which does not match,
      // so a cold `git add -A` drops the file and the review shows it deleted.
      const adapter = ProcessSessionDiffAdapter();
      Directory(p.join(repo.path, '.vscode')).createSync();
      final launch = File(p.join(repo.path, '.vscode', 'launch.json.example'));
      launch.writeAsStringSync('{"version":"0.2.0"}\n');
      File(
        p.join(repo.path, '.gitignore'),
      ).writeAsStringSync('.vscode/*\n!.vscode/launch.example.json\n');
      await _git(['add', '-A'], repo.path);
      await _git(['add', '-f', '.vscode/launch.json.example'], repo.path);
      await _git(['commit', '-q', '-m', 'track launch'], repo.path);

      expect(await adapter.changedFiles(repo.path, 'HEAD'), isEmpty);

      launch.writeAsStringSync('{"version":"9.9.9"}\n');
      File(
        p.join(repo.path, '.vscode', 'settings.json'),
      ).writeAsStringSync('local\n');
      File(p.join(repo.path, 'fresh.txt')).writeAsStringSync('brand new\n');

      final edited = await adapter.changedFiles(repo.path, 'HEAD');
      final byName = {for (final f in edited) f.filename: f};
      expect(
        byName.keys,
        containsAll(<String>['.vscode/launch.json.example', 'fresh.txt']),
      );
      expect(byName.containsKey('.vscode/settings.json'), isFalse);
      expect(
        byName['.vscode/launch.json.example']!.status,
        PrFileStatus.modified,
      );
      expect(byName['.vscode/launch.json.example']!.patch, contains('9.9.9'));

      launch.deleteSync();
      final deleted = await adapter.changedFiles(repo.path, 'HEAD');
      final after = {for (final f in deleted) f.filename: f};
      expect(
        after['.vscode/launch.json.example']!.status,
        PrFileStatus.removed,
      );
      expect(after.containsKey('.vscode/settings.json'), isFalse);
    },
  );

  test('returns empty for a path that is not a git worktree', () async {
    const adapter = ProcessSessionDiffAdapter();
    final plain = Directory.systemTemp.createTempSync('cc_not_a_repo');
    addTearDown(() => plain.deleteSync(recursive: true));
    expect(await adapter.changedFiles(plain.path, 'HEAD'), isEmpty);
  });

  group('groupedChanges', () {
    test(
      'splits staged (index) from unstaged (worktree + untracked)',
      () async {
        const adapter = ProcessSessionDiffAdapter();
        // staged.txt: created and `git add`ed → goes to the staged bucket.
        File(
          p.join(repo.path, 'staged.txt'),
        ).writeAsStringSync('staged body\n');
        await _git(['add', 'staged.txt'], repo.path);
        // tracked.txt: modified but NOT staged → unstaged bucket.
        File(p.join(repo.path, 'tracked.txt')).writeAsStringSync('edited\n');
        // fresh.txt: brand-new untracked → unstaged bucket (as added).
        File(p.join(repo.path, 'fresh.txt')).writeAsStringSync('new file\n');

        final grouped = await adapter.groupedChanges(repo.path);

        expect(grouped.staged.map((f) => f.filename), equals(['staged.txt']));
        expect(grouped.staged.single.status, PrFileStatus.added);
        expect(
          grouped.unstaged.map((f) => f.filename),
          containsAll(<String>['tracked.txt', 'fresh.txt']),
        );
        final byName = {for (final f in grouped.unstaged) f.filename: f};
        expect(byName['tracked.txt']!.status, PrFileStatus.modified);
        expect(byName['tracked.txt']!.patch, contains('edited'));
        expect(byName['fresh.txt']!.status, PrFileStatus.added);
        expect(byName['fresh.txt']!.patch, contains('new file'));
      },
    );

    test('a file staged then further edited appears in BOTH buckets', () async {
      const adapter = ProcessSessionDiffAdapter();
      File(p.join(repo.path, 'tracked.txt')).writeAsStringSync('staged edit\n');
      await _git(['add', 'tracked.txt'], repo.path);
      File(
        p.join(repo.path, 'tracked.txt'),
      ).writeAsStringSync('staged edit\nplus more\n');

      final grouped = await adapter.groupedChanges(repo.path);

      expect(grouped.staged.map((f) => f.filename), contains('tracked.txt'));
      expect(grouped.unstaged.map((f) => f.filename), contains('tracked.txt'));
    });

    test('empty buckets for a clean tree', () async {
      const adapter = ProcessSessionDiffAdapter();
      final grouped = await adapter.groupedChanges(repo.path);
      expect(grouped.staged, isEmpty);
      expect(grouped.unstaged, isEmpty);
    });

    test('mixes untracked files into VS Code path order', () async {
      const adapter = ProcessSessionDiffAdapter();
      Directory(p.join(repo.path, 'src')).createSync();
      File(p.join(repo.path, 'src', 'z.txt')).writeAsStringSync('z\n');
      await _git(['add', '-A'], repo.path);
      await _git(['commit', '-q', '-m', 'src'], repo.path);
      File(p.join(repo.path, 'tracked.txt')).writeAsStringSync('edited\n');
      File(p.join(repo.path, 'src', 'z.txt')).writeAsStringSync('edited\n');
      File(p.join(repo.path, 'src', 'a.txt')).writeAsStringSync('new\n');
      File(p.join(repo.path, 'Added.txt')).writeAsStringSync('new\n');

      final grouped = await adapter.groupedChanges(repo.path);
      final changed = await adapter.changedFiles(repo.path, 'HEAD');

      const expected = ['Added.txt', 'tracked.txt', 'src/a.txt', 'src/z.txt'];
      expect(grouped.unstaged.map((f) => f.filename), expected);
      expect(changed.map((f) => f.filename), expected);
    });
  });
}
