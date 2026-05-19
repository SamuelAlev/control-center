/// GFM autolink extension: bare `http://` / `https://` / `www.` links in
/// plain text, with the spec's trailing-punctuation and unbalanced-paren
/// trimming rules.
library;

import 'package:cc_markdown/src/parser/delimiter_stack.dart';

/// A recognized bare autolink: the display/link text and the characters
/// consumed from the source (equal to `text.length`).
final class CcBareAutolink {
  /// Creates a [CcBareAutolink].
  const CcBareAutolink({required this.text, required this.url});

  /// The matched text (also the link label).
  final String text;

  /// The destination URL (`www.` links get an `http://` prefix).
  final String url;
}

const int _openParen = 0x28;
const int _closeParen = 0x29;
const int _semicolon = 0x3B;
const int _lt = 0x3C;

bool _isUrlEnd(int unit) => ccIsWhitespace(unit) || unit == _lt;

/// Attempts to match a bare autolink at [start] in [text]. [before] is the
/// code unit preceding the match (-1 at start of text): GFM only recognizes
/// bare links after whitespace or `*`, `_`, `~`, `(`.
CcBareAutolink? tryParseBareAutolink(String text, int start, int before) {
  if (before != -1 &&
      !ccIsWhitespace(before) &&
      before != 0x2A &&
      before != 0x5F &&
      before != 0x7E &&
      before != _openParen) {
    return null;
  }

  var isWww = false;
  int schemeEnd;
  if (text.startsWith('https://', start)) {
    schemeEnd = start + 8;
  } else if (text.startsWith('http://', start)) {
    schemeEnd = start + 7;
  } else if (text.startsWith('www.', start)) {
    isWww = true;
    schemeEnd = start + 4;
  } else {
    return null;
  }

  // A link must have something after the scheme / www. that looks like a
  // domain (at least one non-terminator, containing no whitespace).
  var end = schemeEnd;
  while (end < text.length && !_isUrlEnd(text.codeUnitAt(end))) {
    end++;
  }
  if (end == schemeEnd) {
    return null;
  }

  // Validate a minimal domain: for www. links require a dot after the prefix.
  final body = text.substring(schemeEnd, end);
  if (isWww && !body.contains('.')) {
    return null;
  }

  // GFM trailing trimming: strip trailing punctuation; balance parens; strip
  // an entity-looking `&...;` tail.
  var linkEnd = end;
  while (linkEnd > schemeEnd) {
    final unit = text.codeUnitAt(linkEnd - 1);
    if (unit == _closeParen) {
      var opens = 0;
      var closes = 0;
      for (var i = start; i < linkEnd; i++) {
        final u = text.codeUnitAt(i);
        if (u == _openParen) {
          opens++;
        } else if (u == _closeParen) {
          closes++;
        }
      }
      if (closes > opens) {
        linkEnd--;
        continue;
      }
      break;
    }
    if (unit == _semicolon) {
      // Strip `&xyz;`-shaped tails (entity reference).
      var i = linkEnd - 2;
      while (i > start && _isEntityChar(text.codeUnitAt(i))) {
        i--;
      }
      if (i > start && text.codeUnitAt(i) == 0x26 /* & */ ) {
        linkEnd = i;
        continue;
      }
      linkEnd--;
      continue;
    }
    if (_isTrailingPunctuation(unit)) {
      linkEnd--;
      continue;
    }
    break;
  }
  if (linkEnd <= schemeEnd) {
    return null;
  }

  final matched = text.substring(start, linkEnd);
  return CcBareAutolink(
    text: matched,
    url: isWww ? 'http://$matched' : matched,
  );
}

bool _isTrailingPunctuation(int unit) =>
    unit == 0x3F || // ?
    unit == 0x21 || // !
    unit == 0x2E || // .
    unit == 0x2C || // ,
    unit == 0x3A || // :
    unit == 0x2A || // *
    unit == 0x5F || // _
    unit == 0x7E || // ~
    unit == 0x27 || // '
    unit == 0x22; // "

bool _isEntityChar(int unit) =>
    (unit >= 0x30 && unit <= 0x39) ||
    (unit >= 0x41 && unit <= 0x5A) ||
    (unit >= 0x61 && unit <= 0x7A) ||
    unit == 0x23; // #
