import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/core/domain/value_objects/wake_context.dart';
import 'package:control_center/features/messaging/domain/entities/channel.dart';

/// A parsed structured agent mention.
class StructuredMention {
  /// Creates a [StructuredMention].
  const StructuredMention({required this.agentId, required this.raw});

  /// The agent ID extracted from the mention.
  final String agentId;
  /// The raw mention text.
  final String raw;
}

/// Port for messaging channel operations.
abstract interface class MessagingPort {
  /// Sends a user message to a channel.
  Future<void> sendUserMessage(String channelId, String content);

  /// Adds an agent to a channel.
  Future<void> addAgentToChannel(String channelId, String agentId);

  /// Creates a group channel. The optional [mode] is set on the channel row
  /// at creation time so the dispatch pipeline picks it up on the first
  /// message dispatched into the channel.
  Future<Channel> createGroup(
    String name,
    List<String> agentIds, {
    ConversationMode mode = ConversationMode.chat,
    String? workspaceId,
  });

  /// Sends a user message and automatically dispatches agents.
  Future<void> sendAndDispatch(
    String channelId,
    String content, {
    String? workspaceId,
    List<StructuredMention>? structuredMentions,
    String? parentMessageId,
  });

  /// Dispatches an agent to respond in a channel.
  ///
  /// The implementation resolves `agentName`, `workingDirectory`, and
  /// `adapterId` from the agent record so callers do not need to pass them.
  Future<void> dispatchAgent({
    required String channelId,
    required String agentId,
    required String prompt,
    String? workspaceId,
    String? ticketId,
    WakeContext? wakeContext,
    String? parentMessageId,
  });

  /// Marks a pending plan as refining and re-dispatches with feedback.
  Future<void> refinePlan({
    required String channelId,
    required String feedback,
    String? workspaceId,
  });
}
