@TestOn('!windows')
library;

import 'dart:io';

import 'package:cc_server_core/src/server_boot_refusal.dart';
import 'package:test/test.dart';

int _mode(String path) => FileStat.statSync(path).mode & 0x1ff;

Future<void> _chmod(String mode, String path) async {
  final result = await Process.run('chmod', [mode, path]);
  expect(result.exitCode, 0);
}

void main() {
  late Directory root;
  setUp(() => root = Directory.systemTemp.createTempSync('cc_datadir'));
  tearDown(() => root.deleteSync(recursive: true));

  test('a missing data directory is created 0700', () {
    final dataDir = '${root.path}/nested/data';
    secureDataDirectory(dataDir);
    expect(_mode(dataDir), 0x1c0, reason: '0700');
  });

  test(
    'an existing wide directory and its secret files are tightened',
    () async {
      final dataDir = '${root.path}/data';
      Directory('$dataDir/ws-1').createSync(recursive: true);
      Directory('$dataDir/logs').createSync();
      File('$dataDir/ws-1/workspace.db').writeAsStringSync('');
      for (final name in [...secretFileNames, 'font_catalog.json']) {
        File('$dataDir/$name').writeAsStringSync('x');
        await _chmod('644', '$dataDir/$name');
      }
      for (final path in [dataDir, '$dataDir/ws-1', '$dataDir/logs']) {
        await _chmod('755', path);
      }

      secureDataDirectory(dataDir);

      expect(_mode(dataDir), 0x1c0, reason: 'data dir 0700');
      for (final name in secretFileNames) {
        expect(_mode('$dataDir/$name'), 0x180, reason: '$name 0600');
      }
      expect(_mode('$dataDir/ws-1'), 0x1c0, reason: 'workspace dir 0700');
      // Not a known secret: left as the data dir's own mode protects it.
      expect(_mode('$dataDir/font_catalog.json'), 0x1a4);
      expect(_mode('$dataDir/logs'), 0x1ed);
    },
  );

  test(
    'a directory that cannot be made owner-only refuses the boot',
    () async {
      // A directory we do not own: chmod is refused, so the mode stays wide.
      // `/tmp` is world-writable and owned by root on every POSIX host CI
      // runs, so the refusal is observable without privileges.
      final shared = Directory('/tmp').resolveSymbolicLinksSync();
      if (FileStat.statSync(shared).mode & 0x3f == 0) {
        markTestSkipped('/tmp is already owner-only here');
        return;
      }
      expect(
        () => secureDataDirectory(shared),
        throwsA(
          isA<DataDirNotPrivate>().having(
            (e) => e.message,
            'message',
            allOf(contains(shared), contains('chmod 700')),
          ),
        ),
      );
    },
    skip: Platform.environment['USER'] == 'root'
        ? 'root may chmod anything'
        : false,
  );
}
