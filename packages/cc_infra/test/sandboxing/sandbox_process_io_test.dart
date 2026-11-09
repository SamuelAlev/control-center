import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_infra/src/sandboxing/no_sandbox_adapter.dart';
import 'package:cc_infra/src/sandboxing/sandbox_process_io.dart';
import 'package:test/test.dart';

void main() {
  group('drainForwardings', () {
    test('waits for every line written after the exit', () async {
      final source = StreamController<List<int>>();
      final lines = <String>[];
      final forwarding = ProcessLineForwarding.start(source.stream, lines.add);
      // The child has exited; its last lines are still in the pipe.
      final drained = drainForwardings([forwarding]);
      for (var i = 0; i < 50; i++) {
        source.add(utf8.encode('line $i\n'));
        await Future<void>.delayed(Duration.zero);
      }
      await source.close();
      await drained;
      expect(lines, hasLength(50));
      expect(lines.last, 'line 49');
    });

    test('a pipe a descendant keeps open cannot park the exec', () async {
      final source = StreamController<List<int>>();
      addTearDown(source.close);
      final lines = <String>[];
      final forwarding = ProcessLineForwarding.start(source.stream, lines.add);
      source.add(utf8.encode('before\n'));
      final watch = Stopwatch()..start();
      await drainForwardings([
        forwarding,
      ], grace: const Duration(milliseconds: 100));
      expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
      expect(lines, ['before']);
    });
  });

  test(
    'NoSandboxAdapter.exec delivers every stdout line before it returns',
    () async {
      final adapter = NoSandboxAdapter();
      final dir = await Directory.systemTemp.createTemp('cc-exec-drain-');
      addTearDown(() => dir.delete(recursive: true));
      final handle = await adapter.launch(
        SandboxSpec(
          sessionId: 's1',
          workspaceId: 'ws',
          bindMounts: [
            SandboxBindMount(hostPath: dir.path, guestPath: dir.path),
          ],
        ),
      );
      expect(handle.backend, SandboxBackend.none);
      final lines = <String>[];
      final sub = adapter.events(handle).listen((e) {
        if (e.type == SandboxEventType.stdout) {
          lines.add(e.content);
        }
      });
      addTearDown(sub.cancel);
      final code = await adapter.exec(handle, [
        '/bin/sh',
        '-c',
        'i=0; while [ \$i -lt 200 ]; do echo l\$i; i=\$((i+1)); done',
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(code, 0);
      expect(lines, hasLength(200));
      await adapter.destroy(handle);
    },
    testOn: '!windows',
  );
}
