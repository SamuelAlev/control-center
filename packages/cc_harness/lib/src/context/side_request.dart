import 'package:cc_harness/src/messages.dart';
import 'package:cc_harness/src/provider/llm_provider_port.dart';
import 'package:cc_harness/src/provider/reasoning_effort.dart';

/// Asks the live conversation a question without polluting it: append one
/// trailing `user` message to a history snapshot, same system prompt/cache key,
/// text-only. A system/developer tail would break the cached prefix on several
/// providers. Used by handoff docs and `/btw`.
class SideRequest {
  /// Creates a [SideRequest] over `provider`.
  const SideRequest(this._provider);

  final LlmProviderPort _provider;

  /// Asks [question] against a snapshot of [history] and returns the text.
  ///
  /// [history] is NOT mutated — the whole point is that the live conversation
  /// never learns this happened.
  ///
  /// Returns null when the provider produced nothing or errored: every caller
  /// has a graceful degradation (no handoff document, no side answer) and none
  /// of them should fail a run over it.
  Future<String?> ask({
    required List<HarnessMessage> history,
    required String question,
    String? systemPrompt,
    String? model,
    String? cacheKey,
    int maxTokens = 4096,
    ReasoningEffort? effort,
    Duration timeout = const Duration(minutes: 3),
  }) async {
    // A snapshot, plus one trailing turn. Copying the list rather than
    // appending in place is what keeps this side-effect-free.
    final messages = [...history, HarnessMessage.user(question)];
    final buffer = StringBuffer();
    try {
      final stream = _provider.complete(
        messages: messages,
        // No tools at all: this is the cheapest way to say "answer, do not
        // act". A provider given tools may call one, and a side request that
        // edits a file is a bug with no upside.
        tools: const [],
        config: LlmCompleteConfig(
          model: model,
          systemPrompt: systemPrompt,
          maxTokens: maxTokens,
          effort: effort,
          // Same key as the live run, so the shared prefix is a cache HIT.
          cacheKey: cacheKey,
        ),
      );
      await for (final event in stream.timeout(timeout)) {
        switch (event) {
          case LlmTextDelta(:final text):
            buffer.write(text);
          case LlmError():
            return null;
          case LlmDone():
            break;
          default:
            break;
        }
      }
    } on Object {
      return null;
    }
    final text = buffer.toString().trim();
    return text.isEmpty ? null : text;
  }
}

/// The prompt that turns a conversation into a handoff document.
///
/// Written for the reader who has NONE of this context: the next session, or a
/// person picking the work up cold. The three-part shape (what the task is,
/// what was learned, what remains) is the same one the turn-limit handoff
/// uses, so a run that ends either way produces a document of the same shape.
const String handoffPrompt = '''
Write a handoff document for whoever continues this work. They have none of
this conversation — only what you write here.

Structure it exactly as:

## Task
What was being attempted, and why.

## State
What is done and verified, what is done but unverified, and what was tried
and rejected (with the reason — that is what stops the next person repeating
it). Name concrete files, symbols and commands.

## Next
Ordered next steps, most important first. For each, say what "done" looks
like.

Be specific over complete: three precise facts beat a page of summary. Do NOT
invent progress that did not happen, and say plainly where you were stuck.''';

/// Renders an ephemeral side question so the model knows not to act on it.
String sideQuestionPrompt(String question) => '''
Answer this question about the work so far. It is a SIDE QUESTION: your answer
is shown to the user and is NOT added to the conversation, so do not treat it
as a new instruction and do not start any work.

$question''';
