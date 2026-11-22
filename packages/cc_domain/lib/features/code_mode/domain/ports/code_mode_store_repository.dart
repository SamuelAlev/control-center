import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_store_write.dart';

/// Durable `store(key, value)` / `load(key)` values, per conversation and
/// agent, in the workspace database.
///
/// Every method takes the workspace explicitly and resolves its database per
/// call. Values are JSON text, so every size check counts exactly the bytes
/// that are stored.
abstract interface class CodeModeStoreRepository {
  /// Every stored value of [agentId] in [conversationId], key to JSON text.
  /// Empty when nothing is stored.
  Future<Map<String, String>> readAll(
    String workspaceId, {
    required String conversationId,
    required String agentId,
  });

  /// Applies [writes] atomically: all of them or none.
  ///
  /// Runs [CodeModeStoreRules.apply] against the values stored at commit
  /// time, inside the same transaction, so two scripts of the same agent
  /// committing at once cannot together pass the total cap. Throws the
  /// `ValidationException` that check throws when a cap would be broken.
  /// `rewind` does not undo a commit.
  Future<void> commit(
    String workspaceId, {
    required String conversationId,
    required String agentId,
    required List<CodeModeStoreWrite> writes,
  });
}
