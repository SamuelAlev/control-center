import 'package:cc_data/cc_data.dart'
    show RemoteSandboxExecGrantRepository, SandboxExecGrantView;
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The client adapter for the server's sandbox exec-grant store.
final sandboxExecGrantRepositoryProvider =
    Provider<RemoteSandboxExecGrantRepository>(
      (ref) => RemoteSandboxExecGrantRepository(ref.watch(rpcClientProvider)),
    );

/// Which grants a [SandboxExecGrantsNotifier] lists: one workspace, filtered
/// to paths containing `query` (blank = all).
typedef SandboxExecGrantsKey = ({String workspaceId, String query});

/// Rows per `sandbox.listExecGrants` page.
const int kSandboxExecGrantsPageSize = 25;

/// The decisions loaded so far for one [SandboxExecGrantsKey].
@immutable
class SandboxExecGrantList {
  /// Creates a [SandboxExecGrantList].
  const SandboxExecGrantList({
    required this.grants,
    required this.total,
    this.loadingMore = false,
    this.loadMoreError,
  });

  /// Rows loaded so far, newest first.
  final List<SandboxExecGrantView> grants;

  /// How many grants match the query on the server.
  final int total;

  /// Whether the next page is being fetched.
  final bool loadingMore;

  /// Why the last next-page fetch failed; the loaded rows stay put.
  final Object? loadMoreError;

  /// Whether the server holds rows not loaded yet.
  bool get hasMore => grants.length < total;
}

/// The recorded decisions in a workspace, paged and searched on the server.
///
/// A server without exec grants (a demo) answers with an empty page rather
/// than an error, so the settings page shows its empty state instead of a
/// failure.
final sandboxExecGrantsProvider = AsyncNotifierProvider.autoDispose
    .family<
      SandboxExecGrantsNotifier,
      SandboxExecGrantList,
      SandboxExecGrantsKey
    >(SandboxExecGrantsNotifier.new);

/// Loads the first page for its key, appends later pages on [loadMore], and
/// drops a revoked row in place instead of refetching every loaded page.
class SandboxExecGrantsNotifier extends AsyncNotifier<SandboxExecGrantList> {
  /// Creates the notifier for [key].
  SandboxExecGrantsNotifier(this.key);

  /// The workspace and query this list answers.
  final SandboxExecGrantsKey key;

  RemoteSandboxExecGrantRepository get _repo =>
      ref.read(sandboxExecGrantRepositoryProvider);

  @override
  Future<SandboxExecGrantList> build() async {
    final page = await ref
        .watch(sandboxExecGrantRepositoryProvider)
        .list(
          key.workspaceId,
          query: key.query,
          limit: kSandboxExecGrantsPageSize,
        );
    return SandboxExecGrantList(grants: page.grants, total: page.total);
  }

  /// Fetches the next page and appends it.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.loadingMore || !current.hasMore) {
      return;
    }
    state = AsyncData(
      SandboxExecGrantList(
        grants: current.grants,
        total: current.total,
        loadingMore: true,
      ),
    );
    try {
      final page = await _repo.list(
        key.workspaceId,
        query: key.query,
        offset: current.grants.length,
        limit: kSandboxExecGrantsPageSize,
      );
      if (!ref.mounted) {
        return;
      }
      // A row revoked elsewhere shifts the offsets by one; dedupe by id so the
      // shift cannot list a row twice.
      final seen = {for (final g in current.grants) g.id};
      state = AsyncData(
        SandboxExecGrantList(
          grants: [
            ...current.grants,
            for (final g in page.grants)
              if (seen.add(g.id)) g,
          ],
          total: page.total,
        ),
      );
    } on Object catch (e) {
      if (!ref.mounted) {
        return;
      }
      state = AsyncData(
        SandboxExecGrantList(
          grants: current.grants,
          total: current.total,
          loadMoreError: e,
        ),
      );
    }
  }

  /// Revokes [id] on the server, then removes it from the loaded rows.
  Future<void> revoke(String id) async {
    await _repo.revoke(key.workspaceId, id);
    if (!ref.mounted) {
      return;
    }
    final current = state.value;
    if (current == null) {
      return;
    }
    final grants = [
      for (final g in current.grants)
        if (g.id != id) g,
    ];
    state = AsyncData(
      SandboxExecGrantList(
        grants: grants,
        total: current.total - (current.grants.length - grants.length),
      ),
    );
  }
}
