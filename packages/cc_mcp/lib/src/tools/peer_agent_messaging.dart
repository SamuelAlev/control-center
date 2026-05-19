import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_origin.dart';

/// The outcome of resolving a peer-message recipient by id or unique name
/// (PRD 22 §2). Resolution is exact — never fuzzy — so a typo names candidates
/// rather than silently reaching the wrong agent.
sealed class RecipientResolution {
  /// Creates a [RecipientResolution].
  const RecipientResolution();
}

/// The recipient was resolved unambiguously to [agent].
class ResolvedRecipient extends RecipientResolution {
  /// Creates a [ResolvedRecipient].
  const ResolvedRecipient(this.agent);

  /// The resolved recipient agent.
  final Agent agent;
}

/// The recipient could not be resolved (missing args, unknown id/name, or an
/// ambiguous name). [message] is the agent-facing explanation to return as a
/// tool error — it lists candidate names/ids so the caller can retry.
class UnresolvedRecipient extends RecipientResolution {
  /// Creates an [UnresolvedRecipient].
  const UnresolvedRecipient(this.message);

  /// The agent-facing explanation of why resolution failed.
  final String message;
}

/// Shared plumbing for the agent↔agent peer-messaging tools (`send_to_agent`,
/// `ask_agent`): exact recipient resolution and agent-DM channel reuse/creation.
///
/// Both tools resolve peers and pair channels identically, so this lives in one
/// place. Workspace isolation is honoured: only agents in the caller's
/// workspace are eligible and channels are searched within the workspace.
class PeerAgentMessaging {
  /// Creates a [PeerAgentMessaging] over the given repositories. [eventBus]
  /// (when wired) receives [ChannelCreated] for a freshly minted DM channel so
  /// the background provisioner flips it out of its born-`provisioning` state.
  const PeerAgentMessaging({
    required AgentRepository agents,
    required MessagingRepository messaging,
    DomainEventBus? eventBus,
  }) : _agents = agents,
       _messaging = messaging,
       _eventBus = eventBus;

  final AgentRepository _agents;
  final MessagingRepository _messaging;
  final DomainEventBus? _eventBus;

  /// Resolves the recipient by [toAgentId] (preferred) or exact [toAgentName]
  /// within [workspaceId]. An unknown id, an unknown name, or an ambiguous name
  /// returns an [UnresolvedRecipient] naming the candidates — never a fuzzy
  /// match. Providing neither is also unresolved.
  Future<RecipientResolution> resolveRecipient({
    required String workspaceId,
    String? toAgentId,
    String? toAgentName,
  }) async {
    final candidates = await _agents.watchByWorkspace(workspaceId).first;
    if (toAgentId != null && toAgentId.isNotEmpty) {
      final matches = candidates.where((a) => a.id == toAgentId).toList();
      if (matches.isEmpty) {
        return UnresolvedRecipient(
          'No agent with id "$toAgentId" exists in workspace $workspaceId.',
        );
      }
      return ResolvedRecipient(matches.first);
    }
    if (toAgentName != null && toAgentName.isNotEmpty) {
      final matches = candidates.where((a) => a.name == toAgentName).toList();
      if (matches.isEmpty) {
        final names = candidates.map((a) => a.name).join(', ');
        return UnresolvedRecipient(
          'No agent named "$toAgentName" in workspace $workspaceId. '
          'Available agents: ${names.isEmpty ? '(none)' : names}.',
        );
      }
      if (matches.length > 1) {
        final ids = matches.map((a) => a.id).join(', ');
        return UnresolvedRecipient(
          'Agent name "$toAgentName" is ambiguous in workspace $workspaceId '
          '(${matches.length} matches). Use to_agent_id instead. '
          'Candidate ids: $ids.',
        );
      }
      return ResolvedRecipient(matches.first);
    }
    return const UnresolvedRecipient(
      'Missing recipient: provide either to_agent_id or to_agent_name.',
    );
  }

  /// Returns the existing agent-DM channel between the two agents, or creates a
  /// new one ([ChannelOrigin.agentDm]) when none exists. Reuse matches on the
  /// exact set of non-human participants, so a fresh channel is only minted the
  /// first time this pair converses.
  Future<Channel> resolveOrCreateAgentDm({
    required String workspaceId,
    required String toAgentId,
    required String toAgentName,
    String? fromAgentId,
    String? fromAgentName,
  }) async {
    final target = <String>{
      toAgentId,
      if (fromAgentId != null && fromAgentId.isNotEmpty) fromAgentId,
    };
    final channels = await _messaging
        .watchChannelsByWorkspace(workspaceId)
        .first;
    for (final channel in channels) {
      if (channel.origin != ChannelOrigin.agentDm) {
        continue;
      }
      final participants = await _messaging.getParticipants(
        workspaceId,
        channel.id,
      );
      final agentIds = <String>{
        for (final p in participants)
          if (!p.isUser) p.principalId,
      };
      if (agentIds.length == target.length && agentIds.containsAll(target)) {
        return channel;
      }
    }
    final name = (fromAgentName != null && fromAgentName.isNotEmpty)
        ? '$fromAgentName ↔ $toAgentName'
        : 'DM with $toAgentName';
    final channel = await _messaging.createChannel(
      workspaceId,
      name,
      target.toList(),
      origin: ChannelOrigin.agentDm,
    );
    // The repo insert does not publish and channels are born `provisioning` —
    // announce the creation so the background provisioner flips it to ready.
    _eventBus?.publish(
      ChannelCreated(
        channelId: channel.id,
        workspaceId: workspaceId,
        occurredAt: DateTime.now(),
      ),
    );
    return channel;
  }
}
