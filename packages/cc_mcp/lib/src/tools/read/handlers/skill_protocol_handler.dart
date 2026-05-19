import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_infra/src/ports/workspace_filesystem_port.dart';
import 'package:cc_mcp/src/tools/read/internal_url.dart';
import 'package:cc_mcp/src/tools/read/internal_url_router.dart';

/// Handles `skill://<name>` URLs by reading the skill's `SKILL.md`
/// from the workspace filesystem.
class SkillProtocolHandler {
  /// Creates a [SkillProtocolHandler].
  SkillProtocolHandler({required WorkspaceFilesystemPort filesystem})
    : _filesystem = filesystem;

  final WorkspaceFilesystemPort _filesystem;

  /// Resolves [url] by reading the skill file from disk.
  Future<CallResult> handle(SkillUrl url, ReadContext context) async {
    final workspaceId = context.workspaceId;
    if (workspaceId == null) {
      return CallResult.error(
        'skill:// requires a workspace_id context',
      );
    }

    final slug = url.slug;
    final content = await _filesystem.readSkillFile(workspaceId, slug);

    if (content == null) {
      return CallResult.error(
        'Skill not found: $slug in workspace $workspaceId',
      );
    }

    return CallResult.success(
      jsonEncode({
        'skill_slug': slug,
        'workspace_id': workspaceId,
        'content': content,
      }),
    );
  }
}
