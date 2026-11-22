import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/context.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';

/// A [HarnessSummarizerPort] that produces true anchored summaries via an
/// [LlmProviderPort] (a real model call), falling back to the deterministic
/// [StructuralHarnessSummarizer] on any error or empty output. A fallback is
/// reported with [HarnessSummary.modelWritten] false so the compaction result
/// does not claim a model summary it never got. A cancelled run is not a
/// failure: the request is abandoned and [CancelledException] propagates, so
/// the compactor commits nothing.
///
/// The pinned evidence (the person's original request, their later requests
/// and steering, and the loop's system steering) is re-attached to the
/// model's text verbatim ([withPinnedEvidence]), exactly as the structural
/// digest carries it: a model paraphrase must not be the only copy of the
/// requirements the next fold sees. Pin markers the model writes itself are
/// neutralised, so its text can never forge the block.
///
/// Uses the run's own provider so no extra credential/model resolution is
/// needed; the call is one-shot (non-streaming drain) and cache-free.
///
/// The request is tagged [LlmCallPurpose.compaction] so the provider usage
/// ledger can attribute and price it (report 3A) — a compaction must never look
/// free by moving work into a call nothing counts.
class LlmHarnessSummarizer implements HarnessSummarizerPort {
  /// Creates an [LlmHarnessSummarizer] over `provider`.
  const LlmHarnessSummarizer(
    this._provider, {
    this.budget = HarnessEvidenceBudget.defaults,
    this.calibration,
    this.providerId,
  });

  final LlmProviderPort _provider;

  /// Evidence budget for the bounded history handed to the model.
  final HarnessEvidenceBudget budget;

  /// Optional estimator calibration. When set, the prompt-token estimate for
  /// each summarization request is compared against the provider's reported
  /// prompt usage and folded in under [LlmCallPurpose.compaction].
  final TokenCalibration? calibration;

  /// Provider id used to key [calibration]; defaults to the provider's own
  /// display name.
  final String? providerId;

  static const StructuralHarnessSummarizer _fallback =
      StructuralHarnessSummarizer();

  @override
  Future<HarnessSummary> summarize(HarnessCompactionInput input) async {
    input.cancel.throwIfCancelled();
    try {
      final userPrompt = _userPrompt(input);
      final buf = StringBuffer();
      // The estimate must cover the SAME content the provider bills: the
      // system prompt plus the single user turn.
      final estimatedPromptTokens =
          TokenEstimator.instance.estimate(harnessCompactionSystemPrompt) +
          TokenEstimator.instance.estimate(userPrompt);
      var usage = const LlmUsage();
      await for (final event
          in _provider
              .complete(
                messages: [HarnessMessage.user(userPrompt)],
                config: const LlmCompleteConfig(
                  systemPrompt: harnessCompactionSystemPrompt,
                  maxTokens: 2048,
                  cacheEnabled: false,
                  purpose: LlmCallPurpose.compaction,
                ),
              )
              .untilCancelled(input.cancel)) {
        switch (event) {
          case LlmTextDelta(:final text):
            buf.write(text);
          case LlmUsage():
            usage = usage.reconcile(event);
          case LlmDone(usage: final finalUsage):
            if (finalUsage != null) {
              usage = usage.reconcile(finalUsage);
            }
          case LlmError(:final message):
            throw StateError(message);
          default:
            break;
        }
      }
      input.cancel.throwIfCancelled();
      _observeUsage(
        estimatedPromptTokens,
        usage.inputTokens + usage.cacheReadTokens + usage.cacheWriteTokens,
      );
      final text = buf.toString().trim();
      return text.isEmpty
          ? await _fallback.summarize(input)
          : HarnessSummary(
              withPinnedEvidence(text, input, budget: budget),
              modelWritten: true,
            );
    } on CancelledException {
      rethrow;
    } on Object {
      return _fallback.summarize(input);
    }
  }

  void _observeUsage(int estimatedPromptTokens, int observedPromptTokens) {
    final calibration = this.calibration;
    if (calibration == null || observedPromptTokens <= 0) {
      return;
    }
    calibration.observe(
      providerId: providerId ?? _provider.displayName,
      modelId: _provider.defaultModel,
      purpose: LlmCallPurpose.compaction,
      estimatedTokens: estimatedPromptTokens,
      observedPromptTokens: observedPromptTokens,
    );
  }

  String _userPrompt(HarnessCompactionInput input) {
    final buf = StringBuffer();
    final prev = input.previousSummary?.trim();
    if (prev != null && prev.isNotEmpty) {
      buf
        ..writeln('<previous-summary>')
        ..writeln(prev)
        ..writeln('</previous-summary>')
        ..writeln()
        ..writeln(
          'Update the anchored summary above using the conversation history '
          'below. Preserve still-true details, remove stale details, merge in '
          'new facts.',
        )
        ..writeln();
    } else {
      buf
        ..writeln(
          'Create an anchored summary from the conversation history '
          'below.',
        )
        ..writeln();
    }
    buf
      ..writeln('<conversation-history>')
      ..writeln(
        serializeHarnessHistory(
          input.messages,
          selfAgentName: input.selfAgentName,
          budget: budget,
          activeEditTargets: input.activeEditTargets.isEmpty
              ? collectActiveEditTargets(input.messages)
              : input.activeEditTargets,
        ),
      )
      ..writeln('</conversation-history>');
    final focus = input.focus?.trim();
    if (focus != null && focus.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('<focus>')
        ..writeln(focus)
        ..writeln('</focus>')
        ..writeln(
          'The focus above says what must survive this summary: keep '
          'everything it names, in full.',
        );
    }
    return buf.toString();
  }
}
