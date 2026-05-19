import 'package:cc_domain/core/domain/ports/git_snapshot_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_infra/src/git/process_git_snapshot_adapter.dart';
import 'package:cc_infra/src/messaging/agent_working_directory.dart';
import 'package:cc_infra/src/messaging/conversation_checkpoint_service.dart';

/// Host-side glue that makes a conversation revert/unrevert (undo/redo)
/// self-contained: it resolves the conversation's worktree from the DB (the
/// space's agent participant's working directory) and runs the
/// [ConversationCheckpointService] so the revert rolls back BOTH the transcript
/// and — when the host owns the checkout and the turn carries a git snapshot —
/// the worktree filesystem.
///
/// Lives here (not in the catalog) so every host that owns the messaging DB +
/// the agent checkouts (the spawned cc_server and the desktop's self-serve
/// in-process host) wires the SAME behaviour from one tested place. The worktree
/// path is resolved exactly as dispatch resolves it for snapshot capture
/// ([workingDirectoryFromAgentMdPath] over `agent.agentMdPath`), so restore
/// targets the same git object store the snapshot was written into.
class ConversationCheckpointCoordinator {
  /// Creates a [ConversationCheckpointCoordinator].
  ///
  /// [git] defaults to the process `git` adapter (the only snapshot backend);
  /// inject a fake in tests.
  ConversationCheckpointCoordinator({
    required MessagingRepository messaging,
    required AgentRepository agents,
    GitSnapshotPort git = const ProcessGitSnapshotAdapter(),
  }) : _messaging = messaging,
       _agents = agents,
       _service = ConversationCheckpointService(repo: messaging, git: git);

  final MessagingRepository _messaging;
  final AgentRepository _agents;
  final ConversationCheckpointService _service;

  /// Reverts [spaceId] to [messageId] (undo) within [workspaceId]. Resolves
  /// the conversation's
  /// worktree so the filesystem is rolled back too; a worktree that can't be
  /// resolved (no agent participant, a `/tmp` placeholder, or a multi-agent room
  /// whose snapshot belongs to another agent's checkout) degrades to a
  /// transcript-only revert (the service swallows a failed git restore).
  Future<RevertOutcome> revertTo({
    required String workspaceId,
    required String spaceId,
    required String messageId,
    bool inclusive = false,
  }) async {
    final worktreePath = await _resolveWorktree(workspaceId, spaceId);
    return _service.revertTo(
      workspaceId: workspaceId,
      spaceId: spaceId,
      messageId: messageId,
      worktreePath: worktreePath,
      inclusive: inclusive,
    );
  }

  /// Undoes the most-recent revert (redo) in [workspaceId] — conversation-only,
  /// the filesystem is not re-applied.
  Future<RevertOutcome> unrevert({
    required String workspaceId,
    required String spaceId,
  }) => _service.unrevert(workspaceId: workspaceId, spaceId: spaceId);

  /// The conversation's worktree path: the working directory of the first
  /// non-user agent participant that resolves to a real checkout (not the `/tmp`
  /// placeholder). Null when none resolves — the revert then runs transcript
  /// only.
  Future<String?> _resolveWorktree(String workspaceId, String spaceId) async {
    final participants = await _messaging.getParticipants(workspaceId, spaceId);
    for (final participant in participants) {
      if (participant.isUser) {
        continue;
      }
      final agent = await _agents.getById(workspaceId, participant.principalId);
      if (agent == null) {
        continue;
      }
      final path = workingDirectoryFromAgentMdPath(agent.agentMdPath);
      if (path != '/tmp') {
        return path;
      }
    }
    return null;
  }
}
