@TestOn('vm')
library;

import 'dart:io';

import 'package:cc_infra/cc_infra.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory repo;

  Future<ProcessResult> git(List<String> args) =>
      Process.run('git', args, workingDirectory: repo.path);

  setUp(() async {
    repo = await Directory.systemTemp.createTemp('cc_session_diff');
    await git(['init', '-q']);
    await git(['config', 'user.email', 'test@example.com']);
    await git(['config', 'user.name', 'Test']);
  });

  tearDown(() async {
    if (repo.existsSync()) {
      await repo.delete(recursive: true);
    }
  });

  test(
    'computes changed files between a snapshot ref and the working tree',
    () async {
      const snapshot = ProcessGitSnapshotAdapter();
      const diff = ProcessSessionDiffAdapter();

      // Baseline state, committed so the worktree is clean.
      await File('${repo.path}/keep.txt').writeAsString('one\ntwo\nthree\n');
      await git(['add', '-A']);
      await git(['commit', '-q', '-m', 'base']);

      // Capture the session start ref.
      final start = await snapshot.capture(repo.path);
      expect(start, isNotNull);

      // The agent edits a file and creates a new one.
      await File(
        '${repo.path}/keep.txt',
      ).writeAsString('one\nCHANGED\nthree\n');
      await File('${repo.path}/added.txt').writeAsString('brand new\n');

      final changed = await diff.changedFiles(repo.path, start!);
      final names = changed.map((f) => f.filename).toSet();

      expect(names, containsAll(<String>{'keep.txt', 'added.txt'}));
      final keep = changed.firstWhere((f) => f.filename == 'keep.txt');
      expect(keep.additions, greaterThan(0));
      expect(keep.deletions, greaterThan(0));
      expect(keep.patch, contains('CHANGED'));
    },
  );

  test('returns an empty list when nothing changed', () async {
    const snapshot = ProcessGitSnapshotAdapter();
    const diff = ProcessSessionDiffAdapter();

    await File('${repo.path}/a.txt').writeAsString('x\n');
    await git(['add', '-A']);
    await git(['commit', '-q', '-m', 'base']);

    final start = await snapshot.capture(repo.path);
    final changed = await diff.changedFiles(repo.path, start!);
    expect(changed, isEmpty);
  });

  test(
    'groupedChanges splits a partially staged file into both buckets',
    () async {
      const diff = ProcessSessionDiffAdapter();

      await File('${repo.path}/f.txt').writeAsString('a\nb\nc\n');
      await git(['add', '-A']);
      await git(['commit', '-q', '-m', 'base']);

      // Stage one edit, then edit the worktree again — the VS Code
      // partially-staged shape the Source control tab renders as two entries.
      await File('${repo.path}/f.txt').writeAsString('a\nSTAGED\nc\n');
      await git(['add', 'f.txt']);
      await File('${repo.path}/f.txt').writeAsString('a\nSTAGED\nWORKTREE\n');

      final grouped = await diff.groupedChanges(repo.path);

      expect(grouped.staged.map((f) => f.filename), ['f.txt']);
      expect(grouped.unstaged.map((f) => f.filename), ['f.txt']);
      // Each bucket carries ITS diff: index vs HEAD, worktree vs index.
      expect(grouped.staged.single.patch, contains('STAGED'));
      expect(grouped.staged.single.patch, isNot(contains('WORKTREE')));
      expect(grouped.unstaged.single.patch, contains('WORKTREE'));
    },
  );

  test('non-ASCII filenames still get a patch (core.quotePath off)', () async {
    const diff = ProcessSessionDiffAdapter();

    // With git's default core.quotePath=true the `diff --git` header octal-
    // escapes this name while `-z` output stays raw, so the per-file patch
    // lookup would miss and the file would render with an empty body.
    await File('${repo.path}/ünïcode.txt').writeAsString('eins\n');
    await git(['add', '-A']);
    await git(['commit', '-q', '-m', 'base']);
    await File('${repo.path}/ünïcode.txt').writeAsString('zwei\n');

    final grouped = await diff.groupedChanges(repo.path);

    expect(grouped.unstaged.map((f) => f.filename), ['ünïcode.txt']);
    expect(grouped.unstaged.single.patch, contains('zwei'));
  });

  test('returns an empty list for a non-worktree path', () async {
    const diff = ProcessSessionDiffAdapter();
    final notRepo = await Directory.systemTemp.createTemp('cc_not_repo');
    try {
      final changed = await diff.changedFiles(notRepo.path, 'deadbeef');
      expect(changed, isEmpty);
    } finally {
      await notRepo.delete(recursive: true);
    }
  });
}
