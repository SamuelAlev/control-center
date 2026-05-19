// Token-line helpers shared by the main-isolate tokenizer seam
// (shiki_tokenizers.dart) and the PR-diff worker core.
//
// FLUTTER-FREE ON PURPOSE: compiled into the diff Web Worker by
// `dart compile js` (enforced by the "Web Worker cores are Flutter-free"
// group in test/core/architecture_constraints_test.dart).

import 'package:shiki_flutter/engine.dart';

/// Re-attaches carriage returns that shiki's tokenizer normalized away, so
/// per-line token concatenation equals the corresponding source line exactly
/// (the intraline-emphasis and diff offset math depend on it).
///
/// Cheap no-op (single `contains`) for LF-only sources.
List<List<ThemedToken>> reattachCarriageReturns(
  String code,
  List<List<ThemedToken>> lines,
) {
  if (!code.contains('\r')) {
    return lines;
  }
  final sourceLines = code.split('\n');
  if (sourceLines.length != lines.length) {
    // Line-count mismatch means assumptions are off — return the tokenizer's
    // view untouched rather than mis-attaching.
    return lines;
  }
  final result = <List<ThemedToken>>[];
  for (var i = 0; i < lines.length; i++) {
    if (!sourceLines[i].endsWith('\r')) {
      result.add(lines[i]);
      continue;
    }
    final line = lines[i];
    if (line.isEmpty) {
      result.add(const [ThemedToken(content: '\r', offset: 0)]);
      continue;
    }
    final last = line.last;
    result.add([
      ...line.sublist(0, line.length - 1),
      ThemedToken(
        content: '${last.content}\r',
        offset: last.offset,
        color: last.color,
        bgColor: last.bgColor,
        fontStyle: last.fontStyle,
        scopes: last.scopes,
      ),
    ]);
  }
  return result;
}
