import 'dart:convert';
import 'dart:io';

import 'package:cc_infra/cc_paths.dart';
import 'package:test/test.dart';

void main() {
  group('writePrivateFile', () {
    late Directory dir;
    setUp(() async => dir = await Directory.systemTemp.createTemp('cc_priv'));
    tearDown(() => dir.delete(recursive: true));

    test(
      'creates the file owner-only, replaces atomically and leaves no temp',
      () async {
        final path = '${dir.path}/secret';
        await writePrivateFile(path, utf8.encode('one'));
        await writePrivateFile(path, utf8.encode('two'));
        expect(File(path).readAsStringSync(), 'two');
        expect(File(path).statSync().mode & 0x1ff, 0x180, reason: '0600');
        expect(dir.listSync().map((e) => e.path), [path]);
        await expectLater(
          writePrivateFile(path, utf8.encode('three'), overwrite: false),
          throwsA(isA<FileSystemException>()),
        );
        expect(File(path).readAsStringSync(), 'two');
      },
      skip: Platform.isWindows ? 'POSIX modes only' : false,
    );

    test(
      'a destination that was world-readable is replaced by an 0600 inode',
      () async {
        final path = '${dir.path}/secret';
        File(path).writeAsStringSync('old');
        await Process.run('chmod', ['644', path]);
        await writePrivateFile(path, utf8.encode('new'));
        expect(File(path).statSync().mode & 0x1ff, 0x180, reason: '0600');
        expect(File(path).readAsStringSync(), 'new');
      },
      skip: Platform.isWindows ? 'POSIX modes only' : false,
    );
  });
}
