import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/messaging/providers/repo_content_search_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Ephemeral UI state of the sidebar "search in files" panel, kept per space
/// so the typed query, option toggles, glob filters and whole-repo expansion
/// survive the panel unmounting — the sidebar swaps between tree and search
/// on every toggle (`t` / ⌘F / Esc), which would otherwise wipe the query
/// each time. Client UI memory only; never persisted.
typedef WorktreeSearchUiState = ({
  String text,
  ContentSearchOptions options,
  bool showFilters,
  bool wholeRepo,
});

/// Per-space memento for the search panel; see [WorktreeSearchUiState].
final prWorktreeSearchUiStateProvider =
    StateProvider.family<WorktreeSearchUiState, String>(
      (ref, spaceId) => (
        text: '',
        options: const ContentSearchOptions(),
        showFilters: false,
        wholeRepo: false,
      ),
    );

/// Identifies a content-search request scoped to ONE conversation worktree
/// (the PR-head CoW tree), for the PR workbench sidebar's "search in files"
/// mode.
///
/// `wholeRepo` false (default) greps only `pathsKey` (sorted, newline-joined
/// PR filenames). `wholeRepo` true greps the whole PR-head tree. `pathsKey`
/// is a string so the family key compares by value (a `List` would refetch
/// on every rebuild).
typedef WorktreeContentSearchArgs = ({
  String workspaceId,
  String spaceId,
  String repoId,
  String query,
  ContentSearchOptions options,
  bool wholeRepo,
  String pathsKey,
});

/// Server-side content search across a single PR space's isolated CoW
/// worktree, via the `worktree.searchContent` op (`git grep` on the SERVER's
/// PR-head tree, tracked + untracked so local uncommitted edits match too).
/// Results are grouped per file — reusing the Explorer's [FileContentMatch]
/// wire shape. An empty query yields nothing; a server without the op resolves
/// to an empty list.
///
/// When `wholeRepo` is false, `pathsKey` is sent as the `paths` option so
/// grep cannot leak into files the PR does not touch. An empty `pathsKey`
/// in that mode is an empty PR (no RPC — would otherwise grep the whole
/// tree).
final prWorktreeSearchProvider = FutureProvider.autoDispose
    .family<List<FileContentMatch>, WorktreeContentSearchArgs>((
      ref,
      args,
    ) async {
      final query = args.query.trim();
      if (query.isEmpty) {
        return const [];
      }
      if (!args.wholeRepo && args.pathsKey.isEmpty) {
        return const [];
      }
      try {
        final options = Map<String, Object?>.of(args.options.toWire());
        if (!args.wholeRepo) {
          options['paths'] = args.pathsKey.split('\n');
        }
        final data = await ref
            .watch(rpcClientProvider)
            .call('worktree.searchContent', {
              'workspace_id': args.workspaceId,
              'space_id': args.spaceId,
              'repo_id': args.repoId,
              'query': query,
              'options': options,
            });
        return ((data['hits'] as List?) ?? const []).whereType<Map>().map((h) {
          final m = h.cast<String, dynamic>();
          final lines = ((m['matches'] as List?) ?? const [])
              .whereType<Map>()
              .map((e) {
                final le = e.cast<String, dynamic>();
                return (
                  line: (le['line'] as num?)?.toInt() ?? 0,
                  text: le['text'] as String? ?? '',
                );
              })
              .toList();
          return (
            repoId: m['repoId'] as String? ?? '',
            relativePath: m['relativePath'] as String? ?? '',
            lines: lines,
          );
        }).toList();
      } on RemoteRpcException catch (e) {
        if (e.code == RpcErrorCodes.opUnknown) {
          return const [];
        }
        rethrow;
      }
    });
