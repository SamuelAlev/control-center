import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show NotFoundException, RepoOpKind;
import 'package:cc_domain/core/domain/repositories/workspace_settings_repository.dart';
import 'package:cc_domain/core/domain/value_objects/account_pool.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_host/cc_host.dart' show RepoOp;
import 'package:cc_server_core/src/cc_server_runtime.dart' show accountPoolKey;

/// `account_pools.get` and `.set`: which credentials a workspace (or one of
/// its agents) may spend, in what order, and whether to drain them one at a
/// time or spread runs across them. ONE pair of ops for both lanes — the
/// Claude Code adapter's account directories and a harness provider's stored
/// credentials — because the thing being edited is identical: an ordered list
/// plus a strategy.
///
/// Reads sit at `member` (every member can see how their runs are routed);
/// writes carry an EXPLICIT admin floor, matching `workspace_settings.set`,
/// because attaching or reordering changes which plan every member's runs
/// spend.
///
/// Empty when the host has no workspace settings store. Injected via
/// `extraOps` so `remote_rpc_catalog.dart` does not grow.
List<RepoOp> buildAccountPoolOps(WorkspaceSettingsRepository? settings) {
  if (settings == null) {
    return const [];
  }
  return [
    RepoOp(
      name: 'account_pools.get',
      kind: RepoOpKind.read,
      minRole: WorkspaceRole.member,
      requiredArgs: ['lane'],
      handler: (ctx) async {
        final lane = ctx.args['lane'] as String;
        final agentId = ctx.args['agent_id'] as String?;
        final key = accountPoolKey(lane, agentId);
        if (key == null) {
          throw const NotFoundException('Unknown account pool lane');
        }
        final raw = await settings.get(ctx.workspaceId!, key);
        // The workspace pool is returned alongside an agent's own, so the
        // editor can show what an unset agent would inherit rather than a
        // misleading empty list.
        final inheritedKey = agentId == null
            ? null
            : accountPoolKey(lane, null);
        final inherited = inheritedKey == null
            ? null
            : await settings.get(ctx.workspaceId!, inheritedKey);
        return {
          'pool': _decodePool(raw),
          if (inherited != null) 'inherited': _decodePool(inherited),
        };
      },
    ),
    RepoOp(
      name: 'account_pools.set',
      kind: RepoOpKind.mutate,
      minRole: WorkspaceRole.admin,
      requiredArgs: ['lane'],
      handler: (ctx) async {
        final lane = ctx.args['lane'] as String;
        final agentId = ctx.args['agent_id'] as String?;
        final key = accountPoolKey(lane, agentId);
        if (key == null) {
          throw const NotFoundException('Unknown account pool lane');
        }
        final pool = ctx.args['pool'];
        // Always the SESSION workspace — a client can never write a pool
        // into a foreign workspace (isolation invariant).
        await settings.set(
          ctx.workspaceId!,
          key,
          pool is Map<String, dynamic>
              ? jsonEncode(AccountPool.fromJson(pool).toJson())
              // Null clears the pool, which is how an agent goes back to
              // inheriting the workspace's.
              : null,
        );
        return {'ok': true};
      },
    ),
  ];
}

/// Decodes a stored pool into its wire shape, tolerating a corrupt value.
///
/// A pool that will not parse reads as unconfigured rather than failing the
/// op: the editor then shows an empty list the operator can fix, instead of a
/// settings page that refuses to open.
Map<String, dynamic> _decodePool(String? raw) {
  if (raw == null || raw.isEmpty) {
    return const AccountPool().toJson();
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return AccountPool.fromJson(decoded).toJson();
    }
  } on Object {
    // Fall through to the empty pool.
  }
  return const AccountPool().toJson();
}
