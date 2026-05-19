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
/// **The one place it is unambiguously better is overflow RECOVERY.** A
/// summarizing compactor shrinks the context by making a model call, and on a
/// forced compaction the call it makes is the one that just overflowed. This
/// path needs no call at all, so `force: true` uses it whenever the reader can
/// see — even when the configured default is the summary.
class SnapcompactCompactor implements HarnessCompactor {
  /// Creates a [SnapcompactCompactor].
  SnapcompactCompactor({
    required HarnessCompactor fallback,
    required this.modelId,
    required this.readerHasVision,
    this.preferSnapshots = false,
    this.config = CompactionConfig.defaults,
  }) : _fallback = fallback;

  final HarnessCompactor _fallback;

  /// The model that will read the pages — it decides their shape.
  final String? modelId;

  /// Whether that model can see images at all.
  ///
  /// False makes this a plain pass-through: rendering text no reader can look
  /// at is not a degraded compaction, it is a deleted conversation.
  final bool readerHasVision;

  /// Whether snapshots are the DEFAULT, rather than only the recovery path.
  ///
  /// Off until measured on real transcripts against a real model mix, which is
  /// what the replay rig exists for. Overflow recovery does not wait for that
  /// measurement, because there the alternative is a call that cannot succeed.
  final bool preferSnapshots;

  /// Thresholds, shared with the fallback.
  final CompactionConfig config;

  /// The text the last pass rendered from, re-rendered on the next one.
  String _retainedSource = '';

  @override
  Future<HarnessCompactionResult> maybeCompact(
    List<HarnessMessage> history, {
    required int? contextWindow,
    int overheadTokens = 0,
    String selfAgentName = 'assistant',
    bool force = false,
  }) async {
    final useSnapshots = readerHasVision && (preferSnapshots || force);
    if (!useSnapshots) {
      return _fallback.maybeCompact(
        history,
        contextWindow: contextWindow,
        overheadTokens: overheadTokens,
        selfAgentName: selfAgentName,
        force: force,
      );
    }

    final before = estimateHarnessHistory(history);
    if (contextWindow == null) {
      return HarnessCompactionResult.unchanged(before);
    }
    if (!force && before + overheadTokens + config.buffer < contextWindow) {
      return HarnessCompactionResult.unchanged(before);
    }

    final SnapcompactResult snapped;
    try {
      snapped = Snapcompactor(shape: snapFrameShapeFor(modelId)).compact(
        history,
        retainedSource: _retainedSource,
      );
    } on Object catch (e) {
      // A rasterizer failure must never cost the run: fall through to the
      // summary, which is what would have happened without this at all.
      CcInfraLog.warning('snapcompact failed, summarizing instead: $e');
      return _fallback.maybeCompact(
        history,
        contextWindow: contextWindow,
        overheadTokens: overheadTokens,
        selfAgentName: selfAgentName,
        force: force,
      );
    }

    if (!snapped.didCompact) {
      // Too short to be worth an image. The summarizer may still find
      // something (elision, image shedding), so it gets the turn.
      return _fallback.maybeCompact(
        history,
        contextWindow: contextWindow,
        overheadTokens: overheadTokens,
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

    return HarnessCompactionResult(
      changed: true,
      // Not a summary: nothing was rewritten and no model was asked. Callers
      // that re-anchor a prompt cache on `summarized` must not do so here,
      // because the prefix did not change shape — it got shorter.
      summarized: false,
      messagesFolded: snapped.foldedCount,
      tokensBefore: before,
      tokensAfter: estimateHarnessHistory(history),
    );
  }

  /// Delegated: eliding uneventful tool results is orthogonal to strategy, and
  /// a second copy would be one more thing to keep in step.
  @override
  int pruneToolResults(List<HarnessMessage> history, {bool force = false}) =>
      _fallback.pruneToolResults(history, force: force);
}
