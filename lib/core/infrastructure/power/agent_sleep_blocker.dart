import 'package:cc_domain/features/ticketing/domain/awake/sleep_blocker_port.dart';
import 'package:control_center/core/infrastructure/power/background_activity_guard.dart';

/// Adapts the platform [BackgroundActivityGuard] to the domain [SleepBlockerPort]
/// so the `AgentAwakeService` can prevent OS sleep while agents work.
///
/// On macOS this brackets the work in an `NSProcessInfo` activity assertion
/// (the same mechanism meeting recording uses); a no-op elsewhere.
class GuardSleepBlocker implements SleepBlockerPort {
  /// Creates a [GuardSleepBlocker] over [_guard].
  const GuardSleepBlocker(this._guard);

  final BackgroundActivityGuard _guard;

  @override
  Future<void> begin(String reason) => _guard.begin(reason);

  @override
  Future<void> end() => _guard.end();
}
