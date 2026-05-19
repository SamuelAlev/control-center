import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_page.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_kind.dart';

/// A space message paired with its embedding vector bytes.
class EmbeddedMessage {
  /// Creates an [EmbeddedMessage].
  EmbeddedMessage({required this.message, required this.embedding});

  /// The domain message entity.
  final Message message;

  /// Raw embedding bytes (Float32List stored as Uint8List view).
  final Uint8List embedding;
}

/// Repository interface for messaging spaces.
///
/// **Conversations invariant:** a space holds flat, co-equal conversations and
/// **every conversation owns its own uuid** — a conversation id is NEVER the
/// space id. Code holding only a `spaceId` omits the `conversationId` and gets
/// the space's STANDING conversation: its oldest active one, minted UNTITLED
/// when the space has none (the title model names it from its first human
/// message).
///
/// **Workspace invariant:** every operation takes the `workspaceId` that owns
/// the space. Space, conversation and message ids are uuids, but a uuid is
/// not an access boundary: the workspace scopes the lookup, so an id from
/// another workspace is simply not found rather than read or written.
/// [watchSpaces] is the single documented exception.
abstract class MessagingRepository {
  /// CROSS-WORKSPACE BY DESIGN: every space the server knows about, for the
  /// dashboard's all-spaces view. Workspace-scoped surfaces use
  /// [watchSpacesByWorkspace].
  Stream<List<Space>> watchSpaces();

  /// Watches participants for [spaceId] within [workspaceId].
  Stream<List<SpaceParticipant>> watchParticipants(
    String workspaceId,
    String spaceId,
  );

  /// Watches the messages of one conversation (stream) inside a space.
  Stream<List<Message>> watchMessages(
    String workspaceId,
    String spaceId,
    String conversationId,
  );

  /// Watches every message in [spaceId], across ALL of its conversations.
  ///
  /// The streaming twin of [getSpaceMessages], and it exists for the same
  /// reason: the review surfaces (the accordion, the verdict banner) render
  /// findings filed by several reviewers, each in its own stream, and watching
  /// one conversation shows one reviewer's.
  ///
  /// Defaults to the standing conversation so an implementation without a
  /// space-wide subscription still streams something; both shipped
  /// implementations override it.
  Stream<List<Message>> watchSpaceMessages(String workspaceId, String spaceId);

  /// Watches spaces for a specific workspace.
  Stream<List<Space>> watchSpacesByWorkspace(String workspaceId);

  /// Watches the newest [limit] messages of a conversation (ascending for
  /// display), plus whether older messages exist beyond the window.
  Stream<({List<Message> messages, bool hasMore})> watchMessagesWindow(
    String workspaceId,
    String spaceId,
    String conversationId, {
    required int limit,
  });

  /// Loads one cursor-based page of a conversation's history (oldest-first for
  /// display). Pass a prior page's [MessagePage.nextCursor] as [cursor] to load
  /// the page before it. The page is backfilled to a turn boundary so it never
  /// begins mid-exchange.
  Future<MessagePage> getMessagePage(
    String workspaceId,
    String spaceId,
    String conversationId, {
    int limit = defaultMessagePageSize,
    String? cursor,
  });

  /// Returns a single message by id within [workspaceId], or null.
  Future<Message?> getMessageById(String workspaceId, String messageId);

  /// One space by id within [workspaceId], or null. Host-side loader for the
  /// sync delta feed; remote adapters may not support it.
  Future<Space?> getSpaceById(String workspaceId, String spaceId);

  /// Creates a space in [workspaceId] with zero or more agents. The optional
  /// [mode] sets the conversation mode at creation time so the dispatch pipeline
  /// picks it up on the first message (avoids a race with [setSpaceMode]).
  /// [createdByUserId] records the creating human as a participant; system-
  /// created spaces (pipelines) pass null and human rows are added lazily on
  /// first open.
  /// [repoIds] optionally scopes which of the workspace's repos this space's
  /// conversation worktree provisions. Null (the default) means all workspace
  /// repos, preserving pre-selection behaviour; an EMPTY list means the space
  /// explicitly checks out no repos at all.
  /// [repoBranches] pins a selected repo's worktree to the branch it is cut
  /// from, keyed by repo id. A repo absent from the map takes its own default
  /// branch. It is the BASE, not the working branch: the worktree still gets
  /// its own branch cut from here, so nothing an agent commits lands on it.
  Future<Space> createSpace(
    String workspaceId,
    String name,
    List<String> agentIds, {
    Mode mode = Mode.chat,
    String? pipelineRunId,
    String? createdByUserId,
    SpaceKind kind = SpaceKind.topic,
    List<String>? repoIds,
    Map<String, String>? repoBranches,
  });

  /// Updates the [Mode] for a space within [workspaceId].
  Future<void> setSpaceMode(String workspaceId, String spaceId, Mode mode);

  /// Whether [spaceId] exists in [workspaceId].
  Future<bool> spaceExists(String workspaceId, String spaceId);

  /// Adds a participant (agent by default, or a human user) to a space.
  Future<void> addParticipant(
    String workspaceId,
    String spaceId,
    String principalId, {
    PrincipalType participantType = PrincipalType.agent,
  });

  /// Gets current participants for [spaceId] within [workspaceId].
  Future<List<SpaceParticipant>> getParticipants(
    String workspaceId,
    String spaceId,
  );

  /// Sends a message to a conversation inside a space. Returns the message ID.
  /// [conversationId] defaults to the space's STANDING conversation — its
  /// oldest active one, minted untitled when the space has none.
  Future<String> sendMessage({
    required String workspaceId,
    required String spaceId,
    required String content,
    required String senderId,
    required String senderType,
    String? conversationId,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    String? id,
  });

  /// Updates an existing message. [idempotencyKey] (PRD 19 §3) dedupes retries
  /// of one logical edit — including an undo/redo inverse — server-side.
  /// [messageType] (snake_case wire value) rewrites the row's type; the
  /// steering queue uses it for the run-end steering → text conversion.
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
    String? messageType,
    String? idempotencyKey,
  });

  /// Inserts a queued steering message into [conversationId].
  ///
  /// Unlike [sendMessage] this does NOT advance the conversation's leaf and
  /// does not bump the space's `updated_at`: a steering row annotates a
  /// running turn rather than being one, so the branch tree and sidebar
  /// ordering must not react to it. The row hangs off the leaf as it was at
  /// insert time and nothing ever points back to it, which is what makes
  /// [deleteSteeringMessage] a plain delete.
  Future<String> insertSteeringMessage({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String content,
    required String senderId,
    required Map<String, dynamic> metadata,
    String? id,
  });

  /// Hard-deletes a steering message. Only safe for steering rows (they never
  /// become the leaf, so no parent chain crosses them); the caller is
  /// responsible for having checked the row's type and state first.
  Future<void> deleteSteeringMessage(
    String workspaceId,
    String messageId,
  );

  /// Gets all (non-reverted) messages for a conversation. [conversationId]
  /// defaults to the space's STANDING conversation (its oldest active one) —
  /// an agent run only ever sees its own conversation's history.
  Future<List<Message>> getMessages(
    String workspaceId,
    String spaceId, {
    String? conversationId,
  });

  /// Gets all (non-reverted) messages in [spaceId] across EVERY conversation
  /// it holds, in creation order.
  ///
  /// [getMessages] answers "what has this thread said", which is what an agent
  /// run needs. This answers "what has happened in this room", which is what a
  /// space-wide reader needs — the PR review surface above all: a finding
  /// belongs to the pull request, not to the thread the reviewer who filed it
  /// happened to be working in, so gathering findings from the standing
  /// conversation alone silently loses every one filed in a reviewer's own
  /// stream.
  ///
  /// Defaults to [getMessages] so an implementation that has no space-wide
  /// query still answers something sensible; the server's DAO-backed
  /// implementation overrides it with the real thing.
  Future<List<Message>> getSpaceMessages(String workspaceId, String spaceId) =>
      getMessages(workspaceId, spaceId);

  /// Full-text search within a single space: returns live (non-reverted)
  /// messages whose content matches [query], best-match first (newest for
  /// ties), capped at [limit]. An empty/stopword-only query returns nothing.
  Future<List<Message>> searchInSpace(
    String workspaceId,
    String spaceId,
    String query, {
    int limit,
  });

  /// Marks messages as compacted within [workspaceId].
  Future<void> markCompacted(String workspaceId, List<String> ids);

  /// Reverts (rolls back) the live conversation to [messageId]: every message
  /// after it is hidden (and the message itself when [inclusive]). Reverted
  /// messages are kept so [unrevertConversation] can restore them. Returns the
  /// ids that were reverted.
  Future<List<String>> revertConversationTo(
    String workspaceId,
    String spaceId,
    String messageId, {
    bool inclusive = false,
  });

  /// Restores the most-recently-reverted batch (undo a revert). Returns the
  /// restored ids, or empty when there is nothing to restore.
  Future<List<String>> unrevertConversation(String workspaceId, String spaceId);

  /// The conversation's whole branch tree.
  Future<ConversationTree> conversationTree({
    required String workspaceId,
    required String conversationId,
  });

  /// Points the conversation at [messageId], so the next message continues
  /// from there.
  ///
  /// **Writes nothing but a pointer.** That is the entire session-tree design:
  /// branching does not delete, hide or copy anything, so the path you left is
  /// still there and switching back is another pointer move. Editing a prompt
  /// and re-running stops costing you the answer you were comparing against.
  Future<void> branchConversationAt({
    required String workspaceId,
    required String conversationId,
    required String messageId,
  });

  /// Copies the branch ending at [messageId] into a NEW conversation in the
  /// same space, and returns its id.
  ///
  /// A copy rather than a pointer, unlike [branchConversationAt], because the
  /// point of a fork is to take the work somewhere else: two conversations
  /// that share rows would show each other's later messages.
  Future<String> forkConversation({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    String? messageId,
    String? title,
  });

  /// Deletes a space and all its data.
  Future<void> deleteSpace(String workspaceId, String spaceId);

  /// Archives a space within [workspaceId]: a soft hide that keeps every
  /// message, participant and worktree, stamped with the archive time. The
  /// space leaves the sidebar, the space-activity feed and agent-facing space
  /// lists until [unarchiveSpace] restores it.
  Future<void> archiveSpace(String workspaceId, String spaceId);

  /// Restores an archived space within [workspaceId] (clears the archive
  /// stamp). A no-op on a space that is not archived.
  Future<void> unarchiveSpace(String workspaceId, String spaceId);

  /// Updates a space's name.
  Future<void> updateSpaceName(String workspaceId, String spaceId, String name);

  /// The space's effective repo selection, in `createSpace`'s `repoIds`
  /// contract: null → all workspace repos (the default), an EMPTY list →
  /// explicitly no repos, a subset → those repos.
  Future<List<String>?> spaceRepoSelection(String workspaceId, String spaceId);

  /// The base branch each of the space's repos is cut from, keyed by repo id.
  /// Repos that take their own default branch are absent from the map.
  Future<Map<String, String>> spaceRepoBranches(
    String workspaceId,
    String spaceId,
  );

  /// Replaces a space's repo selection (same contract as
  /// [spaceRepoSelection]). Repo ids are validated against the workspace
  /// (a foreign or unknown id is refused, never persisted). Persisting the
  /// selection is all this does — tearing down the worktrees a deselection
  /// orphans is the provisioner's job (`releaseSpaceReposOutside`), driven by
  /// the caller.
  Future<void> setSpaceRepos(
    String workspaceId,
    String spaceId,
    List<String>? repoIds,
  );

  /// Clears all messages from a space.
  Future<void> clearSpaceMessages(String workspaceId, String spaceId);

  /// Removes a participant (agent or user) from a space.
  Future<void> removeParticipant(
    String workspaceId,
    String spaceId,
    String principalId,
  );

  /// Updates the embedding vector for a message.
  Future<void> updateMessageEmbedding(
    String workspaceId,
    String messageId,
    Uint8List embedding,
  );

  /// Gets messages with non-null embeddings for a space.
  Future<List<EmbeddedMessage>> getMessagesWithEmbedding(
    String workspaceId,
    String spaceId,
  );

  /// Gets messages without embeddings for backfill (text/system only), within
  /// [workspaceId]. The backfill runs one workspace at a time so each embedding
  /// is written back to the file its message came from.
  Future<List<Message>> getMessagesWithoutEmbedding(
    String workspaceId, {
    int limit = 200,
  });
}
