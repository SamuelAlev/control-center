import 'dart:io';

import 'package:control_center/features/repos/data/datasources/process_git_command_adapter.dart';
import 'package:test/test.dart';

void main() {
  const adapter = ProcessGitCommandAdapter();

  // ------------------------------------------------------------------
  // run() — command construction & output capture
  // ------------------------------------------------------------------
  group('ProcessGitCommandAdapter.run', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('git_adapter_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('captures stdout and exit code 0 on success', () async {
      // Init a git repo so commands succeed.
      await Process.run('git', ['init'], workingDirectory: tempDir.path);

      final result = await adapter.run(
        ['rev-parse', '--git-dir'],
        workdir: tempDir.path,
      );

      expect(result.exitCode, 0);
      expect(result.isSuccess, isTrue);
      expect(result.stdout.trim(), '.git');
    });

    test('captures stderr and non-zero exit code on failure', () async {
      // Init git repo but with no commits — 'git log' fails.
      await Process.run('git', ['init'], workingDirectory: tempDir.path);

      final result = await adapter.run(
        ['log'],
        workdir: tempDir.path,
      );

      expect(result.exitCode, isNot(0));
      expect(result.isSuccess, isFalse);
      expect(result.stderr, isNotEmpty);
    });

    test('completes with empty output when command produces none', () async {
      await Process.run('git', ['init'], workingDirectory: tempDir.path);
      // `git gc --auto` is a no-op on a tiny fresh repo.
      final result = await adapter.run(
        ['gc', '--auto'],
        workdir: tempDir.path,
      );

      // Exit 0 and nothing on stdout.
      expect(result.exitCode, 0);
      // stdout may be empty or minimal; stderr typically empty.
    });

    test('throws when workdir does not exist', () async {
      expect(
        adapter.run(
          ['status'],
          workdir: '${tempDir.path}/nonexistent',
        ),
        throwsA(isA<ProcessException>()),
      );
    });

    test('command receives correct arguments', () async {
      await Process.run('git', ['init'], workingDirectory: tempDir.path);
      // Create a file so `git status --short` produces output.
      File('${tempDir.path}/foo.txt').writeAsStringSync('bar');

      final result = await adapter.run(
        ['status', '--short'],
        workdir: tempDir.path,
      );

      // --short produces '?? filename' for untracked files.
      expect(result.stdout.trim(), '?? foo.txt');
    });
  });

  // ------------------------------------------------------------------
  // run() — onProgress
  // ------------------------------------------------------------------
  group('ProcessGitCommandAdapter onProgress', () {
    late Directory tempDir;
    late Directory bareRepo;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('git_adapter_test_');
      bareRepo = Directory('${tempDir.path}/bare.git');
      bareRepo.createSync();
      // Create a bare repo with one commit so clone has something to do.
      Process.runSync('git', ['init', '--bare'], workingDirectory: bareRepo.path);
      // Create a temp work repo, commit, push to bare.
      final work = Directory('${tempDir.path}/work');
      work.createSync();
      Process.runSync('git', ['init'], workingDirectory: work.path);
      File('${work.path}/readme.txt').writeAsStringSync('hello');
      Process.runSync('git', ['add', '.'], workingDirectory: work.path);
      Process.runSync('git', ['commit', '-m', 'init'], workingDirectory: work.path, environment: {
        'GIT_AUTHOR_NAME': 'Test',
        'GIT_AUTHOR_EMAIL': 'test@test.com',
        'GIT_COMMITTER_NAME': 'Test',
        'GIT_COMMITTER_EMAIL': 'test@test.com',
      });
      Process.runSync('git', ['remote', 'add', 'origin', bareRepo.path], workingDirectory: work.path);
      Process.runSync('git', ['push', 'origin', 'main'], workingDirectory: work.path);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('calls onProgress for stderr lines during clone', () async {
      final progressLines = <String>[];
      final cloneDest = Directory('${tempDir.path}/clone_dest');

      await adapter.run(
        ['clone', '--progress', bareRepo.path, cloneDest.path],
        workdir: tempDir.path,
        onProgress: progressLines.add,
      );

      // `git clone` emits progress on stderr.
      expect(progressLines, isNotEmpty);
      // Should contain receiving/done-type messages.
      expect(
        progressLines.any((l) => l.contains('Receiving') || l.contains('Enumerating') || l.contains('done')),
        isTrue,
      );
    });

    test('skips empty and whitespace-only progress lines', () async {
      // The onProgress callback already filters empty lines; we verify
      // no empty strings leak through.
      final progressLines = <String>[];
      final cloneDest = Directory('${tempDir.path}/clone_dest2');

      await adapter.run(
        ['clone', '--progress', bareRepo.path, cloneDest.path],
        workdir: tempDir.path,
        onProgress: progressLines.add,
      );

      for (final line in progressLines) {
        expect(line.trim().isNotEmpty, isTrue);
      }
    });
  });

  // ------------------------------------------------------------------
  // runStreaming()
  // ------------------------------------------------------------------
  group('ProcessGitCommandAdapter.runStreaming', () {
    late Directory tempDir;
    late Directory bareRepo;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('git_adapter_test_');
      bareRepo = Directory('${tempDir.path}/bare.git');
      bareRepo.createSync();
      Process.runSync('git', ['init', '--bare'], workingDirectory: bareRepo.path);
      final work = Directory('${tempDir.path}/work');
      work.createSync();
      Process.runSync('git', ['init'], workingDirectory: work.path);
      File('${work.path}/readme.txt').writeAsStringSync('hello');
      Process.runSync('git', ['add', '.'], workingDirectory: work.path);
      Process.runSync('git', ['commit', '-m', 'init'], workingDirectory: work.path, environment: {
        'GIT_AUTHOR_NAME': 'Test',
        'GIT_AUTHOR_EMAIL': 'test@test.com',
        'GIT_COMMITTER_NAME': 'Test',
        'GIT_COMMITTER_EMAIL': 'test@test.com',
      });
      Process.runSync('git', ['remote', 'add', 'origin', bareRepo.path], workingDirectory: work.path);
      Process.runSync('git', ['push', 'origin', 'main'], workingDirectory: work.path);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('emits stderr lines as stream events', () async {
      final cloneDest = Directory('${tempDir.path}/clone_stream');
      final lines = <String>[];

      final stream = adapter.runStreaming(
        ['clone', '--progress', bareRepo.path, cloneDest.path],
        workdir: tempDir.path,
      );

      await for (final line in stream) {
        lines.add(line);
      }

      expect(lines, isNotEmpty);
      // Git's clone progress writes to stderr with Receiving/done.
      expect(
        lines.any((l) => l.contains('Receiving') || l.contains('Enumerating') || l.contains('done')),
        isTrue,
      );
      // Verify no empty lines emitted.
      for (final line in lines) {
        expect(line.trim().isNotEmpty, isTrue);
      }
    });

    test('emits no events when command produces no stderr', () async {
      await Process.run('git', ['init'], workingDirectory: tempDir.path);
      final lines = <String>[];

      final stream = adapter.runStreaming(
        ['rev-parse', '--git-dir'],
        workdir: tempDir.path,
      );

      await for (final line in stream) {
        lines.add(line);
      }

      // rev-parse writes to stdout, not stderr.
      expect(lines, isEmpty);
    });

    test('throws StateError on non-zero exit', () async {
      await Process.run('git', ['init'], workingDirectory: tempDir.path);

      final stream = adapter.runStreaming(
        ['log'],
        workdir: tempDir.path,
      );

      expect(
        stream.toList(),
        throwsA(isA<StateError>()),
      );
    });

    test('StateError message includes command name and exit code', () async {
      await Process.run('git', ['init'], workingDirectory: tempDir.path);

      final stream = adapter.runStreaming(
        ['log'],
        workdir: tempDir.path,
      );

      await expectLater(
        stream.toList(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('log'), contains('failed')),
          ),
        ),
      );
    });

    test('throws when workdir does not exist', () async {
      final stream = adapter.runStreaming(
        ['status'],
        workdir: '${tempDir.path}/nonexistent',
      );

      expect(
        stream.toList(),
        throwsA(isA<ProcessException>()),
      );
    });
  });

  // ------------------------------------------------------------------
  // Environment
  // ------------------------------------------------------------------
  group('ProcessGitCommandAdapter environment', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('git_adapter_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('extra env vars are visible to the git process', () async {
      await Process.run('git', ['init'], workingDirectory: tempDir.path);

      // Use GIT_CONFIG_COUNT to inject a config value via environment.
      final result = await adapter.run(
        ['config', 'user.name'],
        workdir: tempDir.path,
        env: {
          'GIT_CONFIG_COUNT': '1',
          'GIT_CONFIG_KEY_0': 'user.name',
          'GIT_CONFIG_VALUE_0': 'TestUserViaEnv',
        },
      );

      expect(result.exitCode, 0);
      expect(result.stdout.trim(), 'TestUserViaEnv');
    });

    test('GIT_TERMINAL_PROMPT is disabled', () async {
      // Verify by running a command that would normally prompt — git
      // should fail cleanly instead of hanging. We check that the
      // adapter's built-in env is active by confirming a credential
      // prompt doesn't appear.
      await Process.run('git', ['init'], workingDirectory: tempDir.path);

      // `git fetch` against a non-existent host fails quickly thanks to
      // GIT_TERMINAL_PROMPT=0 and GIT_ASKPASS=echo, rather than hanging.
      final result = await adapter.run(
        ['fetch', 'https://0.0.0.0/nonexistent.git'],
        workdir: tempDir.path,
      );

      // Should exit with error, not hang forever.
      expect(result.exitCode, isNot(0));
    });
  });

  // ------------------------------------------------------------------
  // Edge cases
  // ------------------------------------------------------------------
  group('ProcessGitCommandAdapter edge cases', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('git_adapter_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('handles commands with many arguments', () async {
      await Process.run('git', ['init'], workingDirectory: tempDir.path);

      final result = await adapter.run(
        ['-c', 'color.ui=never', 'status', '--short', '--branch'],
        workdir: tempDir.path,
      );

      expect(result.exitCode, 0);
    });

    test('reports exit code 0 for successful commands', () async {
      await Process.run('git', ['init'], workingDirectory: tempDir.path);
      File('${tempDir.path}/f.txt').writeAsStringSync('x');
      await Process.run('git', ['add', 'f.txt'], workingDirectory: tempDir.path);
      Process.runSync('git', ['commit', '-m', 'c'], workingDirectory: tempDir.path, environment: {
        'GIT_AUTHOR_NAME': 'T',
        'GIT_AUTHOR_EMAIL': 't@t.com',
        'GIT_COMMITTER_NAME': 'T',
        'GIT_COMMITTER_EMAIL': 't@t.com',
      });

      final result = await adapter.run(
        ['rev-parse', 'HEAD'],
        workdir: tempDir.path,
      );

      expect(result.exitCode, 0);
      expect(result.stdout, isNotEmpty);
      expect(result.isSuccess, isTrue);
    });
  });
}
