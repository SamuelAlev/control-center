import 'package:cc_domain/features/dispatch/domain/context/context_window_usage.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_token_totals.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The fixed system-overhead allowance `computeContextWindowUsage` adds on top
/// of the conversation — an approximation of the persistent system prompt and
/// tool schemas, kept here so the aggregate-fed meter reads identically to the
/// message-fed one it replaced.
const int _systemOverheadTokens = 2000;

/// Live size of a space's standing conversation, aggregated SERVER-side.
///
/// The meters need a sum over the live region and nothing else, so the sum is
/// what crosses the wire. Folding it client-side meant holding the whole
/// conversation open — an uncapped subscription re-sending every message on
/// every write — which is what made opening a long chat, or merely hovering a
/// busy space in the sidebar, cost its entire history.
///
/// The conversation is RESOLVED rather than assumed, exactly as
/// [spaceMessagesProvider] does: a conversation owns its own uuid and is never
/// the space id.
final conversationTokenTotalsProvider = StreamProvider.autoDispose
    .family<ConversationTokenTotals, String>((ref, spaceId) {
      final conversationId = ref
          .watch(standingConversationIdProvider(spaceId))
          .value;
      if (conversationId == null) {
        return Stream.value(ConversationTokenTotals.empty);
      }
      return ref
          .watch(messagingSummariesPortProvider)
          .watchConversationTokens(
            ref.requireWorkspaceId(),
            spaceId,
            conversationId,
          );
    });

/// Live context-window usage for a conversation against a single agent's
/// window: the provider-reported reading of the newest model call when a run
/// reported one (and the window it ran with), else the server-computed
/// estimate against the agent's configured context size in tokens. Zero
/// window when neither is known — the meter then waits for the inspection.
///
/// [ContextWindowUsage.lastTurn] is always null here: the aggregate carries no
/// per-message detail, and nothing renders it — the meters read `usedTokens`,
/// `windowTokens` and the thresholds derived from them.
final conversationContextUsageProvider = Provider.autoDispose
    .family<ContextWindowUsage, ({String spaceId, String agentId})>((
      ref,
      args,
    ) {
      final totals =
          ref.watch(conversationTokenTotalsProvider(args.spaceId)).value ??
          ConversationTokenTotals.empty;
      final agent = ref.watch(agentDetailProvider(args.agentId)).value;
      return ContextWindowUsage(
        usedTokens:
            totals.reportedContextTokens ??
            _systemOverheadTokens + totals.tokens,
        windowTokens: totals.reportedWindowTokens ?? agent?.contextSize ?? 0,
      );
    });
