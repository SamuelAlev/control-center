import 'dart:io';

import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/src/tools/workspace_paths.dart';
import 'package:path/path.dart' as p;

/// Finds files matching a glob pattern, returned newest-first.
///
/// Supports `*` (any run within a path segment), `**` (any depth), and `?`.
/// Skips VCS / build directories.
class FindTool extends HarnessTool {
  /// Creates a [FindTool].
  FindTool({this.maxResults = 200});

  /// Cap on the number of paths returned.
  final int maxResults;

  @override
  String get name => 'find';

  @override
  String get description =>
      "Find files matching a glob pattern (e.g. '**/*.dart'). Returns paths "
      'sorted by modification time, newest first.';

  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'pattern': {
        'type': 'string',
        'description': "Glob pattern (e.g. '**/*.dart').",
      },
      'path': {
        'type': 'string',
        'description': 'Base directory (default: workspace root).',
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
    final regex = _globToRegExp(pattern);

    final matches = <(String, DateTime)>[];
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
      final rel = p.relative(entity.path, from: base);
      if (_isIgnored(rel)) {
        continue;
      }
      if (regex.hasMatch(rel)) {
        matches.add((rel, entity.statSync().modified));
      }
    }
    if (matches.isEmpty) {
      return HarnessToolResult.success('No files match $pattern.');
    }
    matches.sort((a, b) => b.$2.compareTo(a.$2));
    final shown = matches.take(maxResults).map((m) => m.$1).toList();
    final buffer = StringBuffer(shown.join('\n'));
    if (matches.length > maxResults) {
      buffer.write('\n\n(${matches.length} total; showing first $maxResults)');
    }
    return HarnessToolResult.success(buffer.toString());
  }

  static bool _isIgnored(String relativePath) {
    const ignored = {'.git', 'node_modules', '.dart_tool', 'build', '.fvm'};
    return p.split(relativePath).any(ignored.contains);
  }

  /// Translates a glob to a regex, with `**` matching across path separators
  /// and `*`/`?` matching within a segment.
  static RegExp _globToRegExp(String glob) {
    final buffer = StringBuffer('^');
    for (var i = 0; i < glob.length; i++) {
      final char = glob[i];
      if (char == '*') {
        if (i + 1 < glob.length && glob[i + 1] == '*') {
          // `**/` matches zero or more leading path segments (including none),
          // so `**/*.dart` matches both top-level and nested files.
          if (i + 2 < glob.length && glob[i + 2] == '/') {
            buffer.write('(?:.*/)?');
            i += 2;
          } else {
            buffer.write('.*');
            i++;
          }
        } else {
          buffer.write('[^/]*');
        }
      } else if (char == '?') {
        buffer.write('[^/]');
      } else if ('.()[]{}\$^+|\\'.contains(char)) {
        buffer
          ..write(r'\')
          ..write(char);
      } else {
        buffer.write(char);
      }
    }
    buffer.write(r'$');
    return RegExp(buffer.toString());
  }
}
