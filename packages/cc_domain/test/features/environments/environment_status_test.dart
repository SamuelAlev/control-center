import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:test/test.dart';

void main() {
  group('EnvironmentStatus.canBecome', () {
    test('a teardown under way ends failed or gone, never back up', () {
      const from = EnvironmentStatus.destroying;
      expect(from.canBecome(EnvironmentStatus.gone), isTrue);
      expect(from.canBecome(EnvironmentStatus.failed), isTrue);
      for (final next in [
        EnvironmentStatus.ready,
        EnvironmentStatus.degraded,
        EnvironmentStatus.starting,
        EnvironmentStatus.stopped,
      ]) {
        expect(from.canBecome(next), isFalse, reason: next.wire);
      }
    });

    test('nothing comes up from a stop without starting first', () {
      for (final from in [
        EnvironmentStatus.stopping,
        EnvironmentStatus.stopped,
        EnvironmentStatus.gone,
      ]) {
        expect(from.canBecome(EnvironmentStatus.ready), isFalse);
        expect(from.canBecome(EnvironmentStatus.degraded), isFalse);
        expect(from.canBecome(EnvironmentStatus.destroying), isTrue);
      }
      expect(
        EnvironmentStatus.stopped.canBecome(EnvironmentStatus.starting),
        isTrue,
      );
    });

    test('a failed environment may recover on its own', () {
      expect(
        EnvironmentStatus.failed.canBecome(EnvironmentStatus.ready),
        isTrue,
      );
    });

    test('staying put is always allowed', () {
      for (final status in EnvironmentStatus.values) {
        expect(status.canBecome(status), isTrue);
      }
    });
  });

  group('EnvironmentComponentPhase', () {
    test('every phase round-trips, an unknown one reads as null', () {
      for (final phase in EnvironmentComponentPhase.values) {
        expect(EnvironmentComponentPhase.tryParse(phase.wire), phase);
      }
      expect(EnvironmentComponentPhase.tryParse('quantum'), isNull);
    });

    test('live, up, failed and down are decided here', () {
      expect(EnvironmentComponentPhase.values.where((p) => p.isLive).toSet(), {
        EnvironmentComponentPhase.starting,
        EnvironmentComponentPhase.running,
        EnvironmentComponentPhase.ready,
      });
      expect(
        EnvironmentComponentPhase.values.where((p) => p.isFailed).toSet(),
        {EnvironmentComponentPhase.failed, EnvironmentComponentPhase.crashed},
      );
      expect(EnvironmentComponentPhase.waiting.isUp, isFalse);
      expect(EnvironmentComponentPhase.closed.isDown, isTrue);
    });
  });
}
