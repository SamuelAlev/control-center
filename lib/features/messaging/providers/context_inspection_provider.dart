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
/// system prompt, rules, skills, tool surface, subagents and memory. For a
/// built-in-harness agent never the conversation, whose size arrives
/// separately as an aggregate ([conversationTokenTotalsProvider]) and whose
/// messages only the explorer reads (see [contextBreakdownProvider]). For a
/// Claude Code agent the server includes the history block the run actually
/// receives, plus a runner segment the client sizes from the reported reading.
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
    this.isMeasured = false,
  });

  /// The server inspection, or null while the summary RPC has not landed yet
  /// (or failed). The conversation segment below is always present, so a
  /// loading popover still shows the client-known part of the breakdown.
  final ContextInspection? inspection;

  /// Every segment in [ContextSegmentKind] declaration order: the server's
  /// persistent segments followed by the client-composed conversation segment.
  final List<ContextSegment> segments;

  /// Total tokens in play: the provider-reported reading when a run reported
  /// one, else persistent + conversation estimates.
  final int totalTokens;

  /// The window [totalTokens] is measured against: the one the reporting run
  /// used, else the server's resolution for the agent, else the agent's
  /// configured context size.
  final int windowTokens;

  /// Whether [totalTokens] is the provider's own count of the model's last
  /// call rather than an estimate.
  final bool isMeasured;

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

/// A run's provider-reported context reading: how many tokens the model held
/// on its newest call, and the window it ran with when known.
typedef ReportedContext = ({int tokens, int? windowTokens});

/// The reported reading carried by [totals], or null when no run reported one.
ReportedContext? reportedContextOf(ConversationTokenTotals totals) {
  final tokens = totals.reportedContextTokens;
  return tokens == null
      ? null
      : (tokens: tokens, windowTokens: totals.reportedWindowTokens);
}

/// Merges the server [inspection] (persistent segments, possibly null while
/// loading) with the client-composed [estimatedConversation] segment into a
/// single breakdown. Segments come out in [ContextSegmentKind] declaration
/// order regardless of wire order, so the stacked bar is stable across
/// renders. [fallbackWindowTokens] is the client-side window used until the
/// server's authoritative `windowTokens` lands.
///
/// With a [reported] reading the total is the provider's count, not a sum of
/// estimates, and the part nobody can measure directly absorbs the
/// difference: the conversation for the harness (whose transcript replay is
/// the only unmeasured input), the runner segment for Claude Code (whose own
/// prompt, tools and turn work are invisible here). A Claude Code inspection
/// brings its own conversation segment — the history block the run receives —
/// which replaces the estimate over the whole stored conversation.
ContextBreakdown composeContextBreakdown(
  ContextInspection? inspection,
  ContextSegment estimatedConversation,
  int fallbackWindowTokens, {
  ReportedContext? reported,
  required bool isLoading,
  required bool hasError,
}) {
  final serverConversation = inspection?.segmentFor(
    ContextSegmentKind.conversation,
  );
  var known = 0;
  for (final segment in inspection?.segments ?? const <ContextSegment>[]) {
    if (segment.kind != ContextSegmentKind.runner &&
        segment.kind != ContextSegmentKind.conversation) {
      known += segment.tokens;
    }
  }
  final remainder = reported == null || inspection == null
      ? null
      : reported.tokens - known - (serverConversation?.tokens ?? 0);

  ContextSegment conversation() {
    if (serverConversation != null) {
      return serverConversation;
    }
    if (remainder == null) {
      return estimatedConversation;
    }
    return _resized(estimatedConversation, remainder);
  }

  ContextSegment? runner() {
    final segment = inspection?.segmentFor(ContextSegmentKind.runner);
    if (segment == null || remainder == null) {
      return segment;
    }
    return _resized(segment, remainder);
  }

  final segments = <ContextSegment>[
    for (final kind in ContextSegmentKind.values)
      if (kind == ContextSegmentKind.conversation)
        conversation()
      else if (kind == ContextSegmentKind.runner)
        ?runner()
      else
        ?inspection?.segmentFor(kind),
  ];
  final reportedWindow = reported?.windowTokens;
  final windowTokens = reportedWindow != null && reportedWindow > 0
      ? reportedWindow
      : inspection != null && inspection.windowTokens > 0
      ? inspection.windowTokens
      : fallbackWindowTokens;
  var estimatedTotal = 0;
  for (final segment in segments) {
    estimatedTotal += segment.tokens;
  }
  return ContextBreakdown(
    inspection: inspection,
    segments: segments,
    totalTokens: reported?.tokens ?? estimatedTotal,
    windowTokens: windowTokens,
    isMeasured: reported != null,
    isLoading: isLoading,
    hasError: hasError,
  );
}

/// [segment] carrying [tokens] (never negative): the reading measured it, so
/// the estimate it was built from no longer stands. A single-part segment's
/// part is resized with it, so the explorer's rail agrees with the bar.
ContextSegment _resized(ContextSegment segment, int tokens) {
  final measured = tokens < 0 ? 0 : tokens;
  final parts = segment.parts.length == 1
      ? [
          ContextPart(
            id: segment.parts.single.id,
            title: segment.parts.single.title,
            subtitle: segment.parts.single.subtitle,
            tokens: measured,
            chars: segment.parts.single.chars,
            content: segment.parts.single.content,
          ),
        ]
      : segment.parts;
  return ContextSegment(
    kind: segment.kind,
    tokens: measured,
    chars: segment.chars,
    parts: parts,
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
        reported: reportedContextOf(totals),
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
