@TestOn('mac-os')
library;

import 'dart:io';

import 'package:control_center/core/infrastructure/rift/rift_client.dart';
import 'package:control_center/core/infrastructure/rift/rift_ffi_bindings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// End-to-end test of the rift FFI binding against the real, locally-built
/// `librift_ffi.dylib`. Skips when the native lib isn't installed (run
/// `scripts/build_rift.sh` first) so it never fails on machines without it.
void main() {
  final home = Platform.environment['HOME'] ?? '';
  final candidates = <String>[
    if (Platform.environment['RIFT_FFI_DYLIB'] != null)
      Platform.environment['RIFT_FFI_DYLIB']!,
    p.join(home, 'Library', 'Application Support', 'com.alev.control-center',
        'librift_ffi.dylib'),
    p.join(Directory.current.path, 'macos', 'Frameworks', 'librift_ffi.dylib'),
  ];
  final bindings = RiftFfiBindings.tryLoad(explicitPaths: candidates);

  group('RiftClient (real FFI)', () {
    late Directory tmp;
    late RiftClient rift;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('rift_ffi_e2e');
      rift = RiftClient(
        dylibPaths: candidates,
        databasePath: p.join(tmp.path, 'rift.sqlite'),
      );
    });

    tearDown(() async {
      if (tmp.existsSync()) {
        await tmp.delete(recursive: true);
      }
    });

    Future<void> git(List<String> args, String cwd) async {
      final r = await Process.run('git', args, workingDirectory: cwd);
      expect(r.exitCode, 0, reason: 'git ${args.join(' ')}: ${r.stderr}');
    }

    test('init + copyAll create yields an isolated, complete copy', () async {
      final src = Directory(p.join(tmp.path, 'src'))..createSync();
      await git(['init', '-q'], src.path);
      await git(['config', 'user.email', 't@t.t'], src.path);
      await git(['config', 'user.name', 't'], src.path);
      File(p.join(src.path, 'file.txt')).writeAsStringSync('hello');
      Directory(p.join(src.path, 'node_modules')).createSync();
      File(p.join(src.path, 'node_modules', 'big.js')).writeAsStringSync('x');
      await git(['add', 'file.txt'], src.path);
      await git(['commit', '-qm', 'init'], src.path);

      await rift.init(at: src.path);
      final dest = await rift.create(
        from: src.path,
        into: p.join(tmp.path, 'managed'),
        name: 'task-a',
        copyAll: true,
        hooks: false,
      );

      // The copy is complete (copyAll keeps node_modules) and independent.
      expect(File(p.join(dest, 'file.txt')).existsSync(), isTrue);
      expect(Directory(p.join(dest, '.git')).existsSync(), isTrue);
      expect(File(p.join(dest, 'node_modules', 'big.js')).existsSync(), isTrue);

      // Writing in the copy never touches the source.
      File(p.join(dest, 'file.txt')).writeAsStringSync('changed');
      expect(File(p.join(src.path, 'file.txt')).readAsStringSync(), 'hello');

      // The source is not a git worktree host — the copy is fully separate.
      expect(
        Directory(p.join(src.path, '.git', 'worktrees')).existsSync(),
        isFalse,
      );

      // Cleanup via the registry.
      await rift.remove(at: dest);
      await rift.gc();
    });
  }, skip: bindings == null ? 'librift_ffi not installed' : false);
}
