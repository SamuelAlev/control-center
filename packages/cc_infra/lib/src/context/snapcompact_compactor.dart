import 'package:cc_harness/context.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_infra/src/context/snapcompact.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// A compactor that renders discarded history onto images instead of
/// summarizing it.
///
/// **Why it wraps rather than replaces the summarizing compactor.** Two things
/// have to stay true. It must degrade to a summary when the reader has no
/// vision — otherwise the whole context becomes an attachment nothing can read
/// — and it must still handle the cheap paths (tool-result elision, image
/// shedding) that have nothing to do with strategy. Both come free by
/// delegating.
///
/// **Snapshot folding is EXPLICIT OPT-IN (report 3G).** The strategy is only
/// used when [preferSnapshots] is set. It used to also fire on every forced
/// overflow recovery; that is removed, because "no summarizer call" does not
/// establish lower end-to-end cost or better recovery, and OCR fidelity for
/// exact code, paths and identifiers is a fidelity question that has to be
/// measured before the strategy becomes a default. Overflow recovery therefore
/// takes the conservative text path (a deeper summary), which is what it would
/// have done without this class at all.
class SnapcompactCompactor implements HarnessCompactor {
  /// Creates a [SnapcompactCompactor].
  SnapcompactCompactor({
    required this._fallback,
    required this.modelId,
    required this.readerHasVision,
    this.preferSnapshots = false,
    this.config = CompactionConfig.defaults,
    this.providerId,
    this.imageLimit,
    this.maxFrames = 6,
    String? retainedSource,
  }) : _retainedSource = retainedSource ?? '';

  final HarnessCompactor _fallback;

  /// The model that will read the pages — it decides their shape.
  final String? modelId;

  /// Whether that model can see images at all.
  ///
  /// False makes this a plain pass-through: rendering text no reader can look
  /// at is not a degraded compaction, it is a deleted conversation.
  final bool readerHasVision;

  /// Whether snapshots are the DEFAULT strategy, rather than a recovery path.
  ///
  /// Off until measured on real transcripts against a real model mix, which is
  /// what the replay rig exists for. When off, this compactor never images —
  /// not even under forced overflow recovery.
  final bool preferSnapshots;

  /// Thresholds, shared with the fallback.
  final CompactionConfig config;

  /// Provider id used to resolve the per-request image ceiling. When null the
  /// explicit [imageLimit] is the only bound.
  final String? providerId;

  /// Explicit per-request image ceiling, or null to resolve it from
  /// [providerId]. A snapshot pass that would push the request past this
  /// ceiling is refused and the text path runs instead — exceeding the
  /// provider's image limit is a 400, not a degradation.
  final int? imageLimit;

  /// Most pages a single pass may introduce. A page holds tens of thousands of
  /// characters, so more than a few means the fold is not compacting so much as
  /// translating; refusing keeps a pathological fold from replacing a large
  /// text history with an equally large set of images.
  final int maxFrames;

  /// The text the last pass rendered from, re-rendered on the next one.
  ///
  /// Seeded from the constructor for RESTART RECOVERY: persisted by the host
  /// (the source travels on `HarnessCompactionResult.retainedSnapshotSource`),
  /// and restored here so a later fold of the snapshot message can still recover
  /// the conversation it represents.
  String _retainedSource;

  /// The retained snapshot source, for the host to persist.
  String get retainedSource => _retainedSource;

  @override
  Future<HarnessCompactionResult> maybeCompact(
    List<HarnessMessage> history, {
    required int? contextWindow,
    int overheadTokens = 0,
    int reservedOutputTokens = 0,
    String selfAgentName = 'assistant',
    bool force = false,
  }) async {
    final useSnapshots = readerHasVision && preferSnapshots;
    if (!useSnapshots) {
      return _fallbackWithRehydration(
        history,
        contextWindow: contextWindow,
        overheadTokens: overheadTokens,
        reservedOutputTokens: reservedOutputTokens,
        selfAgentName: selfAgentName,
        force: force,
      );
    }

    final before = estimateHarnessHistory(history);
    if (contextWindow == null) {
      return HarnessCompactionResult.unchanged(before);
    }
    if (!force &&
        before + overheadTokens + reservedOutputTokens + config.buffer <
            contextWindow) {
      return HarnessCompactionResult.unchanged(before);
    }

    final SnapcompactResult snapped;
    try {
      snapped = Snapcompactor(
        shape: snapFrameShapeFor(modelId),
      ).compact(history, retainedSource: _retainedSource);
    } on Object catch (e) {
      // A rasterizer failure must never cost the run: fall through to the
      // summary, which is what would have happened without this at all.
      CcInfraLog.warning('snapcompact failed, summarizing instead: $e');
      return _fallbackWithRehydration(
        history,
        contextWindow: contextWindow,
        overheadTokens: overheadTokens,
        reservedOutputTokens: reservedOutputTokens,
        selfAgentName: selfAgentName,
        force: force,
      );
    }

    // Budget refusals: fall back to the text path, which can cut deeper.
    final refusal = _refusalReason(
      snapped,
      before,
      overheadTokens,
      reservedOutputTokens,
      contextWindow,
    );
    if (refusal != null) {
      CcInfraLog.info('snapcompact skipped ($refusal); summarizing instead.');
      return _fallbackWithRehydration(
        history,
        contextWindow: contextWindow,
        overheadTokens: overheadTokens,
        reservedOutputTokens: reservedOutputTokens,
        selfAgentName: selfAgentName,
        force: force,
      );
    }

    _retainedSource = snapped.retainedSource;
    // `history` is caller-owned and mutated in place — the loop holds the same
    // list across turns, so replacing the reference here would leave it
    // reading the pre-compaction conversation forever.
    history
      ..clear()
      ..addAll(snapped.messages);

    final after = estimateHarnessHistory(history);
    return HarnessCompactionResult(
      changed: true,
      // Not a summary: nothing was rewritten and no model was asked. Callers
      // that re-anchor a prompt cache on `summarized` must not do so here,
      // because the prefix did not change shape — it got shorter.
      summarized: false,
      messagesFolded: snapped.foldedCount,
      // A snapshot keeps a verbatim head, so the folded span does NOT start at
      // 0 — the caller's checkpoint remap must shift from here.
      foldedFromIndex: snapped.replacementIndex,
      // Persisted by the host so a restart can still recover this text.
      retainedSnapshotSource: _retainedSource,
      tokensBefore: before,
      tokensAfter: after,
      policy: config.policy,
      reclaimedTokens: before - after,
    );
  }

  /// Runs the text fallback over a history whose snapshot regions are first
  /// restored to TEXT.
  ///
  /// Without this, a refused later snapshot pass (page cap / image ceiling /
  /// fit) hands the fallback a history whose snapshot message is an image plus a
  /// caption — and the text summarizer sees only the caption, silently losing
  /// the entire first snapshot. The retained source is cumulative, so restoring
  /// it recovers the real conversation.
  ///
  /// Message COUNT is preserved (one replacement message in, one out), so the
  /// caller's checkpoint remap is unaffected; a bare rehydration with no
  /// subsequent fold is still reported as `changed`, because the bytes changed.
  Future<HarnessCompactionResult> _fallbackWithRehydration(
    List<HarnessMessage> history, {
    required int? contextWindow,
    required int overheadTokens,
    required int reservedOutputTokens,
    required String selfAgentName,
    required bool force,
  }) async {
    final rehydrated = rehydrateSnapcompactHistory(history, _retainedSource);
    final rehydratedChanged = !identical(rehydrated, history);
    final before = estimateHarnessHistory(history);
    final result = await _fallback.maybeCompact(
      rehydrated,
      contextWindow: contextWindow,
      overheadTokens: overheadTokens,
      reservedOutputTokens: reservedOutputTokens,
      selfAgentName: selfAgentName,
      force: force,
    );
    if (rehydratedChanged) {
      // The fallback mutates the list it was given; adopt it back into the
      // caller-owned list.
      history
        ..clear()
        ..addAll(rehydrated);
      // Clear the retained source ONLY when no message in the post-pass history
      // is a snapshot PAGE — the same IDENTITY test the host's
      // `absorbSnapshotSource` uses. The image count is deliberately NOT
      // consulted: an unrelated screenshot must not keep a stale source alive,
      // and a page whose images were shed is still a page.
      if (!history.any((m) => m.isSnapshotCarrier)) {
        _retainedSource = '';
      }
    }
    if (rehydratedChanged && !result.changed) {
      return HarnessCompactionResult(
        changed: true,
        summarized: false,
        messagesFolded: 0,
        tokensBefore: before,
        tokensAfter: estimateHarnessHistory(history),
        policy: config.policy,
        decisionReason:
            'snapshot region rehydrated to text for the text fallback',
      );
    }
    return result;
  }

  /// Why this snapshot pass must not be applied, or null when it may.
  ///
  /// The two absolute ceilings are the provider's per-request image limit and
  /// the model's context window — the window check reserves the PROMPT overhead
  /// AND the output reservation, so a fit that would leave no room to answer is
  /// refused; the relative one is that the pass has to actually reduce the
  /// request. An image-only rewrite that does not shrink the prompt (each page
  /// costs a flat block of tokens, and the text it replaced may have been
  /// small) is a rewrite that breaks the cache for nothing, so it is reported
  /// as no-change rather than applied.
  String? _refusalReason(
    SnapcompactResult snapped,
    int before,
    int overheadTokens,
    int reservedOutputTokens,
    int contextWindow,
  ) {
    if (!snapped.didCompact) {
      return 'nothing foldable';
    }
    if (snapped.frames > maxFrames) {
      return '${snapped.frames} pages exceeds the $maxFrames-page cap';
    }
    final limit = imageLimit ?? providerImageLimitFor(providerId);
    final imagesAfter = countHarnessImages(snapped.messages);
    if (imagesAfter > limit) {
      return '$imagesAfter images would exceed the provider limit $limit';
    }
    final after =
        estimateHarnessHistory(snapped.messages) +
        overheadTokens +
        reservedOutputTokens;
    if (after >= before + overheadTokens + reservedOutputTokens) {
      return 'the fold did not reduce the prompt';
    }
    if (after + config.buffer >= contextWindow) {
      return 'the folded prompt still exceeds the window';
    }
    return null;
  }

  /// Delegated: eliding uneventful tool results is orthogonal to strategy, and
  /// a second copy would be one more thing to keep in step.
  @override
  int pruneToolResults(List<HarnessMessage> history, {bool force = false}) =>
      _fallback.pruneToolResults(history, force: force);
}
