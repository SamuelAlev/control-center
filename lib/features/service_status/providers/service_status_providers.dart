import 'dart:async';

import 'package:cc_domain/features/service_status/domain/entities/github_service_status.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
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
    final statuses? when select(statuses) != null =>
      AsyncData(select(statuses)!),
    _ => const AsyncLoading(),
  },
};
