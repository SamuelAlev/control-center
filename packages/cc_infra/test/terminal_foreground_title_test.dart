import 'dart:io';

import 'package:cc_infra/src/sandboxing/terminal_foreground_title.dart';
import 'package:test/test.dart';

void main() {
  group('prettyCommandTitle', () {
    test('basenames path tokens', () {
      expect(prettyCommandTitle('/usr/bin/git status'), 'git status');
      expect(
        prettyCommandTitle('/opt/homebrew/bin/cargo build'),
        'cargo build',
      );
    });

    test('keeps a plain command with args', () {
      expect(prettyCommandTitle('sleep 100'), 'sleep 100');
    });

    test('drops a leading interpreter launching a script (ghostty parity)', () {
      expect(
        prettyCommandTitle('node /Users/x/.volta/bin/pnpm dev serve'),
        'pnpm dev serve',
      );
    });

    test('keeps the interpreter when its next token is a flag', () {
      expect(
        prettyCommandTitle('python3 -m http.server'),
        'python3 -m http.server',
      );
    });

    test('collapses a prompt shell to empty', () {
      expect(prettyCommandTitle('-zsh'), '');
      expect(prettyCommandTitle('/bin/zsh -il'), '');
      expect(prettyCommandTitle('bash -il'), '');
    });

    test('drops a shell interpreter running a script too', () {
      expect(
        prettyCommandTitle('bash build.sh --release'),
        'build.sh --release',
      );
    });

    test('caps overlong titles', () {
      final title = prettyCommandTitle('cmd ${'a' * 100}');
      expect(title.length, 60);
      expect(title.endsWith('…'), isTrue);
    });

    test('empty input stays empty', () {
      expect(prettyCommandTitle(''), '');
      expect(prettyCommandTitle('   '), '');
    });
  });

  group('TerminalForegroundTracker', () {
    test('emits the command when a job takes the foreground, then dedupes', () {
      final tracker = TerminalForegroundTracker(shellPid: 100);
      expect(tracker.onSample(tpgid: 200, command: 'sleep 100'), 'sleep 100');
      // Same foreground group on the next ticks → no re-emission (an OSC the
      // job set must not be clobbered by the poll).
      expect(tracker.onSample(tpgid: 200, command: 'sleep 100'), isNull);
      expect(tracker.currentTitle, 'sleep 100');
    });

    test('emits empty when the shell returns to the prompt', () {
      final tracker = TerminalForegroundTracker(shellPid: 100)
        ..onSample(tpgid: 200, command: 'sleep 100');
      expect(tracker.onSample(tpgid: 100, command: ''), '');
      expect(tracker.currentTitle, '');
    });

    test('a failed sample keeps state', () {
      final tracker = TerminalForegroundTracker(shellPid: 100)
        ..onSample(tpgid: 200, command: 'sleep 100');
      expect(tracker.onSample(tpgid: null, command: ''), isNull);
      expect(tracker.currentTitle, 'sleep 100');
    });

    test('a wrapped shell at its prompt titles empty via the shell rule', () {
      // Under bwrap the PTY child is the wrapper, so at the prompt the
      // foreground pgid is the shell's — NOT the tracked pid. The prompt-shell
      // rule still collapses it to ''.
      final tracker = TerminalForegroundTracker(shellPid: 100);
      expect(tracker.onSample(tpgid: 150, command: '/bin/bash -il'), '');
    });
  });

  group('sampleForegroundTitle', () {
    ProcessResult ok(String stdout) => ProcessResult(0, 0, stdout, '');

    test('resolves the foreground command via tpgid then command', () async {
      final tracker = TerminalForegroundTracker(shellPid: 100);
      final calls = <List<String>>[];
      final title = await sampleForegroundTitle(
        tracker,
        runProcess: (cmd, args) async {
          calls.add([cmd, ...args]);
          if (args[1] == 'tpgid=') {
            return ok('  200\n');
          }
          return ok('/usr/local/bin/cargo build\n');
        },
      );
      expect(title, 'cargo build');
      expect(calls, [
        ['ps', '-o', 'tpgid=', '-p', '100'],
        ['ps', '-o', 'command=', '-p', '200'],
      ]);
    }, testOn: '!windows');

    test('shell foreground skips the command lookup and clears', () async {
      final tracker = TerminalForegroundTracker(shellPid: 100)
        ..onSample(tpgid: 200, command: 'sleep 100');
      var lookups = 0;
      final title = await sampleForegroundTitle(
        tracker,
        runProcess: (cmd, args) async {
          if (args[1] == 'command=') {
            lookups++;
          }
          return ok('100');
        },
      );
      expect(title, '');
      expect(lookups, 0);
    }, testOn: '!windows');

    test(
      'propagates a ps exec failure so the caller can stop polling',
      () async {
        final tracker = TerminalForegroundTracker(shellPid: 100);
        expect(
          () => sampleForegroundTitle(
            tracker,
            runProcess: (_, _) => throw const ProcessException('ps', []),
          ),
          throwsA(isA<ProcessException>()),
        );
      },
      testOn: '!windows',
    );
  });
}
