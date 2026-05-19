import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_bundle_port.dart';

/// `verify_skills` — checks every pinned skill's on-disk content against the
/// hash recorded in `skills-lock.json`, reporting matched / drifted / missing.
class VerifySkillsTool extends McpTool {
  /// Creates a [VerifySkillsTool].
  VerifySkillsTool({required SkillBundlePort bundles}) : _bundles = bundles;

  final SkillBundlePort _bundles;

  @override
  String get name => 'verify_skills';

  @override
  String get description =>
      'Verifies the workspace\'s pinned skills against skills-lock.json, '
      'reporting which match their recorded hash, which have drifted, and '
      'which are missing on disk.';

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
    final result = await _bundles.verify(workspaceId);
    return CallResult.success(
      jsonEncode({
        'is_clean': result.isClean,
        'matched': result.matched,
        'drifted': result.drifted,
        'missing': result.missing,
        'stale': result.stale,
        'quarantined': result.quarantined,
      }),
    );
  }
}
