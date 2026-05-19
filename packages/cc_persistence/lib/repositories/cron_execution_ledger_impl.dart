import 'package:cc_domain/features/pipelines/domain/services/cron_execution_ledger.dart';
import 'package:cc_persistence/database/daos/cron_execution_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';

/// Drift-backed [CronExecutionLedger].
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).cronExecutionDao` per call: a claimed cron slot is a
/// row in its workspace's own database file, so the uniqueness the claim relies
/// on is enforced within that one file.
class CronExecutionLedgerImpl implements CronExecutionLedger {
  /// Creates a [CronExecutionLedgerImpl] over the per-workspace databases.
  CronExecutionLedgerImpl(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  CronExecutionDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).cronExecutionDao;

  @override
  Future<bool> claimSlot({
    required String id,
    required String workspaceId,
    required String triggerId,
    required DateTime plannedAt,
  }) => _dao(workspaceId).claimSlot(
    id: id,
    workspaceId: workspaceId,
    triggerId: triggerId,
    plannedAt: plannedAt,
  );
}
