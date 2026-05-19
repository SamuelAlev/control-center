import 'dart:io';

import 'package:test/test.dart';

/// Pins the DERIVED permission catalog.
///
/// `RepoOp.permission` computes `<domain>:<tier>` from an op's name prefix and
/// the role floor it already enforces, so all ~550 ops carry a permission
/// without anyone typing one. That derivation is what keeps a NEW op gated by
/// default — but it also means a new op prefix silently mints a new
/// permission domain nobody reviewed, and custom roles are written in exactly
/// that vocabulary.
///
/// So the DOMAIN set is pinned here: adding an op under a new prefix fails
/// until a human acknowledges the new domain, and removing the last op of a
/// domain fails until the stale entry goes. The per-op tier needs no pinning
/// — `permission_parity_test.dart` proves it equals the enforced role floor
/// for every op and preset.
///
/// Source-level (grep), like the other catalog ratchets: instantiating the
/// real catalog takes ~40 dependencies.
void main() {
  Directory repoRoot() {
    var dir = Directory.current;
    while (true) {
      if (File(
        '${dir.path}/packages/cc_server_core/lib/src/remote_rpc_catalog.dart',
      ).existsSync()) {
        return dir;
      }
      final parent = dir.parent;
      if (parent.path == dir.path) {
        return Directory.current;
      }
      dir = parent;
    }
  }

  /// Every permission domain the op catalog currently mints. Each is a
  /// feature area a custom role can be written against.
  const pinnedDomains = <String>{
    'account_pools', 'acp', 'action_policy', 'adapter',
    // Stage 2 governance: custom roles, the authorization audit trail and
    // the install-wide managed policy clamp.
    'roles', 'audit', 'managed_policy',
    'agentGoalRuns', 'agent_presence', 'agent_run_log', 'agent_working_memory',
    'agents', 'approval_routing', 'approvals', 'autonomy',
    'blob', 'cache', 'calendar', 'chat',
    'checker', 'claude', 'claude_accounts', 'codeServer',
    'confirmation', 'connection', 'connectivity', 'context',
    'conversation', 'credential_gate', 'credentials', 'demo',
    'dictation', 'dispatch', 'evals', 'fleet',
    'fonts', 'forge', 'fs', 'gif',
    'github', 'goals', 'ide', 'identity',
    'invites', 'isolated_repo', 'kimi', 'mcp',
    'meeting', 'members', 'memory_access_grant', 'memory_domain',
    'memory_fact', 'memory_policy', 'messaging', 'models',
    'newsfeed', 'notes', 'notifications', 'oauth',
    'openai', 'orchestration', 'pairing', 'pipeline',
    'pipeline_run', 'pipeline_template', 'pipeline_trigger', 'plan',
    'playbook', 'pr', 'pr_lifecycle', 'pr_review',
    'prefs', 'presence', 'process', 'project',
    'providerApps', 'provider_policy', 'providers', 'reactions',
    'repos', 'review_hub', 'review_space', 'review_studio',
    'rig', 'sandbox', 'server', 'server_settings',
    'serviceStatus', 'skills', 'soundscape', 'space_read',
    'sso', 'steering', 'subscriptions', 'sync',
    'takeover', 'team', 'terminal', 'ticket_link',
    'ticket_sync', 'ticketing', 'tickets', 'todos',
    'usage', 'users', 'voice_profile', 'weather',
    'workProduct', 'workspace', 'workspace_settings', 'worktree',
  };

  test('the permission catalog mints exactly the pinned domains', () {
    final root = repoRoot();
    final serverSrc = Directory(
      '${root.path}/packages/cc_server_core/lib/src',
    );
    // `name:` is matched through any intervening comment but never across the
    // next `RepoOp(`, so each match binds to its own op (same form as
    // `rpc_op_coverage_test.dart`).
    final repoOpNameRe = RegExp(
      r"""RepoOp\((?:(?!RepoOp\()[\s\S])*?name:\s*(['"])([^'"$]+)\1""",
    );

    final found = <String>{};
    for (final entity in serverSrc.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      for (final m in repoOpNameRe.allMatches(entity.readAsStringSync())) {
        final name = m.group(2)!;
        final dot = name.indexOf('.');
        found.add(dot > 0 ? name.substring(0, dot) : name);
      }
    }

    expect(found, isNotEmpty, reason: 'catalog parse found no op names');

    final added = found.difference(pinnedDomains);
    expect(
      added,
      isEmpty,
      reason:
          'New permission domain(s). Every op under a new prefix mints a new '
          'entry in the catalog that custom roles are written against, so it '
          'is a naming decision, not an accident. Add them here (or reuse an '
          'existing prefix):\n'
          '${added.map((d) => "  $d").join("\n")}',
    );

    final removed = pinnedDomains.difference(found);
    expect(
      removed,
      isEmpty,
      reason:
          'Pinned domain(s) no longer minted by any op — a custom role '
          'denying one would now deny nothing. Remove them here:\n'
          '${removed.map((d) => "  $d").join("\n")}',
    );
  });
}
