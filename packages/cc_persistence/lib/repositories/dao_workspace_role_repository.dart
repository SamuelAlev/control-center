import 'dart:convert';

import 'package:cc_domain/core/domain/entities/role_definition.dart';
import 'package:cc_domain/core/domain/repositories/workspace_role_repository.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_persistence/database/daos/workspace_role_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:drift/drift.dart';

/// Drift-backed [WorkspaceRoleRepository] for custom (subtractive) roles.
///
/// Holds the manager and resolves the DAO per call — a custom role lives in
/// its workspace's own database file.
class DaoWorkspaceRoleRepository implements WorkspaceRoleRepository {
  /// Creates a [DaoWorkspaceRoleRepository].
  DaoWorkspaceRoleRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  WorkspaceRoleDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).workspaceRoleDao;

  @override
  Future<List<RoleDefinition>> forWorkspace(String workspaceId) async {
    final rows = await _dao(workspaceId).forWorkspace(workspaceId);
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Stream<List<RoleDefinition>> watchForWorkspace(String workspaceId) => _dao(
    workspaceId,
  ).watchForWorkspace(workspaceId).map(
    (rows) => rows.map(_fromRow).toList(growable: false),
  );

  @override
  Future<RoleDefinition?> byId(String workspaceId, String id) async {
    final row = await _dao(workspaceId).byId(workspaceId, id);
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<void> upsert(String workspaceId, RoleDefinition role) =>
      _dao(workspaceId).upsert(
        WorkspaceRolesTableCompanion.insert(
          id: role.id,
          workspaceId: workspaceId,
          name: role.name,
          basePreset: role.basePreset.wireName,
          deniedPermissions: Value(
            jsonEncode(role.deniedPermissions.toList()..sort()),
          ),
          updatedAt: Value(DateTime.now()),
        ),
      );

  @override
  Future<void> delete(String workspaceId, String id) =>
      _dao(workspaceId).deleteById(workspaceId, id);

  RoleDefinition _fromRow(WorkspaceRolesTableData r) => RoleDefinition(
    id: r.id,
    name: r.name,
    basePreset: _basePresetOf(r.basePreset),
    deniedPermissions: _decode(r.deniedPermissions),
    isCustom: true,
  );

  /// The stored base preset, floored to guest when unparseable and CAPPED at
  /// admin.
  ///
  /// `roles.upsert` already refuses to create an owner-based role, but a
  /// workspace database is an operator-supplied artifact (`workspace.import`
  /// adopts a file from disk), so a row claiming `owner` must not be able to
  /// mint an owner on read. Ownership is one seat, held by the membership
  /// row, transferred by its own op.
  static WorkspaceRole _basePresetOf(String stored) {
    final parsed = WorkspaceRole.fromWire(stored) ?? WorkspaceRole.guest;
    return parsed == WorkspaceRole.owner ? WorkspaceRole.admin : parsed;
  }

  static Set<String> _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is List ? {for (final e in decoded) e.toString()} : {};
    } catch (_) {
      return {};
    }
  }
}
