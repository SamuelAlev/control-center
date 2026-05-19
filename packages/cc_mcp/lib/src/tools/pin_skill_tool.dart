import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_bundle_port.dart';
import 'package:cc_harness/tools.dart';

/// `pin_skill` — records an already-present (manually-authored or
/// runtime-local) workspace skill into `skills-lock.json` by hashing it now,
/// so it becomes a content-addressed, verifiable pin.
class PinSkillTool extends McpTool {
  /// Creates a [PinSkillTool].
  PinSkillTool({required SkillBundlePort bundles}) : _bundles = bundles;

  final SkillBundlePort _bundles;

  @override
  String get name => 'pin_skill';
  @override
  Set<ActionClass> get actionClasses => const {
    ActionClass.fileWriteOutsideWorktree,
  };

  @override
  String get description =>
      'Pins an existing workspace skill into skills-lock.json by hashing its '
      'current content, so it can be verified for drift later.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string'},
      'slug': {'type': 'string'},
    },
    'required': ['workspace_id', 'slug'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    final slug = arguments['slug'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    if (slug is! String) {
      return CallResult.error('Missing or invalid argument: slug');
    }
    try {
      final entry = await _bundles.pinLocal(
        workspaceId: workspaceId,
        slug: slug,
      );
      return CallResult.success(
        jsonEncode({
          'slug': entry.slug,
          'computed_hash': entry.computedHash,
          'source_type': entry.sourceType.wire,
          'status': 'pinned',
        }),
      );
    } on Object catch (e) {
      return CallResult.error('pin_skill failed: $e');
    }
  }
}
