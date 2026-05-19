import 'package:cc_domain/features/sandboxing/domain/entities/sandbox_exec_grant.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

/// Maps [SandboxExecGrant] entities to and from their drift rows.
class SandboxExecGrantMapper {
  /// Creates a [SandboxExecGrantMapper].
  const SandboxExecGrantMapper();

  /// Row → entity.
  SandboxExecGrant fromRow(SandboxExecGrantsTableData row) => SandboxExecGrant(
    id: row.id,
    workspaceId: row.workspaceId,
    path: row.path,
    decision: SandboxExecGrantDecision.fromWire(row.decision),
    createdBy: row.createdBy,
    createdAt: row.createdAt,
  );

  /// Entity → insertable companion.
  SandboxExecGrantsTableCompanion toCompanion(SandboxExecGrant grant) =>
      SandboxExecGrantsTableCompanion(
        id: Value(grant.id),
        workspaceId: Value(grant.workspaceId),
        path: Value(grant.path),
        decision: Value(grant.decision.wire),
        createdBy: Value(grant.createdBy),
        createdAt: Value(grant.createdAt),
      );
}
