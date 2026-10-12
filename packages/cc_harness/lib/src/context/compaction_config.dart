/// Tunables for anchored conversation compaction.
///
/// Compaction fires when the live (non-compacted) region of a conversation
/// grows close to the model's context window. The newest turns are kept
/// verbatim; everything older is folded into an anchored summary that carries
/// the prior summary forward (preserve still-true, drop stale, merge new).
library;

import 'package:cc_harness/src/context/harness_evidence.dart';
import 'package:cc_harness/src/context/tool_observation.dart'
    show kToolOutputRetentionMinTokens;

/// Which observation-compaction strategy the harness applies.
///
/// The three correspond to the policies report 3D asks to compare on the same
/// tasks. [current] is the shipped behaviour and the conservative TEXT default;
/// the image-based strategy (snapshot folding) is a separate opt-in on the
/// compactor and is never selected here.
enum CompactionPolicy {
  /// Fold whole spans into an anchored summary; elide uneventful results and
  /// shed stale images. Meaningful observations are left verbatim.
  current,

  /// Mask stale, safely-RECOVERABLE observations in place (replace the text
  /// with a reference handle) and skip the summarization rewrite when masking
  /// alone brings the history under budget.
  masking,

  /// Mask stale observations AND summarize at the fold boundary — masking
  /// shrinks what the summary has to digest, summarization reclaims the rest.
  hybrid,
}

/// Tunables for anchored conversation compaction.
class CompactionConfig {
  /// Creates a [CompactionConfig].
  const CompactionConfig({
    this.auto = true,
    this.prune = true,
    this.keepTurns = 3,
    this.keepTokens,
    this.buffer = 8000,
    this.pruneThresholdTokens = 2000,
    this.policy = CompactionPolicy.current,
    this.maskThresholdTokens = 4000,
    this.maskKeepTurns = 2,
    this.maskMinObservationTokens = kToolOutputRetentionMinTokens,
    this.evidenceBudget = const HarnessEvidenceBudget(),
  }) : assert(keepTurns >= 1, 'must keep at least one turn verbatim'),
       assert(buffer >= 0, 'buffer must be non-negative'),
       assert(
         pruneThresholdTokens >= 0,
         'prune threshold must be non-negative',
       ),
       assert(maskKeepTurns >= 0, 'mask keep turns must be non-negative'),
       assert(maskThresholdTokens >= 0, 'mask threshold must be non-negative'),
       assert(
         maskMinObservationTokens >= 0,
         'mask min observation tokens must be non-negative',
       );

  /// Whether compaction triggers automatically on context pressure. When false
  /// only an explicit (manual) compaction request compacts.
  final bool auto;

  /// Whether selective tool-output pruning runs alongside compaction.
  final bool prune;

  /// Number of newest turns (delimited by user messages) kept verbatim.
  final int keepTurns;

  /// Optionally keep the newest turns worth of this many tokens verbatim.
  /// When set, the kept region is the LARGER of [keepTurns] turns and the
  /// turns that fit in [keepTokens] — so a few very large turns are not split.
  final int? keepTokens;

  /// Headroom (tokens) kept free below the context window. Auto-compaction
  /// triggers once `usage + buffer >= contextWindow`.
  final int buffer;

  /// Minimum tokens a prune pass must reclaim before it is allowed to rewrite
  /// history.
  ///
  /// Pruning edits messages IN PLACE, and any byte change invalidates the
  /// provider's cached prefix from that point on. Run unconditionally on every
  /// tool-bearing turn — as it used to be — it re-broke the message cache
  /// continuously to save a few dozen tokens at a time, paying full price for
  /// the entire history to reclaim almost nothing.
  ///
  /// Batching means rare, deep rewrites instead of constant shallow ones: the
  /// pass stays free until it is worth what it costs. Zero restores the old
  /// prune-every-turn behaviour.
  final int pruneThresholdTokens;

  /// Which observation-compaction strategy to apply. Defaults to [CompactionPolicy.current] —
  /// the conservative text policy. Masking is opt-in.
  final CompactionPolicy policy;

  /// Minimum tokens a MASKING pass must reclaim before it rewrites history.
  ///
  /// Masking is subject to the same cache-rebuild economics as elision, and one
  /// more cost of its own: each mask replaces text with a reference the model
  /// may later spend tokens to read back. The threshold is deliberately higher
  /// than [pruneThresholdTokens] because masking is a bigger, less certain
  /// reclaim than eliding known-uneventful results.
  final int maskThresholdTokens;

  /// Newest user turns whose observations are protected from masking. The
  /// agent is reasoning about these; masking them would swap the thing it is
  /// looking at for a handle.
  final int maskKeepTurns;

  /// Observations smaller than this many estimated tokens are not masked: the
  /// reference plus the model's eventual read-back costs more than the text.
  ///
  /// Defaults to [kToolOutputRetentionMinTokens], the SAME constant ingestion
  /// uses to decide what to store, and measured with the same TokenEstimator
  /// — so one "200" means one thing in both places and, for non-error
  /// observations, `stored ⇔ maskable` holds in both directions.
  final int maskMinObservationTokens;

  /// Budget for the bounded, evidence-bearing history handed to a summarizer.
  final HarnessEvidenceBudget evidenceBudget;

  /// The default configuration.
  static const CompactionConfig defaults = CompactionConfig();

  /// Whether this policy masks stale observations.
  bool get masksObservations =>
      policy == CompactionPolicy.masking || policy == CompactionPolicy.hybrid;

  /// Returns a copy with selected fields overridden.
  CompactionConfig copyWith({
    bool? auto,
    bool? prune,
    int? keepTurns,
    int? keepTokens,
    int? buffer,
    int? pruneThresholdTokens,
    CompactionPolicy? policy,
    int? maskThresholdTokens,
    int? maskKeepTurns,
    int? maskMinObservationTokens,
    HarnessEvidenceBudget? evidenceBudget,
  }) => CompactionConfig(
    auto: auto ?? this.auto,
    prune: prune ?? this.prune,
    keepTurns: keepTurns ?? this.keepTurns,
    keepTokens: keepTokens ?? this.keepTokens,
    buffer: buffer ?? this.buffer,
    pruneThresholdTokens: pruneThresholdTokens ?? this.pruneThresholdTokens,
    policy: policy ?? this.policy,
    maskThresholdTokens: maskThresholdTokens ?? this.maskThresholdTokens,
    maskKeepTurns: maskKeepTurns ?? this.maskKeepTurns,
    maskMinObservationTokens:
        maskMinObservationTokens ?? this.maskMinObservationTokens,
    evidenceBudget: evidenceBudget ?? this.evidenceBudget,
  );
}
