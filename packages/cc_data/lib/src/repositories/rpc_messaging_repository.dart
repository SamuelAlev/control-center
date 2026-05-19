import 'dart:typed_data';

import 'package:cc_data/cc_data.dart' show RpcMessagingPort;
import 'package:cc_data/src/repositories/remote_messaging_repository.dart';
import 'package:cc_data/src/repositories/rpc_messaging_port.dart'
    show RpcMessagingPort;
import 'package:cc_data/src/sync/synced_store.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update_codec.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_domain/features/messaging/domain/ports/channel_turn_relay_port.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_summaries_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_activity.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_origin.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_provisioning_status.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_provisioning_step.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_cursor.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_page.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [MessagingRepository] backed by the RPC client — the thin-client data path.
///
/// Implements the domain interface over the host's `messaging.*` ops + the
/// `messaging.watch*` subscriptions, mapping the channel/message/participant
/// wire DTOs back to domain entities. The host owns persistence and validates
/// channel ownership against the bound workspace before returning any row; this
/// client never touches a database.
///
/// The reads/watches/mutations the UI reaches through the public repository
/// provider are served. The host-owned surface a thin client never drives
/// directly — channel lifecycle (`createChannel`/`deleteChannel`/…, all
/// invoked via the server-side `MessagingService`), embedding backfill, and
/// compaction — throws [UnsupportedError] or returns an empty fallback.
class RpcMessagingRepository
    implements
        MessagingRepository,
        ChannelTurnRelayPort,
        MessagingSummariesPort {
  /// Creates an [RpcMessagingRepository] over [client]. When [sync] is
  /// supplied and its `messaging` kill-switch is on, [watchChannels] /
  /// [watchChannelsByWorkspace] / [watchParticipants] adopt the deterministic
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

  /// Rebuilds a [Channel] from its wire DTO. Missing timestamps fall back to
  /// the epoch; a missing/unknown mode falls back to chat. Public so the
  /// sibling [RpcMessagingPort] (channel-lifecycle dispatch) reuses the exact
  /// same DTO→entity mapping rather than duplicating it.
  static Channel channelFromDto(ChannelDto d) => Channel(
    id: d.id,
    name: d.name,
    workspaceId: d.workspaceId.isEmpty ? null : d.workspaceId,
    createdAt: d.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt:
        d.updatedAt ?? d.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    mode: Mode.fromDbValue(d.mode),
    provisioningStatus: ChannelProvisioningStatus.fromDbValue(
      d.provisioningStatus,
    ),
    provisioningStep: ChannelProvisioningStep.fromDbValue(d.provisioningStep),
    pipelineRunId: d.pipelineRunId,
    origin: ChannelOrigin.fromWire(d.origin),
  );

  /// Rebuilds a [ChannelMessage] from its wire DTO. The DTO carries the parent
  /// channel id; when absent (a lossy older surface) it falls back to
  /// [fallbackChannelId] so the non-empty-channelId invariant holds.
  static ChannelMessage _messageFromDto(
    MessageDto d, {
    String? fallbackChannelId,
  }) {
    final metadata = d.metadata;
    return ChannelMessage(
      id: d.id,
      channelId: d.channelId ?? fallbackChannelId ?? '',
      senderId: d.senderId,
      senderType:
          ChannelSenderType.values.asNameMap()[d.senderType] ??
          ChannelSenderType.user,
      content: d.content,
      messageType:
          ChannelMessageType.values.asNameMap()[d.messageType] ??
          ChannelMessageType.text,
      metadata: metadata is Map ? metadata.cast<String, dynamic>() : null,
      conversationId:
          d.conversationId ?? d.channelId ?? fallbackChannelId ?? '',
      compacted: d.compacted,
      createdAt: d.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static ChannelParticipant _participantFromDto(ChannelParticipantDto d) =>
      ChannelParticipant(
        id: d.id,
        channelId: d.channelId,
        principalId: d.principalId,
        participantType:
            PrincipalType.fromWire(d.participantType) ?? PrincipalType.agent,
        role: d.role,
        joinedAt: d.joinedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        lastReadAt: d.lastReadAt,
      );

  // ---- Watches (served over the catalog `messaging.watch*` queries) ----

  @override
  Stream<List<Channel>> watchChannels() {
    // `watchChannels` carries no workspace arg (the host binds it per
    // session), so the adoption lookup reads the SAME id the RPC client is
    // already stamping onto every call — see `RemoteRpcClient.activeWorkspaceId`.
    final workspaceId = _client.activeWorkspaceId;
    if (workspaceId == null || workspaceId.isEmpty) {
      return _legacyWatchChannels();
    }
    return watchChannelsByWorkspace(workspaceId);
  }

  @override
  Stream<List<Channel>> watchChannelsByWorkspace(String workspaceId) {
    final store = _sync?.storeFor('messaging', workspaceId);
    if (store == null) {
      // Kill-switch OFF (or the store demoted itself) — the legacy path.
      return _legacyWatchChannels(workspaceId);
    }
    return _watchAdoptedChannels(store, workspaceId);
  }

  /// The snapshot subscription, pinned to [workspaceId] when the caller named
  /// one (null = the client's ambient active workspace, for [watchChannels]).
  ///
  /// The `workspaceId` is NOT informational: the server scopes the stream to
  /// the `workspace_id` in the args, and the client injects its ambient active
  /// workspace only when the args omit it. Since the ambient id follows the
  /// route and flips on a switch — independently of the workspace a caller is
  /// asking about — dropping the arg let a workspace-keyed caller receive
  /// ANOTHER workspace's channels (e.g. `workspaceChannelsProvider(A)`,
  /// re-subscribing right after the switch to B, was answered with B's list —
  /// and vice versa, which then paired B with A's channel ids on every
  /// workspace-scoped read). Threading it through keeps
  /// `watchChannelsByWorkspace(w)` an honest promise.
  Stream<List<Channel>> _legacyWatchChannels([String? workspaceId]) => _remote
      .watchChannels(workspaceId: workspaceId)
      .map((dtos) => dtos.map(channelFromDto).toList());

  /// Seeds [store]'s `channels` table from the FIRST emission of the legacy
  /// snapshot watch (`.first` subscribes then auto-cancels once it resolves),
  /// then follows the store's own delta-fed rows — sorted to match the
  /// server's `messaging.watchChannels` ordering (newest-`updatedAt`-first;
  /// see `MessagingDao.watchChannelsByWorkspace`). `messaging.watchChannels`
  /// already returns every channel in [workspaceId], so a full-replace seed is
  /// correct (unlike `channel_participants`, which is scoped per channel — see
  /// `_watchAdoptedParticipants`).
  Stream<List<Channel>> _watchAdoptedChannels(
    SyncedStore store,
    String workspaceId,
  ) async* {
    final seedDtos = await _remote
        .watchChannels(workspaceId: workspaceId)
        .first;
    store.seed(
      'channels',
      seedDtos.map((d) => d.toJson()).toList(),
      (row) => row['id'] as String,
    );
    yield* store
        .watchRows('channels')
        .map(
          (rows) =>
              rows.map((r) => channelFromDto(ChannelDto.fromJson(r))).toList()
                ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
        );
  }

  @override
  Stream<List<ChannelMessage>> watchMessages(
    String workspaceId,
    String channelId,
    String conversationId,
  ) => _remote
      .watchMessages(workspaceId, channelId, conversationId)
      .map(
        (dtos) => dtos
            .map((d) => _messageFromDto(d, fallbackChannelId: channelId))
            .toList(),
      );

  @override
  Stream<({List<ChannelMessage> messages, bool hasMore})> watchMessagesWindow(
    String workspaceId,
    String channelId,
    String conversationId, {
    required int limit,
  }) =>
      // Windowed SERVER-side (`messaging.watchMessagesWindow`): the wire
      // carries only the newest `limit` rows (lite shape, no segments), so
      // emission cost is O(window), not O(conversation).
      _remote
          .watchMessagesWindow(
            workspaceId,
            channelId,
            conversationId,
            limit: limit,
          )
          .map(
            (w) => (
              messages: w.messages
                  .map((d) => _messageFromDto(d, fallbackChannelId: channelId))
                  .toList(),
              hasMore: w.hasMore,
            ),
          );

  @override
  Stream<List<ChannelParticipant>> watchParticipants(
    String workspaceId,
    String channelId,
  ) {
    // Keyed off the caller's [workspaceId], never the client's ambient active
    // one: the channel resolves in exactly one workspace, and the ambient id
    // flips on a switch independently of the channel being watched.
    final store = workspaceId.isEmpty
        ? null
        : _sync?.storeFor('messaging', workspaceId);
    if (store == null) {
      return _remote
          .watchParticipants(workspaceId, channelId)
          .map((dtos) => dtos.map(_participantFromDto).toList());
    }
    return _watchAdoptedParticipants(store, workspaceId, channelId);
  }

  /// Seeds [store]'s `channel_participants` table for [channelId] and follows
  /// the store's own delta-fed rows, filtered back down to this channel and
  /// sorted to match the server's `messaging.watchParticipants` ordering
  /// (oldest-`joinedAt`-first; see `MessagingDao.watchParticipants`).
  ///
  /// `channel_participants` is a WHOLE-STORE table shared by every open
  /// channel, but the legacy watch (`messaging.watchParticipants`) is scoped
  /// to just [channelId] — unlike `channels`/`tickets`, there is no
  /// "every participant in the workspace" legacy query to seed from in one
  /// shot. A plain `store.seed(...)` with only this channel's rows would
  /// therefore erase any OTHER channel's rows already cached from a
  /// concurrent watch (e.g. a second open channel's participant list). So the
  /// seed is a MERGE: keep every row for a different channel, replace this
  /// channel's rows with the fresh snapshot.
  Stream<List<ChannelParticipant>> _watchAdoptedParticipants(
    SyncedStore store,
    String workspaceId,
    String channelId,
  ) async* {
    final seedDtos = await _remote
        .watchParticipants(workspaceId, channelId)
        .first;
    final existing = await store.watchRows('channel_participants').first;
    final merged = [
      ...existing.where((r) => r['channel_id'] != channelId),
      ...seedDtos.map((d) => d.toJson()),
    ];
    store.seed('channel_participants', merged, (row) => row['id'] as String);
    yield* store
        .watchRows('channel_participants')
        .map(
          (rows) =>
              rows
                  .where((r) => r['channel_id'] == channelId)
                  .map(
                    (r) =>
                        _participantFromDto(ChannelParticipantDto.fromJson(r)),
                  )
                  .toList()
                ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt)),
        );
  }

  /// Typed live turn relay: decodes `seed`/`updates` frames, skipping unknown
  /// frame kinds so protocol additions degrade to a no-op.
  @override
  Stream<ChannelTurnEvent> watchChannelTurns(String channelId) => _remote
      .watchChannelTurns(channelId)
      .map(channelTurnEventFromWire)
      .where((e) => e != null)
      .cast<ChannelTurnEvent>();

  @override
  Stream<List<ChannelActivity>> watchChannelActivity(String workspaceId) =>
      // Pinned to [workspaceId] rather than the client's ambient active
      // workspace: this feeds a workspace-keyed provider family, and the
      // ambient id flips on a switch independently of the workspace being
      // asked about (see `_legacyWatchChannels`).
      _remote
          .watchChannelActivity(workspaceId: workspaceId)
          .map(
            (rows) => [for (final row in rows) ?ChannelActivity.fromJson(row)],
          );

  // ---- Reads ----

  @override
  Future<ChannelMessage?> getMessageById(
    String workspaceId,
    String messageId,
  ) async {
    final dto = await _remote.getMessageById(workspaceId, messageId);
    return dto == null ? null : _messageFromDto(dto);
  }

  @override
  Future<Channel?> getChannelById(String workspaceId, String channelId) =>
      throw UnsupportedError(
        'getChannelById is host-only (the sync delta feed loads rows '
        'server-side); clients read channels from their synced store.',
      );

  @override
  Future<List<ChannelMessage>> getMessages(
    String workspaceId,
    String channelId, {
    String? conversationId,
  }) async {
    final dtos = await _remote.getMessages(
      workspaceId,
      channelId,
      conversationId: conversationId,
    );
    return dtos
        .map((d) => _messageFromDto(d, fallbackChannelId: channelId))
        .toList();
  }

  @override
  Future<List<ChannelMessage>> searchInChannel(
    String workspaceId,
    String channelId,
    String query, {
    int limit = 50,
  }) async {
    final dtos = await _remote.searchInChannel(
      workspaceId,
      channelId,
      query,
      limit: limit,
    );
    return dtos
        .map((d) => _messageFromDto(d, fallbackChannelId: channelId))
        .toList();
  }

  @override
  Future<MessagePage> getMessagePage(
    String workspaceId,
    String channelId,
    String conversationId, {
    int limit = defaultMessagePageSize,
    String? cursor,
  }) async {
    // Thin-client fallback: the host returns the full conversation, so paginate
    // in memory. The cursor encodes the boundary message's createdAt (rowid is
    // unavailable client-side, so 0 is used as a sentinel tie-breaker —
    // strictly-older-by-time is sufficient for display paging).
    final all = (await getMessages(
      workspaceId,
      channelId,
      conversationId: conversationId,
    )).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final decoded = MessageCursor.decode(cursor);
    final older = decoded == null
        ? all
        : all
              .where(
                (m) => m.createdAt.millisecondsSinceEpoch < decoded.createdAtMs,
              )
              .toList();
    final hasMore = older.length > limit;
    final page = hasMore ? older.sublist(older.length - limit) : older;
    String? nextCursor;
    if (hasMore && page.isNotEmpty) {
      nextCursor = MessageCursor(
        createdAtMs: page.first.createdAt.millisecondsSinceEpoch,
        rowid: 0,
      ).encode();
    }
    return MessagePage(
      messages: page,
      hasMore: hasMore,
      nextCursor: nextCursor,
    );
  }

  @override
  Future<bool> channelExists(String workspaceId, String channelId) =>
      _remote.channelExists(workspaceId, channelId);

  @override
  Future<List<ChannelParticipant>> getParticipants(
    String workspaceId,
    String channelId,
  ) async {
    final dtos = await _remote.getParticipants(workspaceId, channelId);
    return dtos.map(_participantFromDto).toList();
  }

  // ---- Mutations ----

  @override
  Future<String> sendMessage({
    required String workspaceId,
    required String channelId,
    required String content,
    required String senderId,
    required String senderType,
    String? conversationId,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    String? id,
  }) => _remote.sendMessage(
    workspaceId: workspaceId,
    channelId: channelId,
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
    String? idempotencyKey,
  }) => _remote.updateMessage(
    workspaceId,
    messageId,
    content: content,
    metadata: metadata,
    idempotencyKey: idempotencyKey,
  );

  @override
  Future<void> setChannelMode(
    String workspaceId,
    String channelId,
    Mode mode,
  ) => _remote.setChannelMode(workspaceId, channelId, mode.toDbValue());

  @override
  Future<void> addParticipant(
    String workspaceId,
    String channelId,
    String principalId, {
    PrincipalType participantType = PrincipalType.agent,
  }) => _remote.addParticipant(workspaceId, channelId, principalId);

  // ---- Host-owned surface: channel lifecycle, embeddings, compaction. ----
  // The UI reaches these through the server-side `MessagingService` (Dao-backed
  // execution), never through this thin-client repository.
  @override
  Future<Channel> createChannel(
    String workspaceId,
    String name,
    List<String> agentIds, {
    Mode mode = Mode.chat,
    String? pipelineRunId,
    String? createdByUserId,
    ChannelOrigin origin = ChannelOrigin.user,
    List<String> repoIds = const [],
  }) => throw UnsupportedError('createChannel is host-side only');

  // Conversation revert/unrevert (undo/redo) run on the HOST — it owns the DB
  // (the transcript rollback) and, when it owns the conversation's CoW worktree,
  // the filesystem rollback to the turn's git snapshot. The reverted/restored
  // rows drop out of / reappear in the `messaging.watch*` streams, so a
  // subscribed UI updates reactively. The interface returns the affected ids;
  // the richer `filesystemRestored` bit is available on the wire client for
  // callers that surface it.
  @override
  Future<List<String>> revertConversationTo(
    String workspaceId,
    String channelId,
    String messageId, {
    bool inclusive = false,
  }) async => (await _remote.revertConversationTo(
    workspaceId,
    channelId,
    messageId,
    inclusive: inclusive,
  )).affected;

  @override
  Future<List<String>> unrevertConversation(
    String workspaceId,
    String channelId,
  ) => _remote.unrevertConversation(workspaceId, channelId);

  @override
  Future<void> deleteChannel(String workspaceId, String channelId) =>
      throw UnsupportedError('deleteChannel is host-side only');

  @override
  Future<void> updateChannelName(
    String workspaceId,
    String channelId,
    String name,
  ) => throw UnsupportedError('updateChannelName is host-side only');

  @override
  Future<void> clearChannelMessages(String workspaceId, String channelId) =>
      throw UnsupportedError('clearChannelMessages is host-side only');

  @override
  Future<void> removeParticipant(
    String workspaceId,
    String channelId,
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
  Future<List<EmbeddedChannelMessage>> getMessagesWithEmbedding(
    String workspaceId,
    String channelId,
  ) => throw UnsupportedError('getMessagesWithEmbedding is host-side only');

  @override
  Future<List<ChannelMessage>> getMessagesWithoutEmbedding(
    String workspaceId, {
    int limit = 200,
  }) => throw UnsupportedError('getMessagesWithoutEmbedding is host-side only');
}
