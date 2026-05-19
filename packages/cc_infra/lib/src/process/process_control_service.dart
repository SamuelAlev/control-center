import 'dart:io';

import 'package:cc_domain/core/domain/ports/process_control_port.dart';

/// Provides OS-level process control (kill, liveness check) for agent processes.
class ProcessControlService implements ProcessControlPort {
  /// Creates a const [ProcessControlService].
  const ProcessControlService();

  @override
  Future<void> kill(int pid) async {
    try {
      Process.killPid(pid);
    } catch (_) {}
  }

  @override
  bool isPidAlive(int pid) {
    try {
      final result = Process.runSync('kill', ['-0', '$pid']);
      return result.exitCode == 0;
    } on ProcessException {
      return false;
    } on Object {
      return false;
    }
  }
}
