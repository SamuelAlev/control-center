/// Serialization of conversation history into normalized bitmap-ready text.
///
/// [serializeEntries] turns a list of [VisionEntry] records into a single
/// markdown-ish string: user / assistant / reasoning prose plus merged tool
/// call + result blocks, with per-result and per-argument truncation budgets,
/// dim-ink toggles around tool output, and contextually useless tool pairs
/// dropped entirely. The whole result is folded through [normalizeForBitmap] so
/// it is ready for the foveated planner and renderer. Ported from oh-my-pi's
/// `snapcompact.serializeConversation`.
library;

import 'dart:convert';

import 'package:cc_infra/src/messaging/vision/vision_normalize.dart';

/// Per-tool-result character cap in serialized history. Longer results keep a
/// head/tail slice with an elision marker in the middle.
const int toolResultMaxChars = 2000;

/// Per-argument-value character cap inside serialized tool calls (so a write /
/// edit body cannot dump a whole file into the archive).
const int toolArgMaxChars = 500;

/// Whole-argument-list character cap per serialized tool call.
const int toolCallMaxChars = 2000;

/// Fraction of a truncation budget spent on the head; the remainder keeps the
/// tail, where command errors and test failures usually land.
const double truncateHeadRatio = 0.6;

/// One conversation entry to serialize for vision compaction.
///
/// A [role] of `tool` (or `toolResult`) carries a tool call and/or its result;
/// the serializer merges a call and its paired result into a single block.
class VisionEntry {
  /// Creates a [VisionEntry].
  const VisionEntry({
    required this.role,
    required this.text,
    this.toolName,
    this.toolArgs,
    this.useless = false,
    this.intent,
  });

  /// One of `user`, `assistant`, `reasoning`, `tool`, or `toolResult`.
  final String role;

  /// The entry's body text (user/assistant prose, reasoning, or tool result).
  final String text;

  /// Tool name for `tool`/`toolResult` entries (e.g. `Read`, `Edit`).
  final String? toolName;

  /// Parsed tool arguments for `tool`/`toolResult` entries.
  final Map<String, dynamic>? toolArgs;

  /// When `true`, this tool call/result pair carries no archive-worthy
  /// information and is dropped entirely during serialization.
  final bool useless;

  /// Optional one-line intent comment rendered as `//intent` above the call.
  final String? intent;
}

/// Serializes [entries] into normalized, bitmap-ready text.
///
/// Per role:
/// - `user` → `# User\n<text>`
/// - `assistant` → `# Assistant\n<text>`
/// - `reasoning` → `# Assistant (thinking)\n_<text>_`
/// - `tool` / `toolResult` → `# Tool call\n//<intent?>\n<name>(<args>)\n` then
///   the truncated result wrapped in [dimOn]/[dimOff].
///
/// Entries flagged [VisionEntry.useless] are skipped. Tool results are capped
/// at [toolResultMaxChars] (keeping [truncateHeadRatio] head / remainder tail),
/// each argument value at [toolArgMaxChars], and the whole argument list at
/// [toolCallMaxChars]. The joined output is run through [normalizeForBitmap].
String serializeEntries(List<VisionEntry> entries) {
  final parts = <String>[];

  for (final entry in entries) {
    switch (entry.role) {
      case 'user':
        final content = stripDimMarkers(entry.text);
        if (content.isNotEmpty) {
          parts.add('# User\n$content');
        }
      case 'assistant':
        final content = stripDimMarkers(entry.text);
        if (content.trim().isNotEmpty) {
          parts.add('# Assistant\n$content');
        }
      case 'reasoning':
        final content = stripDimMarkers(entry.text);
        if (content.trim().isNotEmpty) {
          parts.add('# Assistant (thinking)\n_${content}_');
        }
      case 'tool':
      case 'toolResult':
        if (entry.useless) {
          continue;
        }
        parts.add(_serializeToolEntry(entry));
      default:
        // Unknown roles serialize as plain prose so nothing is silently lost.
        final content = stripDimMarkers(entry.text);
        if (content.trim().isNotEmpty) {
          parts.add(content);
        }
    }
  }

  return normalizeForBitmap(parts.join('\n\n'));
}

/// Serializes a single tool call/result entry into a `# Tool call` block.
String _serializeToolEntry(VisionEntry entry) {
  final lines = <String>['# Tool call'];

  final intent = entry.intent == null
      ? ''
      : stripDimMarkers(entry.intent!).replaceAll(RegExp(r'\s+'), ' ').trim();
  if (intent.isNotEmpty) {
    lines.add('//$intent');
  }

  final name = entry.toolName ?? 'tool';
  final argsStr = _serializeArgs(entry.toolArgs);
  lines.add('$name($argsStr)');

  final result = stripDimMarkers(entry.text);
  if (result.isNotEmpty) {
    final body = truncateForSummary(result, toolResultMaxChars, truncateHeadRatio);
    lines.add('$dimOn$body$dimOff');
  }

  return lines.join('\n');
}

/// Serializes a tool argument map to `key=value, …`, with each value capped at
/// [toolArgMaxChars] and the whole list capped at [toolCallMaxChars].
String _serializeArgs(Map<String, dynamic>? args) {
  if (args == null || args.isEmpty) {
    return '';
  }
  final rendered = args.entries.map((entry) {
    String encoded;
    try {
      encoded = jsonEncode(entry.value);
    } on JsonUnsupportedObjectError {
      encoded = '${entry.value}';
    }
    final value =
        truncateForSummary(encoded, toolArgMaxChars, truncateHeadRatio);
    return '${entry.key}=$value';
  }).join(', ');
  return truncateForSummary(rendered, toolCallMaxChars, truncateHeadRatio);
}

/// Keeps the head and tail of [text], eliding the middle when it exceeds
/// [maxChars]. [headRatio] (clamped to `[0, 1]`) is the head's share of the
/// budget. The elision marker reports how many characters were dropped.
String truncateForSummary(String text, int maxChars, double headRatio) {
  if (text.length <= maxChars) {
    return text;
  }
  final ratio = headRatio.clamp(0.0, 1.0);
  final headChars = (maxChars * ratio).round();
  final tailChars = maxChars - headChars;
  final elided = text.length - maxChars;
  final head = text.substring(0, headChars);
  final tail = tailChars > 0 ? text.substring(text.length - tailChars) : '';
  return '$head …${elided}ch elided… $tail';
}
