import 'package:control_center/shared/widgets/composer/composer_models.dart';

/// Pure function that, given the current text and caret position, decides
/// whether a mention popup should be open and what query to show.
///
/// Rules:
/// - A trigger char (`@`, `/`, `#`) opens the popup when typed at the start
///   of the text or immediately after whitespace / start-of-line.
/// - `/` only triggers at offset 0 (slash-commands are top-of-message).
/// - The query ends at the caret. Whitespace inside the query closes it.
/// - Returns `null` when no popup should be shown.
MentionQuery? detectMentionQuery(String text, int caret) {
  if (caret < 0 || caret > text.length) {
    return null;
  }

  // Scan backwards from caret to find a trigger char with the right prefix.
  for (var i = caret - 1; i >= 0; i--) {
    final ch = text[i];
    if (ch == ' ' || ch == '\n' || ch == '\t') {
      return null;
    }
    final trigger = MentionTrigger.fromChar(ch);
    if (trigger == null) {
      continue;
    }

    final precededByBoundary = i == 0 ||
        text[i - 1] == ' ' ||
        text[i - 1] == '\n' ||
        text[i - 1] == '\t';
    if (!precededByBoundary) {
      return null;
    }

    if (trigger == MentionTrigger.slash && i != 0) {
      return null;
    }

    final partial = text.substring(i + 1, caret);
    // Bail if the partial contains whitespace (closed by typing a space).
    if (partial.contains(' ') ||
        partial.contains('\n') ||
        partial.contains('\t')) {
      return null;
    }
    return MentionQuery(
      trigger: trigger,
      partial: partial,
      start: i,
      end: caret,
    );
  }
  return null;
}
