import 'dart:io';

import 'package:cc_natives/cc_natives.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// The probe is the code indexer's boot-time short-circuit: its digest must
/// move on ANY observable change (commit, stage, new untracked file, a file
/// inside an untracked directory, a SECOND edit to an already-dirty file) and
/// stay put when nothing changed. A missed change here silently freezes the
/// index, so these tests are the correctness contract.
void main() {
  final hasGit = Process.runSync('git', ['--version']).exitCode == 0;

  Future<Directory> createRepo() async {
    final dir = Directory.systemTemp.createTempSync('probe_test_');
    for (final args in [
      ['init'],
      ['config', 'user.email', 'test@test'],
      ['config', 'user.name', 'test'],
      ['config', 'commit.gpgsign', 'false'],
    ]) {
      final result = await Process.run('git', args, workingDirectory: dir.path);
      expect(result.exitCode, 0, reason: 'git $args: ${result.stderr}');
    }
    return dir;
  }

  Future<void> git(Directory repo, List<String> args) async {
    final result = await Process.run('git', args, workingDirectory: repo.path);
    expect(result.exitCode, 0, reason: 'git $args: ${result.stderr}');
  }

  Future<void> commitAll(Directory repo, String message) async {
    await git(repo, ['add', '-A']);
    await git(repo, ['commit', '-m', message]);
  }

  const probe = RepoStateProbe();

  test('non-git directory probes to null (never skip)', () async {
    final dir = Directory.systemTemp.createTempSync('probe_nongit_');
    addTearDown(() => dir.deleteSync(recursive: true));
    expect(await probe.probe(dir.path), isNull);
  }, skip: hasGit ? null : 'git not on PATH');

  test('digest is stable across probes of an unchanged checkout', () async {
    final repo = await createRepo();
    addTearDown(() => repo.deleteSync(recursive: true));
    File(p.join(repo.path, 'a.dart')).writeAsStringSync('void a() {}');
    await commitAll(repo, 'initial');

    final first = await probe.probe(repo.path);
    final second = await probe.probe(repo.path);
    expect(first, isNotNull);
    expect(first!.headSha, isNotEmpty);
    expect(first.dirtyCount, 0);
    expect(second!.digest, first.digest);
    expect(second.headSha, first.headSha);
  }, skip: hasGit ? null : 'git not on PATH');

  test('a new untracked file moves the digest', () async {
    final repo = await createRepo();
    addTearDown(() => repo.deleteSync(recursive: true));
    File(p.join(repo.path, 'a.dart')).writeAsStringSync('void a() {}');
    await commitAll(repo, 'initial');
    final before = await probe.probe(repo.path);

    File(p.join(repo.path, 'new.dart')).writeAsStringSync('void n() {}');
    final after = await probe.probe(repo.path);
    expect(after!.digest, isNot(before!.digest));
    expect(after.dirtyCount, 1);
  }, skip: hasGit ? null : 'git not on PATH');

  test(
    'a new file INSIDE an untracked directory moves the digest (-uall)',
    () async {
      final repo = await createRepo();
      addTearDown(() => repo.deleteSync(recursive: true));
      File(p.join(repo.path, 'a.dart')).writeAsStringSync('void a() {}');
      await commitAll(repo, 'initial');
      Directory(p.join(repo.path, 'newdir')).createSync();
      File(p.join(repo.path, 'newdir', 'one.dart')).writeAsStringSync('1');
      final before = await probe.probe(repo.path);

      // Without --untracked-files=all porcelain collapses the directory to one
      // `newdir/` entry, so this second file would be invisible.
      File(p.join(repo.path, 'newdir', 'two.dart')).writeAsStringSync('2');
      final after = await probe.probe(repo.path);
      expect(after!.digest, isNot(before!.digest));
    },
    skip: hasGit ? null : 'git not on PATH',
  );

  test('staging and committing move the digest / head', () async {
    final repo = await createRepo();
    addTearDown(() => repo.deleteSync(recursive: true));
    File(p.join(repo.path, 'a.dart')).writeAsStringSync('void a() {}');
    await commitAll(repo, 'initial');
    File(p.join(repo.path, 'a.dart')).writeAsStringSync('void a2() {}');
    final dirty = await probe.probe(repo.path);

    await git(repo, ['add', 'a.dart']);
    final staged = await probe.probe(repo.path);
    expect(staged!.digest, isNot(dirty!.digest));

    await git(repo, ['commit', '-m', 'edit']);
    final committed = await probe.probe(repo.path);
    expect(committed!.headSha, isNot(staged.headSha));
    expect(committed.digest, isNot(staged.digest));
  }, skip: hasGit ? null : 'git not on PATH');

  test(
    'a SECOND edit to an already-dirty file moves the digest (stat fold)',
    () async {
      final repo = await createRepo();
      addTearDown(() => repo.deleteSync(recursive: true));
      File(p.join(repo.path, 'a.dart')).writeAsStringSync('void a() {}');
      await commitAll(repo, 'initial');

      // First edit: file is now dirty.
      File(p.join(repo.path, 'a.dart')).writeAsStringSync('void edit1() {}');
      final afterFirst = await probe.probe(repo.path);
      expect(afterFirst!.dirtyCount, 1);

      // Second edit: porcelain output is BYTE-IDENTICAL (' M a.dart'), which is
      // exactly the blind spot the mtime/size stat fold covers. Force a
      // different size so the fold moves even on a filesystem with coarse
      // mtime granularity.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      File(
        p.join(repo.path, 'a.dart'),
      ).writeAsStringSync('void edit2_longer() {}');
      final afterSecond = await probe.probe(repo.path);
      expect(
        afterSecond!.digest,
        isNot(afterFirst.digest),
        reason: 'a repeat edit to an already-dirty file must move the digest',
      );
    },
    skip: hasGit ? null : 'git not on PATH',
  );

  test('gives up (null) when the dirty set exceeds maxDirtyEntries', () async {
    final repo = await createRepo();
    addTearDown(() => repo.deleteSync(recursive: true));
    File(p.join(repo.path, 'a.dart')).writeAsStringSync('void a() {}');
    await commitAll(repo, 'initial');
    for (var i = 0; i < 5; i++) {
      File(p.join(repo.path, 'f$i.dart')).writeAsStringSync('$i');
    }
    const tiny = RepoStateProbe(maxDirtyEntries: 3);
    expect(await tiny.probe(repo.path), isNull);
  }, skip: hasGit ? null : 'git not on PATH');

  test(
    'an unborn branch (fresh init, no commits) still fingerprints',
    () async {
      final repo = await createRepo();
      addTearDown(() => repo.deleteSync(recursive: true));
      File(p.join(repo.path, 'a.dart')).writeAsStringSync('void a() {}');
      final fp = await probe.probe(repo.path);
      expect(fp, isNotNull);
      expect(fp!.headSha, isEmpty);
      expect(fp.dirtyCount, 1);
    },
    skip: hasGit ? null : 'git not on PATH',
  );
}
