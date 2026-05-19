import 'package:cc_domain/cc_domain.dart' show FileSearchHit, RpcErrorCodes;
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Identifies a fuzzy file-search request: the workspace, the query, and the
/// conversation whose isolated CoW worktrees are searched (null → the shared
/// linked checkouts).
typedef RepoFileSearchArgs = ({
  String workspaceId,
  String query,
  String? spaceId,
});

/// One file hit paired with the linked repo it belongs to.
typedef RepoFileHit = ({FileSearchHit hit, String repoId});

/// The Explorer's flat search state: hits accumulated across pages, whether
/// another page may follow, and whether a page fetch is in flight.
///
/// `hits` is already ranked (score desc, then path) — ordered once per
/// appended page rather than on every rebuild of the list that shows it.
typedef RepoFileSearchState = ({
  List<RepoFileHit> hits,
  bool hasMore,
  bool loadingMore,
});

/// Page size for the Explorer's flat results list. Bounds one response; the
/// user pages through the ranked list by scrolling, so the reachable set is
/// unbounded.
const int kExplorerSearchPageSize = 100;

/// Calls the server's `repos.searchFiles` op and decodes one ranked page.
///
/// The single client-side decode site for that op — every file-search surface
/// (the IDE Explorer's flat list, the composer's `@` file mentions) goes
/// through here, so no client ever searches the filesystem itself. Pages with
/// [offset]/[limit]; `hasMore` reports whether another page may follow. When
/// the connected server doesn't expose the op (it owns no checkouts),
/// resolves to an empty terminal page rather than throwing.
Future<({List<RepoFileHit> hits, bool hasMore})> fetchRepoFileSearchPage(
  RemoteRpcClient client, {
  required String workspaceId,
  required String query,
  int offset = 0,
  int limit = kExplorerSearchPageSize,
  String? spaceId,
}) async {
  try {
    final data = await client.call('repos.searchFiles', {
      'workspace_id': workspaceId,
      'query': query,
      'offset': offset,
      'limit': limit,
      'space_id': ?spaceId,
    });
    final hits = <RepoFileHit>[
      for (final h in ((data['hits'] as List?) ?? const []).whereType<Map>())
        () {
          final w = h.cast<String, dynamic>();
          return (
            hit: FileSearchHit.fromJson(w),
            repoId: w['repoId'] as String? ?? '',
          );
        }(),
    ];
    return (hits: hits, hasMore: data['has_more'] as bool? ?? false);
  } on RemoteRpcException catch (e) {
    if (e.code == RpcErrorCodes.opUnknown) {
      return (hits: const <RepoFileHit>[], hasMore: false);
    }
    rethrow;
  }
}

/// Calls `repos.searchFiles` for one page, for surfaces that query per
/// keystroke rather than per rebuild (the composer's `@` file mentions).
///
/// Resolving the RPC client lazily — inside the returned closure — matters:
/// [rpcClientProvider] throws until the composition root overrides it with the
/// connected client, so a widget must be able to hold this function before the
/// handshake completes.
final repoFileSearchFnProvider =
    Provider<
      Future<List<RepoFileHit>> Function(String, String, {String? spaceId})
    >(
      (ref) =>
          (workspaceId, query, {spaceId}) async =>
              (await fetchRepoFileSearchPage(
                ref.read(rpcClientProvider),
                workspaceId: workspaceId,
                query: query,
                spaceId: spaceId,
              )).hits,
    );

/// Server-side fuzzy file search across a workspace's linked repo roots.
///
/// The desktop is a thin client — fff/the file walk run on the SERVER over the
/// CoW checkouts it owns (works identically on web + desktop) via the
/// `repos.searchFiles` op. The op attaches `repoId` to each hit (matched by
/// `rootPath` → linked repo), so the value is a typed wrapper
/// `({FileSearchHit hit, String repoId})` the IDE Explorer uses to group/open
/// files per-repo. The ranked list is PAGED (offset + limit + `has_more`) —
/// the Explorer's flat results list scrolls through pages with [loadMore];
/// the tree is no longer fed from this op at all (it lazily lists directories
/// via `repoDirectoryListingProvider` instead).
class RepoFileSearchNotifier extends AsyncNotifier<RepoFileSearchState> {
  /// Creates a [RepoFileSearchNotifier] for one query.
  RepoFileSearchNotifier(this.args);

  /// The query this notifier searches for.
  final RepoFileSearchArgs args;

  @override
  Future<RepoFileSearchState> build() async {
    final page = await fetchRepoFileSearchPage(
      ref.read(rpcClientProvider),
      workspaceId: args.workspaceId,
      query: args.query,
      spaceId: args.spaceId,
    );
    return (
      hits: _ranked(page.hits),
      hasMore: page.hasMore,
      loadingMore: false,
    );
  }

  /// Fetches the next ranked page and appends it. No-op when there is no more
  /// to load or a fetch is in flight; a failure keeps the accumulated hits
  /// (the scroll listener retries on the next scroll event).
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) {
      return;
    }
    // Set synchronously (before any await) so a rebuild triggered by this
    // write cannot schedule a second concurrent loadMore.
    state = AsyncData((
      hits: current.hits,
      hasMore: current.hasMore,
      loadingMore: true,
    ));
    try {
      final page = await fetchRepoFileSearchPage(
        ref.read(rpcClientProvider),
        workspaceId: args.workspaceId,
        query: args.query,
        offset: current.hits.length,
        spaceId: args.spaceId,
      );
      state = AsyncData((
        hits: _ranked([...current.hits, ...page.hits]),
        hasMore: page.hasMore,
        loadingMore: false,
      ));
    } on Object {
      state = AsyncData((
        hits: current.hits,
        hasMore: true,
        loadingMore: false,
      ));
    }
  }
}

/// Orders accumulated hits the way the flat list shows them: best score
/// first, ties broken by path. Done here, once per appended page, because the
/// ranking of a fetched page cannot change — sorting in the list's `build`
/// re-ran it for every keystroke and every parent rebuild instead.
List<RepoFileHit> _ranked(List<RepoFileHit> hits) => [...hits]
  ..sort((a, b) {
    final byScore = b.hit.score.compareTo(a.hit.score);
    if (byScore != 0) {
      return byScore;
    }
    return a.hit.relativePath.compareTo(b.hit.relativePath);
  });

/// The ranked fuzzy results for one query, auto-disposed when the Explorer
/// stops showing them (typing swaps to a new query's instance).
final repoFileSearchProvider = AsyncNotifierProvider.family
    .autoDispose<
      RepoFileSearchNotifier,
      RepoFileSearchState,
      RepoFileSearchArgs
    >(RepoFileSearchNotifier.new);
