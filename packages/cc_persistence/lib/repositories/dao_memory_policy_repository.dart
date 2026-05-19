import 'dart:convert';

import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:cc_persistence/database/daos/memory_policy_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart'
    as db;
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/memory_policy_mapper.dart';
import 'package:drift/drift.dart';

/// DAO-based repository for memory policies.
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).memoryPolicyDao` per call: policies live in their
/// workspace's own database file, so the workspace id picks the file before any
/// SQL runs.
class DaoMemoryPolicyRepository implements MemoryPolicyRepository {
  /// Creates a [DaoMemoryPolicyRepository] over the per-workspace databases.
  DaoMemoryPolicyRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;
  final MemoryPolicyMapper _mapper = const MemoryPolicyMapper();

  MemoryPolicyDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).memoryPolicyDao;

  @override
  Stream<List<MemoryPolicy>> watchByWorkspace(String workspaceId) =>
      _dao(workspaceId)
          .watchByWorkspace(workspaceId)
          .map((rows) => rows.map(_mapper.toDomain).toList());

  @override
  Future<List<MemoryPolicy>> getByWorkspace(String workspaceId) =>
      _dao(workspaceId)
          .getByWorkspace(workspaceId)
          .then((rows) => rows.map(_mapper.toDomain).toList());

  @override
  Future<MemoryPolicy?> getById(String workspaceId, String id) =>
      _dao(workspaceId)
          .getById(workspaceId, id)
          .then((row) => row != null ? _mapper.toDomain(row) : null);

  @override
  Future<void> upsert(MemoryPolicy policy) => _dao(policy.workspaceId).upsert(
    db.MemoryPoliciesTableCompanion(
      id: Value(policy.id),
      workspaceId: Value(policy.workspaceId),
      domain: Value(policy.domain),
      rule: Value(policy.rule),
      sourceFactIds: Value(jsonEncode(policy.sourceFactIds)),
      requiredRole: Value(policy.requiredRole?.name),
      active: Value(policy.active),
      createdAt: Value(policy.createdAt),
      updatedAt: Value(policy.updatedAt),
    ),
  );

  @override
  Future<List<MemoryPolicy>> getActiveByWorkspace(
    String workspaceId, {
    String? domain,
  }) => _dao(workspaceId)
      .getActiveByWorkspace(workspaceId, domain: domain)
      .then((rows) => rows.map(_mapper.toDomain).toList());

  @override
  Future<void> delete(String workspaceId, String id) =>
      _dao(workspaceId).deleteById(workspaceId, id);
}
