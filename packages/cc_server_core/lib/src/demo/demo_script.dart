/// The demo's hand-authored agent-run scripts.
///
/// A script is a recorded-looking agent turn: thinking, prose, tool calls with
/// their results and a token-usage report. `ScriptedAgentLoop` replays one
/// instead of calling a model, so a public demo streams a convincing run
/// without a provider credential and without executing a single tool.
///
/// This is deliberately NOT `SessionRecordingData`: that type carries
/// expected-signature/eval fields a hand-authored demo has no honest value for,
/// and nothing produces one from a live run today.
library;

/// One step of a [DemoRunScript].
sealed class DemoScriptStep {
  /// Const base constructor.
  const DemoScriptStep();

  /// Decodes a step from its authored JSON form.
  ///
  /// Throws [FormatException] on an unknown `kind` — a typo in a fixture must
  /// fail the generator, not silently drop a beat from the run.
  factory DemoScriptStep.fromJson(Map<String, dynamic> json) {
    final kind = json['kind'];
    return switch (kind) {
      'thinking' => DemoThinkingStep(json['text'] as String? ?? ''),
      'say' => DemoSayStep(json['text'] as String? ?? ''),
      'tool' => DemoToolStep(
        tool: json['tool'] as String? ?? 'read',
        args: Map<String, dynamic>.from(
          json['args'] as Map? ?? const <String, dynamic>{},
        ),
        result: json['result'] as String? ?? '',
        isError: json['is_error'] as bool? ?? false,
      ),
      'usage' => DemoUsageStep(
        inputTokens: json['input'] as int? ?? 0,
        outputTokens: json['output'] as int? ?? 0,
        cacheReadTokens: json['cache_read'] as int? ?? 0,
        cacheWriteTokens: json['cache_write'] as int? ?? 0,
        thoughtTokens: json['thought'] as int? ?? 0,
      ),
      _ => throw FormatException('Unknown demo script step kind: $kind'),
    };
  }
}

/// Streamed extended-thinking text.
final class DemoThinkingStep extends DemoScriptStep {
  /// Creates a thinking step.
  const DemoThinkingStep(this.text);

  /// The reasoning text, streamed in chunks.
  final String text;
}

/// Streamed assistant prose.
final class DemoSayStep extends DemoScriptStep {
  /// Creates a prose step.
  const DemoSayStep(this.text);

  /// The assistant text, streamed in chunks.
  final String text;
}

/// A tool call and the result it "returned".
///
/// The tool never runs: `ScriptedAgentLoop` emits the start and result events
/// straight from the fixture, so the transcript renders a real tool card while
/// nothing touches the filesystem, the network or a process.
final class DemoToolStep extends DemoScriptStep {
  /// Creates a tool step.
  const DemoToolStep({
    required this.tool,
    required this.args,
    required this.result,
    this.isError = false,
  });

  /// The tool name shown on the card (e.g. `read`, `grep`, `edit`).
  final String tool;

  /// The arguments shown on the card.
  final Map<String, dynamic> args;

  /// The result body shown on the card.
  final String result;

  /// Whether the card renders as a failure.
  final bool isError;
}

/// A token-usage report for the turn just streamed.
///
/// The numbers are real inputs to the real cost calculator — a demo run's cost,
/// token counts and cache rate are computed by the same code a live run uses,
/// so the observability surfaces are exercised rather than faked.
final class DemoUsageStep extends DemoScriptStep {
  /// Creates a usage step.
  const DemoUsageStep({
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.cacheReadTokens = 0,
    this.cacheWriteTokens = 0,
    this.thoughtTokens = 0,
  });

  /// Non-cached input tokens.
  final int inputTokens;

  /// Output (completion) tokens.
  final int outputTokens;

  /// Cache-hit read tokens.
  final int cacheReadTokens;

  /// Cache-write tokens.
  final int cacheWriteTokens;

  /// Reasoning tokens.
  final int thoughtTokens;
}

/// One replayable agent run.
class DemoRunScript {
  /// Creates a script.
  const DemoRunScript({
    required this.id,
    required this.triggers,
    required this.steps,
  });

  /// Decodes a script from its authored JSON form.
  factory DemoRunScript.fromJson(Map<String, dynamic> json) => DemoRunScript(
    id: json['id'] as String,
    triggers: [
      for (final t in json['triggers'] as List? ?? const [])
        (t as String).toLowerCase(),
    ],
    steps: [
      for (final s in json['steps'] as List? ?? const [])
        DemoScriptStep.fromJson(Map<String, dynamic>.from(s as Map)),
    ],
  );

  /// Stable id, addressable with the `[[demo:script=<id>]]` marker.
  final String id;

  /// Lowercase keywords matched against the visitor's message.
  final List<String> triggers;

  /// The beats of the run, in order.
  final List<DemoScriptStep> steps;

  /// How strongly this script matches [message]; 0 means no match.
  ///
  /// Longer triggers score higher so a specific phrase ("pull request") beats
  /// an incidental word ("pr") when both appear.
  int scoreFor(String message) {
    final haystack = message.toLowerCase();
    var score = 0;
    for (final trigger in triggers) {
      if (haystack.contains(trigger)) {
        score += trigger.length;
      }
    }
    return score;
  }
}
