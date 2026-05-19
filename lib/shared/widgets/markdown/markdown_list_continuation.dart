import 'package:flutter/widgets.dart';

/// Matches a markdown list line: optional indent, a bullet (`-`/`*`/`+`) or an
/// ordered marker (`1.` / `1)`), the spacing after it, then the content.
final RegExp _listItem = RegExp(r'^(\s*)(?:([-*+])|(\d+)([.)]))(\s+)(.*)$');

/// Continues a markdown list when the user presses Enter, mirroring editors like
/// GitHub's: Enter on a non-empty list item starts the next item (carrying the
/// indent, bullet, or the next number); Enter on an *empty* list item ends the
/// list by removing the marker.
///
/// Pure: given the controller value BEFORE and AFTER a keystroke, it returns the
/// rewritten value, or null when nothing should change (the keystroke wasn't a
/// plain newline at the end of a list item). Top-level so it is unit-testable.
TextEditingValue? continueMarkdownList(
  TextEditingValue oldValue,
  TextEditingValue newValue,
) {
  // Only react to a single '\n' just inserted at a collapsed caret.
  if (!newValue.selection.isCollapsed) {
    return null;
  }
  final caret = newValue.selection.baseOffset;
  if (caret <= 0 ||
      caret > newValue.text.length ||
      newValue.text.length != oldValue.text.length + 1 ||
      newValue.text[caret - 1] != '\n') {
    return null;
  }

  final before = newValue.text.substring(0, caret - 1);
  final lineStart = before.lastIndexOf('\n') + 1;
  final line = before.substring(lineStart);
  final m = _listItem.firstMatch(line);
  if (m == null) {
    return null;
  }

  final indent = m.group(1)!;
  final bullet = m.group(2); // -, *, + (or null for ordered)
  final number = m.group(3); // digits (or null for bullet)
  final closer = m.group(4) ?? '.'; // . or )
  final spacing = m.group(5)!;
  final content = m.group(6)!;

  if (content.trim().isEmpty) {
    // Empty item + Enter → end the list: strip the marker from that line.
    final text =
        newValue.text.substring(0, lineStart) + newValue.text.substring(caret);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: lineStart),
    );
  }

  // Non-empty item → insert the next marker after the new line.
  final String marker;
  if (bullet != null) {
    marker = '$indent$bullet$spacing';
  } else {
    final next = (int.tryParse(number!) ?? 1) + 1;
    marker = '$indent$next$closer$spacing';
  }
  final text =
      newValue.text.substring(0, caret) + marker + newValue.text.substring(caret);
  return TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: caret + marker.length),
  );
}

/// Wires [continueMarkdownList] onto [controller] as a self-correcting listener.
/// Returns a disposer that removes the listener. Re-entrancy guarded so the
/// rewrite it performs doesn't recurse.
VoidCallback attachListContinuation(TextEditingController controller) {
  var last = controller.value;
  var applying = false;
  void listener() {
    if (applying) {
      return;
    }
    final previous = last;
    final current = controller.value;
    last = current;
    final rewritten = continueMarkdownList(previous, current);
    if (rewritten != null) {
      applying = true;
      controller.value = rewritten;
      last = rewritten;
      applying = false;
    }
  }

  controller.addListener(listener);
  return () => controller.removeListener(listener);
}
