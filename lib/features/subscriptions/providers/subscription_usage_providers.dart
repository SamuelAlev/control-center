import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/settings/providers/harness_providers_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Repository for live subscription-usage reads over RPC.
final subscriptionsRepositoryProvider = Provider<RpcSubscriptionsRepository>(
  (ref) => RpcSubscriptionsRepository(ref.watch(rpcClientProvider)),
);

/// How often the title-bar usage pill refreshes. Subscription windows move
/// slowly (5-hour / weekly) and the provider endpoints rate-limit aggressive
/// polling.
const Duration _refreshInterval = Duration(minutes: 10);

/// Polls live subscription usage (Claude Code, Codex, z.ai) and exposes the
/// latest per-provider snapshots for the title-bar usage pill.
///
/// Fetched SERVER-SIDE over the `subscriptions.usage` op: the host reads each
/// CLI's own credentials and the z.ai key from the harness provider credential
/// store (Settings → Adapters → Providers & models), then calls the provider
/// usage endpoints. No credential ever leaves the server.
final subscriptionUsageProvider =
    AsyncNotifierProvider<SubscriptionUsageNotifier, List<SubscriptionUsage>>(
      SubscriptionUsageNotifier.new,
    );

/// Notifier that fetches subscription usage and refreshes it on a timer.
class SubscriptionUsageNotifier extends AsyncNotifier<List<SubscriptionUsage>> {
  Timer? _timer;
  bool _fetching = false;

  @override
  Future<List<SubscriptionUsage>> build() async {
    // Re-fetch when the z.ai provider connection changes (key saved/removed
    // under Settings → Adapters), but not on unrelated provider edits. Both
    // lanes count: the quota is the coding plan's, but an install that
    // connected its plan key under plain `zai` before the lanes were split is
    // still what the server falls back to.
    ref.watch(
      harnessProvidersProvider.select(
        (p) =>
            p.asData?.value.any(
              (i) => (i.id == 'zai-coding' || i.id == 'zai') && i.connected,
            ) ??
            false,
      ),
    );
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });
    _timer ??= Timer.periodic(_refreshInterval, (_) => _refreshSilent());
    return _fetch();
  }

  Future<List<SubscriptionUsage>> _fetch() =>
      ref.read(subscriptionsRepositoryProvider).fetchUsage();

  /// Force-refresh from the UI (e.g. when the user opens the pill). Keeps the
  /// last snapshot on screen while the fetch runs — never blanks the popover
  /// with a value-less loading state. No-op while a fetch is already running.
  Future<void> refresh() => _run();

  /// Timer-driven background refresh: never blanks and never spins.
  Future<void> _refreshSilent() => _run();

  /// Runs one fetch with an in-flight guard so concurrent timer + user
  /// refreshes can't double-spawn the Codex process or race to clobber a newer
  /// result. On failure the last good snapshot is retained (the chip stays
  /// populated); a first-load failure (no prior data) surfaces the error.
  Future<void> _run() async {
    if (_fetching) {
      return;
    }
    _fetching = true;
    final prior = state.value;
    try {
      final next = await AsyncValue.guard(_fetch);
      if (next.hasValue) {
        state = next;
      } else if (prior != null) {
        state = AsyncData(prior);
      } else {
        state = next;
      }
    } finally {
      _fetching = false;
    }
  }
}
