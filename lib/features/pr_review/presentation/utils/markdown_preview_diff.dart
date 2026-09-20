import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:meta/meta.dart';

/// Opens an addition run in annotated preview markdown.
///
/// Private-use so the characters cannot appear in a real document. The
/// preview's inline plugin claims them and the renderer paints a GitHub-style
/// green wash; they never leak into the source diff.
const String kMarkdownDiffInsOpen = '\u{E000}a';

/// Opens a deletion run in annotated preview markdown.
const String kMarkdownDiffDelOpen = '\u{E000}d';

/// Closes an addition or deletion run.
const String kMarkdownDiffClose = '\u{E001}';

/// Leading character of every annotation sentinel (`U+E000`).
const int kMarkdownDiffTriggerUnit = 0xE000;

/// Rebuilds [headContent] as a merged markdown document with addition and
/// deletion sentinels so the preview can paint GitHub-style rich diffs.
///
/// List items, headings and other atomic block lines that changed are emitted
/// twice (old in a deletion wrap, new in an addition wrap) so both versions
/// stay visible. Prose runs are word-diffed into one merged paragraph.
///
/// An empty [patch] returns [headContent] unchanged. New files should skip
/// this entirely — highlighting every line green is noise, not a review.
String annotateMarkdownPreview({
  required String headContent,
  required String patch,
}) {
  if (patch.isEmpty || headContent.isEmpty) {
    return headContent;
  }
  final parsed = parseUnifiedDiff(patch);
  if (parsed.isEmpty) {
    return headContent;
  }

  final headLines = headContent.split('\n');
  final out = StringBuffer();
  var wrote = false;
  var nextHeadLine = 1;
  final dels = <String>[];
  final adds = <String>[];

  void emit(String chunk) {
    if (chunk.isEmpty) {
      return;
    }
    if (wrote) {
      out.write('\n');
    }
    out.write(chunk);
    wrote = true;
  }

  void flushChanges() {
    if (dels.isEmpty && adds.isEmpty) {
      return;
    }
    emit(_annotateChangeRun(dels, adds));
    dels.clear();
    adds.clear();
  }

  void copyHead(int fromLine, int toLineInclusive) {
    if (fromLine > toLineInclusive) {
      return;
    }
    final from = (fromLine - 1).clamp(0, headLines.length);
    final to = toLineInclusive.clamp(0, headLines.length);
    if (from >= to) {
      return;
    }
    emit(headLines.sublist(from, to).join('\n'));
    nextHeadLine = toLineInclusive + 1;
  }

  for (final line in parsed) {
    switch (line.kind) {
      case DiffLineKind.hunkHeader:
        flushChanges();
      case DiffLineKind.expandGap:
        flushChanges();
        final start = line.newLine;
        final end = line.gapNewEnd;
        if (start != null && end != null) {
          copyHead(start, end);
        }
      case DiffLineKind.context:
        flushChanges();
        emit(line.content);
        if (line.newLine != null) {
          nextHeadLine = line.newLine! + 1;
        }
      case DiffLineKind.deletion:
        dels.add(line.content);
      case DiffLineKind.addition:
        adds.add(line.content);
        if (line.newLine != null) {
          nextHeadLine = line.newLine! + 1;
        }
    }
  }
  flushChanges();
  if (nextHeadLine <= headLines.length) {
    copyHead(nextHeadLine, headLines.length);
  }
  return out.toString();
}

String _annotateChangeRun(List<String> dels, List<String> adds) {
  if (dels.isEmpty && adds.isEmpty) {
    return '';
  }
  final atomic =
      (dels.isEmpty || dels.every(_isAtomicLine)) &&
      (adds.isEmpty || adds.every(_isAtomicLine));
  if (atomic) {
    return _annotateAtomicRun(dels, adds);
  }
  if (dels.any(_isFenceRelated) || adds.any(_isFenceRelated)) {
    // Fences cannot carry sentinels (the ``` would no longer open a fence).
    // Show the new block only.
    return adds.join('\n');
  }
  return _annotateProseRun(dels, adds);
}

String _annotateAtomicRun(List<String> dels, List<String> adds) {
  final parts = <String>[];
  for (final line in dels) {
    if (_isFenceRelated(line)) {
      continue;
    }
    parts.add(_wrapLine(line, added: false));
  }
  for (final line in adds) {
    if (_isFenceRelated(line)) {
      parts.add(line);
      continue;
    }
    parts.add(_wrapLine(line, added: true));
  }
  return parts.join('\n');
}

String _annotateProseRun(List<String> dels, List<String> adds) {
  if (dels.isEmpty) {
    return adds.map((l) => _wrapLine(l, added: true)).join('\n');
  }
  if (adds.isEmpty) {
    return dels.map((l) => _wrapLine(l, added: false)).join('\n');
  }
  final delSplit = dels.map(_splitLine).toList();
  final addSplit = adds.map(_splitLine).toList();
  final prefix = _sharedPrefix(delSplit, addSplit);
  if (prefix == null) {
    return [
      ...dels.map((l) => _wrapLine(l, added: false)),
      ...adds.map((l) => _wrapLine(l, added: true)),
    ].join('\n');
  }
  final oldText = delSplit.map((s) => s.body).join('\n');
  final newText = addSplit.map((s) => s.body).join('\n');
  final merged = _wordMerge(oldText, newText);
  if (prefix.isEmpty) {
    return merged;
  }
  return merged.split('\n').map((l) => '$prefix$l').join('\n');
}

String _wrapLine(String line, {required bool added}) {
  final trimmed = line.trimLeft();
  if (trimmed.startsWith('|')) {
    return _wrapTableRow(line, added: added);
  }
  final split = _splitLine(line);
  if (split.body.isEmpty) {
    return line;
  }
  return '${split.prefix}${_wrap(split.body, added: added)}';
}

/// Wraps each table cell's text, not the `|` row. A wrap around the whole
/// line would leave the parser looking at a paragraph, not a table.
String _wrapTableRow(String line, {required bool added}) {
  final indentLength = line.length - line.trimLeft().length;
  final indent = line.substring(0, indentLength);
  final parts = line.substring(indentLength).split('|');
  final wrapped = <String>[];
  for (var i = 0; i < parts.length; i++) {
    final cell = parts[i];
    final isEdge = i == 0 || i == parts.length - 1;
    if (isEdge && cell.trim().isEmpty) {
      wrapped.add(cell);
      continue;
    }
    final trimmed = cell.trim();
    if (trimmed.isEmpty || _tableDelimiterRe.hasMatch(trimmed)) {
      wrapped.add(cell);
      continue;
    }
    wrapped.add(_wrap(cell, added: added));
  }
  return '$indent${wrapped.join('|')}';
}

String _wrap(String text, {required bool added}) {
  final sanitized = _stripSentinels(text);
  if (sanitized.isEmpty) {
    return sanitized;
  }
  // Keep leading/trailing newlines outside the wrap so a blank line still
  // splits paragraphs for the block parser.
  final start = _firstNonWs(sanitized);
  if (start == -1) {
    return sanitized;
  }
  final end = _lastNonWs(sanitized) + 1;
  final open = added ? kMarkdownDiffInsOpen : kMarkdownDiffDelOpen;
  final inner = sanitized.substring(start, end);
  // A wrap that itself contains a paragraph break would split the block and
  // leave the closer in the next paragraph, so each paragraph is wrapped.
  if (!inner.contains('\n\n')) {
    return '${sanitized.substring(0, start)}$open$inner$kMarkdownDiffClose'
        '${sanitized.substring(end)}';
  }
  final wrapped = inner
      .split('\n\n')
      .map((part) {
        if (part.trim().isEmpty) {
          return part;
        }
        return '$open$part$kMarkdownDiffClose';
      })
      .join('\n\n');
  return '${sanitized.substring(0, start)}$wrapped${sanitized.substring(end)}';
}

String _wordMerge(String oldText, String newText) {
  if (oldText == newText) {
    return newText;
  }
  if (oldText.isEmpty) {
    return _wrap(newText, added: true);
  }
  if (newText.isEmpty) {
    return _wrap(oldText, added: false);
  }

  final table = <String>[];
  final indexByCode = <String, int>{};
  final protectedOld = _protectCodeSpans(oldText, table, indexByCode);
  final protectedNew = _protectCodeSpans(newText, table, indexByCode);

  final dmp = DiffMatchPatch();
  final diffs = dmp.diff(protectedOld, protectedNew);
  dmp.diffCleanupSemantic(diffs);

  final buf = StringBuffer();
  for (final diff in diffs) {
    final restored = _restoreCodeSpans(diff.text, table);
    switch (diff.operation) {
      case DIFF_EQUAL:
        buf.write(_stripSentinels(restored));
      case DIFF_DELETE:
        buf.write(_wrap(restored, added: false));
      case DIFF_INSERT:
        buf.write(_wrap(restored, added: true));
    }
  }
  return buf.toString();
}

/// GFM inline code: N backticks, content that does not contain N backticks,
/// then N backticks. Protecting them as a single PUA char keeps a word-diff
/// from splitting a code span and dropping the backticks.
final RegExp _codeSpanRe = RegExp(r'(`+)((?:(?!\1).)*?)\1');

const int _codePlaceholderBase = 0xE010;
const int _codePlaceholderMax = 240;

String _protectCodeSpans(
  String text,
  List<String> table,
  Map<String, int> indexByCode,
) {
  if (!text.contains('`')) {
    return text;
  }
  return text.replaceAllMapped(_codeSpanRe, (m) {
    if (table.length >= _codePlaceholderMax) {
      return m[0]!;
    }
    final code = m[0]!;
    final index = indexByCode.putIfAbsent(code, () {
      table.add(code);
      return table.length - 1;
    });
    return String.fromCharCode(_codePlaceholderBase + index);
  });
}

String _restoreCodeSpans(String text, List<String> table) {
  if (table.isEmpty) {
    return text;
  }
  final buf = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final unit = text.codeUnitAt(i);
    final index = unit - _codePlaceholderBase;
    if (index >= 0 && index < table.length) {
      buf.write(table[index]);
    } else {
      buf.writeCharCode(unit);
    }
  }
  return buf.toString();
}

String _stripSentinels(String text) {
  if (text.isEmpty) {
    return text;
  }
  final buf = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final unit = text.codeUnitAt(i);
    if (unit == kMarkdownDiffTriggerUnit ||
        unit == 0xE001 ||
        (unit >= _codePlaceholderBase &&
            unit < _codePlaceholderBase + _codePlaceholderMax)) {
      continue;
    }
    buf.writeCharCode(unit);
  }
  return buf.toString();
}

final RegExp _atomicPrefixRe = RegExp(
  r'^((?:[ \t]*>[ \t]*)*[ \t]*)(#{1,6}[ \t]+|(?:[-*+]|\d{1,9}[.)])[ \t]+)?',
);

final RegExp _tableDelimiterRe = RegExp(r'^:?-+:?$');

@immutable
class _LineSplit {
  const _LineSplit({required this.prefix, required this.body});
  final String prefix;
  final String body;
}

_LineSplit _splitLine(String line) {
  final trimmed = line.trimLeft();
  if (trimmed.startsWith('```') ||
      trimmed.startsWith('~~~') ||
      trimmed.startsWith('|')) {
    return _LineSplit(prefix: '', body: line);
  }
  final match = _atomicPrefixRe.matchAsPrefix(line);
  if (match == null) {
    return _LineSplit(prefix: '', body: line);
  }
  final prefix = match.group(0) ?? '';
  return _LineSplit(prefix: prefix, body: line.substring(prefix.length));
}

bool _isAtomicLine(String line) {
  final trimmed = line.trimLeft();
  if (trimmed.startsWith('```') ||
      trimmed.startsWith('~~~') ||
      trimmed.startsWith('|')) {
    return true;
  }
  final match = _atomicPrefixRe.matchAsPrefix(line);
  final marker = match?.group(2);
  return marker != null && marker.isNotEmpty;
}

bool _isFenceRelated(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('```') || trimmed.startsWith('~~~');
}

String? _sharedPrefix(List<_LineSplit> dels, List<_LineSplit> adds) {
  String? prefix;
  for (final split in [...dels, ...adds]) {
    prefix ??= split.prefix;
    if (split.prefix != prefix) {
      return null;
    }
  }
  return prefix ?? '';
}

int _firstNonWs(String text) {
  for (var i = 0; i < text.length; i++) {
    final unit = text.codeUnitAt(i);
    if (unit != 0x20 && unit != 0x09 && unit != 0x0A && unit != 0x0D) {
      return i;
    }
  }
  return -1;
}

int _lastNonWs(String text) {
  for (var i = text.length - 1; i >= 0; i--) {
    final unit = text.codeUnitAt(i);
    if (unit != 0x20 && unit != 0x09 && unit != 0x0A && unit != 0x0D) {
      return i;
    }
  }
  return -1;
}
