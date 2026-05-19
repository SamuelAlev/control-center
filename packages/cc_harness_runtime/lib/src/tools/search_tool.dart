import 'dart:io';
import 'dart:isolate';

import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/src/tools/workspace_paths.dart';
import 'package:path/path.dart' as p;

/// Plain-data parameters shipped into the scan isolate (a `RegExp` is not
/// sendable, so the pattern crosses as its source string).
class _ScanRequest {
  const _ScanRequest({
    required this.base,
    required this.workspaceRoot,
    required this.sharedRoots,
    required this.pattern,
    required this.glob,
    required this.maxResults,
  });

  final String base;
  final String workspaceRoot;
  final List<String> sharedRoots;
  final String pattern;
  final String glob;
  final int maxResults;
}

/// Plain-data scan outcome returned from the worker isolate.
class _ScanResult {
  const _ScanResult(
    this.results,
    this.truncated,
    this.totalMatches,
    this.listError,
  );

  final List<String> results;
  final bool truncated;
  final int totalMatches;
  final String? listError;
}

/// Searches file contents with a regular expression and returns matching lines
/// with their file path and line number.
class SearchTool extends HarnessTool {
  /// Creates a [SearchTool].
  SearchTool({this.maxResults = 200});

  /// Cap on the number of match lines returned (the tail is summarized).
  final int maxResults;

  /// Files larger than this are skipped (bytes) — reading them whole would blow
  /// memory and stall the event loop for no useful text match.
  static const int _maxFileBytes = 2 * 1024 * 1024;

  @override
  String get name => 'search';

  @override
  String get description =>
      'Search file contents using a regular expression. Returns matching '
      'lines with file path and line number.';

  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'pattern': {
        'type': 'string',
        'description': 'Regular expression to search for.',
      },
      'path': {
        'type': 'string',
        'description': 'Directory to search in (default: workspace root).',
      },
      'glob': {
        'type': 'string',
        'description': "File-name glob filter (e.g. '*.dart').",
        'default': '*',
      },
    },
    'required': ['pattern'],
  };

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    final pattern = args['pattern'];
    if (pattern is! String || pattern.isEmpty) {
      return HarnessToolResult.error('Missing or invalid argument: pattern');
    }
    try {
      // Validate here so a bad pattern is a clean tool error rather than an
      // isolate crash; the worker recompiles it (a RegExp is not sendable).
      RegExp(pattern);
    } on FormatException catch (e) {
      return HarnessToolResult.error('Invalid regex: ${e.message}');
    }

    final rawPath = args['path'] as String? ?? '.';
    final base = resolveInsideWorkspace(
      context.workingDirectory,
      rawPath,
      sharedRoots: context.sharedRoots,
    );
    if (base == null) {
      return HarnessToolResult.error(
        outsideWorkspaceMessage(
          'search',
          rawPath,
          workspaceRoot: context.workingDirectory,
          sharedRoots: context.sharedRoots,
        ),
      );
    }
    final dir = Directory(base);
    if (!dir.existsSync()) {
      return HarnessToolResult.error('Directory not found: $rawPath');
    }
    final globPattern = args['glob'] as String? ?? '*';

    // The walk (a full recursive `listSync`), every `readAsStringSync` and
    // every per-line regex run happen off the caller's isolate. This tool is
    // embedded in cc_server: on a monorepo workspace the whole scan is seconds
    // of BLOCKED event loop, which stalls every concurrent RPC.
    final request = _ScanRequest(
      base: base,
      workspaceRoot: context.workingDirectory,
      sharedRoots: context.sharedRoots.toList(growable: false),
      pattern: pattern,
      glob: globPattern,
      maxResults: maxResults,
    );
    final _ScanResult outcome;
    try {
      outcome = await Isolate.run(() => _scan(request));
    } on Object catch (e) {
      return HarnessToolResult.error('Search failed: $e');
    }
    if (outcome.listError != null) {
      return HarnessToolResult.error(
        'Failed to list $rawPath: ${outcome.listError}',
      );
    }

    if (outcome.results.isEmpty) {
      return HarnessToolResult.success('No matches for /$pattern/.');
    }
    final buffer = StringBuffer(outcome.results.join('\n'));
    if (outcome.truncated) {
      buffer.write(
        '\n\n(${outcome.totalMatches} total matches; '
        'showing first $maxResults)',
      );
    }
    return HarnessToolResult.success(buffer.toString());
  }

  /// The whole walk + read + match, run inside a worker isolate.
  static _ScanResult _scan(_ScanRequest req) {
    final regex = RegExp(req.pattern);
    final globRegex = _globToRegExp(req.glob);
    final results = <String>[];
    var truncated = false;
    var totalMatches = 0;

    // Symlinks are not followed during the walk (so a link inside a worktree
    // can't escape the workspace); the one exception is direct-child links of
    // the base that resolve inside the workspace — the overlay's
    // `repos → ../../repos` — which listWorkspaceTree expands. Listing is
    // resilient: an unreadable subdirectory is skipped, not fatal.
    final List<FileSystemEntity> entities;
    try {
      entities = listWorkspaceTree(
        req.base,
        workspaceRoot: req.workspaceRoot,
        sharedRoots: req.sharedRoots,
      );
    } on FileSystemException catch (e) {
      return _ScanResult(const [], false, 0, e.message);
    }
    for (final entity in entities) {
      if (entity is! File) {
        continue;
      }
      final rel = p.relative(entity.path, from: req.workspaceRoot);
      if (_isIgnored(rel)) {
        continue;
      }
      if (!globRegex.hasMatch(p.basename(entity.path))) {
        continue;
      }
      String content;
      try {
        // Skip very large files: reading them whole would blow memory and the
        // event loop and they are almost never useful text matches.
        if (entity.lengthSync() > _maxFileBytes) {
          continue;
        }
        content = entity.readAsStringSync();
      } on Object {
        continue; // skip binary / unreadable
      }
      final lines = content.split('\n');
      for (var i = 0; i < lines.length; i++) {
        if (regex.hasMatch(lines[i])) {
          totalMatches++;
          if (results.length < req.maxResults) {
            results.add('$rel:${i + 1}: ${lines[i].trim()}');
          } else {
            truncated = true;
          }
        }
      }
    }
    return _ScanResult(results, truncated, totalMatches, null);
  }

  static bool _isIgnored(String relativePath) {
    const ignored = {'.git', 'node_modules', '.dart_tool', 'build', '.fvm'};
    final segments = p.split(relativePath);
    return segments.any(ignored.contains);
  }

  static RegExp _globToRegExp(String glob) {
    final buffer = StringBuffer('^');
    for (final char in glob.split('')) {
      switch (char) {
        case '*':
          buffer.write('.*');
        case '?':
          buffer.write('.');
        case '.':
        case '(':
        case ')':
        case '[':
        case ']':
        case '{':
        case '}':
        case r'$':
        case '^':
        case '+':
        case '|':
        case r'\':
          buffer.write(
            r'\'
            '$char',
          );
        default:
          buffer.write(char);
      }
    }
    buffer.write(r'$');
    return RegExp(buffer.toString());
  }
}
