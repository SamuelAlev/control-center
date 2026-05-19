import 'dart:convert';

import 'package:control_center/core/database/app_database.dart' as db;
import 'package:control_center/core/database/daos/memory_policy_dao.dart';
import 'package:control_center/core/domain/entities/memory_policy.dart';
import 'package:control_center/features/memory/data/mappers/memory_policy_mapper.dart';
import 'package:control_center/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:drift/drift.dart';

/// DAO-based repository for memory policies.
class DaoMemoryPolicyRepository implements MemoryPolicyRepository {
  /// Creates a [DaoMemoryPolicyRepository].
  DaoMemoryPolicyRepository(this._dao);

  final MemoryPolicyDao _dao;
  final MemoryPolicyMapper _mapper = const MemoryPolicyMapper();

  @override
  Stream<List<MemoryPolicy>> watchByWorkspace(String workspaceId) =>
      _dao.watchByWorkspace(workspaceId).map(
        (rows) => rows.map(_mapper.toDomain).toList(),
      );

  @override
  Future<List<MemoryPolicy>> getByWorkspace(String workspaceId) =>
      _dao.getByWorkspace(workspaceId).then(
        (rows) => rows.map(_mapper.toDomain).toList(),
      );

  @override
  Future<MemoryPolicy?> getById(String workspaceId, String id) => _dao
      .getById(workspaceId, id)
      .then((row) => row != null ? _mapper.toDomain(row) : null);

  @override
  Future<void> upsert(MemoryPolicy policy) => _dao.upsert(
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
  }) =>
      _dao.getActiveByWorkspace(workspaceId, domain: domain).then(
        (rows) => rows.map(_mapper.toDomain).toList(),
      );

  @override
  Future<void> delete(String workspaceId, String id) =>
      _dao.deleteById(workspaceId, id);
}
