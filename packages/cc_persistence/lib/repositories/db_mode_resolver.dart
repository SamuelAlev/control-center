import 'package:cc_domain/core/domain/ports/mode_resolver.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_persistence/database/daos/messaging_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';

/// [ModeResolver] backed by the messaging DAO.
///
/// One indexed lookup on `spaces.id` per dispatch, in the database file of
/// the workspace the dispatch belongs to. The fallback to [Mode.chat] preserves
/// the existing free-for-all behaviour for dispatches that aren't attached to a
/// space (e.g. CLI one-shots) and for a space id belonging to some other
/// workspace — which simply is not in this file.
class DbModeResolver implements ModeResolver {
  /// Creates a new [DbModeResolver] over the per-workspace databases.
  DbModeResolver(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  MessagingDao _dao(String workspaceId) => _dbs.of(workspaceId).messagingDao;

  @override
  Future<Mode> resolveForConversation(
    String workspaceId,
    String? conversationId,
  ) async {
    if (conversationId == null || conversationId.isEmpty) {
      return Mode.chat;
    }
    final row = await _dao(workspaceId).getSpaceById(conversationId);
    if (row == null) {
      return Mode.chat;
    }
    return Mode.fromDbValue(row.mode);
  }
}
