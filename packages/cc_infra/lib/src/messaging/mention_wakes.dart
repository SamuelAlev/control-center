import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/services/agent_mention_parser.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_frame.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_detail.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/services/mention_wake_policy.dart';
import 'package:cc_domain/features/messaging/domain/services/peer_delegation_guards.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:uuid/uuid.dart';

/// Inserts a wake (`WakeQueueService.enqueue`). True when it was written.
typedef WakeSink = Future<bool> Function(Wake wake);

/// Wakes the teammates an agent `@mentions` in a finished turn
/// ("@architect …"): one `peerMessage` wake per teammate, through the wake
/// queue, never a direct dispatch.
///
/// Bounds: [AgentMentionParser.parseProseMentions] (no code, addresses or
/// version pins); [MentionWakePolicy] (exact name, no prefix, ambiguity
/// wakes nobody, no self); [DelegationGuards] depth and cycle over the chain
/// (no new authority, unlike `delegate_task`); [PairRateLimiter] per ordered
/// pair. The woken run acts for nobody: the requester of the mentioning run
/// is not inherited, so another agent's text never borrows a person's
/// identity. A person's own message that mentions an agent is a direct
/// dispatch, not this.
class MentionWakes {
  /// Creates the waker over [_agents] and [_messages] (refusal rows);
  /// [_addAgentToSpace] makes the woken agent a participant.
  MentionWakes(
    this._agents,
    this._messages,
    this._addAgentToSpace, {
    this._clock = DateTime.now,
  });

  final AgentRepository? _agents;
  final MessagingRepository _messages;
  final Future<void> Function(
    String workspaceId,
    String spaceId,
    String agentId,
  )
  _addAgentToSpace;
  final DateTime Function() _clock;

  /// Where the wakes go. Late-bound: the wake queue is built after the
  /// messaging service. Null inserts nothing (a server without a queue).
  WakeSink? sink;

  /// The chains wakes drained into live runs carried, per run (bounded):
  /// the run's own chain grows by them at its turn's end.
  final Map<String, List<String>> _carried = {};

  /// Most runs [_carried] remembers; the oldest is dropped first.
  static const int maxCarriedRuns = 512;

  /// A wake with [chain] was drained into the live run [runId]: the run's
  /// mention chain grows by it, so depth and cycle checks at its turn's end
  /// count the agents that led to the wake (`WakeQueueService.chainCarried`).
  void carryChain(String workspaceId, String runId, List<String> chain) {
    final key = '$workspaceId\u0000$runId';
    _carried[key] = mergeChains(_carried.remove(key) ?? const [], chain);
    while (_carried.length > maxCarriedRuns) {
      _carried.remove(_carried.keys.first);
    }
  }

  /// [first], then the agents of [then] it does not already name, in order.
  static List<String> mergeChains(List<String> first, List<String> then) => [
    ...first,
    for (final agent in then)
      if (!first.contains(agent)) agent,
  ];

  static const _uuid = Uuid();
  final _parser = const AgentMentionParser();
  final _policy = const MentionWakePolicy();
  final _guards = const DelegationGuards();

  /// Backstop for wake chains that are individually legal but repeat: the
  /// cycle guard already makes a loop impossible WITHIN one chain, so this
  /// bounds how often a given ordered pair can restart one.
  final _rateLimiter = PairRateLimiter(
    maxPerWindow: 5,
    window: const Duration(minutes: 5),
  );

  /// The truncation note at the end of a cut payload.
  static const String truncatedNote =
      '\n…(truncated — the full turn is in this conversation)';

  /// The payload of a mention wake: the mentioning turn, cut to fit
  /// `Wake.maxPayloadLength`.
  static String payloadOf(String content) =>
      content.length <= Wake.maxPayloadLength
      ? content
      : '${content.substring(0, Wake.maxPayloadLength - truncatedNote.length)}'
            '$truncatedNote';

  /// Wakes the agents [content] mentions. [senderRunId] is the mentioning
  /// run (the dedup key's anchor); [chain] the agents whose
  /// mentions led to [senderAgentId]'s run, oldest first. Best-effort: never
  /// throws into the turn that already finished.
  Future<void> wakeMentioned({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String senderAgentId,
    required String senderAgentName,
    required String senderRunId,
    required String content,
    required List<String> chain,
  }) async {
    // What wakes drained into this run carried joins its own chain.
    final carried = _carried.remove('$workspaceId\u0000$senderRunId');
    final runChain = carried == null ? chain : mergeChains(chain, carried);
    try {
      final agents = _agents;
      final insert = sink;
      if (agents == null || insert == null) {
        return;
      }
      final tokens = _parser.parseProseMentions(content);
      if (tokens.isEmpty) {
        return;
      }
      final candidates = await agents.watchByWorkspace(workspaceId).first;
      final targets = _policy.resolveTargets(
        tokens: tokens,
        candidates: candidates,
        selfAgentId: senderAgentId,
      );
      // An unresolved token is prose, not a failed mention: agents write "@"
      // in sentences all the time. A REFUSED wake names a real teammate that
      // was deliberately not reached, so that one is reported below.
      if (targets.isEmpty) {
        return;
      }

      // The chain the woken agents inherit: everyone on this wake path, the
      // agent that just spoke last.
      final chainSoFar = [...runChain, senderAgentId];
      final depth = _guards.checkDepth(runChain.length);
      if (!depth.allowed) {
        await _postRefusals(workspaceId, spaceId, conversationId, [
          '${depth.refusal} No agent was woken by this turn.',
        ]);
        return;
      }

      final refusals = <String>[];
      final now = _clock();
      for (final target in targets) {
        final cycle = _guards.checkCycle(chainSoFar, target.agent.id);
        if (!cycle.allowed) {
          refusals.add('@${target.agent.name}: ${cycle.refusal}');
          continue;
        }
        if (!_rateLimiter.tryAcquire(senderAgentId, target.agent.id, now)) {
          refusals.add(
            '@${target.agent.name}: rate limited — $senderAgentName has '
            'woken it too many times in a short window.',
          );
          continue;
        }
        await _addAgentToSpace(workspaceId, spaceId, target.agent.id);
        await insert(
          Wake(
            id: _uuid.v4(),
            workspaceId: workspaceId,
            spaceId: spaceId,
            conversationId: conversationId,
            agentId: target.agent.id,
            reason: WakeReason.peerMessage,
            payload: payloadOf(content),
            detail: WakeDetail(
              sourceAgentId: senderAgentId,
              sourceRunId: senderRunId,
              sourceConversationId: conversationId,
              messageId: senderRunId,
              fields: {
                WakeFields.sourceAgentName: senderAgentName,
                WakeFields.via: WakeFields.viaMention,
              },
            ),
            dedupKey: 'mention:$senderRunId:${target.agent.id}',
            notBefore: now,
            chain: chainSoFar,
            createdAt: now,
          ),
        );
      }
      await _postRefusals(workspaceId, spaceId, conversationId, refusals);
    } on Object catch (e) {
      // A wake is a courtesy on top of a turn that already succeeded.
      CcInfraLog.warning('MentionWakes: waking mentioned agents failed: $e');
    }
  }

  /// Posts refused wakes as one system message. A guard that declines
  /// silently is indistinguishable from the bug this exists to fix.
  Future<void> _postRefusals(
    String workspaceId,
    String spaceId,
    String conversationId,
    List<String> refusals,
  ) async {
    if (refusals.isEmpty) {
      return;
    }
    await _messages.sendMessage(
      workspaceId: workspaceId,
      spaceId: spaceId,
      content: refusals.length == 1
          ? 'Mention not delivered — ${refusals.single}'
          : 'Mentions not delivered:\n'
                '${refusals.map((r) => '• $r').join('\n')}',
      senderId: 'system',
      senderType: 'system',
      messageType: 'system',
      conversationId: conversationId,
    );
  }
}
