import 'dart:io';

import 'package:cc_infra/src/process/process_control_service.dart';
import 'package:test/test.dart';

/// Exercises [ProcessControlService] — the OS process-control port. Proves
/// `isPidAlive` returns true for a live child and false for an unused pid, and
/// that `kill` terminates a spawned child (the two halves of the kill/liveness
/// contract). A long-lived `sleep` child provides a safe target pid.
void main() {
  const service = ProcessControlService();

  group('ProcessControlService.isPidAlive', () {
    test('reports a live child process as alive', () async {
      final proc = await Process.start('sleep', ['10']);
      addTearDown(proc.kill);
      // Give the OS a beat to assign the pid.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(service.isPidAlive(proc.pid), isTrue);
      proc.kill();
      // Reap.
      await proc.exitCode;
    });

    test('reports an unused pid as not alive', () {
      // An almost-certainly-unused pid.
      expect(service.isPidAlive(999999), isFalse);
    });
  });

  group('ProcessControlService.kill', () {
    test('terminates a spawned child process', () async {
      final proc = await Process.start('sleep', ['30']);
      final pid = proc.pid;
      // Confirm it's alive, then kill via the service.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(service.isPidAlive(pid), isTrue);

      await service.kill(pid);
      // The exit code resolves once the process is gone.
      await proc.exitCode;
      expect(service.isPidAlive(pid), isFalse);
    });

    test('kill on an already-dead pid does not throw', () async {
      final proc = await Process.start('true', <String>[]);
      await proc.exitCode;
      expect(() => service.kill(proc.pid), returnsNormally);
    });
  });
}
