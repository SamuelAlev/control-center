import 'package:flutter/services.dart' show TextEditingValue, TextSelection;

/// Pure, UI-free transforms over a [TextEditingValue] that power the markdown
/// toolbar and its keyboard shortcuts. Kept separate from the widget so the
/// selection/caret math is unit-testable in isolation.
///
/// Every function returns a new [TextEditingValue] with the text rewritten and
/// the selection restored so typing continues naturally after the edit.

/// Wraps the current selection in [left]/[right] (e.g. `**`…`**`). With no
/// selection, inserts the pair and places the caret between them. If the
/// selection is already wrapped in [left]/[right], unwraps it (toggle).
TextEditingValue wrapSelection(
  TextEditingValue value,
  String left,
  String right,
) {
  final text = value.text;
  final sel = value.selection.isValid
      ? value.selection
      : TextSelection.collapsed(offset: text.length);
  final start = sel.start;
  final end = sel.end;
  final selected = text.substring(start, end);
  final before = text.substring(0, start);
  final after = text.substring(end);

  // Already wrapped → toggle off.
  if (before.endsWith(left) && after.startsWith(right)) {
    final newText = before.substring(0, before.length - left.length) +
        selected +
        after.substring(right.length);
    final newStart = start - left.length;
    return TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: newStart,
        extentOffset: newStart + selected.length,
      ),
    );
  }

  if (selected.isEmpty) {
    final newText = before + left + right + after;
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + left.length),
    );
  }

  final newText = before + left + selected + right + after;
  final newStart = start + left.length;
  return TextEditingValue(
    text: newText,
    selection: TextSelection(
      baseOffset: newStart,
      extentOffset: newStart + selected.length,
    ),
  );
}

/// Toggles a line [prefix] (e.g. `## `, `- `, `- [ ] `, `> `) on every line the
/// selection spans. If all non-blank lines already start with [prefix] it is
/// removed; otherwise it is added. Blank lines are left untouched.
TextEditingValue toggleLinePrefix(TextEditingValue value, String prefix) {
  final text = value.text;
  final sel = value.selection.isValid
      ? value.selection
      : TextSelection.collapsed(offset: text.length);

  final lineStart =
      sel.start == 0 ? 0 : text.lastIndexOf('\n', sel.start - 1) + 1;
  var lineEnd = text.indexOf('\n', sel.end);
  if (lineEnd == -1) {
    lineEnd = text.length;
  }

  final block = text.substring(lineStart, lineEnd);
  final lines = block.split('\n');
  final allPrefixed =
      lines.every((l) => l.trim().isEmpty || l.startsWith(prefix));
  final newLines = <String>[
    for (final l in lines)
      if (l.trim().isEmpty)
        l
      else if (allPrefixed)
        (l.startsWith(prefix) ? l.substring(prefix.length) : l)
      else
        prefix + l,
  ];
  final newBlock = newLines.join('\n');
  final newText = text.substring(0, lineStart) + newBlock + text.substring(lineEnd);
  final delta = newBlock.length - block.length;
  return TextEditingValue(
    text: newText,
    selection: TextSelection(
      baseOffset: lineStart,
      extentOffset: (lineEnd + delta).clamp(lineStart, newText.length),
    ),
  );
}

/// Inserts a markdown link `[label](url)` around the selection (the selection
/// becomes the label; `text` if empty), leaving the `url` placeholder selected
/// so the user can type the destination immediately.
TextEditingValue insertLink(TextEditingValue value) {
  final text = value.text;
  final sel = value.selection.isValid
      ? value.selection
      : TextSelection.collapsed(offset: text.length);
  final selected = text.substring(sel.start, sel.end);
  final label = selected.isEmpty ? 'text' : selected;
  final prefix = '[$label](';
  const url = 'url';
  final inserted = '$prefix$url)';
  final newText = text.substring(0, sel.start) + inserted + text.substring(sel.end);
  final urlStart = sel.start + prefix.length;
  return TextEditingValue(
    text: newText,
    selection: TextSelection(
      baseOffset: urlStart,
      extentOffset: urlStart + url.length,
    ),
  );
}
