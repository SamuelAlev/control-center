import 'package:cc_infra/src/dispatch/harness_run_controller.dart';
import 'package:test/test.dart';

void main() {
  group('HarnessRunController', () {
    test('a pause is refused while no harness loop drives the session', () {
      final harness = HarnessRunController();
      expect(harness.isActive, isFalse);
      expect(harness.pause(), isFalse);
      expect(harness.pauseGate.isPaused, isFalse);
    });

    test('a live loop pauses at the gate and resumes on hand-back', () {
      final harness = HarnessRunController()..begin();
      expect(harness.isActive, isTrue);
      expect(harness.pause(), isTrue);
      expect(harness.pauseGate.isPaused, isTrue);
      harness.resume();
      expect(harness.pauseGate.isPaused, isFalse);
    });

    test('ending the loop releases a pause nobody will check again', () {
      final harness = HarnessRunController()..begin();
      harness.pause();
      harness.end();
      expect(harness.isActive, isFalse);
      expect(harness.pauseGate.isPaused, isFalse);
      expect(harness.pause(), isFalse);
    });
  });
}
