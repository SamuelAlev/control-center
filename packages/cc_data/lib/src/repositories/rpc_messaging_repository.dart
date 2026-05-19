import 'dart:typed_data';

import 'package:cc_data/cc_data.dart' show RpcMessagingPort;
import 'package:cc_data/src/repositories/remote_messaging_repository.dart';
import 'package:cc_data/src/repositories/rpc_messaging_port.dart'
    show RpcMessagingPort;
import 'package:cc_data/src/sync/row_entity_cache.dart';
import 'package:cc_data/src/sync/synced_store.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update_codec.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_summaries_port.dart';
import 'package:cc_domain/features/messaging/domain/ports/space_turn_relay_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_token_totals.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_page.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_activity.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_kind.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_step.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [MessagingRepository] backed by the RPC client — the thin-client data path.
///
/// Implements the domain interface over the host's `messaging.*` ops + the
/// `messaging.watch*` subscriptions, mapping the space/message/participant
/// wire DTOs back to domain entities. The host owns persistence and validates
/// space ownership against the bound workspace before returning any row; this
/// client never touches a database.
///
/// The reads/watches/mutations the UI reaches through the public repository
/// provider are served. The host-owned surface a thin client never drives
/// directly — space lifecycle (`createSpace`/`deleteSpace`/…, all
/// invoked via the server-side `MessagingService`), embedding backfill and
/// compaction — throws [UnsupportedError] or returns an empty fallback.
class RpcMessagingRepository
    implements MessagingRepository, SpaceTurnRelayPort, MessagingSummariesPort {
  /// Creates an [RpcMessagingRepository] over [client]. When [sync] is
  /// supplied and its `messaging` kill-switch is on, [watchSpaces] /
  /// [watchSpacesByWorkspace] / [watchParticipants] adopt the deterministic
  /// sync engine (PRD 16 §6) instead of re-querying their legacy
  /// full-snapshot subscriptions on every change. Message-body watches
  /// (`watchMessages`/windows/turns) are unaffected — they keep their own
  /// streaming pipeline.
  RpcMessagingRepository(RemoteRpcClient client, {ClientSyncEngine? sync})
    : _remote = RemoteMessagingRepository(client),
      _client = client,
      _sync = sync;

  final RemoteMessagingRepository _remote;
  final RemoteRpcClient _client;
  final ClientSyncEngine? _sync;

  /// Rebuilds a [Space] from its wire DTO. Missing timestamps fall back to
  /// the epoch; a missing/unknown mode falls back to chat. Public so the
  /// sibling [RpcMessagingPort] (space-lifecycle dispatch) reuses the exact
  /// same DTO→entity mapping rather than duplicating it.
  static Space spaceFromDto(SpaceDto d) => Space(
    id: d.id,
    name: d.name,
    workspaceId: d.workspaceId.isEmpty ? null : d.workspaceId,
    createdAt: d.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt:
        d.updatedAt ?? d.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    mode: Mode.fromDbValue(d.mode),
    provisioningStatus: SpaceProvisioningStatus.fromDbValue(
      d.provisioningStatus,
    ),
    provisioningStep: SpaceProvisioningStep.fromDbValue(d.provisioningStep),
    pipelineRunId: d.pipelineRunId,
    kind: SpaceKind.fromWire(d.kind),
    archivedAt: d.archivedAt,
  );

  /// Rebuilds a [Message] from its wire DTO. The DTO carries the parent
  /// space id; when absent (a lossy older surface) it falls back to
  /// [fallbackSpaceId] so the non-empty-spaceId invariant holds.
  static Message _messageFromDto(MessageDto d, {String? fallbackSpaceId}) {
    final metadata = d.metadata;
    return Message(
      id: d.id,
      spaceId: d.spaceId ?? fallbackSpaceId ?? '',
      senderId: d.senderId,
      senderType: _spaceSenderTypeByName[d.senderType] ?? SenderType.user,
      content: d.content,
      messageType: _spaceMessageTypeByName[d.messageType] ?? MessageType.text,
      metadata: metadata is Map ? metadata.cast<String, dynamic>() : null,
      conversationId: d.conversationId ?? d.spaceId ?? fallbackSpaceId ?? '',
      compacted: d.compacted,
      createdAt: d.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static SpaceParticipant _participantFromDto(SpaceParticipantDto d) =>
      SpaceParticipant(
        id: d.id,
        spaceId: d.spaceId,
        principalId: d.principalId,
        participantType:
            PrincipalType.fromWire(d.participantType) ?? PrincipalType.agent,
        role: d.role,
        joinedAt: d.joinedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        lastReadAt: d.lastReadAt,
      );

  // ---- Watches (served over the catalog `messaging.watch*` queries) ----

  @override
  Stream<List<Space>> watchSpaces() {
    // `watchSpaces` carries no workspace arg (the host binds it per
    // session), so the adoption lookup reads the SAME id the RPC client is
    // already stamping onto every call — see `RemoteRpcClient.activeWorkspaceId`.
    final workspaceId = _client.activeWorkspaceId;
    if (workspaceId == null || workspaceId.isEmpty) {
      return _legacyWatchSpaces();
    }
    return watchSpacesByWorkspace(workspaceId);
  }

  @override
  Stream<List<Space>> watchSpacesByWorkspace(String workspaceId) {
    final store = _sync?.storeFor('messaging', workspaceId);
    if (store == null) {
      // Kill-switch OFF (or the store demoted itself) — the legacy path.
      return _legacyWatchSpaces(workspaceId);
    }
    return _watchAdoptedSpaces(store, workspaceId);
  }

  /// The snapshot subscription, pinned to [workspaceId] when the caller named
  /// one (null = the client's ambient active workspace, for [watchSpaces]).
  ///
  /// The `workspaceId` is NOT informational: the server scopes the stream to
  /// the `workspace_id` in the args and the client injects its ambient active
  /// workspace only when the args omit it. Since the ambient id follows the
  /// route and flips on a switch — independently of the workspace a caller is
  /// asking about — dropping the arg let a workspace-keyed caller receive
  /// ANOTHER workspace's spaces (e.g. `workspaceSpacesProvider(A)`,
  /// re-subscribing right after the switch to B, was answered with B's list —
  /// and vice versa, which then paired B with A's space ids on every
  /// workspace-scoped read). Threading it through keeps
  /// `watchSpacesByWorkspace(w)` an honest promise.
  Stream<List<Space>> _legacyWatchSpaces([String? workspaceId]) => _remote
      .watchSpaces(workspaceId: workspaceId)
      .map((dtos) => dtos.map(spaceFromDto).toList());

  /// Seeds [store]'s `spaces` table from the FIRST emission of the legacy
  /// snapshot watch (`.first` subscribes then auto-cancels once it resolves),
  /// then follows the store's own delta-fed rows — sorted to match the
  /// server's `messaging.watchSpaces` ordering (newest-`updatedAt`-first;
  /// see `MessagingDao.watchSpacesByWorkspace`). `messaging.watchSpaces`
  /// already returns every space in [workspaceId], so a full-replace seed is
  /// correct (unlike `space_participants`, which is scoped per space — see
  /// `_watchAdoptedParticipants`).
  Stream<List<Space>> _watchAdoptedSpaces(
    SyncedStore store,
    String workspaceId,
  ) async* {
    // Seed ONCE per (store, workspace) — see `SyncedStore.isSeeded`.
    if (!store.isSeeded('spaces')) {
      final seedDtos = await _remote
          .watchSpaces(workspaceId: workspaceId)
          .first;
      store.seed(
        'spaces',
        seedDtos.map((d) => d.toJson()).toList(),
        (row) => row['id'] as String,
      );
    }
    // Per-subscription entity memo — an unchanged row comes back as the SAME
    // Map instance, so its Space is reused rather than re-decoded.
    final cache = RowEntityCache<Space>();
    yield* store
        .watchRows('spaces')
        .map(
          (rows) =>
              cache
                  .map(rows, (r) => spaceFromDto(SpaceDto.fromJson(r)))
                  .toList(growable: false)
                ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
        );
  }

  @override
  Stream<List<Message>> watchMessages(
    String workspaceId,
    String spaceId,
    String conversationId,
  ) => _remote
      .watchMessages(workspaceId, spaceId, conversationId)
      .map(
        (dtos) => dtos
            .map((d) => _messageFromDto(d, fallbackSpaceId: spaceId))
            .toList(),
      );

  @override
  Stream<List<Message>> watchSpaceMessages(
    String workspaceId,
    String spaceId,
  ) => _remote
      .watchSpaceMessages(workspaceId, spaceId)
      .map(
        (dtos) => dtos
            .map((d) => _messageFromDto(d, fallbackSpaceId: spaceId))
            .toList(),
      );

  /// The first emission of [watchSpaceMessages].
  ///
  /// There is no one-shot RPC op behind this: the space-wide read exists for
  /// the server's own review path, and a client that wants it is a client that
  /// wants to watch it. Taking the first frame of the subscription keeps the
  /// two answers identical rather than adding a second op that could drift.
  @override
  Future<List<Message>> getSpaceMessages(String workspaceId, String spaceId) =>
      watchSpaceMessages(workspaceId, spaceId).first;

  @override
  Stream<({List<Message> messages, bool hasMore})> watchMessagesWindow(
    String workspaceId,
    String spaceId,
    String conversationId, {
    required int limit,
  }) =>
      // Windowed SERVER-side (`messaging.watchMessagesWindow`): the wire
      // carries only the newest `limit` rows (lite shape, no segments), so
      // emission cost is O(window), not O(conversation).
      _remote
          .watchMessagesWindow(
            workspaceId,
            spaceId,
            conversationId,
            limit: limit,
          )
          .map(
            (w) => (
              messages: w.messages
                  .map((d) => _messageFromDto(d, fallbackSpaceId: spaceId))
                  .toList(),
              hasMore: w.hasMore,
            ),
          );

  /// [MessagingSummariesPort.watchConversationTokens] — aggregated
  /// SERVER-side, because folding it here would mean subscribing to the whole
  /// conversation to produce two integers.
  @override
  Stream<ConversationTokenTotals> watchConversationTokens(
    String workspaceId,
    String spaceId,
    String conversationId,
  ) =>
      _remote
          .watchConversationTokens(workspaceId, spaceId, conversationId)
          .map(
            (data) => ConversationTokenTotals(
              tokens: (data['tokens'] as num?)?.toInt() ?? 0,
              chars: (data['chars'] as num?)?.toInt() ?? 0,
            ),
          );

  @override
  Stream<List<SpaceParticipant>> watchParticipants(
    String workspaceId,
    String spaceId,
  ) {
    // Keyed off the caller's [workspaceId], never the client's ambient active
    // one: the space resolves in exactly one workspace and the ambient id
    // flips on a switch independently of the space being watched.
    final store = workspaceId.isEmpty
        ? null
        : _sync?.storeFor('messaging', workspaceId);
    if (store == null) {
      return _remote
          .watchParticipants(workspaceId, spaceId)
          .map((dtos) => dtos.map(_participantFromDto).toList());
    }
    return _watchAdoptedParticipants(store, workspaceId, spaceId);
  }

  /// Seeds [store]'s `space_participants` table for [spaceId] and follows
  /// the store's own delta-fed rows, filtered back down to this space and
  /// sorted to match the server's `messaging.watchParticipants` ordering
  /// (oldest-`joinedAt`-first; see `MessagingDao.watchParticipants`).
  ///
  /// `space_participants` is a WHOLE-STORE table shared by every open
  /// space, but the legacy watch (`messaging.watchParticipants`) is scoped
  /// to just [spaceId] — unlike `spaces`/`tickets`, there is no
  /// "every participant in the workspace" legacy query to seed from in one
  /// shot. A plain `store.seed(...)` with only this space's rows would
  /// therefore erase any OTHER space's rows already cached from a
  /// concurrent watch (e.g. a second open space's participant list). So the
  /// seed is a MERGE: keep every row for a different space, replace this
  /// space's rows with the fresh snapshot.
  Stream<List<SpaceParticipant>> _watchAdoptedParticipants(
    SyncedStore store,
    String workspaceId,
    String spaceId,
  ) async* {
    final seedDtos = await _remote
        .watchParticipants(workspaceId, spaceId)
        .first;
    final existing = await store.watchRows('space_participants').first;
    final merged = [
      ...existing.where((r) => r['space_id'] != spaceId),
      ...seedDtos.map((d) => d.toJson()),
    ];
    store.seed('space_participants', merged, (row) => row['id'] as String);
    // The participants table is shared by every space, so this pipeline
    // filters it down per emission; the memo means the surviving rows are not
    // re-decoded as well.
    final cache = RowEntityCache<SpaceParticipant>();
    yield* store
        .watchRows('space_participants')
        .map(
          (rows) =>
              cache
                  .map(
                    rows
                        .where((r) => r['space_id'] == spaceId)
                        .toList(growable: false),
                    (r) => _participantFromDto(SpaceParticipantDto.fromJson(r)),
                  )
                  .toList(growable: false)
                ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt)),
        );
  }

  /// Typed live turn relay: decodes `seed`/`updates` frames, skipping unknown
  /// frame kinds so protocol additions degrade to a no-op.
  @override
  Stream<SpaceTurnEvent> watchSpaceTurns(String spaceId) => _remote
      .watchSpaceTurns(spaceId)
      .map(spaceTurnEventFromWire)
      .where((e) => e != null)
      .cast<SpaceTurnEvent>();

  @override
  Stream<List<SpaceActivity>> watchSpaceActivity(String workspaceId) =>
      // Pinned to [workspaceId] rather than the client's ambient active
      // workspace: this feeds a workspace-keyed provider family and the
      // ambient id flips on a switch independently of the workspace being
      // asked about (see `_legacyWatchSpaces`).
      _remote
          .watchSpaceActivity(workspaceId: workspaceId)
          .map(
            (rows) => [for (final row in rows) ?SpaceActivity.fromJson(row)],
          );

  // ---- Reads ----

  @override
  Future<Message?> getMessageById(String workspaceId, String messageId) async {
    final dto = await _remote.getMessageById(workspaceId, messageId);
    if (dto == null) {
      return null;
    }
    // The ONLY `_messageFromDto` call site with no `fallbackSpaceId`, so it
    // is the only one where the mapper's `?? ''` fallback can produce an empty
    // spaceId — and `Message` now REFUSES that in release, where it
    // used to be a stripped assert. A message that cannot be placed in a
    // space is, for every caller of this method, not found; manufacturing
    // one and letting the domain throw would surface an out-of-window
    // permalink lookup as a crash instead of a miss.
    //
    // Unreachable on today's wire (`messageToWire` always emits `space_id`),
    // which is exactly why it is worth stating: without this the client's
    // crash-freedom rests on a server invariant it cannot see.
    if ((dto.spaceId ?? '').isEmpty) {
      return null;
    }
    return _messageFromDto(dto);
  }

  @override
  Future<Space?> getSpaceById(String workspaceId, String spaceId) =>
      throw UnsupportedError(
        'getChannelById is host-only (the sync delta feed loads rows '
        'server-side); clients read channels from their synced store.',
      );

  @override
  Future<List<Message>> getMessages(
    String workspaceId,
    String spaceId, {
    String? conversationId,
  }) async {
    final dtos = await _remote.getMessages(
      workspaceId,
      spaceId,
      conversationId: conversationId,
    );
    return dtos
        .map((d) => _messageFromDto(d, fallbackSpaceId: spaceId))
        .toList();
  }

  @override
  Future<List<Message>> searchInSpace(
    String workspaceId,
    String spaceId,
    String query, {
    int limit = 50,
  }) async {
    final dtos = await _remote.searchInSpace(
      workspaceId,
      spaceId,
      query,
      limit: limit,
    );
    return dtos
        .map((d) => _messageFromDto(d, fallbackSpaceId: spaceId))
        .toList();
  }

  @override
  Future<MessagePage> getMessagePage(
    String workspaceId,
    String spaceId,
    String conversationId, {
    int limit = defaultMessagePageSize,
    String? cursor,
  }) async {
    // Server-side keyset paging. This used to pull the WHOLE conversation and
    // slice it here — a 2,000-message thread shipped every message, segments
    // included, to render one screenful — because no cursor op existed. The
    // cursor stays opaque to the client: the server mints it from `created_at`
    // plus the row's stable rowid, which is the tie-breaker a client cannot
    // supply (`created_at` is second-resolution, so time alone drops messages
    // that share a second across a page boundary).
    final page = await _remote.getMessagePage(
      workspaceId,
      spaceId,
      conversationId,
      limit: limit,
      cursor: cursor,
    );
    final messages =
        page.messages
            .map((d) => _messageFromDto(d, fallbackSpaceId: spaceId))
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return MessagePage(
      messages: messages,
      hasMore: page.hasMore,
      nextCursor: page.nextCursor,
    );
  }

  @override
  Future<bool> spaceExists(String workspaceId, String spaceId) =>
      _remote.spaceExists(workspaceId, spaceId);

  @override
  Future<List<SpaceParticipant>> getParticipants(
    String workspaceId,
    String spaceId,
  ) async {
    final dtos = await _remote.getParticipants(workspaceId, spaceId);
    return dtos.map(_participantFromDto).toList();
  }

  // ---- Mutations ----

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
  }) => _remote.sendMessage(
    workspaceId: workspaceId,
    spaceId: spaceId,
    content: content,
    senderId: senderId,
    senderType: senderType,
    conversationId: conversationId,
    messageType: messageType,
    metadata: metadata,
    id: id,
  );

  @override
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
    String? messageType,
    String? idempotencyKey,
  }) => _remote.updateMessage(
    workspaceId,
    messageId,
    content: content,
    metadata: metadata,
    messageType: messageType,
    idempotencyKey: idempotencyKey,
  );

  // The steering queue's row writes run through the `steering.*` port ops
  // (RpcMessagingDispatch), not the raw messaging repository — a thin client
  // composing this repository alone never touches them. Implemented because
  // the interface demands it; unreachable on this tier.
  @override
  Future<String> insertSteeringMessage({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String content,
    required String senderId,
    required Map<String, dynamic> metadata,
    String? id,
  }) => throw UnsupportedError(
    'Steering rows are written through the steering queue service',
  );

  @override
  Future<void> deleteSteeringMessage(String workspaceId, String messageId) =>
      throw UnsupportedError(
        'Steering rows are deleted through the steering queue service',
      );

  @override
  Future<void> setSpaceMode(String workspaceId, String spaceId, Mode mode) =>
      _remote.setSpaceMode(workspaceId, spaceId, mode.toDbValue());

  @override
  Future<void> addParticipant(
    String workspaceId,
    String spaceId,
    String principalId, {
    PrincipalType participantType = PrincipalType.agent,
  }) => _remote.addParticipant(workspaceId, spaceId, principalId);

  // ---- Host-owned surface: space lifecycle, embeddings, compaction. ----
  // The UI reaches these through the server-side `MessagingService` (Dao-backed
  // execution), never through this thin-client repository.
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
  }) => throw UnsupportedError('createChannel is host-side only');

  @override
  Future<Map<String, String>> spaceRepoBranches(
    String workspaceId,
    String spaceId,
  ) async => throw UnsupportedError('spaceRepoBranches is host-side only');

  // Conversation revert/unrevert (undo/redo) run on the HOST — it owns the DB
  // (the transcript rollback) and, when it owns the conversation's CoW worktree,
  // the filesystem rollback to the turn's git snapshot. The reverted/restored
  // rows drop out of / reappear in the `messaging.watch*` streams, so a
  // subscribed UI updates reactively. The interface returns the affected ids;
  // the richer `filesystemRestored` bit is available on the wire client for
  // callers that surface it.
  @override
  Future<ConversationTree> conversationTree({
    required String workspaceId,
    required String conversationId,
  }) => _remote.conversationTree(
    workspaceId: workspaceId,
    conversationId: conversationId,
  );

  @override
  Future<void> branchConversationAt({
    required String workspaceId,
    required String conversationId,
    required String messageId,
  }) => _remote.branchConversationAt(
    workspaceId: workspaceId,
    conversationId: conversationId,
    messageId: messageId,
  );

  @override
  Future<String> forkConversation({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    String? messageId,
    String? title,
  }) => _remote.forkConversation(
    workspaceId: workspaceId,
    spaceId: spaceId,
    conversationId: conversationId,
    messageId: messageId,
    title: title,
  );

  @override
  Future<List<String>> revertConversationTo(
    String workspaceId,
    String spaceId,
    String messageId, {
    bool inclusive = false,
  }) async => (await _remote.revertConversationTo(
    workspaceId,
    spaceId,
    messageId,
    inclusive: inclusive,
  )).affected;

  @override
  Future<List<String>> unrevertConversation(
    String workspaceId,
    String spaceId,
  ) => _remote.unrevertConversation(workspaceId, spaceId);

  @override
  Future<void> deleteSpace(String workspaceId, String spaceId) =>
      throw UnsupportedError('deleteChannel is host-side only');

  @override
  Future<void> archiveSpace(String workspaceId, String spaceId) =>
      throw UnsupportedError('archiveSpace is host-side only');

  @override
  Future<void> unarchiveSpace(String workspaceId, String spaceId) =>
      throw UnsupportedError('unarchiveSpace is host-side only');

  @override
  Future<List<String>?> spaceRepoSelection(
    String workspaceId,
    String spaceId,
  ) => throw UnsupportedError('spaceRepoSelection is host-side only');

  @override
  Future<void> setSpaceRepos(
    String workspaceId,
    String spaceId,
    List<String>? repoIds,
  ) => throw UnsupportedError('setSpaceRepos is host-side only');

  @override
  Future<void> updateSpaceName(
    String workspaceId,
    String spaceId,
    String name,
  ) => throw UnsupportedError('updateChannelName is host-side only');

  @override
  Future<void> clearSpaceMessages(String workspaceId, String spaceId) =>
      throw UnsupportedError('clearChannelMessages is host-side only');

  @override
  Future<void> removeParticipant(
    String workspaceId,
    String spaceId,
    String principalId,
  ) => throw UnsupportedError('removeParticipant is host-side only');

  @override
  Future<void> markCompacted(String workspaceId, List<String> ids) =>
      throw UnsupportedError('markCompacted is host-side only');

  @override
  Future<void> updateMessageEmbedding(
    String workspaceId,
    String messageId,
    Uint8List embedding,
  ) => throw UnsupportedError('updateMessageEmbedding is host-side only');

  @override
  Future<List<EmbeddedMessage>> getMessagesWithEmbedding(
    String workspaceId,
    String spaceId,
  ) => throw UnsupportedError('getMessagesWithEmbedding is host-side only');

  @override
  Future<List<Message>> getMessagesWithoutEmbedding(
    String workspaceId, {
    int limit = 200,
  }) => throw UnsupportedError('getMessagesWithoutEmbedding is host-side only');
}

// Enum name→value lookups, built ONCE.
//
// `EnumType.values.asNameMap()` ALLOCATES A NEW MAP on every call, and
// these run per field per row per emission — the delta path re-maps a whole
// table on every frame, so a single ticket change built four fresh maps per
// ticket in the workspace.
final Map<String, MessageType> _spaceMessageTypeByName = MessageType.values
    .asNameMap();
final Map<String, SenderType> _spaceSenderTypeByName = SenderType.values
    .asNameMap();
