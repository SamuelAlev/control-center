import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_bundle_port.dart';

/// `list_skill_updates` — reports which pinned GitHub skills have a newer
/// version available upstream on their tracking branch (PRD 23 §4). Read-only;
/// applying an update is a separate, gated `update_skill` call.
class ListSkillUpdatesTool extends McpTool {
  /// Creates a [ListSkillUpdatesTool].
  ListSkillUpdatesTool({required SkillBundlePort bundles}) : _bundles = bundles;

  final SkillBundlePort _bundles;

  @override
  String get name => 'list_skill_updates';

  @override
  String get description =>
      'Lists the workspace\'s pinned GitHub skills that have a newer version '
      'available upstream (best-effort; a skill whose upstream cannot be '
      'reached is simply omitted). Read-only — use update_skill to apply one.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string'},
    },
    'required': ['workspace_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final updates = await _bundles.checkUpdates(workspaceId);
    return CallResult.success(
      jsonEncode({
        'updates': [
          for (final u in updates)
            {
              'slug': u.slug,
              'current_ref': u.currentRef,
              'latest_ref': u.latestRef,
            },
        ],
      }),
    );
  }
}
