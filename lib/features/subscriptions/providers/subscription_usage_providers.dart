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

/// Polls live subscription usage (Claude Code, Codex, Cursor, z.ai, Kimi) and
/// exposes the latest per-provider snapshots for the title-bar usage pill.
///
/// Fetched SERVER-SIDE over the `subscriptions.usage` op: the host reads each
/// CLI's own credentials and the Cursor/z.ai/Kimi credentials from the harness
/// provider credential store (Settings → Adapters → Providers & models), then
/// calls the provider usage endpoints. No credential ever leaves the server.
final subscriptionUsageProvider =
    AsyncNotifierProvider<SubscriptionUsageNotifier, List<SubscriptionUsage>>(
      SubscriptionUsageNotifier.new,
    );

/// Notifier that fetches subscription usage and refreshes it on a timer.
class SubscriptionUsageNotifier extends AsyncNotifier<List<SubscriptionUsage>> {
  Timer? _timer;

  /// The fetch currently running, and whether it skips the server caches.
  Future<void>? _inFlight;
  bool _inFlightForced = false;

  @override
  Future<List<SubscriptionUsage>> build() async {
    // Re-fetch when a plan provider is connected or disconnected under
    // Settings → Adapters, but not on unrelated provider edits. Both z.ai
    // lanes count: the quota is the coding plan's, but an install that
    // connected its plan key under plain `zai` before the lanes were split is
    // still what the server falls back to.
    ref.watch(
      harnessProvidersProvider.select(
        (p) =>
            p.asData?.value.any(
              (i) =>
                  (i.id == 'zai-coding' ||
                      i.id == 'zai' ||
                      i.id == 'kimi-code' ||
                      i.id == 'cursor') &&
                  i.connected,
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

  Future<List<SubscriptionUsage>> _fetch({bool force = false}) =>
      ref.read(subscriptionsRepositoryProvider).fetchUsage(force: force);

  /// Refresh from the UI (e.g. when the user opens the pill). Keeps the last
  /// snapshot on screen while the fetch runs — never blanks the popover with a
  /// value-less loading state. No-op while a fetch is already running.
  ///
  /// [force] is the flyout's refresh button: the server skips its usage
  /// caches instead of answering from a reading up to five minutes old.
  /// Opening the pill does not force — it happens far too often for that.
  Future<void> refresh({bool force = false}) => _run(force: force);

  /// Timer-driven background refresh: never blanks and never spins.
  Future<void> _refreshSilent() => _run();

  /// Runs one fetch with an in-flight guard so concurrent timer + user
  /// refreshes can't double-spawn the Codex process or race to clobber a newer
  /// result. On failure the last good snapshot is retained (the chip stays
  /// populated); a first-load failure (no prior data) surfaces the error.
  ///
  /// A FORCED run that finds an unforced one in flight waits for it and then
  /// goes: dropping it would make the refresh button do nothing whenever it is
  /// clicked right after the flyout opened, which is exactly when it is.
  Future<void> _run({bool force = false}) async {
    final running = _inFlight;
    if (running != null) {
      if (!force || _inFlightForced) {
        return running;
      }
      await running;
      return _run(force: true);
    }
    final run = _fetchInto(force: force);
    _inFlight = run;
    _inFlightForced = force;
    try {
      await run;
    } finally {
      _inFlight = null;
      _inFlightForced = false;
    }
  }

  Future<void> _fetchInto({required bool force}) async {
    final prior = state.value;
    final next = await AsyncValue.guard(() => _fetch(force: force));
    if (next.hasValue) {
      state = next;
    } else if (prior != null) {
      state = AsyncData(prior);
    } else {
      state = next;
    }
  }
}
