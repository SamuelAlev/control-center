import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/features/rigs/domain/value_objects/rig_file_transfer.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_infra/src/rigs/rig_file_transfer.dart';
import 'package:cc_infra/src/rigs/worktree_sync.dart';
import 'package:test/test.dart';

/// A transport that runs its commands in a REAL `sh` on this host.
///
/// The point of the file lane is a shell script that has to be correct — a
/// collision loop that never overwrites, a path the guest chooses and prints
/// back, a refusal when the directory is unwritable. A mock that returns
/// canned strings would test the Dart around it and none of that, so this runs
/// the actual script and lets the filesystem be the assertion.
class _LocalShellTransport implements WorktreeTransport {
  @override
  List<String> get requiredHostTools => const [];

  @override
  Future<Process> start(String command) => Process.start('sh', ['-c', command]);

  @override
  Future<WorktreeCommandResult> capture(String command) async {
    final result = await Process.run('sh', ['-c', command]);
    return (
      exitCode: result.exitCode,
      stdout: '${result.stdout}',
      stderr: '${result.stderr}',
    );
  }

  @override
  List<String> interactiveShellArgv({String? workingDirectory}) => const ['sh'];
}

void main() {
  late Directory root;
  late RigFileTransfer transfer;

  setUp(() {
    root = Directory.systemTemp.createTempSync('cc-rig-files-');
    transfer = RigFileTransfer(
      transport: _LocalShellTransport(),
      dropDirectory: '${root.path}/drops',
    );
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  RigFilePayload payload(String name, String content) =>
      RigFilePayload(name: name, bytes: Uint8List.fromList(content.codeUnits));

  group('put', () {
    test('creates the drop directory and writes the bytes', () async {
      final landed = await transfer.put([payload('a.txt', 'hello')]);

      expect(landed.single.guestPath, '${root.path}/drops/a.txt');
      expect(File(landed.single.guestPath).readAsStringSync(), 'hello');
    });

    test('never overwrites a file that is already there', () async {
      // A drop that destroys an existing file is data loss nobody would think
      // to attribute to a drag.
      final first = await transfer.put([payload('report.pdf', 'one')]);
      final second = await transfer.put([payload('report.pdf', 'two')]);
      final third = await transfer.put([payload('report.pdf', 'three')]);

      expect(first.single.guestPath, endsWith('/drops/report.pdf'));
      expect(second.single.guestPath, endsWith('/drops/2-report.pdf'));
      expect(third.single.guestPath, endsWith('/drops/3-report.pdf'));
      expect(File(first.single.guestPath).readAsStringSync(), 'one');
    });

    test('sanitises a name that would escape the drop directory', () async {
      final landed = await transfer.put([payload('../../escaped.txt', 'nope')]);

      expect(landed.single.guestPath, '${root.path}/drops/escaped.txt');
      expect(File('${root.path}/escaped.txt').existsSync(), isFalse);
    });

    test('survives a name full of shell metacharacters', () async {
      // The name came from wherever the user dragged it; it reaches a command
      // line inside the guest.
      final landed = await transfer.put([
        payload(r"a'; touch /tmp/pwned; echo '.txt", 'safe'),
      ]);

      expect(File(landed.single.guestPath).readAsStringSync(), 'safe');
      expect(File('/tmp/pwned').existsSync(), isFalse);
    });

    test('writes binary content unchanged', () async {
      final bytes = Uint8List.fromList([0, 1, 2, 255, 254, 10, 13, 0]);
      final landed = await transfer.put([
        RigFilePayload(name: 'blob.bin', bytes: bytes),
      ]);

      expect(File(landed.single.guestPath).readAsBytesSync(), bytes);
    });

    test('reports a failure with the guest\'s own words', () async {
      final blocked = Directory('${root.path}/blocked')..createSync();
      // 0500: the directory exists and cannot be written to.
      Process.runSync('chmod', ['500', blocked.path]);
      final refusing = RigFileTransfer(
        transport: _LocalShellTransport(),
        dropDirectory: blocked.path,
      );

      await expectLater(
        refusing.put([payload('a.txt', 'x')]),
        throwsA(
          isA<RigFileTransferException>().having(
            (e) => e.message,
            'message',
            contains('a.txt'),
          ),
        ),
      );
      Process.runSync('chmod', ['700', blocked.path]);
    });
  });

  group('get', () {
    test('reads a regular file back out', () async {
      final landed = await transfer.put([payload('out.txt', 'contents')]);

      final read = await transfer.get(landed.single.guestPath);

      expect(read?.name, 'out.txt');
      expect(String.fromCharCodes(read!.bytes), 'contents');
      expect(read.mediaType, 'text/plain');
    });

    test('reads binary content unchanged', () async {
      final bytes = Uint8List.fromList(List.generate(4096, (i) => i % 256));
      final landed = await transfer.put([
        RigFilePayload(name: 'blob.bin', bytes: bytes),
      ]);

      final read = await transfer.get(landed.single.guestPath);

      expect(read?.bytes, bytes);
    });

    test('refuses a directory', () async {
      // Streaming a directory would either fail obscurely or, worse, succeed
      // with something that is not a file.
      expect(await transfer.get(root.path), isNull);
    });

    test('answers null for a path that is not there', () async {
      expect(await transfer.get('${root.path}/missing.txt'), isNull);
    });

    test('refuses a path that could end a shell line', () async {
      expect(await transfer.get('/home/cc/a\nrm -rf /'), isNull);
      expect(await transfer.get('relative/path'), isNull);
      expect(await transfer.get(''), isNull);
    });
  });

  group('rejectGuestPath', () {
    test('accepts an ordinary absolute path', () {
      expect(rejectGuestPath('/home/cc/Drops/a b.txt'), isNull);
    });

    test('names what is wrong', () {
      expect(rejectGuestPath(''), contains('empty'));
      expect(rejectGuestPath('home/cc'), contains('absolute'));
      expect(rejectGuestPath('/a\nb'), contains('control character'));
      expect(rejectGuestPath('/${'a' * 5000}'), contains('PATH_MAX'));
    });
  });

  group('rigDropDirectory', () {
    test('gives each surface somewhere it can actually see', () {
      expect(
        rigDropDirectory(surface: RigSurface.computer, exec: false),
        '/home/cc/Drops',
      );
      // headless-shell has no home worth speaking of; /tmp is guaranteed
      // writable and reachable by the browser process.
      expect(
        rigDropDirectory(surface: RigSurface.browser, exec: false),
        '/tmp/cc-drops',
      );
    });

    test('an exec rig drops beside its worktree, never inside it', () {
      // A dropped file must never turn up as an untracked change in
      // somebody's repository.
      final dir = rigDropDirectory(surface: RigSurface.computer, exec: true);
      expect(dir, '/home/cc/drops');
      expect(dir, isNot(contains('/work')));
    });
  });

  group('guestDirectoryOf', () {
    test('splits POSIX paths', () {
      expect(guestDirectoryOf('/home/cc/Drops/a.txt'), '/home/cc/Drops');
      expect(guestDirectoryOf('/a.txt'), '/');
      expect(guestDirectoryOf('bare'), '/');
    });
  });

  group('guessMediaType', () {
    test('reads well-known extensions', () {
      expect(guessMediaType('/a/b.png'), 'image/png');
      expect(guessMediaType('/a/b.PDF'), 'application/pdf');
      expect(guessMediaType('/a/b.tar.gz'), 'application/gzip');
    });

    test('answers null rather than guessing', () {
      expect(guessMediaType('/a/README'), isNull);
      expect(guessMediaType('/a/b.'), isNull);
      expect(guessMediaType('/a/b.unknownext'), isNull);
    });
  });
}
