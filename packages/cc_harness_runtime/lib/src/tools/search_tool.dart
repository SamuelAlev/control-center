import 'dart:io';

import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/src/tools/workspace_paths.dart';
import 'package:path/path.dart' as p;

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
    final RegExp regex;
    try {
      regex = RegExp(pattern);
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
    final globRegex = _globToRegExp(globPattern);

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
        base,
        workspaceRoot: context.workingDirectory,
        sharedRoots: context.sharedRoots,
      );
    } on FileSystemException catch (e) {
      return HarnessToolResult.error('Failed to list $rawPath: ${e.message}');
    }
    for (final entity in entities) {
      if (entity is! File) {
        continue;
      }
      final rel = p.relative(entity.path, from: context.workingDirectory);
      if (_isIgnored(rel)) {
        continue;
      }
      if (!globRegex.hasMatch(p.basename(entity.path))) {
        continue;
      }
      String content;
      try {
        // Skip very large files: reading them whole would blow memory and the
        // event loop, and they are almost never useful text matches.
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
          if (results.length < maxResults) {
            results.add('$rel:${i + 1}: ${lines[i].trim()}');
          } else {
            truncated = true;
          }
        }
      }
    }

    if (results.isEmpty) {
      return HarnessToolResult.success('No matches for /$pattern/.');
    }
    final buffer = StringBuffer(results.join('\n'));
    if (truncated) {
      buffer.write(
        '\n\n($totalMatches total matches; showing first $maxResults)',
      );
    }
    return HarnessToolResult.success(buffer.toString());
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
