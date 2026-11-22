import 'package:cc_domain/features/code_mode/domain/entities/script_outline.dart';

// The first stage of the outline parser: the work budget every stage spends
// from, the tokens and the tree of matched brackets.

/// The work a parse has spent, against its budget. Every stage spends from
/// one counter; spending past [limit] gives up the whole parse.
final class OutlineWork {
  /// Creates a counter with [limit] units to spend.
  OutlineWork(this.limit);

  /// The budget.
  final int limit;

  /// The units spent so far.
  int used = 0;

  /// Spends [units]; throws [OutlineBail] past the budget.
  void spend(int units) {
    used += units;
    if (used > limit) {
      throw const OutlineBail(ScriptOutlineFailure.tooComplex);
    }
  }
}

/// Gives up a parse: the outline is [failure], never a partial tree.
final class OutlineBail implements Exception {
  /// Creates the bail-out.
  const OutlineBail(this.failure);

  /// Why the parse gave up.
  final ScriptOutlineFailure failure;
}

/// Token kinds. A group (matched brackets) is an item of kind [group].
abstract final class OutlineKind {
  /// An identifier or keyword.
  static const int ident = 0;

  /// A numeric literal.
  static const int number = 1;

  /// A string literal.
  static const int string = 2;

  /// A template with no substitution.
  static const int templateFull = 3;

  /// A template up to its first `${`.
  static const int templateHead = 4;

  /// A template part between two substitutions.
  static const int templateMiddle = 5;

  /// A template from its last `}` on.
  static const int templateTail = 6;

  /// A regular expression literal.
  static const int regex = 7;

  /// A punctuator.
  static const int punct = 8;

  /// An opening bracket.
  static const int open = 9;

  /// A closing bracket.
  static const int close = 10;

  /// Matched brackets and the items between them.
  static const int group = 11;
}

/// The opening characters of groups.
abstract final class OutlineChar {
  /// `(`.
  static const int paren = 0x28;

  /// `[`.
  static const int bracket = 0x5B;

  /// `{`.
  static const int brace = 0x7B;

  /// A backtick: a template with substitutions.
  static const int backtick = 0x60;
}

/// A token, or a group of items between matched brackets.
final class OutlineItem {
  /// A token of [kind].
  OutlineItem.token(this.kind, this.start, this.end, this.nl, this.text)
    : open = 0,
      children = const [],
      openEnd = end,
      closeStart = end;

  /// A group opened by [open]; its end is set when it closes.
  OutlineItem.group(this.open, this.start, this.openEnd, this.nl)
    : kind = OutlineKind.group,
      end = openEnd,
      closeStart = openEnd,
      text = null,
      children = [];

  final int kind;
  final int start;
  int end;
  // Whether a line ended between the previous token and this one.
  final bool nl;
  // The text of an identifier or punctuator; null otherwise.
  final String? text;
  // For a group: the opening character, `(`, `[`, `{` or a backtick.
  final int open;
  final List<OutlineItem> children;
  int openEnd;
  int closeStart;

  bool get isGroup => kind == OutlineKind.group;

  bool isIdent(String name) => kind == OutlineKind.ident && text == name;

  bool isPunct(String op) => kind == OutlineKind.punct && text == op;

  bool isGroupOf(int char) => kind == OutlineKind.group && open == char;
}

const Set<String> _regexAfterWords = {
  'return',
  'typeof',
  'instanceof',
  'in',
  'of',
  'new',
  'delete',
  'void',
  'throw',
  'case',
  'do',
  'else',
  'yield',
  'await',
  'extends',
};

const List<String> _multiPuncts = [
  '>>>=',
  '...',
  '===',
  '!==',
  '**=',
  '<<=',
  '>>=',
  '>>>',
  '&&=',
  '||=',
  '??=',
  '=>',
  '==',
  '!=',
  '<=',
  '>=',
  '&&',
  '||',
  '??',
  '?.',
  '++',
  '--',
  '+=',
  '-=',
  '*=',
  '/=',
  '%=',
  '&=',
  '|=',
  '^=',
  '**',
  '<<',
  '>>',
];

/// Whether [c] ends a line.
bool isOutlineLineTerminator(int c) =>
    c == 0x0A || c == 0x0D || c == 0x2028 || c == 0x2029;

/// Whether [c] is white space other than a line end.
bool isOutlineSpace(int c) =>
    c == 0x20 ||
    c == 0x09 ||
    c == 0x0B ||
    c == 0x0C ||
    c == 0xA0 ||
    c == 0xFEFF ||
    c == 0x1680 ||
    (c >= 0x2000 && c <= 0x200A) ||
    c == 0x202F ||
    c == 0x205F ||
    c == 0x3000;

bool _isDigit(int c) => c >= 0x30 && c <= 0x39;

bool _isIdentStart(int c) =>
    (c >= 0x61 && c <= 0x7A) ||
    (c >= 0x41 && c <= 0x5A) ||
    c == 0x24 ||
    c == 0x5F ||
    c == 0x23 ||
    c == 0x5C ||
    (c >= 0x80 && !isOutlineSpace(c) && !isOutlineLineTerminator(c));

bool _isIdentPart(int c) => _isIdentStart(c) || _isDigit(c);

/// Splits a script into tokens in one pass.
final class OutlineLexer {
  /// Creates a lexer for [src] spending from [work].
  OutlineLexer(this.src, OutlineWork work) : _work = work;

  /// The script.
  final String src;
  final OutlineWork _work;

  /// The tokens, once [run].
  final List<OutlineItem> tokens = [];

  // A regular expression scan that failed reached this offset (its line's
  // end): a `/` before it cannot start one either, so it is division
  // without scanning the line again.
  int _noRegexBefore = -1;

  // One entry per open `{`: true when it is a template's `${`.
  final List<bool> _braces = [];

  // One entry per open `(`: true when a `/` right after its `)` starts a
  // regular expression (`if (…) /re/`).
  final List<bool> _parens = [];

  bool _regexOk = true;
  bool _nl = false;

  void _add(int kind, int start, int end, {String? text}) {
    tokens.add(OutlineItem.token(kind, start, end, _nl, text));
    _nl = false;
  }

  /// Splits [src] into [tokens].
  void run() {
    final n = src.length;
    var i = 0;
    while (i < n) {
      _work.spend(1);
      final c = src.codeUnitAt(i);
      if (isOutlineSpace(c)) {
        i++;
        continue;
      }
      if (isOutlineLineTerminator(c)) {
        _nl = true;
        i++;
        continue;
      }
      if (c == 0x2F) {
        final d = i + 1 < n ? src.codeUnitAt(i + 1) : 0;
        if (d == 0x2F) {
          final from = i;
          i += 2;
          while (i < n && !isOutlineLineTerminator(src.codeUnitAt(i))) {
            i++;
          }
          _work.spend(i - from);
          continue;
        }
        if (d == 0x2A) {
          final close = src.indexOf('*/', i + 2);
          if (close < 0) {
            throw const OutlineBail(ScriptOutlineFailure.unterminated);
          }
          _work.spend(close - i);
          for (var j = i + 2; j < close; j++) {
            if (isOutlineLineTerminator(src.codeUnitAt(j))) {
              _nl = true;
              break;
            }
          }
          i = close + 2;
          continue;
        }
        if (_regexOk && i >= _noRegexBefore) {
          final end = _scanRegex(i);
          if (end > 0) {
            _add(OutlineKind.regex, i, end);
            _regexOk = false;
            i = end;
            continue;
          }
        }
      }
      if (c == 0x22 || c == 0x27) {
        final end = _scanString(i, c);
        _add(OutlineKind.string, i, end);
        _regexOk = false;
        i = end;
        continue;
      }
      if (c == OutlineChar.backtick) {
        final (end, head) = _scanTemplate(i + 1);
        if (head) {
          _add(OutlineKind.templateHead, i, end);
          _braces.add(true);
          _regexOk = true;
        } else {
          _add(OutlineKind.templateFull, i, end);
          _regexOk = false;
        }
        i = end;
        continue;
      }
      if (c == 0x7D && _braces.isNotEmpty && _braces.last) {
        _braces.removeLast();
        final (end, head) = _scanTemplate(i + 1);
        if (head) {
          _add(OutlineKind.templateMiddle, i, end);
          _braces.add(true);
          _regexOk = true;
        } else {
          _add(OutlineKind.templateTail, i, end);
          _regexOk = false;
        }
        i = end;
        continue;
      }
      if (_isIdentStart(c)) {
        var j = i + 1;
        while (j < n && _isIdentPart(src.codeUnitAt(j))) {
          j++;
        }
        _work.spend(j - i);
        final word = src.substring(i, j);
        _add(OutlineKind.ident, i, j, text: word);
        _regexOk = _regexAfterWords.contains(word);
        i = j;
        continue;
      }
      if (_isDigit(c) ||
          (c == 0x2E && i + 1 < n && _isDigit(src.codeUnitAt(i + 1)))) {
        final end = _scanNumber(i);
        _work.spend(end - i);
        _add(OutlineKind.number, i, end);
        _regexOk = false;
        i = end;
        continue;
      }
      switch (c) {
        case OutlineChar.paren:
          final previous = tokens.isEmpty ? null : tokens.last;
          _parens.add(
            previous != null &&
                previous.kind == OutlineKind.ident &&
                (previous.text == 'if' ||
                    previous.text == 'while' ||
                    previous.text == 'for' ||
                    previous.text == 'with'),
          );
          _add(OutlineKind.open, i, i + 1, text: '(');
          _regexOk = true;
        case 0x29:
          _add(OutlineKind.close, i, i + 1, text: ')');
          _regexOk = _parens.isNotEmpty && _parens.removeLast();
        case OutlineChar.bracket:
          _add(OutlineKind.open, i, i + 1, text: '[');
          _regexOk = true;
        case 0x5D:
          _add(OutlineKind.close, i, i + 1, text: ']');
          _regexOk = false;
        case OutlineChar.brace:
          _braces.add(false);
          _add(OutlineKind.open, i, i + 1, text: '{');
          _regexOk = true;
        case 0x7D:
          if (_braces.isNotEmpty) {
            _braces.removeLast();
          }
          _add(OutlineKind.close, i, i + 1, text: '}');
          _regexOk = true;
        default:
          final op = _punctAt(i);
          _add(OutlineKind.punct, i, i + op.length, text: op);
          _regexOk = op != '++' && op != '--';
          i += op.length;
          continue;
      }
      i++;
    }
  }

  String _punctAt(int i) {
    if (i + 1 < src.length) {
      for (final op in _multiPuncts) {
        if (src.startsWith(op, i)) {
          // `a?.5:b` is a conditional, not optional chaining.
          if (op == '?.' &&
              i + 2 < src.length &&
              _isDigit(src.codeUnitAt(i + 2))) {
            continue;
          }
          return op;
        }
      }
    }
    return src[i];
  }

  /// The end of the string literal opened by [quote] at [start].
  int _scanString(int start, int quote) {
    final n = src.length;
    var j = start + 1;
    while (j < n) {
      final c = src.codeUnitAt(j);
      if (c == quote) {
        _work.spend(j - start);
        return j + 1;
      }
      if (c == 0x5C) {
        j +=
            j + 2 < n &&
                src.codeUnitAt(j + 1) == 0x0D &&
                src.codeUnitAt(j + 2) == 0x0A
            ? 3
            : 2;
        continue;
      }
      if (c == 0x0A || c == 0x0D) {
        break;
      }
      j++;
    }
    throw const OutlineBail(ScriptOutlineFailure.unterminated);
  }

  /// Scans template text from [start] to its closing backtick or to the
  /// next `${`. Returns the end and whether it stopped at `${`.
  (int, bool) _scanTemplate(int start) {
    final n = src.length;
    var j = start;
    while (j < n) {
      final c = src.codeUnitAt(j);
      if (c == 0x5C) {
        j += 2;
        continue;
      }
      if (c == OutlineChar.backtick) {
        _work.spend(j - start);
        return (j + 1, false);
      }
      if (c == 0x24 &&
          j + 1 < n &&
          src.codeUnitAt(j + 1) == OutlineChar.brace) {
        _work.spend(j - start);
        return (j + 2, true);
      }
      j++;
    }
    throw const OutlineBail(ScriptOutlineFailure.unterminated);
  }

  /// The end of the regular expression literal at [start], or -1 when the
  /// line ends first: the `/` is then read as division, so a misjudged
  /// slash cannot fail a script, and so is any `/` before that line end.
  int _scanRegex(int start) {
    final n = src.length;
    var j = start + 1;
    var inClass = false;
    while (j < n) {
      final c = src.codeUnitAt(j);
      if (isOutlineLineTerminator(c)) {
        _work.spend(j - start);
        _noRegexBefore = j;
        return -1;
      }
      if (c == 0x5C) {
        j += 2;
        continue;
      }
      if (c == OutlineChar.bracket) {
        inClass = true;
      } else if (c == 0x5D) {
        inClass = false;
      } else if (c == 0x2F && !inClass) {
        j++;
        while (j < n && _isIdentPart(src.codeUnitAt(j))) {
          j++;
        }
        _work.spend(j - start);
        return j;
      }
      j++;
    }
    _work.spend(j - start);
    _noRegexBefore = n;
    return -1;
  }

  int _scanNumber(int start) {
    final n = src.length;
    var j = start;
    while (j < n) {
      final c = src.codeUnitAt(j);
      if (_isIdentPart(c) || c == 0x2E) {
        j++;
        // An exponent's sign: `1e-5`.
        if ((c == 0x65 || c == 0x45) &&
            j < n &&
            (src.codeUnitAt(j) == 0x2B || src.codeUnitAt(j) == 0x2D) &&
            !src.startsWith('0x', start) &&
            !src.startsWith('0X', start)) {
          j++;
        }
        continue;
      }
      break;
    }
    return j;
  }
}

/// Matches brackets into groups. Throws [OutlineBail] for brackets that do not
/// match or nest deeper than [maxDepth].
List<OutlineItem> buildOutlineTree(
  List<OutlineItem> tokens, {
  required int maxDepth,
}) {
  final root = <OutlineItem>[];
  final stack = <OutlineItem>[];
  var current = root;
  for (final token in tokens) {
    switch (token.kind) {
      case OutlineKind.open || OutlineKind.templateHead:
        if (stack.length >= maxDepth) {
          throw const OutlineBail(ScriptOutlineFailure.tooDeep);
        }
        final group = OutlineItem.group(
          token.kind == OutlineKind.templateHead
              ? OutlineChar.backtick
              : token.text!.codeUnitAt(0),
          token.start,
          token.end,
          token.nl,
        );
        current.add(group);
        stack.add(group);
        current = group.children;
      case OutlineKind.close || OutlineKind.templateTail:
        if (stack.isEmpty) {
          throw const OutlineBail(ScriptOutlineFailure.unbalanced);
        }
        final group = stack.removeLast();
        final expected = switch (group.open) {
          OutlineChar.paren => ')',
          OutlineChar.bracket => ']',
          OutlineChar.brace => '}',
          _ => null,
        };
        final matches = token.kind == OutlineKind.templateTail
            ? group.open == OutlineChar.backtick
            : token.text == expected;
        if (!matches) {
          throw const OutlineBail(ScriptOutlineFailure.unbalanced);
        }
        group
          ..closeStart = token.start
          ..end = token.end;
        current = stack.isEmpty ? root : stack.last.children;
      case OutlineKind.templateMiddle:
        if (stack.isEmpty || stack.last.open != OutlineChar.backtick) {
          throw const OutlineBail(ScriptOutlineFailure.unbalanced);
        }
        current.add(token);
      default:
        current.add(token);
    }
  }
  if (stack.isNotEmpty) {
    throw const OutlineBail(ScriptOutlineFailure.unbalanced);
  }
  return root;
}
