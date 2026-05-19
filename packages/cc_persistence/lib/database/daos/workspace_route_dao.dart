import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/tables/server_meta_table.dart';
import 'package:cc_persistence/database/tables/workspace_routes_table.dart';
import 'package:drift/drift.dart';

part 'workspace_route_dao.g.dart';

/// Data access object for the [WorkspaceRoutesTable] and [ServerMetaTable] in
/// `global.db`.
///
/// **CROSS-WORKSPACE BY DESIGN** — resolving a workspace from an opaque key is
/// the entire point. See [WorkspaceRoutesTable] for why this exists and which
/// pre-auth entry points depend on it.
@DriftAccessor(tables: [WorkspaceRoutesTable, ServerMetaTable])
class WorkspaceRouteDao extends DatabaseAccessor<GlobalDatabase>
    with _$WorkspaceRouteDaoMixin {
  /// Creates a [WorkspaceRouteDao] for the global database.
  WorkspaceRouteDao(super.attachedDatabase);

  /// Resolves the workspace owning [keyHash] for [kind], or `null`.
  ///
  /// A miss is a miss: there is deliberately no scan fallback, because a scan
  /// would turn a bug (a route that was never written) into a slow success and
  /// hide it forever.
  Future<String?> resolve(WorkspaceRouteKind kind, String keyHash) async {
    final row =
        await (select(workspaceRoutesTable)..where(
              (t) => t.kind.equals(kind.wireName) & t.keyHash.equals(keyHash),
            ))
            .getSingleOrNull();
    return row?.workspaceId;
  }

  /// Records that [keyHash] of [kind] belongs to [workspaceId]. Idempotent.
  ///
  /// Callers write the entity into its workspace database FIRST, then the route:
  /// a route pointing at a row that does not exist yet would resolve to a
  /// not-found, whereas a row with no route is invisible to the pre-auth path
  /// (both are wrong, but the first order fails loudly on the very next read).
  Future<void> put(
    WorkspaceRouteKind kind,
    String keyHash,
    String workspaceId,
  ) => into(workspaceRoutesTable).insertOnConflictUpdate(
    WorkspaceRoutesTableCompanion.insert(
      kind: kind.wireName,
      keyHash: keyHash,
      workspaceId: workspaceId,
      createdAt: Value(DateTime.now()),
    ),
  );

  /// Removes the route for [keyHash] of [kind], if any.
  Future<void> remove(WorkspaceRouteKind kind, String keyHash) async {
    await (delete(workspaceRoutesTable)..where(
          (t) => t.kind.equals(kind.wireName) & t.keyHash.equals(keyHash),
        ))
        .go();
  }

  /// Drops every route belonging to [workspaceId] — called when a workspace is
  /// deleted, so its routes die with its database file instead of resolving to
  /// a workspace that no longer exists.
  Future<void> removeAllForWorkspace(String workspaceId) async {
    await (delete(
      workspaceRoutesTable,
    )..where((t) => t.workspaceId.equals(workspaceId))).go();
  }

  /// Reads a [ServerMetaTable] value, or `null`.
  Future<String?> meta(String key) async {
    final row = await (select(
      serverMetaTable,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  /// Writes a [ServerMetaTable] value.
  Future<void> setMeta(String key, String value) =>
      into(serverMetaTable).insertOnConflictUpdate(
        ServerMetaTableCompanion.insert(key: key, value: value),
      );
}
