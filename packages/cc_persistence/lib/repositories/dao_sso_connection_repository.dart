import 'dart:convert';

import 'package:cc_domain/core/domain/entities/sso_connection.dart';
import 'package:cc_domain/core/domain/repositories/sso_connection_repository.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_persistence/database/daos/sso_connection_dao.dart';
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:drift/drift.dart';

/// DAO-backed [SsoConnectionRepository] over the global [SsoConnectionDao].
class DaoSsoConnectionRepository implements SsoConnectionRepository {
  /// Creates a [DaoSsoConnectionRepository].
  DaoSsoConnectionRepository(this._dao);

  final SsoConnectionDao _dao;

  SsoConnection _toDomain(SsoConnectionsTableData row) {
    final kind = SsoProviderKind.fromWire(row.kind);
    return SsoConnection(
      id: row.id,
      kind: kind ?? SsoProviderKind.saml,
      enabled: row.enabled,
      issuer: row.issuer,
      clientId: row.clientId,
      groupsClaim: row.groupsClaim,
      idpMetadataXml: row.idpMetadataXml,
      spEntityId: row.spEntityId,
      emailAttribute: row.emailAttribute,
      displayNameAttribute: row.displayNameAttribute,
      groupsAttribute: row.groupsAttribute,
      defaultRole:
          WorkspaceRole.fromWire(row.defaultRole) ?? WorkspaceRole.member,
      groupRoleMap: _decodeRoleMap(row.groupRoleMap),
      autoMember: row.autoMember,
      allowJit: row.allowJit,
      allowIdpInitiated: row.allowIdpInitiated,
      wantResponseSigned: row.wantResponseSigned,
      clockSkewSeconds: row.clockSkewSeconds,
      updatedAt: row.updatedAt,
    );
  }

  @override
  Future<SsoConnection?> getByKind(SsoProviderKind kind) async {
    final row = await _dao.getById(kind.wireName);
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<List<SsoConnection>> getAll() async =>
      (await _dao.getAll()).map(_toDomain).toList();

  @override
  Stream<List<SsoConnection>> watchAll() =>
      _dao.watchAll().map((rows) => rows.map(_toDomain).toList());

  @override
  Future<void> upsert(SsoConnection connection) => _dao.upsert(
    SsoConnectionsTableCompanion(
      id: Value(connection.id),
      kind: Value(connection.kind.wireName),
      enabled: Value(connection.enabled),
      issuer: Value(connection.issuer),
      clientId: Value(connection.clientId),
      groupsClaim: Value(connection.groupsClaim),
      idpMetadataXml: Value(connection.idpMetadataXml),
      spEntityId: Value(connection.spEntityId),
      emailAttribute: Value(connection.emailAttribute),
      displayNameAttribute: Value(connection.displayNameAttribute),
      groupsAttribute: Value(connection.groupsAttribute),
      defaultRole: Value(connection.defaultRole.wireName),
      groupRoleMap: Value(_encodeRoleMap(connection.groupRoleMap)),
      autoMember: Value(connection.autoMember),
      allowJit: Value(connection.allowJit),
      allowIdpInitiated: Value(connection.allowIdpInitiated),
      wantResponseSigned: Value(connection.wantResponseSigned),
      clockSkewSeconds: Value(connection.clockSkewSeconds),
      updatedAt: Value(connection.updatedAt),
    ),
  );

  /// Encodes `{group: role}` as JSON wire names; owner mappings are dropped
  /// (SSO may never grant ownership — the same rule the env parsers apply).
  static String _encodeRoleMap(Map<String, WorkspaceRole> map) => jsonEncode({
    for (final entry in map.entries)
      if (entry.value != WorkspaceRole.owner) entry.key: entry.value.wireName,
  });

  /// Decodes the JSON column; unparseable values grant nothing (fail closed).
  static Map<String, WorkspaceRole> _decodeRoleMap(String json) {
    try {
      final raw = jsonDecode(json);
      if (raw is! Map) {
        return const {};
      }
      return {
        for (final entry in raw.entries)
          if (WorkspaceRole.fromWire(entry.value as String?)
              case final WorkspaceRole role
              when role != WorkspaceRole.owner)
            entry.key as String: role,
      };
    } catch (_) {
      return const {};
    }
  }
}
