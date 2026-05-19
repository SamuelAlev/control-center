import 'package:cc_domain/features/ticketing/domain/awake/agent_awake_policy.dart';
import 'package:cc_domain/features/ticketing/domain/awake/agent_awake_service.dart';
import 'package:cc_domain/features/ticketing/domain/awake/sleep_blocker_port.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingBlocker implements SleepBlockerPort {
  int begins = 0;
  int ends = 0;
  bool held = false;

  @override
  Future<void> begin(String reason) async {
    begins++;
    held = true;
  }

  @override
  Future<void> end() async {
    ends++;
    held = false;
  }
}

void main() {
  final now = DateTime.utc(2026, 1, 1, 12);

  group('AgentAwakePolicy', () {
    const policy = AgentAwakePolicy();

    test('keeps awake when an agent is recently working', () {
      expect(
        policy.shouldKeepAwake(
          signals: [AgentAwakeSignal(isWorking: true, lastActivity: now)],
          now: now,
          enabled: true,
        ),
        isTrue,
      );
    });

    test('does not keep awake when disabled', () {
      expect(
        policy.shouldKeepAwake(
          signals: [AgentAwakeSignal(isWorking: true, lastActivity: now)],
          now: now,
          enabled: false,
        ),
        isFalse,
      );
    });

    test('ignores a stale (stuck) working agent past 2h', () {
      expect(
        policy.shouldKeepAwake(
          signals: [
            AgentAwakeSignal(
              isWorking: true,
              lastActivity: now.subtract(const Duration(hours: 3)),
            ),
          ],
          now: now,
          enabled: true,
        ),
        isFalse,
      );
    });

    test('does not keep awake when all agents are idle', () {
      expect(
        policy.shouldKeepAwake(
          signals: [AgentAwakeSignal(isWorking: false, lastActivity: now)],
          now: now,
          enabled: true,
        ),
        isFalse,
      );
    });
  });

  group('AgentAwakeService', () {
    test('acquires the blocker while working and releases when idle', () async {
      var working = true;
      final blocker = _RecordingBlocker();
      final service = AgentAwakeService(
        blocker: blocker,
        readSignals: () => [
          AgentAwakeSignal(isWorking: working, lastActivity: now),
        ],
        isEnabled: () => true,
        now: () => now,
      );

      await service.evaluate();
      expect(blocker.held, isTrue);
      expect(blocker.begins, 1);

      // Idempotent: re-evaluating while still working does not re-acquire.
      await service.evaluate();
      expect(blocker.begins, 1);

      working = false;
      await service.evaluate();
      expect(blocker.held, isFalse);
      expect(blocker.ends, 1);

      await service.dispose();
    });

    test('releases on dispose if still held', () async {
      final blocker = _RecordingBlocker();
      final service = AgentAwakeService(
        blocker: blocker,
        readSignals: () => [
          AgentAwakeSignal(isWorking: true, lastActivity: now),
        ],
        isEnabled: () => true,
        now: () => now,
      );
      await service.evaluate();
      expect(blocker.held, isTrue);
      await service.dispose();
      expect(blocker.held, isFalse);
    });
  });
}
