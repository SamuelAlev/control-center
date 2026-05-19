import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One matching line within a file: its 1-based `line` number and raw `text`
/// (already truncated server-side; the view computes highlight ranges).
typedef ContentMatchLine = ({int line, String text});

/// A file with one or more content matches, grouped for the Explorer's
/// "Content" results (a collapsible header + its matching lines).
typedef FileContentMatch = ({
  String repoId,
  String relativePath,
  List<ContentMatchLine> lines,
});

/// Identifies a content-search request: the workspace, the query, the search
/// options and the conversation whose isolated CoW worktrees are grepped
/// (null → the shared linked checkouts).
typedef RepoContentSearchArgs = ({
  String workspaceId,
  String query,
  ContentSearchOptions options,
  String? spaceId,
});

/// Toggleable content-search options, mirroring VS Code's search controls.
/// Defaults reproduce the legacy case-insensitive literal behaviour.
class ContentSearchOptions {
  /// Creates [ContentSearchOptions] with the legacy defaults.
  const ContentSearchOptions({
    this.caseSensitive = false,
    this.regex = false,
    this.wholeWord = false,
    this.include = '',
    this.exclude = '',
  });

  /// Case-sensitive matching.
  final bool caseSensitive;

  /// Treat the query as a regex.
  final bool regex;

  /// Whole-word matching.
  final bool wholeWord;

  /// Comma/space-separated include pathspec glob(s).
  final String include;

  /// Comma/space-separated exclude pathspec glob(s).
  final String exclude;

  /// Wire form for the RPC `options` map.
  Map<String, Object?> toWire() => {
    'case_sensitive': caseSensitive,
    'regex': regex,
    'whole_word': wholeWord,
    if (include.trim().isNotEmpty) 'include': include.trim(),
    if (exclude.trim().isNotEmpty) 'exclude': exclude.trim(),
  };

  /// Returns a copy with the given fields replaced.
  ContentSearchOptions copyWith({
    bool? caseSensitive,
    bool? regex,
    bool? wholeWord,
    String? include,
    String? exclude,
  }) {
    return ContentSearchOptions(
      caseSensitive: caseSensitive ?? this.caseSensitive,
      regex: regex ?? this.regex,
      wholeWord: wholeWord ?? this.wholeWord,
      include: include ?? this.include,
      exclude: exclude ?? this.exclude,
    );
  }
}

/// Server-side literal content search across a workspace's linked repo roots
/// (the Explorer's "Content" mode), via the `repos.searchContent` op which runs
/// `git grep` on the SERVER's checkouts. Results are grouped per file. An empty
/// query yields nothing; a server without the op resolves to an empty list.
final repoContentSearchProvider = FutureProvider.autoDispose
    .family<List<FileContentMatch>, RepoContentSearchArgs>((ref, args) async {
      final query = args.query.trim();
      if (query.isEmpty) {
        return const [];
      }
      try {
        final data = await ref
            .watch(rpcClientProvider)
            .call('repos.searchContent', {
              'workspace_id': args.workspaceId,
              'query': query,
              'space_id': ?args.spaceId,
              if (args.options != const ContentSearchOptions())
                'options': args.options.toWire(),
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
