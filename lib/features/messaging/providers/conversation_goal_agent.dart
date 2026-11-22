import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/services/agent_mention_parser.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The agent a `/goal` typed as [text] would go to, picked the way the
/// server picks a message's responder: an agent the text mentions, else the
/// agent that last spoke in the conversation, else the conversation's owner,
/// else the first top-level agent of the space. Null when the space has no
/// agent.
///
/// It is a forecast for the goal dialog (who not to offer as the checker,
/// and which provider to differ from); the server decides, and refuses a
/// checker that is the goal's own agent with `goal_checker_is_goal_agent`.
String? resolveGoalAgentId({
  required String text,
  required List<Agent> roster,
  required Set<String> spaceAgentIds,
  required List<Message> conversation,
  String? ownerId,
}) {
  for (final token in const AgentMentionParser().parseMentions(text)) {
    for (final a in roster) {
      if (a.name.toLowerCase().startsWith(token)) {
        return a.id;
      }
    }
  }
  final inSpace = [
    for (final a in roster)
      if (spaceAgentIds.contains(a.id)) a,
  ];
  if (inSpace.isEmpty) {
    return null;
  }
  for (final m in conversation.reversed) {
    if (m.senderType == SenderType.agent &&
        inSpace.any((a) => a.id == m.senderId)) {
      return m.senderId;
    }
  }
  if (ownerId != null && inSpace.any((a) => a.id == ownerId)) {
    return ownerId;
  }
  return (inSpace.where((a) => a.isTopLevel).firstOrNull ?? inSpace.first).id;
}

/// [resolveGoalAgentId] over what the conversation surface already holds:
/// its loaded messages, the space's participants and conversations, and the
/// workspace's agents. Reads, never watches: it answers once, when the goal
/// dialog opens.
String? goalAgentIdFor(
  WidgetRef ref, {
  required String text,
  required String spaceId,
  required String conversationId,
}) {
  final workspaceId = ref.read(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return null;
  }
  final roster =
      ref.read(workspaceAgentsProvider(workspaceId)).asData?.value ??
      const <Agent>[];
  final participants =
      ref.read(spaceParticipantsProvider(spaceId)).asData?.value ?? const [];
  final conversations =
      ref.read(spaceConversationsProvider(spaceId)).asData?.value ?? const [];
  final messages =
      ref
          .read(
            spaceFeedWindowedProvider((
              spaceId: spaceId,
              conversationId: conversationId,
            )),
          )
          .asData
          ?.value
          .messages ??
      const <Message>[];
  return resolveGoalAgentId(
    text: text,
    roster: roster,
    spaceAgentIds: {
      for (final p in participants)
        if (p.participantType == PrincipalType.agent) p.principalId,
    },
    conversation: messages,
    ownerId: conversations
        .where((c) => c.id == conversationId)
        .firstOrNull
        ?.createdByPrincipalId,
  );
}
