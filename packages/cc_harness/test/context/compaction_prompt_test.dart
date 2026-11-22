import 'package:cc_harness/context.dart';
import 'package:test/test.dart';

void main() {
  // The whole prompt, pinned: a change to what the summarizer is asked for is
  // a change both compaction lanes see, so it is made here on purpose.
  test('the compaction system prompt, word for word', () {
    expect(
      compactionSystemPrompt,
      'You are an anchored context-summarization assistant for coding '
      'sessions. Summarize only the conversation history you are given. The '
      'newest turns are kept verbatim outside your summary, so focus on the '
      'older context that still matters for continuing the work: decisions '
      'made, constraints discovered, files and APIs touched, open questions '
      'and the current plan. List the work still in flight — commands running '
      'in the background, questions and requests waiting on an answer, '
      'checklist items not yet done — and for each item how to check on it or '
      'pick it back up. Quote a question still waiting on an answer word for '
      'word. Be concise and factual — no preamble, no restating '
      'these instructions.\n\n'
      'If the history includes a <previous-summary> block, treat it as the '
      'current anchored summary: preserve still-true details, remove stale '
      'details and merge in the new facts. Output only the updated summary.',
    );
    expect(harnessCompactionSystemPrompt, compactionSystemPrompt);
  });
}
