import 'dart:io';

import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/src/tools/workspace_paths.dart';

/// Writes content to a file, creating parent directories as needed.
///
/// Writes are confined to the working directory: a path that resolves outside
/// the workspace is rejected. Write-tier — the loop fires the approval callback
/// before this runs.
class WriteTool extends HarnessTool {
  /// Creates a [WriteTool].
  WriteTool();

  @override
  String get name => 'write';

  @override
  String get description =>
      'Write content to a file in the workspace, creating it (and any parent '
      'directories) if needed. Overwrites existing content.';

  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.write;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'path': {
        'type': 'string',
        'description': 'Workspace-relative path to the file.',
      },
      'content': {
        'type': 'string',
        'description': 'The full content to write.',
      },
    },
    'required': ['path', 'content'],
  };

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    final path = args['path'];
    final content = args['content'];
    if (path is! String || path.isEmpty) {
      return HarnessToolResult.error('Missing or invalid argument: path');
    }
    if (content is! String) {
      return HarnessToolResult.error('Missing or invalid argument: content');
    }
    final resolved = resolveInsideWorkspace(
      context.workingDirectory,
      path,
      sharedRoots: context.sharedRoots,
    );
    if (resolved == null) {
      return HarnessToolResult.error(
        outsideWorkspaceMessage(
          'write',
          path,
          workspaceRoot: context.workingDirectory,
          sharedRoots: context.sharedRoots,
        ),
      );
    }
    try {
      final file = File(resolved);
      file.parent.createSync(recursive: true);
      final existed = file.existsSync();
      file.writeAsStringSync(content);
      // Counting code units, not `'\n'.allMatches(...)`: the latter allocates a
      // RegExpMatch object per line, which is real garbage on an MB-scale write.
      var lineCount = 1;
      for (var i = 0; i < content.length; i++) {
        if (content.codeUnitAt(i) == 0x0A) {
          lineCount++;
        }
      }
      return HarnessToolResult.success(
        '${existed ? 'Updated' : 'Created'} $path ($lineCount lines).',
      );
    } on FileSystemException catch (e) {
      return HarnessToolResult.error('Failed to write $path: ${e.message}');
    }
  }
}
