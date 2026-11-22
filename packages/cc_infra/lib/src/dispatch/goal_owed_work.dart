import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/entities/peer_ask.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake_rule.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/peer_ask_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_trigger.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';

/// The ids of the tickets an agent delegated from a conversation that are
/// not finished yet (`tickets.delegated_from_conversation_id`).
typedef OpenDelegations =
    Future<List<String>> Function(
      String workspaceId, {
      required String conversationId,
      required String agentId,
    });

/// What a goal's agent is owed in the goal's conversation, read from rows
/// (plan section 8, "What happens when a segment ends"): when anything is,
/// a segment that ended normally waits (`hold: waiting`) for the first wake
/// instead of starting the next segment at once.
class GoalOwed {
  /// Creates the reading.
  GoalOwed({
    required List<Wake> wakes,
    required List<WakeRule> rules,
    required List<PeerAsk> asks,
    required List<String> delegations,
  }) : wakes = List.unmodifiable(wakes),
       rules = List.unmodifiable(rules),
       asks = List.unmodifiable(asks),
       delegations = List.unmodifiable(delegations);

  /// Pending one-off wakes for the agent in the conversation: not the
  /// goal's own, not a repeating or self-paced rule's, and not held (nothing
  /// delivers a held wake until a person releases it).
  final List<Wake> wakes;

  /// Active one-off and event rules of the agent in the conversation (a
  /// note for a time, a watch). A repeating or self-paced rule is not owed
  /// work: it fires whether or not the goal moves.
  final List<WakeRule> rules;

  /// Pending asks the agent sent from the conversation.
  final List<PeerAsk> asks;

  /// The ids of the tickets the agent delegated from the conversation that
  /// are still open.
  final List<String> delegations;

  /// Whether anything is owed.
  bool get isOwed =>
      wakes.isNotEmpty ||
      rules.isNotEmpty ||
      asks.isNotEmpty ||
      delegations.isNotEmpty;

  /// What the goal's agent set up and still waits on, one id per piece of
  /// work, sorted: a wake rule (`rule:`), an ask it sent (`ask:`), a ticket
  /// it delegated (`ticket:`). A pending wake that delivers one of these (a
  /// rule's wake, an ask's reply, a ticket's completion) is that work's
  /// id, so its answer arriving adds nothing new. Any other pending wake
  /// (another agent's message, an assignment) arrived on its own: the agent
  /// did not set it up, so it is not here. An id here that the last wait
  /// did not have is work set up since (`GoalProgressMarks.isFresh`).
  List<String> get setUp {
    final ids = <String>{
      for (final w in wakes) ?_setUpBy(w),
      for (final r in rules) 'rule:${r.id}',
      for (final a in asks) 'ask:${a.id}',
      for (final t in delegations) 'ticket:$t',
    };
    return ids.toList()..sort();
  }

  /// The work [wake] delivers, when the agent set it up; null for a wake
  /// that arrived on its own.
  static String? _setUpBy(Wake wake) {
    final detail = wake.detail;
    final rule = detail.ruleId;
    if (rule != null && rule.isNotEmpty) {
      return 'rule:$rule';
    }
    return switch (wake.reason) {
      WakeReason.peerReply when detail.askId != null => 'ask:${detail.askId}',
      WakeReason.childCompleted when detail.ticketId != null =>
        'ticket:${detail.ticketId}',
      _ => null,
    };
  }

  /// One line for the conversation: what the goal waits for.
  String describe() => [
    if (wakes.isNotEmpty) '${wakes.length} pending wake(s)',
    if (rules.isNotEmpty) '${rules.length} active wake rule(s)',
    if (asks.isNotEmpty) '${asks.length} pending ask(s)',
    if (delegations.isNotEmpty)
      '${delegations.length} open delegated ticket(s)',
  ].join(', ');
}

/// Whether a rule with [trigger] fires again and again (`Every`, `Cron`,
/// `SelfPaced`) rather than once or on an event (`OnceAt`, `OnEvent`).
bool triggerRepeats(WakeTrigger trigger) => switch (trigger) {
  Every() || Cron() || SelfPaced() => true,
  OnceAt() || OnEvent() => false,
};

/// Reads what a goal's agent is owed in the goal's conversation. A producer
/// whose rows it reads (the wake queue, wake rules, peer asks, delegated
/// tickets) needs nothing else to be counted: its rows are the signal. A
/// source that is not wired (null) counts nothing.
class GoalOwedWork {
  /// Creates the reader.
  const GoalOwedWork({
    required this.wakes,
    required this.rules,
    required this.asks,
    required this.openDelegations,
  });

  /// The wake rows.
  final WakeRepository wakes;

  /// The wake rules; null where none are kept.
  final WakeRuleRepository? rules;

  /// The peer asks; null where none are kept.
  final PeerAskRepository? asks;

  /// The delegated tickets; null where none are kept.
  final OpenDelegations? openDelegations;

  /// What [goal]'s agent is owed in [goal]'s conversation, workspace-scoped.
  Future<GoalOwed> of(AgentGoalRun goal) async {
    final ws = goal.workspaceId;
    final conversation = goal.conversationId;
    final agent = goal.agentId;
    final pending = await wakes.listForConversation(
      ws,
      conversation,
      states: const {WakeState.pending},
    );
    final activeRules =
        await rules?.listForConversation(
          ws,
          conversation,
          statuses: const {WakeRuleStatus.active},
        ) ??
        const <WakeRule>[];
    final pendingAsks =
        await asks?.listPending(
          ws,
          askerAgentId: agent,
          askerConversationId: conversation,
        ) ??
        const <PeerAsk>[];
    final delegations =
        await openDelegations?.call(
          ws,
          conversationId: conversation,
          agentId: agent,
        ) ??
        const <String>[];
    final repeating = {
      for (final rule in activeRules)
        if (triggerRepeats(rule.trigger)) rule.id,
    };
    return GoalOwed(
      wakes: [
        for (final wake in pending)
          if (wake.agentId == agent &&
              wake.detail.goalId != goal.id &&
              !repeating.contains(wake.detail.ruleId))
            wake,
      ],
      rules: [
        for (final rule in activeRules)
          if (rule.agentId == agent && !triggerRepeats(rule.trigger)) rule,
      ],
      asks: pendingAsks,
      delegations: delegations,
    );
  }
}
