import 'dart:io';

import 'package:control_center/features/agents/data/services/process_control_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProcessControlService', () {
    const service = ProcessControlService();

    test('isPidAlive returns true for current process', () {
      final currentPid = pid;
      expect(service.isPidAlive(currentPid), isTrue);
    });

    test('isPidAlive returns false for out-of-range PID', () {
      // PID 99999 is extremely unlikely to exist on any system
      expect(service.isPidAlive(99999), isFalse);
    });

    test('isPidAlive handles edge PID values without throwing', () {
      // Should not crash for PID 0 or other edge values
      expect(service.isPidAlive(0), anyOf(isTrue, isFalse));
    });

    test('kill does not throw for invalid PID', () async {
      await service.kill(99999);
      // No exception thrown
    });

    test('const constructor creates instance', () {
      expect(service, isA<ProcessControlService>());
    });
  });
}
