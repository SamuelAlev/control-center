import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/dispatch/domain/context/token_estimator.dart';
import 'package:cc_domain/features/dispatch/domain/context/tool_result_elision.dart';

/// Replacement text for a tool result dropped by the context-budget pruner.
const String prunedResultMarker = '[Tool output pruned to reclaim context]';

/// Replacement text for an earlier read of a file that was later re-read.
const String supersededReadMarker =
    '[Superseded by a later read of the same file]';

/// Tunables for the conversation-budget pruner. Defaults mirror the kilocode
/// behaviour: keep the two most-recent turns pristine, protect the newest 40k
/// tokens of tool output, and only prune when the reclaim clears 20k tokens.
class PrunePolicy {
  /// Creates a [PrunePolicy].
  const PrunePolicy({
    this.keepRecentTurns = 2,
    this.protectTokens = 40000,
    this.minimumBenefitTokens = 20000,
  });

  /// Number of most-recent turns (delimited by user messages) never pruned.
  final int keepRecentTurns;

  /// Newest tool-output tokens protected from budget pruning.
  final int protectTokens;

  /// Minimum total reclaim (tokens) required before any budget pruning fires.
  final int minimumBenefitTokens;

  /// The default policy.
  static const PrunePolicy defaults = PrunePolicy();
}

/// Cache-awareness gate. Pruning rewrites history, which invalidates the
/// provider's prompt cache for everything from the first changed message
/// onward. We only pay that cost when it is cheap: either the trailing suffix
/// that would be re-sent is small, or the session has been idle long enough
/// that the cache has already expired.
class CachePruneGate {
  /// Creates a [CachePruneGate].
  const CachePruneGate({
    required this.trailingSuffixTokens,
    required this.sinceLastActivity,
    this.smallSuffixThreshold = 8000,
    this.cacheTtl = const Duration(minutes: 5),
  });

  /// Tokens that sit after the would-be cut and must be re-sent uncached.
  final int trailingSuffixTokens;

  /// How long since the conversation last produced output.
  final Duration sinceLastActivity;

  /// A suffix at or below this many tokens is considered cheap to re-send.
  final int smallSuffixThreshold;

  /// Provider prompt-cache time-to-live; idling past it makes pruning free.
  final Duration cacheTtl;

  /// Whether pruning is currently worth its cache cost.
  bool get permitsPrune =>
      trailingSuffixTokens <= smallSuffixThreshold ||
      sinceLastActivity > cacheTtl;

  /// A gate that always permits pruning (used post-compaction, where the cache
  /// is already being rewritten anyway).
  static const CachePruneGate always = CachePruneGate(
    trailingSuffixTokens: 0,
    sinceLastActivity: Duration(days: 365),
  );
}

/// The set of per-message segment rewrites a prune pass produced. Only messages
/// whose transcript actually changed appear in [updatedSegmentsByMessageId].
class PrunePlan {
  /// Creates a [PrunePlan].
  const PrunePlan({
    required this.updatedSegmentsByMessageId,
    required this.reclaimedTokens,
  });

  /// Map of message id → its new transcript segment list.
  final Map<String, List<TranscriptSegment>> updatedSegmentsByMessageId;

  /// Estimated tokens reclaimed across all rewrites.
  final int reclaimedTokens;

  /// Whether the plan changes anything.
  bool get isEmpty => updatedSegmentsByMessageId.isEmpty;
}

/// One prunable tool segment located within the conversation.
class _ToolRef {
  _ToolRef({
    required this.messageId,
    required this.segmentIndex,
    required this.segment,
    required this.tokens,
  });

  final String messageId;
  final int segmentIndex;
  ToolSegment segment;
  final int tokens;
}

/// Plans elision + superseded-read pruning + cache-aware budget pruning across
/// a conversation's transcript, without touching the persistence layer. The
/// caller applies [PrunePlan] by merging each new segment list into the
/// corresponding message's metadata.
///
/// Recent turns are left pristine to preserve the prompt cache; the gate
/// decides whether the rewrite is worth its cache cost at all.
class ConversationPruner {
  /// Creates a [ConversationPruner].
  const ConversationPruner({
    this.policy = PrunePolicy.defaults,
    this.elision = const ToolResultElision(),
    this.estimator = TokenEstimator.instance,
  });

  /// Pruning tunables.
  final PrunePolicy policy;

  /// Useless-result classifier.
  final ToolResultElision elision;

  /// Token estimator for budget accounting.
  final TokenEstimator estimator;

  /// Produces a [PrunePlan] for [messages] (ascending order). [now] timestamps
  /// the pruned segments. [gate] decides whether budget pruning is permitted;
  /// when null, budget pruning runs unconditionally (elision/superseded still
  /// respect the recent-turns window).
  PrunePlan plan(
    List<ChannelMessage> messages, {
    required DateTime now,
    CachePruneGate? gate,
  }) {
    // 1. Compute which messages fall inside the protected recent-turns window.
    final protectedMessageIds = _recentTurnMessageIds(messages);

    // 2. Collect prunable tool refs from older agent turns, newest-first.
    final refs = <_ToolRef>[];
    final workingSegments = <String, List<TranscriptSegment>>{};
    for (final m in messages.reversed) {
      if (!m.isAgentTurn || protectedMessageIds.contains(m.id)) {
        continue;
      }
      final segs = m.transcript;
      if (segs.isEmpty) {
        continue;
      }
      workingSegments[m.id] = List<TranscriptSegment>.of(segs);
      for (var i = 0; i < segs.length; i++) {
        final s = segs[i];
        if (s is! ToolSegment || s.isPruned) {
          continue;
        }
        refs.add(
          _ToolRef(
            messageId: m.id,
            segmentIndex: i,
            segment: s,
            tokens: estimator.estimateSegment(s),
          ),
        );
      }
    }

    if (refs.isEmpty) {
      return const PrunePlan(updatedSegmentsByMessageId: {}, reclaimedTokens: 0);
    }

    final changed = <String>{};
    var reclaimed = 0;

    // 3. Elision pass — blank uneventful results (lossless of signal).
    for (final ref in refs) {
      final s = ref.segment;
      if (elision.isUseless(
        toolName: s.toolName,
        outputs: s.outputs,
        isError: s.isError,
        status: s.status,
      )) {
        ref.segment = s.copyWith(outputs: elidedResultMarker, prunedAt: now);
        changed.add(ref.messageId);
        reclaimed += ref.tokens;
      }
    }

    // 4. Superseded-read pass — keep only the latest read of each file. The
    //    newest read may live in the protected recent window, so scan ALL
    //    messages (newest-first) to find the surviving read per path; any
    //    prunable read that is not that survivor is superseded.
    final newestReadKeyByPath = <String, String>{};
    for (final m in messages.reversed) {
      if (!m.isAgentTurn) {
        continue;
      }
      final segs = m.transcript;
      for (var i = 0; i < segs.length; i++) {
        final s = segs[i];
        if (s is! ToolSegment || s.isPruned) {
          continue;
        }
        final path = _readPath(s);
        if (path == null) {
          continue;
        }
        newestReadKeyByPath.putIfAbsent(path, () => '${m.id}#$i');
      }
    }
    for (final ref in refs) {
      final s = ref.segment;
      if (s.isPruned) {
        continue;
      }
      final path = _readPath(s);
      if (path == null) {
        continue;
      }
      final survivor = newestReadKeyByPath[path];
      if (survivor != null && survivor != '${ref.messageId}#${ref.segmentIndex}') {
        ref.segment = s.copyWith(outputs: supersededReadMarker, prunedAt: now);
        changed.add(ref.messageId);
        reclaimed += ref.tokens;
      }
    }

    // 5. Budget pruning — protect the newest [protectTokens] of remaining tool
    //    output, then prune the rest if the gate permits and the reclaim clears
    //    the minimum benefit.
    if (gate == null || gate.permitsPrune) {
      var cumulative = 0;
      final budgetCandidates = <_ToolRef>[];
      var budgetReclaim = 0;
      for (final ref in refs) {
        final s = ref.segment;
        if (s.isPruned ||
            pruneProtectedTools.contains(_normalize(s.toolName))) {
          continue;
        }
        cumulative += ref.tokens;
        if (cumulative <= policy.protectTokens) {
          continue;
        }
        budgetCandidates.add(ref);
        budgetReclaim += ref.tokens;
      }
      if (budgetReclaim >= policy.minimumBenefitTokens) {
        for (final ref in budgetCandidates) {
          ref.segment =
              ref.segment.copyWith(outputs: prunedResultMarker, prunedAt: now);
          changed.add(ref.messageId);
          reclaimed += ref.tokens;
        }
      }
    }

    if (changed.isEmpty) {
      return const PrunePlan(updatedSegmentsByMessageId: {}, reclaimedTokens: 0);
    }

    // 6. Re-assemble changed messages' segment lists from the working refs.
    final updates = <String, List<TranscriptSegment>>{};
    for (final messageId in changed) {
      final segs = workingSegments[messageId];
      if (segs == null) {
        continue;
      }
      final updated = List<TranscriptSegment>.of(segs);
      for (final ref in refs) {
        if (ref.messageId == messageId) {
          updated[ref.segmentIndex] = ref.segment;
        }
      }
      updates[messageId] = updated;
    }

    return PrunePlan(
      updatedSegmentsByMessageId: updates,
      reclaimedTokens: reclaimed,
    );
  }

  /// Ids of messages within the most-recent [PrunePolicy.keepRecentTurns]
  /// turns. A turn boundary is a user message; the trailing run before the
  /// first counted user boundary is the in-flight turn.
  Set<String> _recentTurnMessageIds(List<ChannelMessage> messages) {
    if (policy.keepRecentTurns <= 0) {
      return const {};
    }
    final protectedIds = <String>{};
    var turns = 0;
    for (final m in messages.reversed) {
      if (m.isUser) {
        turns++;
        protectedIds.add(m.id);
        if (turns >= policy.keepRecentTurns) {
          break;
        }
        continue;
      }
      protectedIds.add(m.id);
    }
    return protectedIds;
  }

  /// The file path a read-family tool targeted, or null if [s] is not a read.
  String? _readPath(ToolSegment s) {
    final tool = _normalize(s.toolName);
    if (tool != 'read' && tool != 'cat' && tool != 'view') {
      return null;
    }
    final inputs = s.inputs;
    if (inputs == null) {
      return null;
    }
    for (final key in const ['file_path', 'path', 'file', 'filename']) {
      final v = inputs[key];
      if (v is String && v.isNotEmpty) {
        return v;
      }
    }
    return null;
  }

  String _normalize(String toolName) {
    var name = toolName.toLowerCase();
    if (name.startsWith('mcp__')) {
      final lastSep = name.lastIndexOf('__');
      if (lastSep >= 0 && lastSep + 2 < name.length) {
        name = name.substring(lastSep + 2);
      }
    }
    return name;
  }
}
