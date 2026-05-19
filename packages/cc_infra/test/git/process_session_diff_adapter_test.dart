import 'dart:io';

import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_infra/src/git/process_session_diff_adapter.dart';
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

  tearDown(() => repo.deleteSync(recursive: true));

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
  });
}
