import 'package:flutter/services.dart';

/// A single insertion at least this many characters long is attached as a
/// text file instead of landing in the field.
///
/// Sized so a stack trace, a log excerpt or a source file becomes one chip,
/// while a few pasted paragraphs of prompt still read inline. Typing never
/// inserts more than a handful of characters in one edit, so the threshold
/// separates pastes from keystrokes without asking how the text arrived.
const int kLongPasteMinChars = 2000;

/// A single insertion spanning at least this many lines is attached even when
/// it is shorter than [kLongPasteMinChars] — forty one-word lines bury the
/// prompt around them just as thoroughly.
const int kLongPasteMinLines = 40;

/// File name a long paste is attached under; uniquified like any other
/// attachment when one is already in the draft.
const String kLongPasteFileName = 'pasted-text.txt';

/// Whether [inserted] is long enough to attach rather than inline.
bool isLongPaste(String inserted) {
  if (inserted.length >= kLongPasteMinChars) {
    return true;
  }
  var lines = 1;
  for (var i = 0; i < inserted.length; i++) {
    if (inserted.codeUnitAt(i) == 0x0A && ++lines >= kLongPasteMinLines) {
      return true;
    }
  }
  return false;
}

/// Diverts one long insertion out of the field.
///
/// Runs as an input formatter, which sees exactly the edits a person makes —
/// keyboard paste, the context menu's Paste, a browser paste on web — and
/// none of the composer's own writes (history recall, dictation, loading a
/// message to edit), which assign the controller directly. When the edit
/// inserts a long run and [onLongPaste] takes it, the field keeps its
/// previous value; the composer attaches the text right after, at the
/// selection the paste would have replaced.
class LongPasteFormatter extends TextInputFormatter {
  /// Creates a [LongPasteFormatter].
  LongPasteFormatter({required this.onLongPaste});

  /// Offered the long text; returns whether it took it. False lets the edit
  /// through unchanged. Called synchronously from the formatter, so it must
  /// defer any write to the controller.
  final bool Function(String text) onLongPaste;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // An IME's in-flight composition belongs to the IME.
    if (!newValue.composing.isCollapsed) {
      return newValue;
    }
    final inserted = insertedText(oldValue.text, newValue.text);
    if (inserted == null || !isLongPaste(inserted)) {
      return newValue;
    }
    return onLongPaste(inserted) ? oldValue : newValue;
  }

  /// The run [next] inserts relative to [previous], or null when the edit
  /// only deleted.
  ///
  /// Common prefix and suffix are stripped, so a paste that replaces a
  /// selection reports only what it put in.
  static String? insertedText(String previous, String next) {
    var prefix = 0;
    final shortest = previous.length < next.length
        ? previous.length
        : next.length;
    while (prefix < shortest &&
        previous.codeUnitAt(prefix) == next.codeUnitAt(prefix)) {
      prefix++;
    }
    var suffix = 0;
    while (suffix < shortest - prefix &&
        previous.codeUnitAt(previous.length - 1 - suffix) ==
            next.codeUnitAt(next.length - 1 - suffix)) {
      suffix++;
    }
    final end = next.length - suffix;
    return end > prefix ? next.substring(prefix, end) : null;
  }
}
