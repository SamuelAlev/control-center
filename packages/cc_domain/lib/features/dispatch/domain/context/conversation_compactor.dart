import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/features/dispatch/domain/context/compaction_config.dart';
import 'package:cc_domain/features/dispatch/domain/context/token_estimator.dart';

/// Why a compaction was produced.
enum CompactionReason {
  /// Triggered automatically by context pressure.
  auto,

  /// Requested explicitly by the user.
  manual,
}

/// A plan describing which messages to fold into an anchored summary and which
/// to keep verbatim. Produced by [ConversationCompactor.plan]; the summary text
/// itself is produced separately by a `ConversationSummarizerPort`.
class CompactionPlan {
  /// Creates a [CompactionPlan].
  const CompactionPlan({
    required this.messagesToCompact,
    required this.tailStartId,
    required this.reason,
    this.previousSummary,
    this.previousSummaryId,
  });

  /// The span of messages (ascending) to fold into the summary.
  final List<ChannelMessage> messagesToCompact;

  /// Id of the first message kept verbatim after the compacted span — the
  /// boundary the summary sits in front of.
  final String tailStartId;

  /// Why this compaction was produced.
  final CompactionReason reason;

  /// The prior anchored summary text to update, if any.
  final String? previousSummary;

  /// Id of the prior compaction message, if any.
  final String? previousSummaryId;

  /// Ids of the messages this plan compacts.
  List<String> get idsToCompact =>
      messagesToCompact.map((m) => m.id).toList(growable: false);
}

/// Decides where to cut a conversation for anchored compaction.
///
/// The cut never splits an agent turn (each CC agent turn is a single message
/// that already bundles its own tool calls + results, so message boundaries are
/// always safe). The kept tail starts at a user message — a real turn boundary
/// — so the summary stands in front of a clean turn start. Only the region
/// after the most-recent prior compaction is considered, so each pass
/// re-anchors the previous summary instead of re-summarizing from scratch.
class ConversationCompactor {
  /// Creates a [ConversationCompactor].
  const ConversationCompactor({this.estimator = TokenEstimator.instance});

  /// Token estimator used to gauge pressure and the kept-tokens window.
  final TokenEstimator estimator;

  /// Plans a compaction over [messages] (ascending order) for a model with
  /// [contextWindowTokens] of context. Returns null when nothing should be
  /// compacted (no pressure under [CompactionConfig.auto], or too little older
  /// history to be worth folding).
  ///
  /// Set [force] for a manual compaction: the pressure gate is skipped but the
  /// "enough to compact" floor still applies.
  CompactionPlan? plan({
    required List<ChannelMessage> messages,
    required int contextWindowTokens,
    CompactionConfig config = CompactionConfig.defaults,
    bool force = false,
  }) {
    if (messages.isEmpty) {
      return null;
    }

    // 1. Find the most-recent prior compaction; only re-summarize after it.
    int? prevCompactionIndex;
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].isContextSummary) {
        prevCompactionIndex = i;
        break;
      }
    }
    final previousSummary =
        prevCompactionIndex != null ? messages[prevCompactionIndex] : null;
    final regionStart = (prevCompactionIndex ?? -1) + 1;
    final region = messages.sublist(regionStart);
    if (region.isEmpty) {
      return null;
    }

    // 2. Pressure gate for auto compaction.
    if (!force && config.auto) {
      final usage = estimator.estimateMessages(region) +
          (previousSummary != null
              ? estimator.estimateMessage(previousSummary)
              : 0);
      if (usage + config.buffer < contextWindowTokens) {
        return null;
      }
    } else if (!force && !config.auto) {
      return null;
    }

    // 3. Find the cut: keep the newest [keepTurns] turns (and/or [keepTokens])
    //    verbatim. The kept tail must begin at a user message.
    final cutIndexInRegion = _findCutIndex(region, config);
    if (cutIndexInRegion <= 0) {
      // Nothing older than the kept tail — nothing to compact.
      return null;
    }

    final toCompact = <ChannelMessage>[];
    for (var i = 0; i < cutIndexInRegion; i++) {
      final m = region[i];
      // Skip prior summaries and already-compacted rows defensively.
      if (m.isContextSummary || m.compacted) {
        continue;
      }
      toCompact.add(m);
    }

    // Need at least two real messages to make folding worthwhile.
    if (toCompact.length < 2) {
      return null;
    }

    final tailStartId = region[cutIndexInRegion].id;

    return CompactionPlan(
      messagesToCompact: toCompact,
      tailStartId: tailStartId,
      reason: force ? CompactionReason.manual : CompactionReason.auto,
      previousSummary: previousSummary?.content,
      previousSummaryId: previousSummary?.id,
    );
  }

  /// Returns the index within [region] where the kept tail begins. The tail is
  /// the newest run that satisfies BOTH the turn floor and the token floor
  /// (whichever keeps more), and always starts at a user message.
  int _findCutIndex(List<ChannelMessage> region, CompactionConfig config) {
    // Index of the user message that starts each of the newest turns.
    final turnStarts = <int>[];
    for (var i = region.length - 1; i >= 0; i--) {
      if (region[i].isUser) {
        turnStarts.add(i);
      }
    }
    if (turnStarts.isEmpty) {
      // No user boundary in the region — keep everything (cannot cut safely).
      return 0;
    }

    // Cut by turns: the start of the keepTurns-th newest turn.
    final byTurnsIdx = turnStarts.length >= config.keepTurns
        ? turnStarts[config.keepTurns - 1]
        : turnStarts.last;

    // Cut by tokens (optional): walk back accumulating tokens until the budget
    // is exceeded, snapping the boundary to a user message.
    var byTokensIdx = region.length;
    final keepTokens = config.keepTokens;
    if (keepTokens != null && keepTokens > 0) {
      var acc = 0;
      var idx = region.length;
      for (var i = region.length - 1; i >= 0; i--) {
        acc += estimator.estimateMessage(region[i]);
        if (region[i].isUser) {
          idx = i;
        }
        if (acc > keepTokens) {
          break;
        }
      }
      byTokensIdx = idx;
    }

    // Keep the LARGER tail (the smaller starting index).
    final cut = byTokensIdx < byTurnsIdx ? byTokensIdx : byTurnsIdx;
    return cut;
  }
}
