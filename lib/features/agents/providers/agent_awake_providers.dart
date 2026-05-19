import 'package:cc_domain/features/agents/domain/value_objects/agent_live_state.dart';
import 'package:cc_domain/features/ticketing/domain/awake/agent_awake_policy.dart';
import 'package:cc_domain/features/ticketing/domain/awake/agent_awake_service.dart';
import 'package:cc_domain/features/ticketing/domain/awake/sleep_blocker_port.dart';
import 'package:control_center/core/infrastructure/power/agent_sleep_blocker.dart';
import 'package:control_center/core/infrastructure/power/background_activity_guard.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/agents/providers/fleet_state_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _keepAwakeKey = 'keep_computer_awake_while_agents_run';

/// Whether to keep the computer awake while any agent is working. Defaults to
/// true; backed by [AppPreferences] (non-sensitive preference).
final keepComputerAwakeProvider =
    NotifierProvider<KeepComputerAwakeNotifier, bool>(
      KeepComputerAwakeNotifier.new,
    );

/// Notifier for [keepComputerAwakeProvider].
class KeepComputerAwakeNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(appPreferencesProvider).getBool(_keepAwakeKey) ?? true;

  /// Persists the preference and updates the live value.
  Future<void> setEnabled({required bool value}) async {
    await ref.read(appPreferencesProvider).setBool(_keepAwakeKey, value: value);
    state = value;
  }
}

/// The platform sleep blocker: a macOS `NSProcessInfo` assertion (shared with
/// the meeting-recording guard), a no-op on web and other platforms.
final sleepBlockerProvider = Provider<SleepBlockerPort>((ref) {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS) {
    return const NoopSleepBlocker();
  }
  return GuardSleepBlocker(ref.watch(backgroundActivityGuardProvider));
});

/// Keeps the OS awake while any agent in the active workspace is working.
///
/// Driven by the `keepComputerAwakeWhileAgentsRun` setting; observes the
/// workspace fleet (running agents + their last activity) and re-evaluates on
/// every fleet/setting change plus a periodic tick (so a stuck run releases the
/// machine after the staleness window). Keep it alive by watching it once at
/// app start.
final agentAwakeServiceProvider = Provider<AgentAwakeService>((ref) {
  final service = AgentAwakeService(
    blocker: ref.watch(sleepBlockerProvider),
    readSignals: () {
      final now = DateTime.now();
      return ref.read(agentFleetProvider).map((f) {
        return AgentAwakeSignal(
          isWorking: f.state == AgentLiveState.running,
          lastActivity: f.lastActive ?? now,
        );
      }).toList();
    },
    isEnabled: () => ref.read(keepComputerAwakeProvider),
  )..start();

  ref.listen(agentFleetProvider, (_, _) => service.evaluate());
  ref.listen(keepComputerAwakeProvider, (_, _) => service.evaluate());
  ref.onDispose(service.dispose);
  return service;
});
