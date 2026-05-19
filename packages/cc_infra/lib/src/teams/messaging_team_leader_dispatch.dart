import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/teams/domain/ports/team_leader_dispatch_port.dart';

/// Dispatches a team's leader by spinning up a conversation and summoning the
/// leader agent into it with the coordinator briefing as the seed message.
///
/// Reuses the standard messaging → dispatch path (the same one a `@`-mention
/// uses), so the leader's delegation links (`[@Name](mention://agent/<uuid>)`
/// from the roster) resolve and summon members through the existing flow.
class MessagingTeamLeaderDispatch implements TeamLeaderDispatchPort {
  /// Creates a [MessagingTeamLeaderDispatch].
  MessagingTeamLeaderDispatch(this._messaging);

  final MessagingPort _messaging;

  @override
  Future<void> dispatchLeader({
    required String workspaceId,
    required String agentId,
    required String prompt,
    String? ticketId,
    String? spaceId,
  }) async {
    try {
      final space = await _messaging.createSpace(
        workspaceId,
        ticketId != null ? 'Team routing · $ticketId' : 'Team routing',
        [agentId],
      );
      await _messaging.sendUserMessage(workspaceId, space.id, prompt);
      await _messaging.dispatchAgent(
        workspaceId: workspaceId,
        spaceId: space.id,
        agentId: agentId,
        prompt: prompt,
        ticketId: ticketId,
      );
    } on Object catch (e, st) {
      CcDomainLog.error(
        'MessagingTeamLeaderDispatch: failed to dispatch leader $agentId',
        e,
        st,
      );
    }
  }
}
