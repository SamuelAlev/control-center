import 'package:flutter/services.dart';

/// Wraps the current non-collapsed selection in a matching delimiter pair
/// instead of replacing it when the user types an opening/markdown character.
///
/// Runs as a [TextInputFormatter], so it only intercepts interactive edits
/// (typing), never programmatic controller assignments such as toolbar actions,
/// `Cmd+B`/`Cmd+I` shortcuts, or history recall. The wrapped text remains
/// selected so repeated presses (e.g. `*` twice for `**bold**` or `` ` `` three
/// times for `` ```code``` ``) nest naturally.
class AutoWrapSelectionFormatter extends TextInputFormatter {
  /// Creates an [AutoWrapSelectionFormatter].
  const AutoWrapSelectionFormatter();

  static const Map<String, String> _wrapPairs = {
    '`': '`',
    '(': ')',
    '[': ']',
    '{': '}',
    '*': '*',
    '_': '_',
    '"': '"',
    "'": "'",
    '~': '~',
  };

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // An IME's in-flight composition (e.g. dead-key accents) belongs to the IME.
    if (newValue.composing.isValid && !newValue.composing.isCollapsed) {
      return newValue;
    }

    final oldSel = oldValue.selection;
    if (!oldSel.isValid || oldSel.isCollapsed) {
      return newValue;
    }

    final start = oldSel.start;
    final end = oldSel.end;
    if (start < 0 || end > oldValue.text.length || start >= end) {
      return newValue;
    }

    final before = oldValue.text.substring(0, start);
    final after = oldValue.text.substring(end);
    if (newValue.text.length != before.length + 1 + after.length) {
      return newValue;
    }

    final newSel = newValue.selection;
    if (!newSel.isValid ||
        !newSel.isCollapsed ||
        newSel.baseOffset != start + 1) {
      return newValue;
    }

    if (!newValue.text.startsWith(before) || !newValue.text.endsWith(after)) {
      return newValue;
    }

    final typed = newValue.text[start];
    final closing = _wrapPairs[typed];
    if (closing == null) {
      return newValue;
    }

    final selected = oldValue.text.substring(start, end);
    final wrappedText = '$before$typed$selected$closing$after';
    final newStart = start + 1;
    final newEnd = newStart + selected.length;
    final reversed = oldSel.baseOffset > oldSel.extentOffset;

    return TextEditingValue(
      text: wrappedText,
      selection: TextSelection(
        baseOffset: reversed ? newEnd : newStart,
        extentOffset: reversed ? newStart : newEnd,
      ),
    );
  }
}
