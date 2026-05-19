import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_token_totals.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_cursor.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_page.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_activity.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_kind.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_harness/context.dart' show TokenEstimator;
import 'package:cc_persistence/database/cross_workspace_queries.dart';
import 'package:cc_persistence/database/daos/conversation_dao.dart';
import 'package:cc_persistence/database/daos/messaging_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/messaging_mapper.dart';
import 'package:cc_persistence/repositories/distinct_rows.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

/// Drift DAO-backed implementation of [MessagingRepository].
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).messagingDao` per call: spaces, conversations,
/// participants and messages all live in the workspace's own database file, so
/// the workspace id picks the file before any SQL runs. [watchSpaces] is the
/// one read that spans files.
class DaoMessagingRepository implements MessagingRepository {
  /// Creates a [DaoMessagingRepository] over the per-workspace databases.
  DaoMessagingRepository(this._dbs) : _cross = CrossWorkspaceQueries(_dbs);

  final WorkspaceDatabaseManager _dbs;
  final CrossWorkspaceQueries _cross;
  final MessagingMapper _mapper = const MessagingMapper();
  final _uuid = const Uuid();

  MessagingDao _dao(String workspaceId) => _dbs.of(workspaceId).messagingDao;
  ConversationDao _conversations(String workspaceId) =>
      _dbs.of(workspaceId).conversationDao;

  /// Suppresses value-identical re-emissions of a drift watch. Shared with
  /// the other hot list watches — see `distinct_rows.dart` for why.
  Stream<List<T>> _distinctRows<T>(Stream<List<T>> source) =>
      distinctRows(source);

  /// Newest-activity-first, the order the space list is displayed in. Applied
  /// to the merged cross-workspace list, which concatenation would otherwise
  /// leave interleaved by workspace.
  static int _newestFirst(SpacesTableData a, SpacesTableData b) =>
      b.updatedAt.compareTo(a.updatedAt);

  /// CROSS-WORKSPACE BY DESIGN: the dashboard's all-spaces view, which is
  /// defined over every workspace. Workspace-scoped surfaces use
  /// [watchSpacesByWorkspace].
  @override
  Stream<List<Space>> watchSpaces() => _cross
      .mergeStreams((db) => db.messagingDao.watchSpaces(), sort: _newestFirst)
      .map(_mapper.spacesToDomain);

  @override
  Stream<List<SpaceParticipant>> watchParticipants(
    String workspaceId,
    String spaceId,
  ) => _dao(
    workspaceId,
  ).watchParticipants(spaceId).map(_mapper.participantsToDomain);

  @override
  Stream<List<Space>> watchSpacesByWorkspace(String workspaceId) => _dao(
    workspaceId,
  ).watchSpacesByWorkspace(workspaceId).map(_mapper.spacesToDomain);

  @override
  Stream<List<Message>> watchMessages(
    String workspaceId,
    String spaceId,
    String conversationId,
  ) => _distinctRows(
    _dao(workspaceId).watchMessages(conversationId),
  ).map(_mapper.messagesToDomain);

  @override
  Stream<({List<Message> messages, bool hasMore})> watchMessagesWindow(
    String workspaceId,
    String spaceId,
    String conversationId, {
    required int limit,
  }) =>
      _distinctRows(
        _dao(workspaceId).watchMessagesWindow(conversationId, limit: limit),
      ).map((rows) {
        final hasMore = rows.length > limit;
        // Rows are ascending (oldest-first); the extra hasMore row is the
        // oldest, so trim from the front to keep the newest `limit`.
        final windowRows = hasMore ? rows.sublist(rows.length - limit) : rows;
        return (
          messages: _mapper.messagesToDomain(windowRows),
          hasMore: hasMore,
        );
      });

  /// The size of a conversation's live region, computed in SQL. NOT part of
  /// [MessagingRepository] — like [watchSpaceActivity] it is a server-only
  /// read-model projection, reached over `messaging.watchConversationTokens`
  /// and consumed through `MessagingSummariesPort`.
  Stream<ConversationTokenTotals> watchConversationTokens(
    String workspaceId,
    String spaceId,
    String conversationId,
  ) {
    const estimator = TokenEstimator.instance;
    return _dao(workspaceId)
        .watchConversationCharCounts(conversationId)
        .map((rows) {
          var tokens = 0;
          var chars = 0;
          for (final row in rows) {
            // Mirrors `ConversationTokenEstimate.estimateMessage`: an agent turn is
            // measured by its transcript (the answer text is a fraction of what the
            // turn actually carries), everything else by its content.
            final counted =
                row.messageType == 'agent_turn' && row.transcriptChars > 0
                ? row.transcriptChars
                : row.contentChars;
            tokens += estimator.estimateChars(counted);
            chars += row.contentChars;
          }
          return ConversationTokenTotals(tokens: tokens, chars: chars);
        })
        // The subscription re-runs on ANY write to `conversation_messages`,
        // including ones that move neither number (a reaction, a read cursor, a
        // message in a sibling conversation). Two ints have value equality, so
        // this drops every emission that would have rebuilt the meter for a
        // reading it was already showing.
        .distinct();
  }

  /// Per-space activity signals for [workspaceId], computed in SQL. NOT
  /// part of [MessagingRepository]: server-only projection behind
  /// `messaging.watchSpaceActivity`.
  Stream<List<SpaceActivity>> watchSpaceActivity(String workspaceId) =>
      _distinctRows(_dao(workspaceId).watchSpaceActivity(workspaceId)).map(
        (rows) => [
          for (final row in rows)
            SpaceActivity(
              spaceId: row.spaceId,
              lastMessageAt: row.lastMessageAt,
              lastAgentMessageAt: row.lastAgentMessageAt,
              openQuestionCount: row.openQuestionCount,
            ),
        ],
      );

  @override
  Future<Message?> getMessageById(String workspaceId, String messageId) async {
    final row = await _dao(workspaceId).getMessageById(messageId);
    if (row == null) {
      return null;
    }
    return _mapper.messageToDomain(row);
  }

  @override
  Future<Space?> getSpaceById(String workspaceId, String spaceId) async {
    final row = await _dao(workspaceId).getSpaceById(spaceId);
    if (row == null) {
      return null;
    }
    return _mapper.spaceToDomain(row);
  }

  @override
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
  }) async {
    final id = _uuid.v4();
    final dao = _dao(workspaceId);
    return dao.transaction(() async {
      await dao.insertSpace(
        SpacesTableCompanion(
          id: drift.Value(id),
          name: drift.Value(name),
          mode: drift.Value(mode.toDbValue()),
          kind: drift.Value(kind.wire),
          // New spaces start provisioning; the background provisioner flips
          // this to `ready` (or `failed`). Spaces with no repos/agents short-
          // circuit to `ready` immediately.
          provisioningStatus: drift.Value(
            SpaceProvisioningStatus.provisioning.toDbValue(),
          ),
          workspaceId: drift.Value(workspaceId),
          pipelineRunId: pipelineRunId != null
              ? drift.Value(pipelineRunId)
              : const drift.Value.absent(),
          // An EXPLICITLY empty selection ("check out nothing") gets its own
          // flag — `space_repos` holding no rows already means "all repos".
          noRepos: drift.Value(repoIds != null && repoIds.isEmpty),
        ),
      );
      // No seeded conversation: the standing one is minted lazily by
      // ConversationDao.ensureStandingConversation on first use — there is no
      // main-conversation id aliasing.
      if (createdByUserId != null) {
        await dao.insertParticipant(
          SpaceParticipantsTableCompanion(
            id: drift.Value(_uuid.v4()),
            spaceId: drift.Value(id),
            principalId: drift.Value(createdByUserId),
            participantType: const drift.Value('user'),
          ),
        );
      }
      for (final agentId in agentIds) {
        await dao.insertParticipant(
          SpaceParticipantsTableCompanion(
            id: drift.Value(_uuid.v4()),
            spaceId: drift.Value(id),
            principalId: drift.Value(agentId),
            participantType: const drift.Value('agent'),
          ),
        );
      }

      // Record the per-space repo selection. Null → no selection (all repos,
      // no rows); empty → "no repos", carried by the `noRepos` flag above.
      if (repoIds != null && repoIds.isNotEmpty) {
        // Isolation chokepoint: a repo id only exists inside its own
        // workspace's database file, so refuse any id not registered here
        // instead of persisting a dangling — or cross-workspace — selection.
        final repoDao = _dbs.of(workspaceId).repoDao;
        for (final repoId in repoIds) {
          if (!await repoDao.exists(repoId)) {
            throw ValidationException(
              'Repo $repoId does not belong to workspace $workspaceId.',
            );
          }
        }
        await _dbs
            .of(workspaceId)
            .spaceRepoDao
            .setReposForSpace(
              workspaceId: workspaceId,
              spaceId: id,
              repoIds: repoIds,
              branches: repoBranches ?? const {},
            );
      }

      final row = await dao.getSpaceById(id);
      if (row == null) {
        throw StateError('Failed to create space');
      }
      return _mapper.spaceToDomain(row);
    });
  }

  @override
  Future<bool> spaceExists(String workspaceId, String spaceId) async =>
      await _dao(workspaceId).getSpaceById(spaceId) != null;

  @override
  Future<void> addParticipant(
    String workspaceId,
    String spaceId,
    String principalId, {
    PrincipalType participantType = PrincipalType.agent,
  }) async {
    await _dao(workspaceId).insertParticipant(
      SpaceParticipantsTableCompanion(
        id: drift.Value(_uuid.v4()),
        spaceId: drift.Value(spaceId),
        principalId: drift.Value(principalId),
        participantType: drift.Value(participantType.wireName),
      ),
    );
  }

  @override
  Future<List<SpaceParticipant>> getParticipants(
    String workspaceId,
    String spaceId,
  ) async {
    final rows = await _dao(workspaceId).getParticipants(spaceId);
    return _mapper.participantsToDomain(rows);
  }

  @override
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
  }) async {
    final messageId = id ?? _uuid.v4();
    final dao = _dao(workspaceId);
    // Default to the space's standing conversation (oldest active; minted
    // untitled and uuid-keyed when none exists yet). No main-id aliasing.
    //
    // The workspace MUST be stamped on the minted row: a `conversations` row
    // with a null `workspace_id` is invisible to `ConversationDao.listForSpace`
    // and the sync trigger fires only `WHEN NEW.workspace_id IS NOT NULL`.
    final convId =
        conversationId ??
        await _conversations(workspaceId).ensureStandingConversation(
          workspaceId: workspaceId,
          spaceId: spaceId,
        );
    // ONE transaction for the whole send. These three writes used to
    // auto-commit separately: three fsyncs and three rounds of trigger +
    // watch-subscriber invalidation per message, and an agent streaming
    // replies multiplies it. They are also logically atomic — a message that
    // landed without its space's `updated_at` bump sorts wrong in the
    // sidebar until the next write.
    await dao.transaction(() async {
      // The new message continues the branch the conversation is currently
      // on, and becomes its tip. Reading the leaf INSIDE the transaction is
      // what makes two concurrent sends produce a chain rather than two
      // siblings that both claim to be last.
      final parentId = await dao.currentLeaf(convId);
      await dao.insertMessage(
        ConversationMessagesTableCompanion(
          id: drift.Value(messageId),
          spaceId: drift.Value(spaceId),
          conversationId: drift.Value(convId),
          senderId: drift.Value(senderId),
          senderType: drift.Value(senderType),
          content: drift.Value(content),
          messageType: drift.Value(messageType),
          metadata: drift.Value(metadata != null ? jsonEncode(metadata) : null),
          parentMessageId: drift.Value(parentId),
        ),
      );
      await dao.setLeaf(convId, messageId);
      await dao.updateSpaceUpdatedAt(spaceId, DateTime.now());
    });
    return messageId;
  }

  @override
  Future<String> insertSteeringMessage({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String content,
    required String senderId,
    required Map<String, dynamic> metadata,
    String? id,
  }) async {
    final messageId = id ?? _uuid.v4();
    final dao = _dao(workspaceId);
    // Deliberately NOT the sendMessage shape: no setLeaf (a steering row
    // annotates the running turn; it must not become the branch tip) and no
    // space updated_at bump (queue chatter must not reorder the sidebar).
    // Hanging the row off the CURRENT leaf keeps it inside the branch it was
    // written in for tree inspection, without anything ever pointing to it.
    final parentId = await dao.currentLeaf(conversationId);
    await dao.insertMessage(
      ConversationMessagesTableCompanion(
        id: drift.Value(messageId),
        spaceId: drift.Value(spaceId),
        conversationId: drift.Value(conversationId),
        senderId: drift.Value(senderId),
        senderType: const drift.Value('user'),
        content: drift.Value(content),
        messageType: const drift.Value('steering'),
        metadata: drift.Value(jsonEncode(metadata)),
        parentMessageId: drift.Value(parentId),
      ),
    );
    return messageId;
  }

  @override
  Future<void> deleteSteeringMessage(
    String workspaceId,
    String messageId,
  ) async {
    await _dao(workspaceId).deleteMessageById(messageId);
  }

  @override
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
    // Rewrites the message's TYPE (snake_case wire value) — used by the
    // steering queue's run-end conversion (steering → text). Null leaves it.
    String? messageType,
    // Dedup happens at the RPC dispatcher's write ledger before this handler
    // runs (PRD 19 §3); the DAO write itself needs no key.
    String? idempotencyKey,
  }) => _dao(workspaceId).updateMessage(
    messageId,
    content: content,
    metadata: metadata,
    messageType: messageType,
  );

  /// Idempotently resolves (minting when absent) the space's standing
  /// conversation id — exposed for callers that key a stream before their
  /// first message exists.
  Future<String> ensureStandingConversation(
    String workspaceId,
    String spaceId,
  ) => _conversations(
    workspaceId,
  ).ensureStandingConversation(workspaceId: workspaceId, spaceId: spaceId);

  @override
  Future<List<Message>> getMessages(
    String workspaceId,
    String spaceId, {
    String? conversationId,
  }) async {
    final convId =
        conversationId ??
        await _conversations(workspaceId).ensureStandingConversation(
          workspaceId: workspaceId,
          spaceId: spaceId,
        );
    final rows = await _dao(workspaceId).getMessages(convId);
    return _mapper.messagesToDomain(rows);
  }

  @override
  Future<List<Message>> getSpaceMessages(
    String workspaceId,
    String spaceId,
  ) async {
    final rows = await _dao(workspaceId).getMessagesForSpace(spaceId);
    return _mapper.messagesToDomain(rows);
  }

  @override
  Stream<List<Message>> watchSpaceMessages(
    String workspaceId,
    String spaceId,
  ) => _dao(
    workspaceId,
  ).watchMessagesForSpace(spaceId).map(_mapper.messagesToDomain);

  @override
  Future<List<Message>> searchInSpace(
    String workspaceId,
    String spaceId,
    String query, {
    int limit = 50,
  }) async {
    final rows = await _dao(
      workspaceId,
    ).searchInSpace(spaceId, query, limit: limit);
    return _mapper.messagesToDomain(rows);
  }

  /// Max extra messages pulled to back the page up to a user-message boundary,
  /// so a loaded page never begins mid-exchange (the assistant-boundary
  /// backfill, capped to avoid loading a whole runaway turn).
  static const int _backfillCap = 20;

  @override
  Future<MessagePage> getMessagePage(
    String workspaceId,
    String spaceId,
    String conversationId, {
    int limit = defaultMessagePageSize,
    String? cursor,
  }) async {
    final dao = _dao(workspaceId);
    final decoded = MessageCursor.decode(cursor);
    // Fetch one extra to detect whether older history remains.
    final rows = await dao.getMessagePageRows(
      spaceId,
      conversationId,
      limit: limit + 1,
      beforeCreatedAtSeconds: decoded == null
          ? null
          : decoded.createdAtMs ~/ 1000,
      beforeRowid: decoded?.rowid,
    );

    var hasMore = rows.length > limit;
    var page = hasMore ? rows.sublist(0, limit) : rows;

    // Backfill: if the oldest row in the page is an agent message, pull older
    // rows until we reach a user message (turn start) or the cap.
    if (hasMore && page.isNotEmpty && page.last.data.senderType != 'user') {
      final oldest = page.last;
      final extra = await dao.getMessagePageRows(
        spaceId,
        conversationId,
        limit: _backfillCap + 1,
        beforeCreatedAtSeconds:
            oldest.data.createdAt.millisecondsSinceEpoch ~/ 1000,
        beforeRowid: oldest.rowid,
      );
      final taken = <({ConversationMessagesTableData data, int rowid})>[];
      for (final r in extra.take(_backfillCap)) {
        taken.add(r);
        if (r.data.senderType == 'user') {
          break;
        }
      }
      page = [...page, ...taken];
      // hasMore reflects whether anything remains before the backfilled tail.
      hasMore = extra.length > taken.length;
    }

    String? nextCursor;
    if (hasMore && page.isNotEmpty) {
      final boundary = page.last;
      nextCursor = MessageCursor(
        createdAtMs: boundary.data.createdAt.millisecondsSinceEpoch,
        rowid: boundary.rowid,
      ).encode();
    }

    // Rows are newest-first; reverse for oldest-first display.
    final messages = page.reversed
        .map((r) => _mapper.messageToDomain(r.data))
        .toList(growable: false);
    return MessagePage(
      messages: messages,
      hasMore: hasMore,
      nextCursor: nextCursor,
    );
  }

  @override
  Future<void> markCompacted(String workspaceId, List<String> ids) =>
      _dao(workspaceId).markCompacted(ids);

  @override
  Future<List<String>> revertConversationTo(
    String workspaceId,
    String spaceId,
    String messageId, {
    bool inclusive = false,
  }) async {
    final dao = _dao(workspaceId);
    // Resolve the space's standing conversation — no main-id aliasing.
    final convId = await _conversations(
      workspaceId,
    ).ensureStandingConversation(workspaceId: workspaceId, spaceId: spaceId);
    // getMessages already returns only live (non-reverted) messages in order.
    final live = await dao.getMessages(convId);
    final targetIndex = live.indexWhere((m) => m.id == messageId);
    if (targetIndex < 0) {
      return const [];
    }
    final from = inclusive ? targetIndex : targetIndex + 1;
    final toRevert = live.sublist(from).map((m) => m.id).toList();
    if (toRevert.isEmpty) {
      return const [];
    }
    await dao.revertMessages(toRevert, DateTime.now().millisecondsSinceEpoch);
    // The branch tip moves with the revert. Without this the next message
    // would still take the reverted tail as its parent, so the tree would
    // record a lineage the conversation no longer shows — and `/tree` would
    // draw a branch nobody made.
    await dao.setLeaf(
      convId,
      inclusive
          ? (targetIndex > 0 ? live[targetIndex - 1].id : null)
          : messageId,
    );
    return toRevert;
  }

  @override
  Future<List<String>> unrevertConversation(
    String workspaceId,
    String spaceId,
  ) async {
    final dao = _dao(workspaceId);
    // The batch lookup is space-scoped by design (messages carry space_id).
    final batch = await dao.getLatestRevertedBatch(spaceId);
    if (batch.isEmpty) {
      return const [];
    }
    await dao.unrevertMessages(batch);
    return batch;
  }

  @override
  Future<ConversationTree> conversationTree({
    required String workspaceId,
    required String conversationId,
  }) async {
    final dao = _dao(workspaceId);
    final rows = await dao.allMessagesForTree(conversationId);
    final leaf = await dao.currentLeaf(conversationId);

    final childCounts = <String, int>{};
    final hasChild = <String>{};
    for (final row in rows) {
      final parent = row.parentMessageId;
      if (parent != null) {
        childCounts[parent] = (childCounts[parent] ?? 0) + 1;
        hasChild.add(parent);
      }
    }
    final onBranch = <String>{};
    if (leaf != null) {
      for (final row in await dao.branchFrom(conversationId, leaf)) {
        onBranch.add(row.id);
      }
    }
    // A leaf is a message nothing continues from. Counting them is how many
    // distinct paths the conversation holds, which is the one number a
    // navigator needs before it decides whether to appear at all.
    final leaves = rows.where((r) => !hasChild.contains(r.id)).length;

    return ConversationTree(
      nodes: [
        for (final row in rows)
          ConversationTreeNode(
            messageId: row.id,
            parentMessageId: row.parentMessageId,
            senderType: row.senderType,
            senderId: row.senderId,
            preview: _previewOf(row.content),
            createdAt: row.createdAt,
            onCurrentBranch: onBranch.contains(row.id),
            childCount: childCounts[row.id] ?? 0,
          ),
      ],
      leafMessageId: leaf,
      branchCount: leaves,
    );
  }

  @override
  Future<void> branchConversationAt({
    required String workspaceId,
    required String conversationId,
    required String messageId,
  }) => _dao(workspaceId).setLeaf(conversationId, messageId);

  @override
  Future<String> forkConversation({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    String? messageId,
    String? title,
  }) async {
    final dao = _dao(workspaceId);
    final tip = messageId ?? await dao.currentLeaf(conversationId);
    final path = tip == null
        ? const <ConversationMessagesTableData>[]
        : await dao.branchFrom(conversationId, tip);

    final forkId = _uuid.v4();
    await dao.transaction(() async {
      await _conversations(workspaceId).insertConversation(
        ConversationsTableCompanion(
          id: drift.Value(forkId),
          workspaceId: drift.Value(workspaceId),
          spaceId: drift.Value(spaceId),
          title: drift.Value(title ?? ''),
          status: const drift.Value('active'),
        ),
      );
      // Copied with FRESH ids: sharing rows would make the fork show the
      // original's later messages, which is the one thing a fork must not do.
      String? parent;
      for (final row in path) {
        final copyId = _uuid.v4();
        await dao.insertMessage(
          ConversationMessagesTableCompanion(
            id: drift.Value(copyId),
            spaceId: drift.Value(spaceId),
            conversationId: drift.Value(forkId),
            senderId: drift.Value(row.senderId),
            senderType: drift.Value(row.senderType),
            content: drift.Value(row.content),
            messageType: drift.Value(row.messageType),
            metadata: drift.Value(row.metadata),
            parentMessageId: drift.Value(parent),
            createdAt: drift.Value(row.createdAt),
          ),
        );
        parent = copyId;
      }
      await dao.setLeaf(forkId, parent);
    });
    return forkId;
  }

  /// A one-line preview for the tree navigator.
  static String _previewOf(String content, {int max = 80}) {
    final flat = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flat.length > max ? '${flat.substring(0, max)}…' : flat;
  }

  @override
  Future<void> deleteSpace(String workspaceId, String spaceId) =>
      _dao(workspaceId).deleteSpaceCascade(spaceId);

  @override
  Future<void> archiveSpace(String workspaceId, String spaceId) =>
      _dao(workspaceId).setSpaceArchived(spaceId, DateTime.now());

  @override
  Future<void> unarchiveSpace(String workspaceId, String spaceId) =>
      _dao(workspaceId).setSpaceArchived(spaceId, null);

  @override
  Future<void> updateSpaceName(
    String workspaceId,
    String spaceId,
    String name,
  ) => _dao(workspaceId).updateSpaceName(spaceId, name);

  @override
  Future<List<String>?> spaceRepoSelection(
    String workspaceId,
    String spaceId,
  ) async {
    final db = _dbs.of(workspaceId);
    final row = await db.messagingDao.getSpaceById(spaceId);
    if (row == null || row.noRepos) {
      // Unknown space reads as "no selection"; an explicit none stays
      // distinguishable as the EMPTY list.
      return row == null ? null : const [];
    }
    final ids = await db.spaceRepoDao.repoIdsForSpace(workspaceId, spaceId);
    return ids.isEmpty ? null : ids;
  }

  @override
  Future<Map<String, String>> spaceRepoBranches(
    String workspaceId,
    String spaceId,
  ) => _dbs
      .of(workspaceId)
      .spaceRepoDao
      .repoBranchesForSpace(workspaceId, spaceId);

  @override
  Future<void> setSpaceRepos(
    String workspaceId,
    String spaceId,
    List<String>? repoIds,
  ) async {
    final db = _dbs.of(workspaceId);
    await db.messagingDao.transaction(() async {
      // Same isolation chokepoint as createSpace: a repo id only exists
      // inside its own workspace's file, so a foreign/unknown id is refused
      // before anything is written.
      if (repoIds != null && repoIds.isNotEmpty) {
        for (final repoId in repoIds) {
          if (!await db.repoDao.exists(repoId)) {
            throw ValidationException(
              'Repo $repoId does not belong to workspace $workspaceId.',
            );
          }
        }
      }
      // Clear-then-reinsert keeps one write path for every shape: null → the
      // "all repos" default (no rows, flag off), empty → explicit none (no
      // rows, flag ON), subset → exactly those rows (flag off).
      await db.messagingDao.updateSpaceNoRepos(
        spaceId,
        repoIds != null && repoIds.isEmpty,
      );
      await db.spaceRepoDao.clearReposForSpace(workspaceId, spaceId);
      if (repoIds != null && repoIds.isNotEmpty) {
        await db.spaceRepoDao.setReposForSpace(
          workspaceId: workspaceId,
          spaceId: spaceId,
          repoIds: repoIds,
        );
      }
    });
  }

  @override
  Future<void> setSpaceMode(String workspaceId, String spaceId, Mode mode) =>
      _dao(workspaceId).updateSpaceMode(spaceId, mode.toDbValue());

  @override
  Future<void> clearSpaceMessages(String workspaceId, String spaceId) =>
      _dao(workspaceId).clearSpaceMessages(spaceId);

  @override
  Future<void> removeParticipant(
    String workspaceId,
    String spaceId,
    String principalId,
  ) => _dao(workspaceId).removeParticipant(spaceId, principalId);

  @override
  Future<void> updateMessageEmbedding(
    String workspaceId,
    String messageId,
    Uint8List embedding,
  ) => _dao(workspaceId).updateMessageEmbedding(messageId, embedding);

  @override
  Future<List<EmbeddedMessage>> getMessagesWithEmbedding(
    String workspaceId,
    String spaceId,
  ) async {
    final rows = await _dao(workspaceId).getMessagesWithEmbedding(spaceId);
    return _mapper.embeddedMessagesToDomain(rows);
  }

  @override
  Future<List<Message>> getMessagesWithoutEmbedding(
    String workspaceId, {
    int limit = 200,
  }) async {
    final rows = await _dao(
      workspaceId,
    ).getMessagesWithoutEmbedding(limit: limit);
    return _mapper.messagesToDomain(rows);
  }
}
