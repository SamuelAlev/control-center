import 'dart:io';

import 'package:cc_natives/cc_natives.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory root;
  late String worktree;

  Future<ProcessResult> git(List<String> args, {String? cwd}) => Process.run(
    'git',
    args,
    workingDirectory: cwd ?? worktree,
    environment: const {'GIT_CONFIG_NOSYSTEM': '1'},
  );

  setUp(() async {
    root = Directory.systemTemp.createTempSync('cc_guard');
    worktree = p.join(root.path, 'acme');
    Directory(worktree).createSync();
    await git(['init', '-q']);
    File(p.join(worktree, 'a.txt')).writeAsStringSync('a');
    RigWorktreeGuard.storePath = p.join(root.path, 'store.json');
    RigWorktreeGuard.debugReset();
  });

  tearDown(() {
    RigWorktreeGuard.forceRelease(worktree);
    RigWorktreeGuard.storePath = null;
    RigWorktreeGuard.debugReset();
    root.deleteSync(recursive: true);
  });

  test('leaves a worktree no rig mounted alone', () {
    expect(
      RigWorktreeGuard.gitArgs(const ['status'], workingDirectory: worktree),
      ['status'],
    );
  });

  test('hardens every git call in a quarantined worktree', () {
    RigWorktreeGuard.quarantine(worktree);
    expect(
      RigWorktreeGuard.gitArgs(const [
        'diff',
      ], workingDirectory: p.join(worktree, 'sub')),
      [...RigWorktreeGuard.hardening, 'diff'],
    );
    expect(
      RigWorktreeGuard.gitArgs(const [
        '-C',
        'acme',
        'status',
      ], workingDirectory: root.path),
      [...RigWorktreeGuard.hardening, '-C', 'acme', 'status'],
    );
  });

  for (final (name, plant) in <(String, void Function(String))>[
    (
      'core.fsmonitor',
      (gitDir) {
        File(p.join(gitDir, 'config')).writeAsStringSync(
          '[core]\n\tfsmonitor = /tmp/evil\n',
          mode: FileMode.append,
        );
      },
    ),
    (
      'a filter driver',
      (gitDir) {
        File(p.join(gitDir, 'config')).writeAsStringSync(
          '[filter "x"]\n\tclean = /tmp/evil\n',
          mode: FileMode.append,
        );
      },
    ),
    (
      'a hook',
      (gitDir) {
        File(
          p.join(gitDir, 'hooks', 'pre-commit'),
        ).writeAsStringSync('#!/bin/sh\n');
      },
    ),
    (
      'an attributes file',
      (gitDir) {
        Directory(p.join(gitDir, 'info')).createSync(recursive: true);
        File(
          p.join(gitDir, 'info', 'attributes'),
        ).writeAsStringSync('* filter=x\n');
      },
    ),
  ]) {
    test('refuses to run git after $name is planted', () {
      RigWorktreeGuard.quarantine(worktree);
      plant(p.join(worktree, '.git'));
      expect(
        () => RigWorktreeGuard.gitArgs(const [
          'status',
        ], workingDirectory: worktree),
        throwsA(isA<RigWorktreeTampered>()),
      );
      expect(RigWorktreeGuard.release(worktree), isFalse);
      expect(
        () => RigWorktreeGuard.gitArgs(const [
          'status',
        ], workingDirectory: worktree),
        throwsA(isA<RigWorktreeTampered>()),
        reason: 'a tampered worktree stays quarantined after release',
      );
    });
  }

  test('a .git pointer rewritten to another directory is caught', () {
    RigWorktreeGuard.quarantine(worktree);
    final elsewhere = Directory(p.join(root.path, 'evil'))..createSync();
    Directory(
      p.join(worktree, '.git'),
    ).renameSync(p.join(elsewhere.path, 'git'));
    File(
      p.join(worktree, '.git'),
    ).writeAsStringSync('gitdir: ${elsewhere.path}/git\n');
    expect(
      () => RigWorktreeGuard.gitArgs(const [
        'status',
      ], workingDirectory: worktree),
      throwsA(isA<RigWorktreeTampered>()),
    );
  });

  test('an untouched worktree is released cleanly', () {
    RigWorktreeGuard.quarantine(worktree);
    File(
      p.join(worktree, 'a.txt'),
    ).writeAsStringSync('worktree edits are fine');
    expect(RigWorktreeGuard.release(worktree), isTrue);
    expect(
      RigWorktreeGuard.gitArgs(const ['status'], workingDirectory: worktree),
      ['status'],
    );
    expect(
      File(p.join(worktree, '.git', RigWorktreeGuard.markerName)).existsSync(),
      isFalse,
    );
  });

  test('a second quarantine keeps the first, trusted fingerprint', () {
    RigWorktreeGuard.quarantine(worktree);
    File(
      p.join(worktree, '.git', 'hooks', 'post-checkout'),
    ).writeAsStringSync('#!/bin/sh\n');
    RigWorktreeGuard.quarantine(worktree);
    expect(
      () => RigWorktreeGuard.gitArgs(const [
        'status',
      ], workingDirectory: worktree),
      throwsA(isA<RigWorktreeTampered>()),
    );
  });

  test('another isolate sees the quarantine through the marker', () {
    RigWorktreeGuard.quarantine(worktree);
    RigWorktreeGuard.storePath = null;
    RigWorktreeGuard.debugReset();
    expect(
      RigWorktreeGuard.gitArgs(const ['status'], workingDirectory: worktree),
      [...RigWorktreeGuard.hardening, 'status'],
    );
  });

  test('a restart sees it through the store, even with the marker gone', () {
    RigWorktreeGuard.quarantine(worktree);
    File(p.join(worktree, '.git', RigWorktreeGuard.markerName)).deleteSync();
    RigWorktreeGuard.debugReset();
    expect(
      RigWorktreeGuard.gitArgs(const ['status'], workingDirectory: worktree),
      [...RigWorktreeGuard.hardening, 'status'],
    );
  });

  test('the hardening really stops a planted fsmonitor and hook', () async {
    final proof = p.join(root.path, 'ran');
    final script = File(p.join(root.path, 'evil.sh'))
      ..writeAsStringSync('#!/bin/sh\ntouch "$proof"\n');
    await Process.run('chmod', ['+x', script.path]);
    // Planted before the quarantine, so the fingerprint trusts it and only
    // the flags stand between git and the script.
    await git(['config', 'core.fsmonitor', script.path]);
    File(
      p.join(worktree, '.git', 'hooks', 'pre-commit'),
    ).writeAsStringSync('#!/bin/sh\ntouch "$proof"\n');
    await Process.run('chmod', [
      '+x',
      p.join(worktree, '.git', 'hooks', 'pre-commit'),
    ]);
    RigWorktreeGuard.quarantine(worktree);
    await git(
      RigWorktreeGuard.gitArgs(const ['status'], workingDirectory: worktree),
    );
    await git(
      RigWorktreeGuard.gitArgs(const [
        'add',
        'a.txt',
      ], workingDirectory: worktree),
    );
    await git(
      RigWorktreeGuard.gitArgs(const [
        '-c',
        'user.email=t@t.test',
        '-c',
        'user.name=t',
        '-c',
        'commit.gpgsign=false',
        'commit',
        '-qm',
        'x',
      ], workingDirectory: worktree),
    );
    expect(File(proof).existsSync(), isFalse);
    // Without the flags the same commands do run it, so the test can fail.
    await git(['status']);
    expect(File(proof).existsSync(), isTrue);
  });
}
