import 'package:cc_data/cc_data.dart' show RemoteContextRepository;
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/dispatch/domain/context/context_inspection.dart';
import 'package:cc_domain/features/dispatch/domain/context/conversation_token_estimator.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_token_totals.dart';
import 'package:cc_harness/context.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/messaging/providers/context_usage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Server-side context inspection reads (the `context.inspect` RPC op).
final contextInspectionRepositoryProvider = Provider<RemoteContextRepository>(
  (ref) => RemoteContextRepository(ref.watch(rpcClientProvider)),
);

/// The server-side PERSISTENT context breakdown for one (space, agent) pair:
/// system prompt, rules, skills, tool surface, subagents and memory — never
/// the conversation, whose size arrives separately as an aggregate
/// ([conversationTokenTotalsProvider]) and whose messages only the explorer
/// reads (see [contextBreakdownProvider]).
///
/// `includeContent` asks the server to carry every part's verbatim text; the
/// summary request (`false`, what the flyout uses) transfers counts only.
final contextInspectionProvider = FutureProvider.autoDispose
    .family<
      ContextInspection,
      ({String spaceId, String agentId, bool includeContent})
    >(
      (ref, args) => ref
          .watch(contextInspectionRepositoryProvider)
          .inspect(
            spaceId: args.spaceId,
            agentId: args.agentId,
            includeContent: args.includeContent,
          ),
    );

/// A context-window reading that merges the server-side persistent breakdown
/// with the client-computed conversation segment into one ordered segment list
/// plus totals. Shared by the flyout (counts only) and the explorer tab
/// (counts + verbatim content) so both render the same numbers.
class ContextBreakdown {
  /// Creates a [ContextBreakdown].
  const ContextBreakdown({
    required this.inspection,
    required this.segments,
    required this.totalTokens,
    required this.windowTokens,
    required this.isLoading,
    required this.hasError,
  });

  /// The server inspection, or null while the summary RPC has not landed yet
  /// (or failed). The conversation segment below is always present, so a
  /// loading popover still shows the client-known part of the breakdown.
  final ContextInspection? inspection;

  /// Every segment in [ContextSegmentKind] declaration order: the server's
  /// persistent segments followed by the client-composed conversation segment.
  final List<ContextSegment> segments;

  /// Total tokens in play: persistent + conversation.
  final int totalTokens;

  /// The model's context window — the server's reading when known, else the
  /// client estimate from the agent's configured context size.
  final int windowTokens;

  /// Whether the summary RPC is in flight with no value yet.
  final bool isLoading;

  /// Whether the summary RPC failed with no value to fall back on.
  final bool hasError;

  /// Fraction of the window used, clamped to `[0, 1]`.
  double get fraction =>
      windowTokens <= 0 ? 0 : (totalTokens / windowTokens).clamp(0.0, 1.0);
}

/// The conversation segment the server deliberately omits: one part per
/// non-compacted message, tokens estimated exactly like
/// `computeContextWindowUsage` (but WITHOUT its fixed system-overhead guess —
/// the server's persistent segments replace that estimate with measured
/// values). Parts always carry their content: the messages are already in
/// memory, so keeping the text costs nothing and lets the explorer show the
/// conversation without a second code path.
ContextSegment buildConversationContextSegment(
  List<Message> messages,
  String? agentName,
) {
  const estimator = TokenEstimator.instance;
  final parts = <ContextPart>[];
  var tokens = 0;
  var chars = 0;
  for (final m in messages) {
    if (m.compacted) {
      continue;
    }
    final messageTokens = estimator.estimateMessage(m);
    tokens += messageTokens;
    chars += m.content.length;
    parts.add(
      ContextPart(
        id: m.id,
        // Honest sender label without l10n (providers see no BuildContext):
        // the agent's display name when the inspection has landed, else the
        // raw sender id.
        title: m.isAgentTurn && agentName != null && agentName.isNotEmpty
            ? agentName
            : m.senderId,
        tokens: messageTokens,
        chars: m.content.length,
        content: m.content,
      ),
    );
  }
  return ContextSegment(
    kind: ContextSegmentKind.conversation,
    tokens: tokens,
    chars: chars,
    parts: parts,
  );
}

/// Merges the server [inspection] (persistent segments, possibly null while
/// loading) with the client-composed [conversation] segment into a single
/// breakdown. Segments come out in [ContextSegmentKind] declaration order
/// regardless of wire order, so the stacked bar is stable across renders.
/// [fallbackWindowTokens] is the client-side window estimate used until the
/// server's authoritative `windowTokens` lands.
ContextBreakdown composeContextBreakdown(
  ContextInspection? inspection,
  ContextSegment conversation,
  int fallbackWindowTokens, {
  required bool isLoading,
  required bool hasError,
}) {
  final segments = <ContextSegment>[
    for (final kind in ContextSegmentKind.values)
      if (kind == ContextSegmentKind.conversation)
        conversation
      else
        ?inspection?.segmentFor(kind),
  ];
  final windowTokens = inspection != null && inspection.windowTokens > 0
      ? inspection.windowTokens
      : fallbackWindowTokens;
  return ContextBreakdown(
    inspection: inspection,
    segments: segments,
    totalTokens: (inspection?.persistentTokens ?? 0) + conversation.tokens,
    windowTokens: windowTokens,
    isLoading: isLoading,
    hasError: hasError,
  );
}

/// The merged breakdown (server summary + client conversation) for one
/// (space, agent) pair — what the context flyout renders. The explorer tab
/// needs verbatim part contents, so it composes its own breakdown from
/// [contextInspectionProvider] with `includeContent: true` through the same
/// [composeContextBreakdown] helper.
final contextBreakdownProvider = Provider.autoDispose
    .family<ContextBreakdown, ({String spaceId, String agentId})>((ref, args) {
      final async = ref.watch(
        contextInspectionProvider((
          spaceId: args.spaceId,
          agentId: args.agentId,
          includeContent: false,
        )),
      );
      final inspection = async.value;
      // Totals, not messages. This provider feeds the header chip and its
      // flyout, and both render only `segment.tokens` — so composing the
      // segment from the conversation would mean holding the whole
      // conversation open to produce one integer. The context EXPLORER, which
      // lists the messages one by one, still builds its own segment from
      // [buildConversationContextSegment]; it is a tab someone opens, not the
      // cost of opening a chat.
      final totals =
          ref.watch(conversationTokenTotalsProvider(args.spaceId)).value ??
          ConversationTokenTotals.empty;
      final conversation = ContextSegment(
        kind: ContextSegmentKind.conversation,
        tokens: totals.tokens,
        chars: totals.chars,
        parts: const [],
      );
      final fallbackWindow = ref
          .watch(
            conversationContextUsageProvider((
              spaceId: args.spaceId,
              agentId: args.agentId,
            )),
          )
          .windowTokens;
      return composeContextBreakdown(
        inspection,
        conversation,
        fallbackWindow,
        isLoading: async.isLoading && inspection == null,
        hasError: async.hasError && inspection == null,
      );
    });

/// Formats a token count for the breakdown UI: 177274 → "177.3K",
/// 256000 → "256K", 832 → "832".
String formatContextTokenCount(int tokens) {
  String scaled(double value, String suffix) {
    final text = value.toStringAsFixed(1);
    final trimmed = text.endsWith('.0')
        ? text.substring(0, text.length - 2)
        : text;
    return '$trimmed$suffix';
  }

  if (tokens >= 1000000) {
    return scaled(tokens / 1000000, 'M');
  }
  if (tokens >= 1000) {
    return scaled(tokens / 1000, 'K');
  }
  return '$tokens';
}
