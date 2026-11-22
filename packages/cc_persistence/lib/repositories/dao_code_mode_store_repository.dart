import 'package:cc_domain/features/code_mode/domain/ports/code_mode_store_repository.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_store_write.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';

/// Drift-backed [CodeModeStoreRepository]: the values scripts kept with
/// `store(key, value)`, in each workspace's own database.
///
/// Holds the [WorkspaceDatabaseManager] and resolves the DAO per call: a
/// cached per-workspace DAO would answer every workspace from the first one.
/// The manager refuses an invalid or deleted workspace id before opening a
/// file.
///
/// The values belong to a conversation and an agent of the workspace: a
/// commit naming either one that the workspace does not hold is refused by
/// the foreign keys, and the values go with whichever of the two is deleted.
class DaoCodeModeStoreRepository implements CodeModeStoreRepository {
  /// Creates a [DaoCodeModeStoreRepository] over the per-workspace databases.
  DaoCodeModeStoreRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  @override
  Future<Map<String, String>> readAll(
    String workspaceId, {
    required String conversationId,
    required String agentId,
  }) async =>
      _dbs.of(workspaceId).codeModeDao.storedValues(conversationId, agentId);

  /// Applies [writes] atomically.
  ///
  /// [CodeModeStoreRules.apply] runs on the values stored at commit time,
  /// inside the write transaction, so concurrent commits for one conversation
  /// and agent are checked one after another and cannot together pass the
  /// total cap. When it throws, nothing is written.
  @override
  Future<void> commit(
    String workspaceId, {
    required String conversationId,
    required String agentId,
    required List<CodeModeStoreWrite> writes,
  }) async {
    // Resolved first so an unknown or deleted workspace is refused even for
    // an empty batch.
    final dao = _dbs.of(workspaceId).codeModeDao;
    if (writes.isEmpty) {
      return;
    }
    await dao.replaceStoredValues(
      conversationId,
      agentId,
      (current) => CodeModeStoreRules.apply(current, writes),
    );
  }
}
