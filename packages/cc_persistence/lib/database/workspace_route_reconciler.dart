import 'package:cc_domain/core/domain/services/webhook_secret_vault.dart';
import 'package:cc_persistence/database/backup/workspace_import.dart';
import 'package:cc_persistence/database/cross_workspace_queries.dart';
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/tables/workspace_routes_table.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:drift/drift.dart';

/// What one [WorkspaceRouteReconciler.run] changed.
typedef WorkspaceRouteReconcileReport = ({
  int removed,
  int restored,
  List<String> unreadable,
});

/// Makes `workspace_routes` agree with the rows its keys point at.
///
/// A route is written beside its entity in another file, so a crash between
/// the two writes, a restore, or a delete path that forgot the route leaves
/// the table wrong in either direction: a dangling route resolves to a row
/// that is gone, a missing one makes a live invite or webhook a not-found.
/// Both fail on the pre-auth path, where there is no scan fallback to hide
/// them. This derives every route from the workspace rows ([routesOf], the
/// same derivation an import uses), deletes routes no row claims (including
/// webhook routes keyed by a raw token rather than its HMAC, which must
/// never resolve) and writes the missing ones.
///
/// CROSS-WORKSPACE BY DESIGN: the routes table is the server-global index
/// over every workspace's pre-auth keys, so checking it means reading every
/// workspace. A workspace whose file cannot be read keeps its routes as
/// they are: nothing can be derived for it, and dropping them would cut it
/// off on the strength of a read error.
class WorkspaceRouteReconciler {
  /// Creates a reconciler over the global routes and [workspaces]' rows.
  WorkspaceRouteReconciler({
    required this._global,
    required WorkspaceDatabaseManager workspaces,
    required this._webhookSecrets,
  }) : _workspaces = workspaces,
       _cross = CrossWorkspaceQueries(workspaces);

  final GlobalDatabase _global;
  final WorkspaceDatabaseManager _workspaces;
  final CrossWorkspaceQueries _cross;
  final WebhookSecretVault _webhookSecrets;

  /// Reconciles every route once.
  Future<WorkspaceRouteReconcileReport> run() async {
    final live = (await _workspaces.liveWorkspaceIds()).toSet();
    final unreadable = <String>[];
    final derived = await _cross.fanOutKeyed(
      (db) async => {
        for (final route in await routesOf(db, _webhookSecrets))
          (route.kind, route.key),
      },
      onError: (workspaceId, _) => unreadable.add(workspaceId),
    );
    final owners = <(WorkspaceRouteKind, String), String>{
      for (final MapEntry(key: workspaceId, value: keys) in derived.entries)
        for (final key in keys) key: workspaceId,
    };
    final routes = await _global.select(_global.workspaceRoutesTable).get();
    final kindsByWire = {
      for (final kind in WorkspaceRouteKind.values) kind.wireName: kind,
    };

    var removed = 0;
    final present = <(WorkspaceRouteKind, String), String>{};
    for (final row in routes) {
      final kind = kindsByWire[row.kind];
      final key = (kind, row.keyHash);
      final keep =
          kind != null &&
          live.contains(row.workspaceId) &&
          (unreadable.contains(row.workspaceId) || owners.containsKey(key));
      if (keep) {
        present[(kind, row.keyHash)] = row.workspaceId;
        continue;
      }
      await _global.customUpdate(
        'DELETE FROM workspace_routes WHERE kind = ? AND key_hash = ?',
        variables: [Variable(row.kind), Variable(row.keyHash)],
        updates: {_global.workspaceRoutesTable},
        updateKind: UpdateKind.delete,
      );
      removed++;
    }

    var restored = 0;
    for (final MapEntry(key: (kind, keyHash), value: workspaceId)
        in owners.entries) {
      if (present[(kind, keyHash)] == workspaceId) {
        continue;
      }
      await _global.workspaceRouteDao.put(kind, keyHash, workspaceId);
      restored++;
    }

    // An invite's secure companion row is only reachable through its route,
    // so one whose route is gone is a pre-auth answer for nothing.
    removed += await _global.customUpdate(
      'DELETE FROM invite_secure_routes WHERE code_hash NOT IN ('
      'SELECT key_hash FROM workspace_routes WHERE kind = ?)',
      variables: [Variable(WorkspaceRouteKind.inviteCode.wireName)],
      updates: {_global.inviteSecureRoutesTable},
      updateKind: UpdateKind.delete,
    );
    return (removed: removed, restored: restored, unreadable: unreadable);
  }
}
