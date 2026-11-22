/// The wakes peer asks and finished work produce (plan section 10, D19 to
/// D21), and the small readers they share: the final answer of a run's
/// message and the hash that spots a repeated question.
library;

import 'dart:convert';

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/peer_ask.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/services/peer_ask_text.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_frame.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/peer_ask_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_detail.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:crypto/crypto.dart';

/// The `peerReply` statuses that do not settle an ask (the amended D20).
// ignore: avoid_classes_with_only_static_members
abstract final class PeerReplyInterim {
  /// The recipient said when it will answer and set a wake (A3.3).
  static const String promised = 'promised';

  /// The recipient waits on a person (A5).
  static const String blockedOnPerson = 'blocked_on_person';

  /// The recipient is parked at the provider's usage limit (A3.2).
  static const String parkedAtLimit = 'parked_at_limit';

  /// Every interim status.
  static const Set<String> all = {promised, blockedOnPerson, parkedAtLimit};

  /// The dedup suffix of each interim status.
  static String suffixOf(String status) => switch (status) {
    promised => 'promised',
    blockedOnPerson => 'blocked',
    _ => 'parked',
  };
}

/// What ended a peer ask without an answer (`PeerAsk.error`, and the
/// `peerReply` wake's [WakeFields.error]).
abstract final class PeerAskErrors {
  /// The recipient's run ended with an empty final message (A3.1).
  static const String noOutput = 'no_output';

  /// The recipient's run failed.
  static const String runFailed = 'run_failed';

  /// A person stopped the recipient's run.
  static const String stoppedByPerson = 'stopped_by_person';

  /// The recipient's run stopped at its budget.
  static const String budget = 'budget';

  /// The recipient's run went silent and was stopped.
  static const String silence = 'silence';

  /// The recipient's run stopped at the provider's usage limit, with no
  /// known reset.
  static const String usageLimit = 'usage_limit';

  /// The question's wake was never delivered (skipped, expired or
  /// cancelled by the queue).
  static const String notDelivered = 'not_delivered';
}

/// The agents above a caller in its chains of asks and wakes (plan section
/// 10, "Guards read rows").
class PeerChain {
  /// Creates a chain. [lineage] is the longest chain of agents above the
  /// caller in this run, oldest first; [waiting] every agent that waits on
  /// the caller through a pending ask, anywhere.
  PeerChain({required List<String> lineage, required Set<String> waiting})
    : lineage = List.unmodifiable(lineage),
      waiting = Set.unmodifiable(waiting);

  /// No chain: a run nobody above started.
  static final PeerChain none = PeerChain(lineage: const [], waiting: const {});

  /// See the constructor.
  final List<String> lineage;

  /// See the constructor.
  final Set<String> waiting;

  /// How many agents are above the caller.
  int get depth => lineage.length;

  /// Whether handing work to [agentId] would close a loop.
  bool wouldCycle(String agentId) =>
      lineage.contains(agentId) || waiting.contains(agentId);

  /// The chain a hand-off from [callerAgentId] carries: the lineage plus the
  /// caller, cut to the newest `Wake.maxChainLength` agents.
  List<String> extendedBy(String callerAgentId) {
    final chain = [...lineage.where((a) => a != callerAgentId), callerAgentId];
    return chain.length <= Wake.maxChainLength
        ? chain
        : chain.sublist(chain.length - Wake.maxChainLength);
  }
}

/// The hash of a question with case and whitespace folded, for the
/// duplicate check.
String peerQuestionHash(String question) => sha256
    .convert(
      utf8.encode(
        question.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' '),
      ),
    )
    .toString();

/// The final answer of an agent turn: its last block of text (the text
/// segments after the last tool call, or before it when the turn ended on a
/// tool call), trimmed. A message with no transcript gives its content.
String finalAnswerOf(Message message) {
  final segments = message.transcript;
  if (segments.isEmpty) {
    return message.content.trim();
  }
  final block = <String>[];
  for (var i = segments.length - 1; i >= 0; i--) {
    final segment = segments[i];
    if (segment is TextSegment) {
      block.insert(0, segment.text);
      continue;
    }
    if (block.join().trim().isNotEmpty) {
      break;
    }
    block.clear();
  }
  return block.join().trim();
}

/// Cuts [text] to [max] characters with a note that the rest is in the
/// conversation.
String cutWithNote(String text, int max, {required String where}) {
  if (text.length <= max) {
    return text;
  }
  final note = '\n…(truncated: the full text is in $where)';
  return '${text.substring(0, max - note.length)}$note';
}

/// The `peerMessage` wake that delivers a peer's message (or an ask's
/// question) to [recipientAgentId] in its conversation. No requester: a
/// run a peer starts is the bot's. The followUp lane: a live run of the
/// recipient in the same conversation takes it at its next turn boundary.
Wake peerMessageWake({
  required String id,
  required String workspaceId,
  required String spaceId,
  required String conversationId,
  required String recipientAgentId,
  required String payload,
  required String messageId,
  required List<String> chain,
  required DateTime now,
  String? senderAgentId,
  String? senderName,
  String? senderRunId,
  String? senderConversationId,
  PeerAsk? ask,
}) => Wake(
  id: id,
  workspaceId: workspaceId,
  spaceId: spaceId,
  conversationId: conversationId,
  agentId: recipientAgentId,
  reason: WakeReason.peerMessage,
  lane: WakeLane.followUp,
  payload: cutWithNote(
    payload,
    Wake.maxPayloadLength,
    where: 'this conversation',
  ),
  detail: WakeDetail(
    askId: ask?.id,
    sourceAgentId: senderAgentId,
    sourceRunId: senderRunId,
    sourceConversationId: senderConversationId,
    messageId: messageId,
    fields: {
      WakeFields.sourceAgentName: ?senderName,
      if (ask != null) WakeFields.askKind: ask.kind.wire,
    },
  ),
  dedupKey: ask == null ? 'peer:$messageId' : 'ask:${ask.id}:message',
  notBefore: now,
  expiresAt: ask?.expiresAt,
  chain: chain,
  expectsReply: ask != null,
  createdAt: now,
);

/// The `peerReply` wake that tells [ask]'s asker what became of it, in the
/// asker's own conversation. [status] is a settled status (`answered`,
/// `failed`, `expired`) or a [PeerReplyInterim] one; the dedup key makes
/// the settling notice one per ask and each interim one per kind. The
/// requester is the asker's run's ([PeerAsk.requestedByUserId], read from
/// that run's row when the ask was made): the reply continues its work.
Wake peerReplyWake({
  required PeerAsk ask,
  required String status,
  required String recipientName,
  required DateTime now,
  String payload = '',
  String? recipientRunId,
  String? replyMessageId,
  Map<String, Object?> fields = const {},
}) {
  final interim = PeerReplyInterim.all.contains(status);
  final suffix = interim ? PeerReplyInterim.suffixOf(status) : 'reply';
  final chain = ask.chain.isNotEmpty && ask.chain.last == ask.askerAgentId
      ? ask.chain.sublist(0, ask.chain.length - 1)
      : ask.chain;
  return Wake(
    id: peerReplyWakeId(ask.id, suffix),
    workspaceId: ask.workspaceId,
    spaceId: ask.askerSpaceId,
    conversationId: ask.askerConversationId,
    agentId: ask.askerAgentId,
    reason: WakeReason.peerReply,
    payload: cutWithNote(
      payload,
      PeerAskLimits.maxReplyChars,
      where: "the recipient's conversation",
    ),
    detail: WakeDetail(
      askId: ask.id,
      sourceAgentId: ask.recipientAgentId,
      sourceRunId: recipientRunId,
      sourceConversationId: ask.recipientConversationId,
      messageId: replyMessageId,
      status: status,
      fields: {
        WakeFields.sourceAgentName: recipientName,
        WakeFields.askKind: ask.kind.wire,
        ...fields,
        // The reply continues the asker's run: its chain of wakes goes on.
        WakeFields.continuesRunId: ?ask.askerRunId,
      },
    ),
    dedupKey: 'ask:${ask.id}:$suffix',
    notBefore: now,
    requestedByUserId: ask.requestedByUserId,
    chain: chain,
    createdAt: now,
  );
}

/// The id of [askId]'s `peerReply` wake with dedup suffix [suffix], so the
/// ask service can cancel an interim notice the ask outran.
String peerReplyWakeId(String askId, String suffix) => 'ask-$askId-$suffix';
