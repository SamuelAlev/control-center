/// Anchored context compaction for the built-in harness loop.
///
/// Reuses the shared PRD-03 context leaves — [TokenEstimator], [CompactionConfig],
/// [ToolResultElision] + its markers and [compactionSystemPrompt] — but plans
/// over the harness's own [HarnessMessage] type (the shared compactor operates
/// on `Message`, a different shape). Pure Dart: the LLM-backed summarizer
/// lives in the infrastructure layer; here we only define the contract and a
/// deterministic fallback.
///
/// The evidence serializer and the masking pass live in `harness_evidence.dart`
/// and are re-exported here so the existing import path keeps resolving.
library;

import 'package:cc_harness/src/context/compaction_config.dart';
import 'package:cc_harness/src/context/compaction_economics.dart';
import 'package:cc_harness/src/context/compaction_prompt.dart';
import 'package:cc_harness/src/context/harness_evidence.dart';
import 'package:cc_harness/src/context/harness_token_accounting.dart';
import 'package:cc_harness/src/context/token_calibration.dart';
import 'package:cc_harness/src/context/token_estimator.dart'
    show TokenEstimator;
import 'package:cc_harness/src/context/tool_output_reference.dart';
import 'package:cc_harness/src/context/tool_result_elision.dart';
import 'package:cc_harness/src/messages.dart';
import 'package:cc_harness/src/provider/llm_provider_port.dart'
    show LlmCallPurpose;

export 'package:cc_harness/src/context/harness_evidence.dart';

/// Re-exported so infrastructure summarizers can build the system prompt without
/// importing the dispatch context module directly.
const String harnessCompactionSystemPrompt = compactionSystemPrompt;

/// Input to a harness summarizer: the span of messages to fold plus the prior
/// anchored summary (if the conversation was compacted before).
class HarnessCompactionInput {
  /// Creates a [HarnessCompactionInput].
  const HarnessCompactionInput({
    required this.messages,
    this.previousSummary,
    this.selfAgentName = 'assistant',
    this.activeEditTargets = const {},
  });

  /// The messages (ascending) being folded.
  final List<HarnessMessage> messages;

  /// The prior anchored summary text, if any.
  final String? previousSummary;

  /// Display name for the agent's turns in the rendered history.
  final String selfAgentName;

  /// Files still being edited across the fold boundary.
  final Set<String> activeEditTargets;
}

/// Produces an anchored summary standing in for a folded span of harness turns.
abstract interface class HarnessSummarizerPort {
  /// Returns the anchored summary text for [input].
  Future<String> summarize(HarnessCompactionInput input);
}

/// A deterministic, LLM-free harness summarizer. Carries the prior summary
/// forward and appends a structured digest of the folded turns; reclaim comes
/// from dropping reasoning + fat tool outputs. The default so compaction works
/// with no summarizer model configured.
///
/// **Bounded across REPEATED folds.** The naive shape (header + carry the whole
/// previous summary forward + append a new digest) grows without limit: every
/// fold re-embeds the entire prior summary, so the "compacted" region is larger
/// after N folds than the history that produced it. Both sections are instead
/// tail-bounded to [HarnessEvidenceBudget.totalChars] on WHOLE-LINE boundaries,
/// with the newest evidence preferred — so a recovery handle in the digest is
/// never cut in half into a fabricated one.
class StructuralHarnessSummarizer implements HarnessSummarizerPort {
  /// Creates a [StructuralHarnessSummarizer].
  const StructuralHarnessSummarizer({
    this.budget = HarnessEvidenceBudget.defaults,
  });

  /// Evidence budget for the rendered digest and the carried summary.
  final HarnessEvidenceBudget budget;

  @override
  Future<String> summarize(HarnessCompactionInput input) async {
    const header = '## Conversation summary (compacted)';
    final prev = _strip(input.previousSummary);
    final split = splitPinnedEvidence(prev);
    final digest = serializeHarnessHistory(
      input.messages,
      selfAgentName: input.selfAgentName,
      budget: budget,
      activeEditTargets: input.activeEditTargets.isEmpty
          ? collectActiveEditTargets(input.messages)
          : input.activeEditTargets,
    );
    // Pin new authoritative steering alongside the original request carried
    // from the prior summary, before either evidence section is tail-bounded.
    final digestSplit = splitPinnedEvidence(digest);

    // The original request and system steering are PINNED: they must survive
    // every fold, so they are budgeted for (not tail-bounded away). The set
    // collapses the case where the carried and fresh copies are identical.
    final pinnedParts = <String>{
      if (split.pinned.isNotEmpty) split.pinned,
      if (digestSplit.pinned.isNotEmpty) digestSplit.pinned,
    };
    final pinned = _boundHead(pinnedParts.join('\n\n'), budget.totalChars ~/ 3);

    var remaining = budget.totalChars - header.length - pinned.length;
    if (remaining < 0) {
      remaining = 0;
    }
    // The new evidence gets a little more room than the carried remainder: the
    // digest carries the active work state and the newest diagnostics.
    final digestRest = digestSplit.rest;
    final digestCap = digestRest.isEmpty ? 0 : (remaining * 3) ~/ 5;
    final restCap = digestRest.isEmpty ? remaining : remaining - digestCap;

    final boundedRest = split.rest.isEmpty
        ? ''
        : boundEvidence(split.rest, restCap);
    final boundedDigest = digestRest.isEmpty
        ? ''
        : boundEvidence(digestRest, digestCap);

    final buf = StringBuffer(header);
    if (pinned.isNotEmpty) {
      // Re-frame: the markers are re-emitted so the NEXT fold can find the block
      // structurally, with the (possibly bounded) payload inside them.
      buf
        ..writeln()
        ..writeln()
        ..writeln(evidencePinBegin)
        ..writeln(pinned)
        ..writeln(evidencePinEnd);
    }
    if (boundedRest.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('### Established context')
        ..writeln(boundedRest);
    }
    if (boundedDigest.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('### Newly compacted')
        ..writeln(boundedDigest);
    }
    return buf.toString().trimRight();
  }

  /// Drops the previous summary's own heading so it is re-wrapped, not nested.
  String _strip(String? summary) {
    final text = summary?.trim() ?? '';
    if (text.isEmpty) {
      return '';
    }
    final lines = text.split('\n');
    if (lines.isNotEmpty && lines.first.trimLeft().startsWith('#')) {
      return lines.skip(1).join('\n').trim();
    }
    return text;
  }
}

/// Head-bounds [text] to [maxChars], keeping the OLDEST content (the original
/// instructions come first) with an explicit marker when it must be cut.
String _boundHead(String text, int maxChars) {
  if (maxChars <= 0 || text.isEmpty) {
    return '';
  }
  if (text.length <= maxChars) {
    return text;
  }
  return '${text.substring(0, maxChars)}…[authoritative context truncated]';
}

/// Tail-bounds [text] to at most [maxChars], dropping the OLDEST whole lines and
/// naming the loss explicitly.
///
/// Whole-line (never mid-line) so a recovery handle embedded in the text — e.g.
/// `read_output(handle: "out_…")` — is either fully present or fully dropped,
/// never truncated into a handle that does not resolve. This is the guarantee
/// that bounding cannot fabricate provenance.
String boundEvidence(String text, int maxChars) {
  if (maxChars <= 0) {
    return '';
  }
  if (text.length <= maxChars) {
    return text;
  }
  const marker = '[earlier evidence dropped: budget reached]';
  final lines = text.split('\n');
  final kept = <String>[];
  var used = 0;
  for (var i = lines.length - 1; i >= 0; i--) {
    final cost = lines[i].length + 1;
    if (used + cost > maxChars) {
      break;
    }
    kept.add(lines[i]);
    used += cost;
  }
  if (kept.isEmpty) {
    return marker;
  }
  return '$marker\n${kept.reversed.join('\n')}';
}

/// The outcome of a compaction / prune pass.
class HarnessCompactionResult {
  /// Creates a [HarnessCompactionResult].
  const HarnessCompactionResult({
    required this.changed,
    required this.summarized,
    required this.messagesFolded,
    required this.tokensBefore,
    required this.tokensAfter,
    this.policy = CompactionPolicy.current,
    this.reclaimedTokens = 0,
    this.rebuildTokens = 0,
    this.maskedObservations = 0,
    this.foldedFromIndex = 0,
    this.retainedSnapshotSource,
    this.decisionReason,
  });

  /// A no-op result (history unchanged).
  const HarnessCompactionResult.unchanged(int tokens)
    : changed = false,
      summarized = false,
      messagesFolded = 0,
      tokensBefore = tokens,
      tokensAfter = tokens,
      policy = CompactionPolicy.current,
      reclaimedTokens = 0,
      rebuildTokens = 0,
      maskedObservations = 0,
      foldedFromIndex = 0,
      retainedSnapshotSource = null,
      decisionReason = null;

  /// Whether the history was modified.
  final bool changed;

  /// True when a summary was produced; false for a prune-only or mask-only pass.
  final bool summarized;

  /// Number of messages folded into the summary.
  final int messagesFolded;

  /// Estimated live PROMPT tokens before the pass (post-calibration when wired).
  final int tokensBefore;

  /// Estimated live PROMPT tokens after the pass (post-calibration when wired).
  final int tokensAfter;

  /// The policy that produced this result.
  final CompactionPolicy policy;

  /// Estimated tokens the pass removed.
  final int reclaimedTokens;

  /// Estimated tokens of the cached prefix the rewrite invalidated.
  final int rebuildTokens;

  /// Observation blocks replaced by a recoverable reference in this pass.
  final int maskedObservations;

  /// Index where the folded span began. The span
  /// `[foldedFromIndex, foldedFromIndex + messagesFolded)` collapsed into ONE
  /// replacement message at [foldedFromIndex].
  ///
  /// The caller's checkpoint remap must use this: a text fold starts at 0, but
  /// a SNAPSHOT fold starts after the verbatim head, so a remap that assumes a
  /// leading fold would shift the head's checkpoints incorrectly.
  final int foldedFromIndex;

  /// For a snapshot pass, the plain text the folded region was rendered from.
  ///
  /// Carried on the result so the host can PERSIST it: the source is otherwise
  /// in-memory only, and after a restart a later fold of the snapshot message
  /// would have no way to recover the text it represents. Null for text folds.
  final String? retainedSnapshotSource;

  /// Why the pass ran (or was skipped), for logs and experiment output.
  final String? decisionReason;

  /// Convenience: the number of tokens the pass reclaimed.
  int get reclaimed => tokensBefore - tokensAfter;
}

/// Compacts a harness history in place when it approaches the context window.
abstract interface class HarnessCompactor {
  /// Compacts [history] (mutating it in place) when
  /// `promptEstimate + overheadTokens + reservedOutputTokens + buffer >=
  /// contextWindow`. Returns what happened. A null [contextWindow] disables
  /// compaction.
  ///
  /// [overheadTokens] is PROMPT overhead only — the system prompt and resident
  /// tool schemas — and its magnitude is estimate-like, so it IS scaled by the
  /// calibration factor. [reservedOutputTokens] is the output reservation
  /// (`maxTokens`); it is a fixed budget, never estimated, and is therefore
  /// NEVER scaled by calibration: applying a factor < 1 to it would shrink the
  /// reservation and let input + output exceed the window.
  ///
  /// Nothing is written to [history] until the pass can complete: when the
  /// summarizer fails, a staged masking is either committed and reported as a
  /// mask-only change or the call rethrows with history untouched — never a
  /// silent "unchanged" over a mutated list.
  ///
  /// When [force] is true the threshold gate is bypassed and the fold runs
  /// unconditionally with a tighter recent-region budget — used for reactive
  /// recovery after the provider itself rejects the request as too large (the
  /// heuristic estimate can under-count what the provider actually measured).
  Future<HarnessCompactionResult> maybeCompact(
    List<HarnessMessage> history, {
    required int? contextWindow,
    int overheadTokens,
    int reservedOutputTokens,
    String selfAgentName,
    bool force,
  });

  /// Reclaims context cheaply by eliding uneventful older tool results, shedding
  /// stale images and (under a masking policy) replacing stale recoverable
  /// observations with a reference, without a summary/cache rewrite.
  ///
  /// Returns the number of model-facing result blocks that CHANGED — elisions,
  /// image sheds AND masks. This is the signal the caller uses to invalidate its
  /// cached-prefix anchor, so an image-only or mask-only rewrite reports a
  /// non-zero count and the anchor is not left pointing into rewritten bytes.
  ///
  /// [force] skips the "is this worth the cache it breaks?" threshold. Set it
  /// only where the cached prefix is being rewritten anyway — i.e. alongside a
  /// compaction — so the pass rides a rewrite that has already been paid for.
  int pruneToolResults(List<HarnessMessage> history, {bool force});
}

/// The default [HarnessCompactor]: reuses [CompactionConfig] tunables, folds on
/// user-turn boundaries keeping the newest turns verbatim and delegates the
/// summary text to a [HarnessSummarizerPort].
///
/// Policy ([CompactionConfig.policy]) selects among the report-3D strategies:
/// [CompactionPolicy.current] folds and elides; [CompactionPolicy.masking]
/// masks stale recoverable observations and folds only if masking cannot get
/// under the window; [CompactionPolicy.hybrid] does both.
class DefaultHarnessCompactor implements HarnessCompactor {
  /// Creates a [DefaultHarnessCompactor].
  const DefaultHarnessCompactor({
    this.summarizer = const StructuralHarnessSummarizer(),
    this.config = CompactionConfig.defaults,
    this.elision = const ToolResultElision(),
    this.economics = CompactionEconomics.defaults,
    this.calibration,
    this.providerId,
    this.modelId,
    this.purpose = LlmCallPurpose.main,
    this.onRewriteDecision,
  });

  /// Produces the anchored summary text.
  final HarnessSummarizerPort summarizer;

  /// Compaction tunables (keepTurns / buffer / prune / policy).
  final CompactionConfig config;

  /// Classifier for uneventful tool results.
  final ToolResultElision elision;

  /// The cache-rebuild economics used to decide whether a rewrite pays.
  final CompactionEconomics economics;

  /// Provider-usage calibration, applied to the PROMPT estimate when wired.
  final TokenCalibration? calibration;

  /// The provider id used to key [calibration].
  final String? providerId;

  /// The model id used to key [calibration].
  final String? modelId;

  /// The purpose the calibration is keyed under — `main` for the primary run,
  /// `subagent` for a nested one, so a subagent's prompt sizes do not skew the
  /// parent's correction.
  final LlmCallPurpose purpose;

  /// Experiment hook: called with each prune/fold decision.
  final void Function(HarnessRewriteDecision decision)? onRewriteDecision;

  /// Calibrated PROMPT token estimate for [history] plus [overhead].
  ///
  /// [overhead] must be prompt-only; the output reservation is added separately
  /// and never scaled here.
  int _estimate(List<HarnessMessage> history, int overhead) =>
      calibratedHarnessTokens(
        estimateHarnessHistory(history) + overhead,
        calibration: calibration,
        providerId: providerId,
        modelId: modelId,
        purpose: purpose,
      );

  /// The correction factor applied to raw estimates (1.0 when uncalibrated).
  ///
  /// Needed to convert provider-token allowances back into raw-estimator units
  /// for tail selection.
  double _calibrationFactor() {
    final calibration = this.calibration;
    if (calibration == null ||
        providerId == null ||
        providerId!.isEmpty ||
        modelId == null ||
        modelId!.isEmpty) {
      return 1.0;
    }
    return calibration.factorFor(
      providerId: providerId!,
      modelId: modelId!,
      purpose: purpose,
    );
  }

  @override
  Future<HarnessCompactionResult> maybeCompact(
    List<HarnessMessage> history, {
    required int? contextWindow,
    int overheadTokens = 0,
    int reservedOutputTokens = 0,
    String selfAgentName = 'assistant',
    bool force = false,
  }) async {
    if (contextWindow == null) {
      return HarnessCompactionResult.unchanged(
        _estimate(history, overheadTokens),
      );
    }
    final originalBefore = _estimate(history, overheadTokens);

    /// Prompt + fixed output reservation must stay under the window.
    bool overBudget(int promptTokens) =>
        force ||
        promptTokens + reservedOutputTokens + config.buffer >= contextWindow;

    // ---- Masking phase (masking / hybrid policies), STAGED. ----
    var staged = history;
    var masked = 0;
    if (config.masksObservations && overBudget(originalBefore)) {
      final plan = maskStaleObservations(
        history,
        keepTurns: config.maskKeepTurns,
        minObservationTokens: config.maskMinObservationTokens,
        apply: false,
      );
      if (plan.changed) {
        final copy = List<HarnessMessage>.of(history);
        final applied = maskStaleObservations(
          copy,
          keepTurns: config.maskKeepTurns,
          minObservationTokens: config.maskMinObservationTokens,
        );
        if (applied.changed) {
          staged = copy;
          masked = applied.maskedCount;
        }
      }
    }

    final before = _estimate(staged, overheadTokens);
    // Did masking (or nothing) already bring the request under the window?
    final nowFits =
        !force && before + reservedOutputTokens + config.buffer < contextWindow;
    if (nowFits) {
      if (masked == 0) {
        return HarnessCompactionResult.unchanged(originalBefore);
      }
      // `masking` stops here — masking IS the strategy. `hybrid` summarizes at
      // the boundary as well, so it falls through to the fold.
      if (config.policy != CompactionPolicy.hybrid) {
        _commit(history, staged);
        return _maskOnlyResult(
          originalBefore: originalBefore,
          history: history,
          overheadTokens: overheadTokens,
          masked: masked,
          reason: 'masking sufficed',
        );
      }
    }

    // Recent region kept verbatim. Bounded so the folded result actually fits
    // under the window (tail + summary + overhead + output reservation). The
    // headroom and keepTokens are in PROVIDER (calibrated) tokens, but
    // `_tokenBudgetCut` sums RAW heuristic estimates — so the allowance is
    // converted back to raw units by the calibration factor. Skipping this is
    // how a tail chosen as N tokens really occupies N×factor and the "compacted"
    // request still overflows.
    final factor = _calibrationFactor();
    final calibratedOverhead = _estimate(const [], overheadTokens);
    final headroom =
        contextWindow -
        calibratedOverhead -
        reservedOutputTokens -
        config.buffer -
        4096;
    final rawHeadroom = (headroom / factor).floor();
    final baseKeepRaw = ((config.keepTokens ?? (contextWindow ~/ 4)) / factor)
        .round();
    final desiredRaw = force ? baseKeepRaw ~/ 2 : baseKeepRaw;
    final keepRecentTokens = desiredRaw.clamp(
      2000,
      rawHeadroom < 2000 ? 2000 : rawHeadroom,
    );

    final cut = _planCut(
      staged,
      keepRecentTokens: keepRecentTokens,
      force: force,
    );
    if (cut <= 0) {
      if (masked > 0) {
        _commit(history, staged);
        return _maskOnlyResult(
          originalBefore: originalBefore,
          history: history,
          overheadTokens: overheadTokens,
          masked: masked,
          reason: 'masked stale observations',
        );
      }
      return HarnessCompactionResult.unchanged(originalBefore);
    }
    final fold = staged.sublist(0, cut);
    final tail = staged.sublist(cut);
    final previousSummary = _extractPreviousSummary(fold);

    // STAGE until commit: nothing is written to `history` until the summary
    // exists. A throwing summarizer therefore leaves the fold un-applied, and
    // any staged masking is committed and reported rather than lost or
    // mislabelled "unchanged".
    final String summaryText;
    try {
      summaryText = await summarizer.summarize(
        HarnessCompactionInput(
          messages: fold,
          previousSummary: previousSummary,
          selfAgentName: selfAgentName,
          activeEditTargets: collectActiveEditTargets(staged),
        ),
      );
    } on Object catch (e) {
      if (masked > 0) {
        _commit(history, staged);
        return _maskOnlyResult(
          originalBefore: originalBefore,
          history: history,
          overheadTokens: overheadTokens,
          masked: masked,
          reason: 'summarizer failed ($e); masking committed, fold skipped',
        );
      }
      rethrow;
    }

    // Invariant the caller's checkpoint remap relies on: the folded span
    // (exactly `cut` == `fold.length` messages) collapses into ONE leading
    // message, so `messagesFolded` names how many leading entries became one.
    //
    // Machine-readable activation metadata is UNIONED onto the replacement:
    // when the only search result referencing a deferred tool sits inside the
    // folded span, losing its `toolReferences` would leave that tool activated
    // in the loop but unreachable on the next native request (and unrecoverable
    // on restart). No model tool_use/tool_result pair is ever fabricated — only
    // the metadata is carried.
    final foldedMessages = <HarnessMessage>[
      HarnessMessage(
        role: HarnessRole.user,
        content: [HarnessTextBlock('$harnessSummaryMarker\n$summaryText')],
        activatedToolNames: collectActivatedToolNames(fold),
      ),
      ...tail,
    ];
    history
      ..clear()
      ..addAll(foldedMessages);

    final after = _estimate(history, overheadTokens);
    // The fold rewrites the whole live prefix, so the rebuild cost is the
    // pre-fold prompt; the decision is recorded for the experiment even when
    // pressure (not the economics) forced it.
    final decision = economics.evaluate(
      reclaimedTokens: originalBefore - after,
      rebuildTokens: before,
      force: true,
    );
    onRewriteDecision?.call(decision);
    return HarnessCompactionResult(
      changed: true,
      summarized: true,
      messagesFolded: fold.length,
      tokensBefore: originalBefore,
      tokensAfter: after,
      policy: config.policy,
      reclaimedTokens: originalBefore - after,
      rebuildTokens: before,
      maskedObservations: masked,
      decisionReason: masked > 0
          ? 'masked $masked then folded (context pressure)'
          : 'folded (context pressure)',
    );
  }

  /// Writes [staged] back into the caller-owned [history] list, in place.
  void _commit(List<HarnessMessage> history, List<HarnessMessage> staged) {
    if (identical(history, staged)) {
      return;
    }
    history
      ..clear()
      ..addAll(staged);
  }

  HarnessCompactionResult _maskOnlyResult({
    required int originalBefore,
    required List<HarnessMessage> history,
    required int overheadTokens,
    required int masked,
    required String reason,
  }) {
    final after = _estimate(history, overheadTokens);
    return HarnessCompactionResult(
      changed: true,
      summarized: false,
      messagesFolded: 0,
      tokensBefore: originalBefore,
      tokensAfter: after,
      policy: config.policy,
      reclaimedTokens: originalBefore - after,
      maskedObservations: masked,
      decisionReason: reason,
    );
  }

  @override
  int pruneToolResults(List<HarnessMessage> history, {bool force = false}) {
    if (!config.prune) {
      return 0;
    }
    // Protect the newest tool-results turn from pruning (recent context).
    final lastToolIdx = history.lastIndexWhere(
      (m) => m.role == HarnessRole.tool,
    );
    // One pass over the assistant turns builds the id→name index. Resolving
    // each result by re-scanning history from 0 made this O(n²) per turn, and
    // it runs on every tool-bearing turn for the whole life of a session.
    final toolNames = _toolNameIndex(history);

    // Pass 1: how much is there to reclaim, and where does the earliest edit
    // sit? Pruning rewrites messages in place, and any byte change costs the
    // provider's cached prefix from that point forward — so the pass has to be
    // worth the cache it breaks.
    var reclaimable = 0;
    var earliest = -1;
    for (var i = 0; i < history.length; i++) {
      if (i == lastToolIdx || history[i].role != HarnessRole.tool) {
        continue;
      }
      var changed = false;
      for (final b in history[i].content) {
        if (b is! HarnessToolResultBlock) {
          continue;
        }
        if (b.content != elidedResultMarker &&
            !isMaskedObservation(b.content) &&
            elision.isUseless(
              toolName: toolNames[b.toolUseId] ?? '',
              outputs: b.content,
              isError: b.isError,
            )) {
          // Net saving: the original text minus the replacement marker.
          reclaimable +=
              TokenEstimator.instance.estimate(b.content) -
              TokenEstimator.instance.estimate(elidedResultMarker);
          changed = true;
        }
        if (b.images.isNotEmpty) {
          reclaimable += b.images.length * kImageTokenCost;
          changed = true;
        }
      }
      if (changed && earliest < 0) {
        earliest = i;
      }
    }

    // Masking candidates, planned without mutating, when the policy masks.
    var maskPlan = HarnessMaskResult.none;
    if (config.masksObservations) {
      maskPlan = maskStaleObservations(
        history,
        keepTurns: config.maskKeepTurns,
        minObservationTokens: config.maskMinObservationTokens,
        apply: false,
      );
      if (maskPlan.changed) {
        reclaimable += maskPlan.reclaimedTokens;
        if (maskPlan.earliestIndex >= 0 &&
            (earliest < 0 || maskPlan.earliestIndex < earliest)) {
          earliest = maskPlan.earliestIndex;
        }
      }
    }

    if (reclaimable <= 0) {
      onRewriteDecision?.call(HarnessRewriteDecision.nothing);
      return 0;
    }

    // The cache prefix that must be re-sent is the SUFFIX THAT SURVIVES the
    // rewrite — the pre-rewrite suffix minus the tokens being removed. Charging
    // the write premium for the deleted tokens themselves (the old behaviour)
    // makes ordinary pruning look unprofitable when almost nothing is left to
    // rebuild.
    final suffixBefore = earliest >= 0
        ? estimateHarnessHistory(history.sublist(earliest))
        : 0;
    final rebuildTokens = (suffixBefore - reclaimable).clamp(0, suffixBefore);
    final retrievalTokens =
        (maskPlan.reclaimedTokens * economics.maskRetrievalFraction).round();
    final decision = economics.evaluate(
      reclaimedTokens: reclaimable,
      rebuildTokens: rebuildTokens,
      retrievalTokens: retrievalTokens,
      force: force,
    );
    onRewriteDecision?.call(decision);

    // A cheap floor, then the economics: a tiny reclaim is never worth a
    // rewrite even if the model has many calls left.
    if (!force &&
        config.pruneThresholdTokens > 0 &&
        reclaimable < config.pruneThresholdTokens) {
      return 0;
    }
    if (!force && !decision.shouldRewrite) {
      return 0;
    }

    var changedBlocks = 0;

    // Apply masking first: it shrinks the text the elision pass then sees.
    if (config.masksObservations && maskPlan.changed) {
      final applied = maskStaleObservations(
        history,
        keepTurns: config.maskKeepTurns,
        minObservationTokens: config.maskMinObservationTokens,
      );
      changedBlocks += applied.maskedCount;
    }

    for (var i = 0; i < history.length; i++) {
      if (i == lastToolIdx) {
        continue;
      }
      final m = history[i];
      if (m.role != HarnessRole.tool) {
        continue;
      }
      final rebuilt = <HarnessContentBlock>[];
      var changed = false;
      for (final b in m.content) {
        if (b is HarnessToolResultBlock &&
            b.content != elidedResultMarker &&
            !isMaskedObservation(b.content) &&
            elision.isUseless(
              toolName: toolNames[b.toolUseId] ?? '',
              outputs: b.content,
              isError: b.isError,
            )) {
          rebuilt.add(
            // copyWith (not the raw constructor) so `outputReference` and
            // `toolReferences` survive the rewrite.
            b.copyWith(content: elidedResultMarker, images: const []),
          );
          changed = true;
          changedBlocks++;
        } else if (b is HarnessToolResultBlock && b.images.isNotEmpty) {
          // Stale screenshot, useful text: shed the image, keep the words.
          // Summarization shrinks text but cannot shrink an image, so without
          // this a run that screenshots every turn accumulates ~1200 tokens
          // per frame forever. The tool's text description is what carries
          // the finding past this point; only the newest tool turn (skipped
          // above) still needs to be looked at.
          rebuilt.add(b.copyWith(images: const []));
          changed = true;
          changedBlocks++;
        } else {
          rebuilt.add(b);
        }
      }
      if (changed) {
        // copyWith (not the raw constructor): the message's activation
        // metadata must survive the rewrite.
        history[i] = m.copyWith(content: rebuilt);
      }
    }
    return changedBlocks;
  }

  /// `toolUseId` → tool name, built in one pass over the assistant turns.
  Map<String, String> _toolNameIndex(List<HarnessMessage> history) {
    final index = <String, String>{};
    for (final m in history) {
      if (m.role != HarnessRole.assistant) {
        continue;
      }
      for (final b in m.content) {
        if (b is HarnessToolUseBlock) {
          // First writer wins, matching the old first-match-from-index-0 scan.
          index.putIfAbsent(b.id, () => b.name);
        }
      }
    }
    return index;
  }

  /// The index to cut at: everything in `history[0:cut)` is folded into the
  /// summary. Returns 0 when there is nothing worth folding. Normally a
  /// multi-turn chat keeps [CompactionConfig.keepTurns] user turns; autonomous
  /// runs use a token budget instead. After a provider overflow, the user-turn
  /// boundary cannot protect an oversized recent tail: choose the deeper safe
  /// token-budget cut when necessary.
  int _planCut(
    List<HarnessMessage> history, {
    required int keepRecentTokens,
    required bool force,
  }) {
    final userIdx = <int>[
      for (var i = 0; i < history.length; i++)
        if (history[i].role == HarnessRole.user) i,
    ];
    final turnCut = userIdx.length > config.keepTurns
        ? userIdx[userIdx.length - config.keepTurns]
        : 0;
    if (!force && turnCut > 0) {
      return turnCut;
    }
    final budgetCut = _tokenBudgetCut(history, keepRecentTokens);
    // A single oversized final assistant turn cannot be kept under this
    // budget. Under forced recovery even that turn must be summarized.
    if (force &&
        budgetCut == history.length - 1 &&
        estimateHarnessMessage(history.last) >= keepRecentTokens) {
      return history.length;
    }
    return budgetCut > turnCut ? budgetCut : turnCut;
  }

  /// Folds older messages within a single user turn, keeping the newest
  /// [keepRecentTokens] verbatim. The returned cut never starts the kept tail on
  /// a `tool` (tool-result) message, so no `tool_use`/`tool_result` pair is
  /// split across the fold boundary.
  int _tokenBudgetCut(List<HarnessMessage> history, int keepRecentTokens) {
    var kept = 0;
    var cut = 0;
    for (var i = history.length - 1; i >= 0; i--) {
      kept += estimateHarnessMessage(history[i]);
      if (kept >= keepRecentTokens) {
        cut = i;
        break;
      }
    }
    if (cut <= 0) {
      return 0;
    }
    // Snap forward so the tail cannot begin with an orphaned tool result.
    while (cut < history.length && history[cut].role == HarnessRole.tool) {
      cut++;
    }
    return cut;
  }

  /// Pulls the prior summary text out of a folded span, if its first user
  /// message is a summary marker.
  String? _extractPreviousSummary(List<HarnessMessage> fold) {
    for (final m in fold) {
      if (m.role == HarnessRole.user) {
        final text = m.textContent.trimLeft();
        if (text.startsWith(harnessSummaryMarker)) {
          return text.substring(harnessSummaryMarker.length).trim();
        }
        return null;
      }
    }
    return null;
  }
}
