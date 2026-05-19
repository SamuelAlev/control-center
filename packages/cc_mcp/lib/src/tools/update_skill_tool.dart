import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_bundle_port.dart';
import 'package:cc_harness/tools.dart';

/// `update_skill` — re-fetches an installed GitHub skill at a new `ref`,
/// re-runs the FULL scan gate over the new bytes and re-pins it (recording the
/// prior hash for rollback). Same fail-closed semantics as install: a
/// quarantine verdict or scanner error aborts and leaves the current version
/// in place (PRD 23 §4).
class UpdateSkillTool extends McpTool {
  /// Creates an [UpdateSkillTool].
  UpdateSkillTool({required SkillBundlePort bundles}) : _bundles = bundles;

  final SkillBundlePort _bundles;

  @override
  bool get requiresApproval => true;

  @override
  Set<ActionClass> get actionClasses => const {
    ActionClass.packageInstall,
    ActionClass.networkEgress,
  };

  @override
  String get name => 'update_skill';

  @override
  String get description =>
      'Updates an installed GitHub skill to a new ref (use a 40-hex commit SHA '
      'for a stable pin). Re-fetches, re-scans the new bytes through the '
      'mandatory gate and re-pins with the prior hash kept for rollback.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string'},
      'slug': {
        'type': 'string',
        'description': 'The installed skill slug to update.',
      },
      'ref': {
        'type': 'string',
        'description': 'Commit SHA (preferred), tag, or branch to pin to.',
      },
      'allow_quarantine_override': {
        'type': 'boolean',
        'description':
            'When true, apply the update even if the scan gate returns a '
            'quarantine verdict (an explicit, recorded operator override). '
            'Defaults to false.',
      },
    },
    'required': ['workspace_id', 'slug', 'ref'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    String? str(String k) =>
        arguments[k] is String ? arguments[k] as String : null;
    final workspaceId = str('workspace_id');
    final slug = str('slug');
    final ref = str('ref');
    if (workspaceId == null) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    if (slug == null || ref == null) {
      return CallResult.error('Missing or invalid argument: slug and ref.');
    }
    try {
      final entry = await _bundles.applyUpdate(
        workspaceId: workspaceId,
        slug: slug,
        ref: ref,
        allowQuarantineOverride: arguments['allow_quarantine_override'] == true,
        spaceId: str('space_id'),
        agentId: str('agent_id'),
      );
      return CallResult.success(
        jsonEncode({
          'slug': entry.slug,
          'ref': entry.ref,
          'computed_hash': entry.computedHash,
          'previous_hash': entry.previousHash,
          'pinned_to_commit': entry.isPinnedToCommit,
          'status': 'updated',
        }),
      );
    } on Object catch (e) {
      return CallResult.error('update_skill failed: $e');
    }
  }
}
