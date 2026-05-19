import 'package:cc_domain/features/ticketing/domain/worktree/worktree_ticket_link.dart';
import 'package:cc_persistence/database/daos/isolated_repo_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';

/// Drift-backed [WorktreeTicketLinkPort] over the worktree (`isolated_repos`)
/// rows: the ticket link lives on the worktree itself (`ticketId` =
/// linkedTicketId, plus the vendor/externalId columns).
///
/// Worktrees belong to a workspace and are stored in that workspace's own
/// database file, which the `workspaceId` on every method selects.
class DaoWorktreeTicketLinkRepository implements WorktreeTicketLinkPort {
  /// Creates a [DaoWorktreeTicketLinkRepository] over the per-workspace
  /// databases.
  DaoWorktreeTicketLinkRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  IsolatedRepoDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).isolatedRepoDao;

  @override
  Future<List<WorktreeTicketRef>> forWorkspace(String workspaceId) async {
    final rows = await _dao(workspaceId).listForWorkspace(workspaceId);
    return rows.map(_toRef).toList();
  }

  @override
  Future<WorktreeTicketRef?> byId(String workspaceId, String worktreeId) async {
    final row = await _dao(workspaceId).findById(workspaceId, worktreeId);
    return row == null ? null : _toRef(row);
  }

  @override
  Future<void> linkTicket({
    required String workspaceId,
    required String worktreeId,
    String? ticketId,
    String? vendor,
    String? externalId,
  }) => _dao(workspaceId).setTicketLink(
    workspaceId,
    worktreeId,
    ticketId: ticketId,
    vendor: vendor,
    externalId: externalId,
  );

  WorktreeTicketRef _toRef(IsolatedReposTableData row) => WorktreeTicketRef(
    worktreeId: row.id,
    workspaceId: row.workspaceId,
    path: row.path,
    ticketId: row.ticketId,
    vendor: row.linkedTicketVendor,
    externalId: row.linkedTicketExternalId,
  );
}
