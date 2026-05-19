import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Identifies one lazily-listed directory: the repo it lives in, its
/// repo-relative path ('' = the repo root) and the conversation whose isolated
/// CoW worktree is being listed (null → the shared linked checkout).
typedef RepoDirectoryListingArgs = ({
  String workspaceId,
  String repoId,
  String path,
  String? spaceId,
});

/// One child entry of a listed directory (repo-relative path).
typedef RepoDirectoryEntry = ({String relativePath, bool isDirectory});

/// The accumulated state of one directory's listing: every entry fetched so
/// far (across cursor pages), whether another page may follow, whether a page
/// fetch is in flight, and whether the last page fetch failed (stops the
/// auto-drain loop; the retry affordance clears it).
///
/// `entries` is in DISPLAY order (directories first, then files, each
/// case-insensitive by path) — sorted once per appended page by
/// [RepoDirectoryListingNotifier] rather than on every rebuild by the tree.
/// The wire order the cursor pages through is plain path order and the
/// notifier tracks it separately; the two must not be confused, or paging
/// would resume from whatever entry happened to sort last.
typedef RepoDirectoryListingState = ({
  List<RepoDirectoryEntry> entries,
  bool hasMore,
  bool loadingMore,
  bool failed,
});

/// Page size for directory listings. Matches the server's default; kept
/// explicit so client and wire agree on the cursor step.
const int kRepoDirectoryPageSize = 500;

/// Calls the server's `repos.listDirectory` op and decodes one cursor page.
///
/// The single client-side decode site for that op — the Explorer tree is the
/// only consumer. When the connected server doesn't expose the op (it predates
/// lazy listings), resolves to an empty terminal page rather than throwing, so
/// a stale server degrades to an empty tree instead of an error panel.
Future<({List<RepoDirectoryEntry> entries, bool hasMore})>
fetchRepoDirectoryListing(
  RemoteRpcClient client, {
  required String workspaceId,
  required String repoId,
  String path = '',
  String cursor = '',
  int limit = kRepoDirectoryPageSize,
  String? spaceId,
}) async {
  try {
    final data = await client.call('repos.listDirectory', {
      'workspace_id': workspaceId,
      'repo_id': repoId,
      'path': path,
      'cursor': cursor,
      'limit': limit,
      'space_id': ?spaceId,
    });
    final entries = <RepoDirectoryEntry>[
      for (final e in ((data['entries'] as List?) ?? const []).whereType<Map>())
        (
          relativePath: e['relativePath'] as String? ?? '',
          isDirectory: e['isDirectory'] as bool? ?? false,
        ),
    ];
    return (entries: entries, hasMore: data['has_more'] as bool? ?? false);
  } on RemoteRpcException catch (e) {
    if (e.code == RpcErrorCodes.opUnknown) {
      return (entries: const <RepoDirectoryEntry>[], hasMore: false);
    }
    rethrow;
  }
}

/// Accumulates one directory's cursor pages into a complete listing.
///
/// The tree never asks for a whole repo at once (that single response was the
/// unbounded frame that killed the WS transport); instead each expanded
/// directory starts at page 0 and auto-drains — the panel calls [loadMore]
/// whenever `hasMore` is set — until `hasMore` is false. Failure of a later
/// page keeps the entries already fetched and raises `failed`, which pauses
/// the drain until the user retries.
class RepoDirectoryListingNotifier
    extends AsyncNotifier<RepoDirectoryListingState> {
  /// Creates a [RepoDirectoryListingNotifier] for one directory.
  RepoDirectoryListingNotifier(this.args);

  /// The directory this notifier lists.
  final RepoDirectoryListingArgs args;

  /// Where the next cursor page resumes: the last entry of the last page in
  /// the SERVER's path order. Kept out of the state because the state's
  /// `entries` are re-ordered for display, and `entries.last` there names an
  /// arbitrary file — paging from it would skip most of the directory.
  String _cursor = '';

  @override
  Future<RepoDirectoryListingState> build() async {
    _holdBriefly(ref);
    final page = await fetchRepoDirectoryListing(
      ref.read(rpcClientProvider),
      workspaceId: args.workspaceId,
      repoId: args.repoId,
      path: args.path,
      spaceId: args.spaceId,
    );
    _cursor = page.entries.isEmpty ? '' : page.entries.last.relativePath;
    return (
      entries: _displayOrder(page.entries),
      hasMore: page.hasMore,
      loadingMore: false,
      failed: false,
    );
  }

  /// Fetches the next cursor page and appends it. No-op when there is no more
  /// to load or a fetch is already in flight; a failure keeps the accumulated
  /// entries and raises `failed` (cleared by the next successful call).
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) {
      return;
    }
    // Set synchronously (before any await) so a rebuild triggered by this
    // write cannot schedule a second concurrent loadMore.
    state = AsyncData((
      entries: current.entries,
      hasMore: current.hasMore,
      loadingMore: true,
      failed: false,
    ));
    try {
      final page = await fetchRepoDirectoryListing(
        ref.read(rpcClientProvider),
        workspaceId: args.workspaceId,
        repoId: args.repoId,
        path: args.path,
        cursor: _cursor,
        spaceId: args.spaceId,
      );
      if (page.entries.isNotEmpty) {
        _cursor = page.entries.last.relativePath;
      }
      state = AsyncData((
        entries: _displayOrder([...current.entries, ...page.entries]),
        hasMore: page.hasMore,
        loadingMore: false,
        failed: false,
      ));
    } on Object {
      // Keep what we have; `failed` stops the auto-drain from spinning on a
      // persistent error and shows the retry affordance.
      state = AsyncData((
        entries: current.entries,
        hasMore: true,
        loadingMore: false,
        failed: true,
      ));
    }
  }
}

/// Orders one directory's accumulated entries for display: directories first,
/// then files, each case-insensitive by path.
///
/// Done ONCE per appended page, here, rather than by the tree on every
/// rebuild. The panel walks every expanded directory on each build, so a sort
/// there re-lowercased every path of every open folder for a keystroke in the
/// filter field, a hover-driven parent rebuild or an arriving page — work
/// whose answer cannot have changed, because a listing is immutable once
/// fetched. Decorated (sort key computed once per entry) so the comparator
/// allocates nothing.
List<RepoDirectoryEntry> _displayOrder(List<RepoDirectoryEntry> entries) {
  final keyed =
      [for (final e in entries) (entry: e, key: e.relativePath.toLowerCase())]
        ..sort((a, b) {
          if (a.entry.isDirectory != b.entry.isDirectory) {
            return a.entry.isDirectory ? -1 : 1;
          }
          return a.key.compareTo(b.key);
        });
  return [for (final k in keyed) k.entry];
}

/// Holds a fetched listing for [_listingTtl] after its last listener drops.
///
/// The IDE sidebar swaps panels with a `switch`, so glancing at Source Control
/// unmounts the Explorer and — under plain `autoDispose` — threw away every
/// directory the operator had open, re-listing all of them (each one a `git
/// check-ignore` process on the server) on the way back. Bounded by TIME, like
/// the PR reader's file cache: the point is that a tab switch is free, not
/// that the client keeps a filesystem. The panel revalidates what it shows on
/// mount, so a held listing is a paint shortcut, never the final word.
void _holdBriefly(Ref ref) {
  final link = ref.keepAlive();
  final timer = Timer(_listingTtl, link.close);
  ref.onDispose(timer.cancel);
}

const _listingTtl = Duration(minutes: 5);

/// One directory's listing, held briefly past its last listener (see
/// [_holdBriefly]) and dropped after that.
final repoDirectoryListingProvider = AsyncNotifierProvider.family
    .autoDispose<
      RepoDirectoryListingNotifier,
      RepoDirectoryListingState,
      RepoDirectoryListingArgs
    >(RepoDirectoryListingNotifier.new);
