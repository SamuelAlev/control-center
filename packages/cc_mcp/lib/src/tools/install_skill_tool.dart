import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_bundle_port.dart';
import 'package:cc_harness/tools.dart';

/// `install_skill` — installs a skill from a GitHub repository, pinned to a
/// commit SHA, and records the pin (origin + rolled-up content hash) in the
/// workspace's `skills-lock.json`.
class InstallSkillTool extends McpTool {
  /// Creates an [InstallSkillTool].
  InstallSkillTool({required SkillBundlePort bundles}) : _bundles = bundles;

  final SkillBundlePort _bundles;

  @override
  bool get requiresApproval => true;

  @override
  String get name => 'install_skill';
  @override
  Set<ActionClass> get actionClasses => const {
    ActionClass.packageInstall,
    ActionClass.networkEgress,
  };

  @override
  String get description =>
      'Installs a skill from a GitHub repository at a pinned ref (use a 40-hex '
      'commit SHA for a stable pin), writing its SKILL.md into the workspace '
      'and recording the pin + content hash in skills-lock.json.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string'},
      'slug': {
        'type': 'string',
        'description': 'Local skill slug to install as.',
      },
      'owner': {'type': 'string', 'description': 'GitHub repo owner.'},
      'repo': {'type': 'string', 'description': 'GitHub repo name.'},
      'path': {
        'type': 'string',
        'description': 'Path to the skill\'s SKILL.md in the repo.',
      },
      'ref': {
        'type': 'string',
        'description': 'Commit SHA (preferred), tag, or branch to pin to.',
      },
      'allow_quarantine_override': {
        'type': 'boolean',
        'description':
            'When true, install even if the mandatory scan gate returns a '
            'quarantine verdict (an explicit, recorded operator override). '
            'Defaults to false — quarantined skills are blocked.',
      },
    },
    'required': ['workspace_id', 'slug', 'owner', 'repo', 'path', 'ref'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    String? str(String k) =>
        arguments[k] is String ? arguments[k] as String : null;
    final workspaceId = str('workspace_id');
    final slug = str('slug');
    final owner = str('owner');
    final repo = str('repo');
    final path = str('path');
    final ref = str('ref');
    if (workspaceId == null) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    if (slug == null ||
        owner == null ||
        repo == null ||
        path == null ||
        ref == null) {
      return CallResult.error(
        'Missing or invalid argument: slug, owner, repo, path, and ref are '
        'required.',
      );
    }

    final allowQuarantineOverride =
        arguments['allow_quarantine_override'] == true;

    try {
      final entry = await _bundles.installFromGitHub(
        workspaceId: workspaceId,
        slug: slug,
        owner: owner,
        repo: repo,
        path: path,
        ref: ref,
        allowQuarantineOverride: allowQuarantineOverride,
        // Thread the caller's scope so the install-time capability→policy check
        // resolves channel/agent rules (falls back to workspace scope).
        channelId: str('channel_id'),
        agentId: str('agent_id'),
      );
      return CallResult.success(
        jsonEncode({
          'slug': entry.slug,
          'source': entry.source,
          'source_type': entry.sourceType.wire,
          'ref': entry.ref,
          'computed_hash': entry.computedHash,
          'pinned_to_commit': entry.isPinnedToCommit,
          'status': 'installed',
        }),
      );
    } on Object catch (e) {
      return CallResult.error('install_skill failed: $e');
    }
  }
}
