import 'dart:io';

import 'package:control_center/core/domain/ports/process_control_port.dart';

class ProcessControlService implements ProcessControlPort {
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
