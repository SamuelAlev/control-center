import 'package:control_center/shared/widgets/markdown/markdown_fences.dart';
import 'package:flutter/services.dart';

final RegExp _url = RegExp(r'^https?://\S+$');

/// Turns a URL pasted over selected text into a markdown link around that
/// text: `[selection](url)`, caret after it.
///
/// Runs as a [TextInputFormatter], so it sees only interactive edits; a paste
/// is the one edit that replaces a selection with a whole URL at once. The
/// paste stays a plain replacement when the selection is itself a URL, spans
/// lines, or sits in a fenced code block.
class PasteLinkFormatter extends TextInputFormatter {
  /// Creates a [PasteLinkFormatter].
  const PasteLinkFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldSel = oldValue.selection;
    final newSel = newValue.selection;
    if (!oldSel.isValid ||
        oldSel.isCollapsed ||
        !newSel.isValid ||
        !newSel.isCollapsed ||
        (newValue.composing.isValid && !newValue.composing.isCollapsed)) {
      return newValue;
    }
    final start = oldSel.start;
    final end = oldSel.end;
    if (end > oldValue.text.length) {
      return newValue;
    }
    final before = oldValue.text.substring(0, start);
    final after = oldValue.text.substring(end);
    final insertedEnd = newValue.text.length - after.length;
    if (insertedEnd <= start ||
        newSel.baseOffset != insertedEnd ||
        !newValue.text.startsWith(before) ||
        !newValue.text.endsWith(after)) {
      return newValue;
    }
    final url = newValue.text.substring(start, insertedEnd).trim();
    final selected = oldValue.text.substring(start, end);
    if (!_url.hasMatch(url) ||
        selected.trim().isEmpty ||
        selected.contains('\n') ||
        _url.hasMatch(selected.trim()) ||
        markdownFenceBodyAt(oldValue.text, start) != null) {
      return newValue;
    }
    // Parentheses would end the destination early; angle brackets hold them.
    final destination = url.contains('(') || url.contains(')') ? '<$url>' : url;
    final link = '[$selected]($destination)';
    return TextEditingValue(
      text: '$before$link$after',
      selection: TextSelection.collapsed(offset: start + link.length),
    );
  }
}
