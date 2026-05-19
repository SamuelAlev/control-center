/// Which end of an over-long tool output to preserve.
enum TruncateDirection {
  /// Keep the head (first lines) — useful when the interesting content is the
  /// command echo / setup at the top.
  head,

  /// Keep the tail (last lines) — useful when the result / error / exit code at
  /// the bottom matters most.
  tail,

  /// Keep a head slice AND a tail slice, dropping the middle. This is the
  /// default for terminal-style output: the first 20% carries the command and
  /// setup context, the last 80% carries the result and any error.
  headAndTail,
}

/// Per-tool truncation limits. A tool output is truncated when it exceeds the
/// [characterLimit] OR the [lineLimit]; the character cap is applied first.
class ToolOutputLimits {
  /// Creates [ToolOutputLimits].
  const ToolOutputLimits({
    this.characterLimit = 50000,
    this.lineLimit = 2000,
    this.direction = TruncateDirection.headAndTail,
    this.headRatio = 0.2,
    this.maxImages = 1,
  }) : assert(headRatio >= 0 && headRatio <= 1, 'headRatio must be in [0,1]');

  /// Maximum characters before truncation kicks in. `<= 0` disables.
  final int characterLimit;

  /// Maximum lines before truncation kicks in. `<= 0` disables.
  final int lineLimit;

  /// Which end(s) to keep.
  final TruncateDirection direction;

  /// Fraction kept from the head when [direction] is [TruncateDirection.headAndTail].
  /// The remainder is kept from the tail. Defaults to the 20/80 split.
  final double headRatio;

  /// Maximum images a single tool result may carry into the transcript.
  ///
  /// Images are the most expensive thing a tool can return (~1200 tokens each,
  /// and they are never compacted down the way text is), so the budget is
  /// deliberately tight: one per result unless a tool opts into more. Extra
  /// images are dropped from the END, keeping the earliest — for a rig
  /// screenshot sequence the first frame is the one the request asked for.
  /// `<= 0` disables images for the tool entirely.
  final int maxImages;

  /// Default limits used when a tool has no specific entry.
  static const ToolOutputLimits standard = ToolOutputLimits();

  /// Returns a copy with selected fields overridden.
  ToolOutputLimits copyWith({
    int? characterLimit,
    int? lineLimit,
    TruncateDirection? direction,
    double? headRatio,
    int? maxImages,
  }) => ToolOutputLimits(
    characterLimit: characterLimit ?? this.characterLimit,
    lineLimit: lineLimit ?? this.lineLimit,
    direction: direction ?? this.direction,
    headRatio: headRatio ?? this.headRatio,
    maxImages: maxImages ?? this.maxImages,
  );
}

/// The result of a truncation pass over a single tool output.
class TruncatedOutput {
  /// Creates a [TruncatedOutput].
  const TruncatedOutput({
    required this.content,
    required this.truncated,
    this.omittedChars = 0,
    this.omittedLines = 0,
  });

  /// The (possibly truncated) content, with an explicit omission marker.
  final String content;

  /// Whether any content was dropped.
  final bool truncated;

  /// Characters dropped (0 when not truncated, or when line-truncated).
  final int omittedChars;

  /// Lines dropped (0 when not truncated, or when char-truncated).
  final int omittedLines;
}

/// Per-tool limit table. CC tools that routinely emit huge output (file reads,
/// shell, search) get tuned caps; everything else falls back to [ToolOutputLimits.standard].
class ToolOutputLimitTable {
  /// Creates a [ToolOutputLimitTable] with an optional [overrides] map keyed by
  /// a normalized tool name (see [_normalizeTool]).
  const ToolOutputLimitTable({Map<String, ToolOutputLimits>? overrides})
    : _overrides = overrides ?? const {};

  final Map<String, ToolOutputLimits> _overrides;

  /// The built-in default table.
  static const ToolOutputLimitTable defaults = ToolOutputLimitTable(
    overrides: {
      // Reads carry the most-recent file content; keep generous head context.
      'read': ToolOutputLimits(
        characterLimit: 60000,
        lineLimit: 3000,
        direction: TruncateDirection.head,
      ),
      // Searches: the head (the matches) is what matters.
      'grep': ToolOutputLimits(
        characterLimit: 30000,
        lineLimit: 1000,
        direction: TruncateDirection.head,
      ),
      'find': ToolOutputLimits(
        characterLimit: 30000,
        lineLimit: 1000,
        direction: TruncateDirection.head,
      ),
      // Shell/build: the tail (result + exit code) matters most.
      'bash': ToolOutputLimits(characterLimit: 50000, lineLimit: 2000),
      'shell': ToolOutputLimits(characterLimit: 50000, lineLimit: 2000),
      // Enclosure (rig) tools return a screenshot per call. Text stays small
      // (a status line + extracted state); the image is the payload, so it
      // keeps its budget of one and the text cap is tightened — a DOM or UI
      // dump has no business filling the window.
      'computer_use': ToolOutputLimits(characterLimit: 30000, lineLimit: 1000),
      'browser_use': ToolOutputLimits(characterLimit: 30000, lineLimit: 1000),
      'mobile_use': ToolOutputLimits(characterLimit: 30000, lineLimit: 1000),
    },
  );

  /// Limits for a tool by (case-insensitive, MCP-prefix-stripped) [toolName].
  ToolOutputLimits forTool(String toolName) =>
      _overrides[_normalizeTool(toolName)] ?? ToolOutputLimits.standard;
}

/// Applies [limits]' image budget to [images], keeping the earliest and
/// dropping the rest. Returns [images] unchanged when it already fits, so the
/// common (empty) case allocates nothing.
List<T> capToolImages<T>(List<T> images, ToolOutputLimits limits) {
  final max = limits.maxImages;
  if (max <= 0) {
    return const [];
  }
  if (images.length <= max) {
    return images;
  }
  return images.sublist(0, max);
}

/// Normalizes a tool name for table lookup: lower-cased, with any
/// `mcp__server__` prefix stripped (so `mcp__cc__read` matches `read`).
String _normalizeTool(String toolName) {
  var name = toolName.toLowerCase();
  if (name.startsWith('mcp__')) {
    final lastSep = name.lastIndexOf('__');
    if (lastSep >= 0 && lastSep + 2 < name.length) {
      name = name.substring(lastSep + 2);
    }
  }
  return name;
}

/// Truncates [content] to fit [limits], preserving the configured end(s) and
/// inserting an explicit `[...N omitted...]` marker where content was dropped.
///
/// The character cap is enforced first (it is the hard ceiling); if the content
/// fits the character cap it is then checked against the line cap. A `<= 0`
/// limit disables that dimension.
TruncatedOutput truncateToolOutput(String content, ToolOutputLimits limits) {
  final charLimit = limits.characterLimit;
  if (charLimit > 0 && content.length > charLimit) {
    final omitted = content.length - charLimit;
    final marker = '\n[...$omitted characters omitted...]\n';
    final body = _sliceString(content, charLimit, limits, marker);
    return TruncatedOutput(
      content: body,
      truncated: true,
      omittedChars: omitted,
    );
  }

  final lineLimit = limits.lineLimit;
  if (lineLimit <= 0) {
    return TruncatedOutput(content: content, truncated: false);
  }

  final lines = content.split('\n');
  if (lines.length <= lineLimit) {
    return TruncatedOutput(content: content, truncated: false);
  }

  final omitted = lines.length - lineLimit;
  final marker = '[...$omitted lines omitted...]';
  final body = _sliceLines(lines, lineLimit, limits, marker);
  return TruncatedOutput(content: body, truncated: true, omittedLines: omitted);
}

String _sliceString(
  String content,
  int limit,
  ToolOutputLimits limits,
  String marker,
) {
  switch (limits.direction) {
    case TruncateDirection.head:
      return content.substring(0, limit) + marker;
    case TruncateDirection.tail:
      return marker + content.substring(content.length - limit);
    case TruncateDirection.headAndTail:
      final head = (limit * limits.headRatio).floor();
      final tail = limit - head;
      return content.substring(0, head) +
          marker +
          content.substring(content.length - tail);
  }
}

String _sliceLines(
  List<String> lines,
  int limit,
  ToolOutputLimits limits,
  String marker,
) {
  switch (limits.direction) {
    case TruncateDirection.head:
      return '${lines.take(limit).join('\n')}\n\n$marker';
    case TruncateDirection.tail:
      return '$marker\n\n${lines.skip(lines.length - limit).join('\n')}';
    case TruncateDirection.headAndTail:
      final head = (limit * limits.headRatio).floor();
      final tail = limit - head;
      final headLines = lines.take(head).join('\n');
      final tailLines = lines.skip(lines.length - tail).join('\n');
      return '$headLines\n\n$marker\n\n$tailLines';
  }
}
