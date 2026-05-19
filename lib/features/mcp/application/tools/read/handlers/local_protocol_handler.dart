import 'dart:convert';
import 'dart:io';

import 'package:control_center/core/domain/ports/workspace_filesystem_port.dart';
import 'package:control_center/features/mcp/application/tools/read/internal_url.dart';
import 'package:control_center/features/mcp/application/tools/read/internal_url_router.dart';
import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';

/// Handles `local://<name>.md` URLs — plan artifacts and contracts
/// shared with subagents. Resolves against the conversation's
/// `plans/` subdirectory when a conversation scope is available,
/// or the workspace root otherwise.
class LocalProtocolHandler {
  /// Creates a [LocalProtocolHandler].
  LocalProtocolHandler({required WorkspaceFilesystemPort filesystem})
    : _filesystem = filesystem;

  final WorkspaceFilesystemPort _filesystem;

  /// Resolves [url] by reading the local file from the workspace.
  Future<CallResult> handle(LocalUrl url, ReadContext context) async {
    final workspaceId = context.workspaceId;
    if (workspaceId == null) {
      return CallResult.error(
        'local:// requires a workspace_id context',
      );
    }

    final filename = url.filename;
    if (filename.contains('..') || filename.startsWith('/')) {
      return CallResult.error(
        'local:// filename contains invalid path segments',
      );
    }

    // Resolve the base directory: conversation plans/ or workspace root.
    Directory baseDir;
    if (context.conversationId != null) {
      final convDir = await _filesystem.conversationDir(
        workspaceId,
        context.conversationId!,
      );
      baseDir = Directory('${convDir.path}/plans');
    } else {
      baseDir = await _filesystem.workspaceDir(workspaceId);
    }

    final file = File('${baseDir.path}/$filename');

    if (!file.existsSync()) {
      return CallResult.error(
        'Local file not found: $filename in workspace $workspaceId',
      );
    }

    final content = file.readAsStringSync();

    return CallResult.success(
      jsonEncode({
        'filename': filename,
        'workspace_id': workspaceId,
        'content': content,
      }),
    );
  }
}
