import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_infra/src/sandboxing/process_sandbox.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

SandboxSpec _spec({List<SandboxBindMount>? bindMounts}) => processSandboxSpec(
  sessionId: 's1',
  workspaceId: 'ws',
  workdir: '/work/tree',
  bindMounts: bindMounts,
  networkEnabled: false,
  mode: Mode.review,
  protectedPaths: const ['/repos/original'],
  execGrantRoots: const ['/work/tree/node_modules/.bin'],
  loopbackPorts: const [4242],
  environmentScope: 'ws/space',
);

void main() {
  group('processSandboxSpec', () {
    test('carries every security input it was given', () {
      final spec = _spec();
      expect(spec.networkEnabled, isFalse);
      expect(spec.mode, Mode.review);
      expect(spec.protectedPaths, ['/repos/original']);
      expect(spec.execGrantRoots, ['/work/tree/node_modules/.bin']);
      expect(spec.loopbackPorts, [4242]);
      expect(spec.environmentScope, 'ws/space');
      expect(spec.guestWorkdir, '/work/tree');
      expect(spec.superviseProcessGroup, isFalse);
    });

    test('mounts only the workdir, read-write, unless told otherwise', () {
      expect(_spec().bindMounts, const [
        SandboxBindMount(hostPath: '/work/tree', guestPath: '/work/tree'),
      ]);
      const ro = SandboxBindMount(
        hostPath: '/shared',
        guestPath: '/shared',
        readOnly: true,
      );
      expect(_spec(bindMounts: const [ro]).bindMounts, const [ro]);
    });

    test('a session runs in <workdir>/.cc-runs/<session> unless named', () {
      expect(processSandboxRunDir(_spec()), '/work/tree/.cc-runs/s1');
      expect(processSandboxPolicy(_spec()).runDir, '/work/tree/.cc-runs/s1');
      expect(
        processSandboxPolicy(_spec(), runDir: '/elsewhere').runDir,
        '/elsewhere',
      );
    });
  });

  test('every cc_infra sandbox spec is built by processSandboxSpec', () {
    // Structural: a launcher that constructs its own SandboxSpec can drop a
    // security input (the ACP path once ran without process-group
    // supervision). Only the shared builder may call the constructor.
    final lib = Directory(p.join(Directory.current.path, 'lib'));
    final offenders = <String>[];
    for (final entity in lib.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      if (p.basename(entity.path) == 'process_sandbox.dart') {
        continue;
      }
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trimLeft();
        if (line.startsWith('//')) {
          continue;
        }
        if (RegExp(r'\bSandboxSpec\(').hasMatch(line)) {
          offenders.add('${p.relative(entity.path, from: lib.path)}:${i + 1}');
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
