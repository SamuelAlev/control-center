import 'package:cc_harness/context.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';

/// A [HarnessSummarizerPort] that produces true anchored summaries via an
/// [LlmProviderPort] (a real model call), falling back to the deterministic
/// [StructuralHarnessSummarizer] on any error or empty output.
///
/// Uses the run's own provider so no extra credential/model resolution is
/// needed; the call is one-shot (non-streaming drain) and cache-free.
class LlmHarnessSummarizer implements HarnessSummarizerPort {
  /// Creates an [LlmHarnessSummarizer] over `provider`.
  const LlmHarnessSummarizer(this._provider);

  final LlmProviderPort _provider;

  static const HarnessSummarizerPort _fallback = StructuralHarnessSummarizer();

  @override
  Future<String> summarize(HarnessCompactionInput input) async {
    try {
      final buf = StringBuffer();
      await for (final event in _provider.complete(
        messages: [HarnessMessage.user(_userPrompt(input))],
        config: const LlmCompleteConfig(
          systemPrompt: harnessCompactionSystemPrompt,
          maxTokens: 2048,
          cacheEnabled: false,
        ),
      )) {
        switch (event) {
          case LlmTextDelta(:final text):
            buf.write(text);
          case LlmError(:final message):
            throw StateError(message);
          default:
            break;
        }
      }
      final text = buf.toString().trim();
      return text.isEmpty ? await _fallback.summarize(input) : text;
    } on Object {
      return _fallback.summarize(input);
    }
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
        ),
      )
      ..writeln('</conversation-history>');
    return buf.toString();
  }
}
