import 'package:cc_persistence/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

/// Public route id → invite code hash and owning workspace, for the pre-auth
/// Noise invite handshake.
///
/// CROSS-WORKSPACE BY DESIGN — lives in `global.db`, beside
/// `workspace_routes`. A pre-auth hello carries the route id only: the stored
/// `SHA-256(code)` is the handshake PSK and must never travel, so the server
/// needs an index from the public id to the hash it will prove against. Rows
/// carry ids and a hash, never workspace content, and are written and removed
/// in the same transaction as the invite's `workspace_routes` row.
@TableIndex(name: 'idx_invite_secure_routes_workspace', columns: {#workspaceId})
class InviteSecureRoutesTable extends Table {
  /// The public id a client derives from the invite code.
  TextColumn get routeId => text()();

  /// `SHA-256(code)`: the handshake PSK. Never sent to a caller.
  TextColumn get codeHash => text()();

  /// The workspace the invite belongs to; the route goes with it.
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();

  @override
  String get tableName => 'invite_secure_routes';

  @override
  Set<Column> get primaryKey => {routeId};
}
