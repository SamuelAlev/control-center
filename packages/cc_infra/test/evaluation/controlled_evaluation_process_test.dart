import 'dart:io';

import 'package:cc_infra/src/evaluation/controlled_evaluation_process.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final unavailable = ControlledEvaluationProcess.capabilityReason();
  tearDownAll(ControlledEvaluationProcess.disposeRuntime);

  test(
    'preflight proves denial against a reachable local endpoint and host canary',
    () async {
      expect(await ControlledEvaluationProcess.probeCapability(), isNull);
    },
    skip: unavailable,
  );

  test(
    'ordinary parent exit terminates children holding inherited output pipes',
    () async {
      final parent = await Directory.systemTemp.createTemp(
        'cc-eval-descendant-',
      );
      final root = await Directory(p.join(parent.path, 'work')).create();
      final home = await Directory(p.join(parent.path, 'home')).create();
      final pidFile = File(p.join(root.path, 'child.pid'));
      try {
        final result =
            await ControlledEvaluationProcess(
              root: root.path,
              home: home.path,
            ).execute('/usr/bin/python3', [
              '-I',
              '-S',
              '-c',
              '''
import os, pathlib
ready_read, ready_write = os.pipe()
hold_read, hold_write = os.pipe()
pid = os.fork()
if pid == 0:
    os.close(ready_read)
    os.write(ready_write, b'R')
    os.close(ready_write)
    os.read(hold_read, 1)
    os._exit(0)
os.close(ready_write)
assert os.read(ready_read, 1) == b'R'
pathlib.Path('child.pid').write_text(str(pid))
print('parent finished')
''',
            ], timeout: const Duration(seconds: 5));
        expect(result.exitCode, 0, reason: result.stderr);
        expect(result.stdout.trim(), 'parent finished');
        expect(result.timedOut, isFalse);
        // Returning also proves EOF: the child deliberately retains both pipes.
      } finally {
        // Keep a failing-before run from leaving a fixture child behind.
        if (await pidFile.exists()) {
          Process.killPid(
            int.parse(await pidFile.readAsString()),
            ProcessSignal.sigkill,
          );
        }
        await parent.delete(recursive: true);
      }
    },
    skip: unavailable,
  );

  test(
    'guest files and captured output obey their enforced byte ceilings',
    () async {
      final parent = await Directory.systemTemp.createTemp('cc-eval-limits-');
      final root = await Directory(p.join(parent.path, 'work')).create();
      final home = await Directory(p.join(parent.path, 'home')).create();
      try {
        final result =
            await ControlledEvaluationProcess(
              root: root.path,
              home: home.path,
            ).execute('/usr/bin/python3', [
              '-I',
              '-S',
              '-c',
              '''
import sys
print('x' * 24000, flush=True)
with open('oversized.bin', 'wb') as output:
    output.write(b'x' * (17 * 1024 * 1024))
''',
            ]);
        expect(result.stdout, 'x' * 16000);
        expect(result.exitCode, isNot(0));
        expect(
          await File(p.join(root.path, 'oversized.bin')).length(),
          lessThanOrEqualTo(16 * 1024 * 1024),
        );
      } finally {
        await parent.delete(recursive: true);
      }
    },
    skip: unavailable,
  );
}
