import 'package:cc_domain/cc_domain.dart' show MessageDto;
import 'package:cc_domain/features/messaging/domain/services/agent_turn_retry_policy.dart';

/// The failed agent turns of [feed] (one conversation, oldest first) that
/// offer Retry: those the server would still retry, by the same rule
/// ([AgentTurnRetryPolicy]).
Set<String> retryableTurnIds(List<MessageDto> feed) =>
    const AgentTurnRetryPolicy().retryable([
      for (final message in feed)
        if (message.messageType == 'agent_turn')
          (
            id: message.id,
            agentId: message.senderId,
            metadata: message.metadata,
          ),
    ]);
