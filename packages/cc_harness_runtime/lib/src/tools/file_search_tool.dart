import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/src/tools/workspace_file_search.dart';

/// Fuzzy filename search over the whole agent workspace.
///
/// Complements the built-in `find` (glob) and `search` (regex-over-contents)
/// tools: this ranks files by fuzzy name relevance ("find the file I half
/// remember"), skipping VCS/build dirs. Read-only. The actual search engine is
/// injected through the kernel's [FileSearchPort] (Control Center wires its
/// cc_natives implementation: Rust `fff` with a pure-Dart fallback).
///
/// Searches the cwd AND every shared root (the conversation's `repos/`
/// worktrees), because the production engine does not descend the overlay's
/// `repos` symlink — see [searchWorkspaceFiles].
class FileSearchTool extends HarnessTool {
  /// Creates a [FileSearchTool] over [fileSearch].
  FileSearchTool({required FileSearchPort fileSearch, this.maxResults = 25})
    : _fileSearch = fileSearch;

  final FileSearchPort _fileSearch;

  /// Cap on the number of results returned.
  final int maxResults;

  @override
  String get name => 'search_files';

  @override
  String get description =>
      'Fuzzy-search for files by name and return the best matches, ranked by '
      'relevance. Use this to locate a file when you only remember part of its '
      'name; use `find` for exact glob patterns and `search` for file contents.';

  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'query': {
        'type': 'string',
        'description': 'Partial or fuzzy file name to search for.',
      },
      'limit': {
        'type': 'integer',
        'description': 'Maximum number of results (default 25).',
      },
    },
    'required': ['query'],
  };

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    final query = args['query'];
    if (query is! String || query.isEmpty) {
      return HarnessToolResult.error('Missing or invalid argument: query');
    }
    final limit = (args['limit'] as num?)?.toInt() ?? maxResults;
    try {
      final results = await searchWorkspaceFiles(
        _fileSearch,
        query,
        workspaceRoot: context.workingDirectory,
        sharedRoots: context.sharedRoots,
        limit: limit,
      );
      if (results.isEmpty) {
        return HarnessToolResult.success('No files match "$query".');
      }
      final lines = [
        for (final hit in results) hit.isDirectory ? '${hit.path}/' : hit.path,
      ];
      return HarnessToolResult.success(lines.join('\n'));
    } on Object catch (e) {
      return HarnessToolResult.error('File search failed: $e');
    }
  }
}
