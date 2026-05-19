import 'dart:io';

import 'package:control_center/core/infrastructure/ide/reveal_in_file_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RevealInFileManager', () {
    ({RevealInFileManager svc, List<List<Object?>> calls}) build({
      required String os,
      int exitCode = 0,
      String stderr = '',
      bool throwProcessException = false,
    }) {
      final calls = <List<Object?>>[];
      final svc = RevealInFileManager(
        operatingSystem: os,
        runProcess: (exe, args) async {
          calls.add([exe, args]);
          if (throwProcessException) {
            throw const ProcessException('x', [], 'not found');
          }
          return ProcessResult(0, exitCode, '', stderr);
        },
      );
      return (svc: svc, calls: calls);
    }

    test('macOS reveals via `open`', () async {
      final b = build(os: 'macos');
      await b.svc.reveal('/tmp/foo');
      expect(b.calls, [
        [
          'open',
          ['/tmp/foo'],
        ],
      ]);
    });

    test('Windows reveals via `explorer`', () async {
      final b = build(os: 'windows');
      await b.svc.reveal(r'C:\foo');
      expect(b.calls, [
        [
          'explorer',
          [r'C:\foo'],
        ],
      ]);
    });

    test('Linux reveals via `xdg-open`', () async {
      final b = build(os: 'linux');
      await b.svc.reveal('/home/x/foo');
      expect(b.calls, [
        [
          'xdg-open',
          ['/home/x/foo'],
        ],
      ]);
    });

    test('trims the path before launching', () async {
      final b = build(os: 'linux');
      await b.svc.reveal('  /home/x/foo  ');
      expect(b.calls.single[1], ['/home/x/foo']);
    });

    test('rejects an empty path without spawning a process', () async {
      final b = build(os: 'macos');
      await expectLater(
        b.svc.reveal('   '),
        throwsA(isA<RevealInFileManagerException>()),
      );
      expect(b.calls, isEmpty);
    });

    test('throws on an unsupported platform', () async {
      final b = build(os: 'fuchsia');
      await expectLater(
        b.svc.reveal('/tmp/foo'),
        throwsA(isA<RevealInFileManagerException>()),
      );
      expect(b.calls, isEmpty);
    });

    test('surfaces a non-zero exit as a failure on macOS/Linux', () async {
      final b = build(os: 'linux', exitCode: 1, stderr: 'no such file');
      await expectLater(
        b.svc.reveal('/tmp/foo'),
        throwsA(
          isA<RevealInFileManagerException>().having(
            (e) => e.message,
            'message',
            contains('no such file'),
          ),
        ),
      );
    });

    test('tolerates the non-zero exit `explorer` returns on success', () async {
      // Windows Explorer exits non-zero even when it opened the folder — that
      // must NOT be treated as a failure.
      final b = build(os: 'windows', exitCode: 1);
      await b.svc.reveal(r'C:\foo'); // does not throw
      expect(b.calls, isNotEmpty);
    });

    test(
      'maps a ProcessException (command missing) to a reveal exception',
      () async {
        final b = build(os: 'linux', throwProcessException: true);
        await expectLater(
          b.svc.reveal('/tmp/foo'),
          throwsA(isA<RevealInFileManagerException>()),
        );
      },
    );
  });
}
