import 'package:cc_domain/cc_domain.dart' show UndoClass, newIdempotencyKey;
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:control_center/core/undo/action_journal.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Edits and soft-deletes user messages over RPC (§8.3).
///
/// Both go through the server's `messaging.updateMessage` op (which validates
/// the message's space belongs to the caller's workspace before mutating).
/// Metadata is merged copy-on-write via the entity helpers so the edit/delete
/// stamps never clobber the transcript, feedback, or turn metrics.
class MessageEditController {
  /// Creates the controller.
  MessageEditController(this._ref);

  final Ref _ref;

  /// Replaces [message]'s content with [newContent] and stamps `editedAt`.
  /// A no-op when the trimmed text is empty or unchanged. Returns whether an
  /// edit was written.
  ///
  /// When [undoLabel] is supplied, the edit is recorded in the [ActionJournal]
  /// so `⌘Z` restores the prior text (PRD 19 §4/§5); the edit and its inverse
  /// each carry a fresh idempotency key.
  Future<bool> edit(
    Message message,
    String newContent, {
    String? undoLabel,
  }) async {
    final trimmed = newContent.trim();
    if (trimmed.isEmpty || trimmed == message.content) {
      return false;
    }
    final repo = _ref.read(messagingRepositoryProvider);
    final previous = message.content;
    Map<String, dynamic> stamp() => message.metadataWithEdited(
      atEpochMs: DateTime.now().millisecondsSinceEpoch,
    );
    await repo.updateMessage(
      _ref.requireWorkspaceId(),
      message.id,
      content: trimmed,
      metadata: stamp(),
      idempotencyKey: newIdempotencyKey(),
    );
    if (undoLabel != null) {
      _ref
          .read(actionJournalProvider.notifier)
          .record(
            UndoableAction(
              label: undoLabel,
              undoClass: UndoClass.reversible,
              undo: () => repo.updateMessage(
                _ref.requireWorkspaceId(),
                message.id,
                content: previous,
                metadata: stamp(),
                idempotencyKey: newIdempotencyKey(),
              ),
              redo: () => repo.updateMessage(
                _ref.requireWorkspaceId(),
                message.id,
                content: trimmed,
                metadata: stamp(),
                idempotencyKey: newIdempotencyKey(),
              ),
            ),
          );
    }
    return true;
  }

  /// Soft-deletes [message]: stamps `deletedAt` (the row + content are kept for
  /// audit/undo; the UI renders a placeholder). Idempotent.
  Future<void> softDelete(Message message) async {
    if (message.isDeleted) {
      return;
    }
    await _ref
        .read(messagingRepositoryProvider)
        .updateMessage(
          _ref.requireWorkspaceId(),
          message.id,
          metadata: message.metadataWithDeleted(
            atEpochMs: DateTime.now().millisecondsSinceEpoch,
          ),
        );
  }
}

/// Provides the [MessageEditController].
final messageEditControllerProvider = Provider<MessageEditController>(
  MessageEditController.new,
);
