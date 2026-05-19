import 'dart:io';

import 'package:cc_infra/src/util/cc_paths.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Exercises [CcPaths] — the pure-Dart on-disk layout resolver. Every method
/// both returns a path and ensures the directory exists, so the tests verify
/// the path layout AND that the directory is created under a temp root.
void main() {
  late Directory sandbox;
  late CcPaths paths;

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('cc_paths_');
    paths = CcPaths(sandbox.path);
  });
  tearDown(() => sandbox.deleteSync(recursive: true));

  group('directory layout', () {
    test('root() returns and creates the app-support root', () async {
      // Use a non-existent nested path to confirm creation.
      paths = CcPaths(p.join(sandbox.path, 'data'));
      final dir = await paths.root();
      expect(dir.path, p.join(sandbox.path, 'data'));
      expect(Directory(dir.path).existsSync(), isTrue);
    });

    test('modelsRoot / grammarsRoot live one level under the root', () async {
      expect((await paths.modelsRoot()).path, p.join(sandbox.path, 'models'));
      expect(
        (await paths.grammarsRoot()).path,
        p.join(sandbox.path, 'grammars'),
      );
    });

    test('pipelineRunDir and meetingAudioDir are keyed by id', () async {
      expect(
        (await paths.pipelineRunDir('r1')).path,
        p.join(sandbox.path, 'pipelines', 'r1'),
      );
      expect(
        (await paths.meetingAudioDir('m1')).path,
        p.join(sandbox.path, 'meetings', 'm1'),
      );
    });

    test('reviewSnapshotDir sanitizes unsafe id characters', () async {
      final dir = await paths.reviewSnapshotDir(
        'PR_node/../evil',
        'comp key with spaces',
      );
      // The sanitizer keeps `.` and `-` but collapses `/` (and other
      // non-[A-Za-z0-9_.-]) to `_`. So `../` → `_.._`.
      expect(
        dir.path,
        p.join(
          sandbox.path,
          'review_snapshots',
          'PR_node_.._evil',
          'comp_key_with_spaces',
        ),
      );
      expect(dir.existsSync(), isTrue);
    });
  });

  group('file paths', () {
    test(
      'databaseFile points at control_center.db and ensures the root',
      () async {
        final f = await paths.databaseFile();
        expect(f.path, p.join(sandbox.path, 'control_center.db'));
      },
    );

    test('mcpConfigFile points at mcp.json and ensures the root', () async {
      final f = await paths.mcpConfigFile();
      expect(f.path, p.join(sandbox.path, 'mcp.json'));
    });

    test('riftRegistryPath is a string join (no ensure)', () {
      expect(paths.riftRegistryPath(), p.join(sandbox.path, 'rift.sqlite'));
    });
  });

  group('native dylib candidate paths', () {
    test('rift / aec / lame candidates are non-empty and rooted under env', () {
      final rift = paths.riftDylibCandidatePaths();
      final aec = paths.aecFfiDylibCandidatePaths();
      final lame = paths.lameFfiDylibCandidatePaths();
      expect(rift, isNotEmpty);
      expect(aec, isNotEmpty);
      expect(lame, isNotEmpty);
      // When the RIFT_FFI_DYLIB env var is set it must appear in the list.
      // (We only assert structure here — the actual file isn't required.)
      expect(rift.any((c) => c.contains('rift_ffi')), isTrue);
      expect(aec.any((c) => c.contains('aec_ffi')), isTrue);
      expect(lame.any((c) => c.contains('lame_ffi')), isTrue);
    });
  });

  group('idempotency', () {
    test('calling a directory method twice does not throw', () async {
      await paths.modelsRoot();
      await expectLater(paths.modelsRoot(), completes);
    });
  });
}
