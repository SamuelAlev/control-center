import 'dart:io';

import 'package:cc_infra/src/git/process_git_snapshot_adapter.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

Future<int> _git(List<String> args, String dir) async {
  final r = await Process.run('git', args, workingDirectory: dir);
  return r.exitCode;
}

void main() {
  late Directory repo;

  setUp(() async {
    repo = Directory.systemTemp.createTempSync('cc_snap_repo');
    await _git(['init', '-q'], repo.path);
    // The runner's global core.autocrlf=true (Windows images default) makes
    // `git checkout` re-write LF as CRLF, so the byte round-trip assertions
    // below would compare against platform-mangled content. The ADAPTER must
    // round-trip bytes; the test repo opts out of git's conversion.
    await _git(['config', 'core.autocrlf', 'false'], repo.path);
    await _git(['config', 'user.email', 'test@example.com'], repo.path);
    await _git(['config', 'user.name', 'Test'], repo.path);
    File(p.join(repo.path, 'a.txt')).writeAsStringSync('original\n');
    await _git(['add', '-A'], repo.path);
    await _git(['commit', '-q', '-m', 'init'], repo.path);
  });

  tearDown(() => repo.deleteSync(recursive: true));

  test('capture + restore round-trips a modified file', () async {
    const adapter = ProcessGitSnapshotAdapter();
    final file = File(p.join(repo.path, 'a.txt'));

    final snap = await adapter.capture(repo.path);
    expect(snap, isNotNull);

    // Drift the file after the snapshot.
    file.writeAsStringSync('CHANGED\n');
    expect(file.readAsStringSync(), 'CHANGED\n');

    await adapter.restore(repo.path, snap!);
    expect(file.readAsStringSync(), 'original\n');
  });

  test(
    'capture includes untracked files; restore recreates deletions',
    () async {
      const adapter = ProcessGitSnapshotAdapter();
      final tracked = File(p.join(repo.path, 'a.txt'));

      final snap = await adapter.capture(repo.path);
      expect(snap, isNotNull);

      // Delete the tracked file, then restore.
      tracked.deleteSync();
      expect(tracked.existsSync(), isFalse);

      await adapter.restore(repo.path, snap!);
      expect(tracked.existsSync(), isTrue);
      expect(tracked.readAsStringSync(), 'original\n');
    },
  );

  test('capture keeps a tracked file that gitignore also matches', () async {
    const adapter = ProcessGitSnapshotAdapter();
    Directory(p.join(repo.path, '.vscode')).createSync();
    File(
      p.join(repo.path, '.vscode', 'launch.json.example'),
    ).writeAsStringSync('{"version":"0.2.0"}\n');
    File(
      p.join(repo.path, '.gitignore'),
    ).writeAsStringSync('.vscode/*\n!.vscode/launch.example.json\n');
    await _git(['add', '-A'], repo.path);
    await _git(['add', '-f', '.vscode/launch.json.example'], repo.path);
    await _git(['commit', '-q', '-m', 'track launch'], repo.path);

    final snap = await adapter.capture(repo.path);
    expect(snap, isNotNull);
    final listed = await Process.run('git', [
      'ls-tree',
      '-r',
      '--name-only',
      snap!,
    ], workingDirectory: repo.path);
    expect(listed.exitCode, 0);
    expect(listed.stdout, contains('.vscode/launch.json.example'));
  });

  test('capture returns null for a non-git directory', () async {
    const adapter = ProcessGitSnapshotAdapter();
    final plain = Directory.systemTemp.createTempSync('cc_not_git');
    addTearDown(() => plain.deleteSync(recursive: true));
    expect(await adapter.capture(plain.path), isNull);
  });
}
