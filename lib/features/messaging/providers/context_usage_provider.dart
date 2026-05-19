import 'package:cc_domain/features/dispatch/domain/context/context_window_usage.dart';
import 'package:cc_domain/features/dispatch/domain/context/token_estimator.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Default character budget when an agent has no configured `contextSize`
/// (mirrors the dispatch-layer fallback of ~1M characters).
const int _defaultContextChars = 1000000;

/// Live context-window usage for a conversation against a single agent's
/// window. Watches the channel's messages and the agent's configured context
/// size, mapping the character budget to an estimated token window. Powers the
/// "145k / 200k" meter and mirrors the same estimate the auto-compaction
/// trigger uses, so the gauge and the behaviour agree.
final conversationContextUsageProvider = Provider.autoDispose
    .family<ContextWindowUsage, ({String channelId, String agentId})>(
  (ref, args) {
    final messages =
        ref.watch(channelMessagesProvider(args.channelId)).value ?? const [];
    final agent = ref.watch(agentDetailProvider(args.agentId)).value;
    final chars = agent?.contextSize ?? _defaultContextChars;
    final windowTokens = TokenEstimator.instance.windowTokensFromChars(chars);
    return computeContextWindowUsage(
      messages: messages,
      windowTokens: windowTokens,
    );
  },
);
