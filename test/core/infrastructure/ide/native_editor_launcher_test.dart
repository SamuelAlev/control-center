import 'dart:io';

import 'package:control_center/core/domain/entities/ide_editor.dart';
import 'package:control_center/core/errors/app_exceptions.dart';
import 'package:control_center/core/infrastructure/ide/native_editor_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NativeEditorLauncher', () {
    test('returns an empty catalog on an unsupported platform', () async {
      final launcher = NativeEditorLauncher(
        operatingSystem: 'fuchsia',
        environment: const {},
        pathExists: (_) => false,
        runProcess: (_, _, {workingDirectory}) async =>
            ProcessResult(0, 0, '', ''),
      );
      expect(await launcher.detectEditors(), isEmpty);
    });

    group('macOS', () {
      NativeEditorLauncher build({
        required Set<String> existing,
        List<List<Object?>>? calls,
        int exitCode = 0,
        String stderr = '',
      }) {
        return NativeEditorLauncher(
          operatingSystem: 'macos',
          environment: const {'HOME': '/Users/test'},
          pathExists: existing.contains,
          runProcess: (exe, args, {workingDirectory}) async {
            calls?.add([exe, args, workingDirectory]);
            return ProcessResult(0, exitCode, '', stderr);
          },
        );
      }

      test('flags an installed app and leaves the rest not installed',
          () async {
        final launcher = build(existing: {'/Applications/Cursor.app'});
        final editors = await launcher.detectEditors();

        IdeEditor byId(String id) => editors.firstWhere((e) => e.id == id);
        expect(byId('cursor').installed, isTrue);
        expect(byId('vscode').installed, isFalse);
        expect(byId('cursor').displayName, 'Cursor');
      });

      test('finds an app under ~/Applications too', () async {
        final launcher = build(existing: {'/Users/test/Applications/Zed.app'});
        final editors = await launcher.detectEditors();
        expect(editors.firstWhere((e) => e.id == 'zed').installed, isTrue);
      });

      test('opens an app via `open -a <app> <dir>`', () async {
        final calls = <List<Object?>>[];
        final launcher = build(
          existing: {'/Applications/Cursor.app'},
          calls: calls,
        );
        await launcher.openDirectory(editorId: 'cursor', directoryPath: '/repo');

        expect(calls, hasLength(1));
        expect(calls.single[0], '/usr/bin/open');
        expect(calls.single[1], ['-a', '/Applications/Cursor.app', '/repo']);
        expect(calls.single[2], isNull);
      });

      test('throws when the directory path is blank', () async {
        final launcher = build(existing: {'/Applications/Cursor.app'});
        expect(
          () => launcher.openDirectory(editorId: 'cursor', directoryPath: '  '),
          throwsA(isA<EditorLaunchException>()),
        );
      });

      test('throws for an unknown editor id', () async {
        final launcher = build(existing: const {});
        expect(
          () => launcher.openDirectory(
            editorId: 'not-an-editor',
            directoryPath: '/repo',
          ),
          throwsA(isA<EditorLaunchException>()),
        );
      });

      test('throws when the requested editor is not installed', () async {
        final launcher = build(existing: const {});
        expect(
          () =>
              launcher.openDirectory(editorId: 'vscode', directoryPath: '/repo'),
          throwsA(isA<EditorLaunchException>()),
        );
      });

      test('throws when the launch process exits non-zero', () async {
        final launcher = build(
          existing: {'/Applications/Cursor.app'},
          exitCode: 1,
          stderr: 'boom',
        );
        await expectLater(
          launcher.openDirectory(editorId: 'cursor', directoryPath: '/repo'),
          throwsA(
            isA<EditorLaunchException>().having(
              (e) => e.message,
              'message',
              contains('boom'),
            ),
          ),
        );
      });
    });

    group('Linux', () {
      test('detects a binary on PATH and opens it with the directory',
          () async {
        final calls = <List<Object?>>[];
        final launcher = NativeEditorLauncher(
          operatingSystem: 'linux',
          environment: const {'PATH': '/usr/bin', 'HOME': '/home/test'},
          pathExists: (p) => p == '/usr/bin/code',
          runProcess: (exe, args, {workingDirectory}) async {
            calls.add([exe, args, workingDirectory]);
            return ProcessResult(0, 0, '', '');
          },
        );

        final editors = await launcher.detectEditors();
        expect(editors.firstWhere((e) => e.id == 'vscode').installed, isTrue);

        await launcher.openDirectory(editorId: 'vscode', directoryPath: '/repo');
        expect(calls.single[0], '/usr/bin/code');
        expect(calls.single[1], ['/repo']);
      });
    });
  });
}
