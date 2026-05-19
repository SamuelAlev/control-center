/// Dispatches a team's **leader** agent with a coordinator briefing.
///
/// The domain `TeamRoutingService` builds the operating protocol +
/// skill-surfaced roster and hands it to this port as a ready-made
/// `prompt`; the infrastructure adapter owns the actual run (conversation
/// creation, dispatch stack, sandbox). Keeping it behind a port lets the
/// routing logic stay pure-Dart and unit-testable with a fake.
abstract interface class TeamLeaderDispatchPort {
  /// Runs the leader [agentId] with [prompt] in [workspaceId]. The adapter
  /// resolves (or creates) a conversation for the [ticketId] when given, so
  /// the leader's delegation thread is attached to the ticket.
  Future<void> dispatchLeader({
    required String workspaceId,
    required String agentId,
    required String prompt,
    String? ticketId,
    String? spaceId,
  });
}
