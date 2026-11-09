import 'dart:async';

import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:uuid/uuid.dart';

/// A ticket somebody asked for from chat (`/cc ticket …`), held until they
/// confirm it inside Control Center.
///
/// A slash command's text cannot be re-read from the provider and, on the
/// shared app, it travelled through a relay. So it never becomes a ticket — or
/// fires a ticket-created pipeline trigger — on its own: the reporter sees the
/// draft in Control Center and creates the ticket there.
class ChatTicketDraft {
  /// Creates a [ChatTicketDraft].
  const ChatTicketDraft({
    required this.id,
    required this.workspaceId,
    required this.provider,
    required this.reporterUserId,
    required this.title,
    required this.createdAt,
    required this.expiresAt,
    this.description,
    this.externalUserId = '',
    this.externalChannelId = '',
  });

  /// Opaque id.
  final String id;

  /// The workspace the ticket would be created in.
  final String workspaceId;

  /// The chat provider the command came from.
  final ChatProvider provider;

  /// The linked Control Center member who ran the command. Only they can
  /// confirm or discard it.
  final String reporterUserId;

  /// The proposed ticket title.
  final String title;

  /// The proposed description, when one was given after `|`.
  final String? description;

  /// The provider-side member who ran the command.
  final String externalUserId;

  /// Where it was run.
  final String externalChannelId;

  /// When the command arrived.
  final DateTime createdAt;

  /// When the draft is dropped unconfirmed.
  final DateTime expiresAt;

  /// The wire shape.
  Map<String, Object?> toJson() => {
    'id': id,
    'workspaceId': workspaceId,
    'provider': provider.wire,
    'reporterUserId': reporterUserId,
    'title': title,
    if (description != null) 'description': description,
    'externalUserId': externalUserId,
    'externalChannelId': externalChannelId,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'expiresAt': expiresAt.toUtc().toIso8601String(),
  };
}

/// A change to one member's drafts, for watchers.
typedef ChatTicketDraftChange = ({String workspaceId, String userId});

/// Ticket drafts from chat commands, waiting for confirmation.
///
/// In memory on purpose, like link codes: a draft is a proposal, not a
/// record, and a restart dropping unconfirmed proposals is acceptable. Bounded
/// per workspace so a chat channel cannot grow the server's memory.
class ChatTicketDraftStore {
  /// Creates a [ChatTicketDraftStore].
  ChatTicketDraftStore({
    this.ttl = const Duration(hours: 24),
    this.maxPerWorkspace = 200,
    DateTime Function()? clock,
    String Function()? newId,
  }) : _clock = clock ?? DateTime.now,
       _newId = newId ?? const Uuid().v4;

  /// How long an unconfirmed draft lives.
  final Duration ttl;

  /// Drafts kept per workspace; the oldest are dropped beyond it.
  final int maxPerWorkspace;

  final DateTime Function() _clock;
  final String Function() _newId;

  /// In insertion order, so the oldest is first.
  final Map<String, ChatTicketDraft> _drafts = {};

  final StreamController<ChatTicketDraftChange> _changes =
      StreamController<ChatTicketDraftChange>.broadcast();

  /// Every change to a member's drafts.
  Stream<ChatTicketDraftChange> get changes => _changes.stream;

  /// Records a draft and returns it.
  ChatTicketDraft add({
    required String workspaceId,
    required ChatProvider provider,
    required String reporterUserId,
    required String title,
    String? description,
    String externalUserId = '',
    String externalChannelId = '',
  }) {
    _sweep();
    final now = _clock();
    final draft = ChatTicketDraft(
      id: _newId(),
      workspaceId: workspaceId,
      provider: provider,
      reporterUserId: reporterUserId,
      title: title,
      description: description,
      externalUserId: externalUserId,
      externalChannelId: externalChannelId,
      createdAt: now,
      expiresAt: now.add(ttl),
    );
    _drafts[draft.id] = draft;
    final inWorkspace = [
      for (final d in _drafts.values)
        if (d.workspaceId == workspaceId) d,
    ];
    final excess = inWorkspace.length - maxPerWorkspace;
    for (final old in inWorkspace.take(excess < 0 ? 0 : excess)) {
      _drafts.remove(old.id);
      _notify(old.workspaceId, old.reporterUserId);
    }
    _notify(workspaceId, reporterUserId);
    return draft;
  }

  /// [userId]'s live drafts in [workspaceId], oldest first.
  List<ChatTicketDraft> forUser(String workspaceId, String userId) {
    _sweep();
    return [
      for (final d in _drafts.values)
        if (d.workspaceId == workspaceId && d.reporterUserId == userId) d,
    ];
  }

  /// Removes and returns [draftId] when it is [userId]'s draft in
  /// [workspaceId]; null otherwise (unknown, expired, somebody else's, or
  /// another workspace's — one answer, so ids cannot be probed).
  ChatTicketDraft? take(String workspaceId, String userId, String draftId) {
    _sweep();
    final draft = _drafts[draftId];
    if (draft == null ||
        draft.workspaceId != workspaceId ||
        draft.reporterUserId != userId) {
      return null;
    }
    _drafts.remove(draftId);
    _notify(workspaceId, userId);
    return draft;
  }

  /// Puts back a draft [take] handed out whose confirmation failed, so the
  /// member can retry. Nothing happens once it has expired.
  void restore(ChatTicketDraft draft) {
    _sweep();
    if (!draft.expiresAt.isAfter(_clock())) {
      return;
    }
    _drafts[draft.id] = draft;
    _notify(draft.workspaceId, draft.reporterUserId);
  }

  void _notify(String workspaceId, String userId) {
    if (!_changes.isClosed) {
      _changes.add((workspaceId: workspaceId, userId: userId));
    }
  }

  void _sweep() {
    final now = _clock();
    final expired = [
      for (final d in _drafts.values)
        if (!d.expiresAt.isAfter(now)) d,
    ];
    for (final d in expired) {
      _drafts.remove(d.id);
      _notify(d.workspaceId, d.reporterUserId);
    }
  }
}
