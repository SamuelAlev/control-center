import 'package:control_center/core/providers/analytics_providers.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The install-wide usage-analytics switch, or null while the server's
/// config is loading.
///
/// The value lives on the server (`telemetry.usage_analytics`) and applies to
/// every client of it; shared by Settings → Privacy and the onboarding
/// consent so both show the same state.
final usageAnalyticsProvider = NotifierProvider<UsageAnalyticsNotifier, bool?>(
  UsageAnalyticsNotifier.new,
);

/// Notifier for [usageAnalyticsProvider].
class UsageAnalyticsNotifier extends Notifier<bool?> {
  @override
  bool? build() =>
      ref.watch(telemetryConfigProvider).value?.usageAnalyticsEnabled;

  /// Flips the server's switch. Shows the new value at once; the config
  /// watch confirms it, and a refused write restores the server's value.
  Future<void> setEnabled({required bool value}) async {
    final previous = state;
    state = value;
    try {
      await ref
          .read(telemetryConfigRepositoryProvider)
          .setUsageAnalyticsEnabled(enabled: value);
    } on Object {
      state = previous;
      rethrow;
    }
  }
}

/// Whether the signed-in user may change the switch: the install's
/// operator, and never on the public demo (which refuses the write).
final canManageUsageAnalyticsProvider = Provider<bool>(
  (ref) => ref.watch(isServerOwnerProvider) && !ref.watch(isDemoServerProvider),
);
