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

  group('ensurePrivateDirectory', () {
    late Directory root;
    setUp(() async => root = await Directory.systemTemp.createTemp('cc_dir'));
    tearDown(() => root.delete(recursive: true));

    int mode(String path) => FileStat.statSync(path).mode & 0x1ff;

    test('creates a missing directory 0700 whatever the umask allows', () {
      final path = '${root.path}/a/b';
      ensurePrivateDirectory(path);
      expect(mode(path), 0x1c0, reason: '0700');
      expect(isOwnerOnly(path), isTrue);
    }, skip: Platform.isWindows ? 'POSIX modes only' : false);

    test('tightens an existing wide directory', () async {
      final path = '${root.path}/wide';
      Directory(path).createSync();
      await Process.run('chmod', ['755', path]);
      expect(isOwnerOnly(path), isFalse);
      ensurePrivateDirectory(path);
      expect(mode(path), 0x1c0, reason: '0700');
    }, skip: Platform.isWindows ? 'POSIX modes only' : false);

    test(
      'refuses a directory whose mode cannot be changed',
      () {
        final shared = Directory('/tmp').resolveSymbolicLinksSync();
        if (isOwnerOnly(shared)) {
          markTestSkipped('/tmp is already owner-only here');
          return;
        }
        expect(
          () => ensurePrivateDirectory(shared),
          throwsA(isA<PrivateDirectoryException>()),
        );
      },
      skip: Platform.isWindows || Platform.environment['USER'] == 'root'
          ? 'needs POSIX modes and an unprivileged user'
          : false,
    );
  });

  group('tightenToOwnerOnly', () {
    late Directory root;
    setUp(() async => root = await Directory.systemTemp.createTemp('cc_tight'));
    tearDown(() => root.delete(recursive: true));

    test(
      'restricts a wide file to 0600 and leaves links and absent paths alone',
      () async {
        final file = '${root.path}/secret';
        File(file).writeAsStringSync('x');
        await Process.run('chmod', ['644', file]);
        final outside = '${root.path}/outside';
        File(outside).writeAsStringSync('x');
        await Process.run('chmod', ['644', outside]);
        Link('${root.path}/link').createSync(outside);

        expect(tightenToOwnerOnly(file), isTrue);
        expect(FileStat.statSync(file).mode & 0x1ff, 0x180, reason: '0600');
        expect(tightenToOwnerOnly(file), isFalse, reason: 'already private');
        expect(tightenToOwnerOnly('${root.path}/link'), isFalse);
        expect(FileStat.statSync(outside).mode & 0x1ff, 0x1a4);
        expect(tightenToOwnerOnly('${root.path}/missing'), isFalse);
      },
      skip: Platform.isWindows ? 'POSIX modes only' : false,
    );
  });
}
