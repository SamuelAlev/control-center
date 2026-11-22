import 'package:cc_domain/core/domain/value_objects/wake_context.dart';

/// Dispatches a team's **leader** agent with a coordinator briefing.
///
/// The domain `TeamRoutingService` builds the operating protocol +
/// skill-surfaced roster and hands it to this port as a ready-made
/// `prompt`; the infrastructure adapter owns the actual run (conversation
/// creation, dispatch stack, sandbox). Keeping it behind a port lets the
/// routing logic stay pure-Dart and unit-testable with a fake.
abstract interface class TeamLeaderDispatchPort {
  /// Runs the leader [agentId] with [prompt] in [workspaceId], in [spaceId]
  /// when the ticket already has one (the team's routed space is reused,
  /// never minted per routing). With no [spaceId] the adapter creates one
  /// and records it on [ticketId]. [reason] is why the leader runs:
  /// `assignment` (the ticket reached the team). [startedByRunId] is the
  /// agent run whose `assign_ticket` call made the assignment
  /// (`WakeContext.startedByRunId`); null for a person's.
  Future<void> dispatchLeader({
    required String workspaceId,
    required String agentId,
    required String prompt,
    required WakeReason reason,
    required String? startedByRunId,
    String? ticketId,
    String? spaceId,
  });

  /// Wakes the leader with a `childCompleted` wake when a member it woke
  /// finished a run ([TeamMemberSettled]): in the leader's own conversation,
  /// once per member run.
  Future<void> wakeLeader(TeamMemberSettled settled);
}

/// A team member's run that a leader's wake started has ended.
class TeamMemberSettled {
  /// Creates the fact.
  const TeamMemberSettled({
    required this.workspaceId,
    required this.teamId,
    required this.leaderAgentId,
    required this.leaderConversationId,
    required this.memberAgentId,
    required this.memberRunId,
    required this.endReason,
    this.memberConversationId,
    this.leaderRunId,
    this.ticketId,
  });

  /// The workspace.
  final String workspaceId;

  /// The team.
  final String teamId;

  /// The leader to wake.
  final String leaderAgentId;

  /// Where the leader is woken: the conversation it woke the member from.
  final String leaderConversationId;

  /// The leader's run that woke the member (its requester is the wake's).
  final String? leaderRunId;

  /// The member.
  final String memberAgentId;

  /// The member's run that ended.
  final String memberRunId;

  /// The member's conversation.
  final String? memberConversationId;

  /// The ticket, when there is one.
  final String? ticketId;

  /// How the member's run ended (`RunEndReason` wire name).
  final String endReason;
}
