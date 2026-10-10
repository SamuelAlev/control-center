import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/service_status/domain/entities/github_service_status.dart';
import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_harness/provider.dart' show HarnessProviderInfo;
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/settings/providers/harness_providers_providers.dart';
import 'package:control_center/features/subscriptions/providers/subscription_usage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One snapshot of every polled external status page (githubstatus.com,
/// status.claude.com, status.openai.com, status.moonshot.cn), fetched in a
/// single `serviceStatus.getAll` RPC. A null entry means the host could not
/// return that page's summary — its fetch failed server-side, or the host
/// wired no fetcher for it.
class ServiceStatuses {
  /// Creates a snapshot; a null field is a page the host could not return.
  const ServiceStatuses({this.github, this.claude, this.openai, this.kimi});

  /// githubstatus.com summary.
  final GitHubServiceStatus? github;

  /// status.claude.com summary.
  final GitHubServiceStatus? claude;

  /// status.openai.com summary.
  final GitHubServiceStatus? openai;

  /// status.moonshot.cn (Kimi) summary.
  final GitHubServiceStatus? kimi;

  @override
  bool operator ==(Object other) =>
      other is ServiceStatuses &&
      other.github == github &&
      other.claude == claude &&
      other.openai == openai &&
      other.kimi == kimi;

  @override
  int get hashCode => Object.hash(github, claude, openai, kimi);
}

/// Surfaced by a slice provider when the host returned no summary for its
/// page, so the per-provider blocks render their fetch-failed state (word +
/// status-page link) exactly as they did when a per-provider op itself
/// errored. The message is never user-facing — the UI uses its own labels.
class ServiceStatusFetchFailed implements Exception {
  /// Creates a [ServiceStatusFetchFailed] naming the failing [provider].
  const ServiceStatusFetchFailed(this.provider);

  /// Which status page could not be fetched (e.g. `github`).
  final String provider;

  @override
  String toString() => 'Service status fetch failed for $provider';
}

const Duration _refreshInterval = Duration(minutes: 2);

/// Polls every external status page in ONE `serviceStatus.getAll` RPC and
/// refreshes it on a timer.
///
/// One poller, one request per tick. The four pages used to be four separate
/// providers each polling their own op every two minutes — four RPCs per
/// tick, each holding its own session concurrency slot for the duration of a
/// host-side fetch.
///
/// Fetched SERVER-SIDE: the host fetches the status pages (the browser can't
/// reach them cross-origin) and relays the raw `summary.json` maps, which the
/// slices parse with the shared web-safe `GitHubServiceStatus.fromSummaryJson`.
final serviceStatusProvider =
    AsyncNotifierProvider<ServiceStatusesNotifier, ServiceStatuses>(
      ServiceStatusesNotifier.new,
    );

/// Notifier behind [serviceStatusProvider]: fetches the combined snapshot and
/// refreshes it on a timer.
class ServiceStatusesNotifier extends AsyncNotifier<ServiceStatuses> {
  Timer? _timer;

  @override
  Future<ServiceStatuses> build() async {
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });
    _timer ??= Timer.periodic(_refreshInterval, (_) => _refreshSilent());
    return _fetch();
  }

  Future<ServiceStatuses> _fetch() async {
    final data = await ref
        .read(rpcClientProvider)
        .call('serviceStatus.getAll', const {});
    GitHubServiceStatus? parse(String key) {
      final summary = data[key];
      return summary is Map
          ? GitHubServiceStatus.fromSummaryJson(summary.cast<String, dynamic>())
          : null;
    }

    return ServiceStatuses(
      github: parse('github'),
      claude: parse('claude'),
      openai: parse('openai'),
      kimi: parse('kimi'),
    );
  }

  /// Force-refresh from the UI (e.g. when the user opens the flyout).
  ///
  /// The loading assignment RETAINS the previous snapshot (Riverpod merges it
  /// into a reload), and the slices forward that retained snapshot — together
  /// those keep the sidebar dot green while a refresh is in flight instead of
  /// flashing the muted "unknown" colour on every flyout open.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  /// Timer-driven background refresh: never blanks the last good snapshot.
  Future<void> _refreshSilent() async {
    final next = await AsyncValue.guard(_fetch);
    if (next.hasValue) {
      state = next;
    }
  }
}

/// The githubstatus.com slice of [serviceStatusProvider]. Kept as a provider
/// so consumers (the degraded banner, the inbox empty state, the flyout)
/// watch one status without knowing about the shared poller.
final githubStatusProvider = Provider<AsyncValue<GitHubServiceStatus>>(
  (ref) => _slice(ref.watch(serviceStatusProvider), 'github', (s) => s.github),
);

/// The status.claude.com slice of [serviceStatusProvider].
final claudeStatusProvider = Provider<AsyncValue<GitHubServiceStatus>>(
  (ref) => _slice(ref.watch(serviceStatusProvider), 'claude', (s) => s.claude),
);

/// The status.openai.com slice of [serviceStatusProvider].
final openaiStatusProvider = Provider<AsyncValue<GitHubServiceStatus>>(
  (ref) => _slice(ref.watch(serviceStatusProvider), 'openai', (s) => s.openai),
);

/// The status.moonshot.cn (Kimi) slice of [serviceStatusProvider].
final kimiStatusProvider = Provider<AsyncValue<GitHubServiceStatus>>(
  (ref) => _slice(ref.watch(serviceStatusProvider), 'kimi', (s) => s.kimi),
);

/// A status page the service status surfaces can show.
enum StatusService {
  /// githubstatus.com.
  github,

  /// status.claude.com.
  claude,

  /// status.openai.com, shown as Codex.
  openai,

  /// status.moonshot.cn, shown as Kimi.
  kimi,
}

/// The services this install actually uses: a connected GitHub account, a
/// signed-in plan (Claude Code, Codex, Kimi Code) or a stored API key. Only
/// these get a row in the flyout and a say in the sidebar badge — an outage
/// at a provider nobody here signed up for is noise.
///
/// Every source reads unresolved as absent, so a service appears once its
/// credential is confirmed rather than flashing in and back out. Both reads
/// ride pollers that are already running (the title-bar usage pill and the
/// settings provider list); this adds no fetches of its own.
///
/// Value-stable: those pollers re-emit on every poll, and a fresh set is
/// never `==` the last one, so the answer is worked out as a record of flags
/// (compared by value) and a new set is handed out only when one flips.
final servicesInUseProvider = Provider<Set<StatusService>>((ref) {
  final inUse = ref.watch(_servicesInUseFlagsProvider);
  return {
    if (inUse.github) StatusService.github,
    if (inUse.claude) StatusService.claude,
    if (inUse.openai) StatusService.openai,
    if (inUse.kimi) StatusService.kimi,
  };
});

/// [servicesInUseProvider]'s answer as flags. A record, so `Provider`'s `==`
/// filter drops a poll that changed nothing.
final _servicesInUseFlagsProvider =
    Provider<({bool github, bool claude, bool openai, bool kimi})>((ref) {
      final forges = ref.watch(connectedForgesProvider);
      final plans = {
        for (final usage
            in ref.watch(subscriptionUsageProvider).value ??
                const <SubscriptionUsage>[])
          if (usage.status != SubscriptionStatus.unconfigured) usage.providerId,
      };
      final keys = {
        for (final provider
            in ref.watch(harnessProvidersProvider).value ??
                const <HarnessProviderInfo>[])
          if (provider.connected) provider.id,
      };
      bool any(Iterable<String> ids) =>
          ids.any((id) => plans.contains(id) || keys.contains(id));
      return (
        github: forges.contains(ForgeHost.github),
        claude: any(const ['claude', 'anthropic']),
        openai: any(const ['codex', 'openai']),
        kimi: any(const ['kimi-code', 'moonshotai']),
      );
    });

/// Maps the combined snapshot onto one provider's [AsyncValue]: loading stays
/// loading, a failed combined fetch fails every slice, and a page the host
/// could not return fails THAT slice only. A loading state that still carries
/// the previous snapshot (Riverpod retains it through `refresh`'s loading
/// assignment) keeps serving that snapshot's page, so `.value` readers — the
/// sidebar's headline dot — never see a null headline mid-refresh; only a page
/// the retained snapshot itself could not return falls back to bare loading.
AsyncValue<GitHubServiceStatus> _slice(
  AsyncValue<ServiceStatuses> all,
  String provider,
  GitHubServiceStatus? Function(ServiceStatuses) select,
) => switch (all) {
  AsyncData(:final value) =>
    select(value) == null
        ? AsyncValue.error(
            ServiceStatusFetchFailed(provider),
            StackTrace.current,
          )
        : AsyncData(select(value)!),
  AsyncError(:final error, :final stackTrace) => AsyncValue.error(
    error,
    stackTrace,
  ),
  _ => switch (all.value) {
    final statuses? when select(statuses) != null => AsyncData(
      select(statuses)!,
    ),
    _ => const AsyncLoading(),
  },
};
