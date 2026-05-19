import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';

/// The kind of activity an agent turn is currently performing, derived from the
/// latest open segment. The presentation layer maps each kind to a localized
/// status line ("Making edits…", "Reading files…", …).
enum TranscriptStatusKind {
  /// Reasoning / extended thinking.
  thinking,

  /// Reading files (read tool).
  readingFiles,

  /// Editing or writing files.
  makingEdits,

  /// Running shell commands.
  runningCommands,

  /// Searching the codebase (grep/glob/ls).
  searching,

  /// Streaming the visible answer text.
  responding,

  /// Running some other named tool (carries [TranscriptStatus.toolName]).
  runningTool,
}

/// A derived status for an in-flight agent turn.
class TranscriptStatus {
  /// Creates a [TranscriptStatus].
  const TranscriptStatus(this.kind, {this.toolName});

  /// What the agent is doing.
  final TranscriptStatusKind kind;

  /// The humanized tool name, set only when [kind] is
  /// [TranscriptStatusKind.runningTool].
  final String? toolName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranscriptStatus &&
          kind == other.kind &&
          toolName == other.toolName;

  @override
  int get hashCode => Object.hash(kind, toolName);
}

/// Normalizes a tool name for matching: lowercased, with any `mcp__server__`
/// prefix stripped down to the final tool segment.
String normalizeToolName(String toolName) {
  final lower = toolName.toLowerCase().trim();
  final idx = lower.lastIndexOf('__');
  return idx >= 0 ? lower.substring(idx + 2) : lower;
}

/// Derives the status of an in-flight turn from its [segments].
///
/// Looks at the last segment: a still-open tool (running), an open
/// reasoning/text segment (no duration), or an open error. Returns null when
/// nothing is open (the turn is idle or finished). Pure and unit-testable.
TranscriptStatus? statusLineFor(List<TranscriptSegment> segments) {
  if (segments.isEmpty) {
    return null;
  }
  final last = segments.last;
  switch (last) {
    case ToolSegment(:final status, :final toolName):
      if (status != ToolSegmentStatus.running) {
        return null;
      }
      return _statusForTool(toolName);
    case ReasoningSegment(:final durationMs):
      return durationMs == null ? const TranscriptStatus(TranscriptStatusKind.thinking) : null;
    case TextSegment(:final durationMs):
      return durationMs == null
          ? const TranscriptStatus(TranscriptStatusKind.responding)
          : null;
    case ErrorSegment():
    case ViolationSegment():
      return null;
  }
}

TranscriptStatus _statusForTool(String toolName) {
  final name = normalizeToolName(toolName);
  if (name.contains('edit') || name.contains('write')) {
    return const TranscriptStatus(TranscriptStatusKind.makingEdits);
  }
  if (name == 'read' || name.contains('read')) {
    return const TranscriptStatus(TranscriptStatusKind.readingFiles);
  }
  if (name.contains('grep') ||
      name.contains('glob') ||
      name.contains('search') ||
      name.contains('find') ||
      name == 'ls' ||
      name.contains('list')) {
    return const TranscriptStatus(TranscriptStatusKind.searching);
  }
  if (name.contains('bash') ||
      name.contains('shell') ||
      name.contains('exec') ||
      name.contains('command')) {
    return const TranscriptStatus(TranscriptStatusKind.runningCommands);
  }
  return TranscriptStatus(TranscriptStatusKind.runningTool, toolName: toolName);
}
