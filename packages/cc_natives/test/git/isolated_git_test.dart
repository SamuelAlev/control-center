import 'dart:io';

import 'package:cc_natives/cc_natives.dart' show IsolatedGit;
import 'package:test/test.dart';

/// A local git command that takes [seconds]: an alias that runs `sleep`.
List<String> _slow(num seconds) => ['-c', 'alias.nap=!sleep $seconds', 'nap'];

void main() {
  test('queues local commands past the concurrency limit', () async {
    final limit = IsolatedGit.localConcurrency;
    final runs = [
      for (var i = 0; i < limit + 3; i++) IsolatedGit.run(_slow(0.4)),
    ];
    await Future<void>.delayed(Duration.zero);

    expect(IsolatedGit.queuedLocalRuns, 3);
    final results = await Future.wait(runs);
    expect(results.map((r) => r.exitCode), everyElement(0));
    expect(IsolatedGit.queuedLocalRuns, 0);
  }, skip: Platform.isWindows ? 'the alias needs a POSIX sleep' : false);

  test('a network command never waits behind local ones', () async {
    final limit = IsolatedGit.localConcurrency;
    final busy = [
      for (var i = 0; i < limit + 2; i++) IsolatedGit.run(_slow(2)),
    ];
    final empty = Directory.systemTemp.createTempSync('cc_no_repo');
    addTearDown(() => empty.deleteSync(recursive: true));
    final watch = Stopwatch()..start();
    final remote = await IsolatedGit.run(['ls-remote', empty.path]);
    watch.stop();

    // It ran (and failed: the directory is no repository) while every local
    // slot was still asleep.
    expect(remote.exitCode, isNot(0));
    expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
    await Future.wait(busy);
  }, skip: Platform.isWindows ? 'the alias needs a POSIX sleep' : false);

  test('a failing local command frees its slot', () async {
    final limit = IsolatedGit.localConcurrency;
    final failing = [
      for (var i = 0; i < limit * 2; i++)
        IsolatedGit.run(['rev-parse', '--verify', 'no-such-ref-anywhere']),
    ];
    final results = await Future.wait(failing);
    expect(results.map((r) => r.exitCode), everyElement(isNot(0)));
    expect(IsolatedGit.queuedLocalRuns, 0);
    final ok = await IsolatedGit.run(['--version']);
    expect(ok.exitCode, 0);
  });
  test('stdin reaches a command that reads it', () async {
    final repo = Directory.systemTemp.createTempSync('cc_stdin_repo');
    addTearDown(() => repo.deleteSync(recursive: true));
    expect((await IsolatedGit.run(['init', '--quiet', repo.path])).exitCode, 0);
    final blob = await IsolatedGit.run([
      'hash-object',
      '-w',
      '--stdin',
    ], workingDirectory: repo.path, stdin: 'hello');
    expect(blob.exitCode, 0, reason: '${blob.stderr}');
    final oid = '${blob.stdout}'.trim();

    final checked = await IsolatedGit.run(
      ['cat-file', '--batch-check=%(objectname) %(objecttype)'],
      workingDirectory: repo.path,
      stdin: '$oid\n${'0' * 40}\n',
    );

    expect(checked.exitCode, 0, reason: '${checked.stderr}');
    expect('${checked.stdout}'.trim().split('\n'), [
      '$oid blob',
      '${'0' * 40} missing',
    ]);
    expect(IsolatedGit.queuedLocalRuns, 0);
  });
}
