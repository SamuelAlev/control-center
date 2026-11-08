import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';

/// A completed tool invocation surfaced from a `tool_use` content block.
class ClaudeToolUse {
  /// Creates a [ClaudeToolUse].
  const ClaudeToolUse({required this.id, required this.name, this.input});

  /// Anthropic tool_use id.
  final String id;

  /// Tool name (e.g. `Bash`, `Edit`).
  final String name;

  /// Decoded tool input.
  final Object? input;
}

/// The result of a tool invocation, paired back to its [ClaudeToolUse] by id.
class ClaudeToolResult {
  /// Creates a [ClaudeToolResult].
  const ClaudeToolResult({
    required this.id,
    required this.outputs,
    this.images = const [],
    this.isError = false,
    this.isAsync = false,
  });

  /// The `tool_use_id` this result answers.
  final String id;

  /// Flattened result text.
  final String outputs;

  /// Durable image references from render_media, never inline base64.
  final List<ToolImageRef> images;

  /// Whether the tool reported a failure.
  final bool isError;

  /// The tool returned a background-launch acknowledgement, not its outcome.
  final bool isAsync;
}

/// Work a subagent (the `Agent` / `Task` tool) did inside a `claude -p` run.
///
/// `claude` reports a subagent on the same stdout as its parent, tagging each
/// line with `parent_tool_use_id`: the id of the spawn call it is working for.
/// The subagent's turns arrive as whole `assistant` / `user` messages (no
/// partial deltas). Foreground answers arrive as spawn-call results; background
/// completion arrives through task lifecycle messages.
sealed class ClaudeSubagentEvent {
  const ClaudeSubagentEvent(this.spawnToolUseId);

  /// The `tool_use` id of the spawn call this subagent is working for.
  final String spawnToolUseId;
}

/// `claude` started a subagent (`system` / `task_started`).
class ClaudeSubagentStarted extends ClaudeSubagentEvent {
  /// Creates a [ClaudeSubagentStarted].
  const ClaudeSubagentStarted(
    super.spawnToolUseId, {
    this.description,
    this.subagentType,
  });

  /// The short task description the parent gave it.
  final String? description;

  /// Which subagent definition runs it (`general-purpose`, `Explore`, …).
  final String? subagentType;
}

/// Terminal outcomes reported by Claude's task lifecycle.
enum ClaudeSubagentStatus {
  /// The child finished successfully.
  completed,

  /// The child failed.
  failed,

  /// The child was stopped before finishing.
  stopped,
}

/// A background subagent ended independently of its spawn tool call.
class ClaudeSubagentFinished extends ClaudeSubagentEvent {
  /// Creates a [ClaudeSubagentFinished].
  const ClaudeSubagentFinished(
    super.spawnToolUseId, {
    required this.status,
    this.summary,
  });

  /// The task's terminal outcome.
  final ClaudeSubagentStatus status;

  /// The completion summary or failure reason, when supplied.
  final String? summary;
}

/// A whole text block the subagent wrote.
class ClaudeSubagentText extends ClaudeSubagentEvent {
  /// Creates a [ClaudeSubagentText].
  const ClaudeSubagentText(super.spawnToolUseId, this.text);

  /// The block's text.
  final String text;
}

/// A whole thinking block the subagent wrote.
class ClaudeSubagentThinking extends ClaudeSubagentEvent {
  /// Creates a [ClaudeSubagentThinking].
  const ClaudeSubagentThinking(super.spawnToolUseId, this.text);

  /// The block's reasoning text.
  final String text;
}

/// A tool call the subagent made.
class ClaudeSubagentToolCall extends ClaudeSubagentEvent {
  /// Creates a [ClaudeSubagentToolCall].
  const ClaudeSubagentToolCall(super.spawnToolUseId, this.call);

  /// The call, with its decoded input.
  final ClaudeToolUse call;
}

/// The result of one of the subagent's tool calls.
class ClaudeSubagentToolResult extends ClaudeSubagentEvent {
  /// Creates a [ClaudeSubagentToolResult].
  const ClaudeSubagentToolResult(super.spawnToolUseId, this.result);

  /// The result, paired to its call by id.
  final ClaudeToolResult result;
}
