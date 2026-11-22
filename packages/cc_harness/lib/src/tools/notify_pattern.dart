/// The pattern language of `notify` on a background command, and its matcher.
///
/// Dart's regular expressions backtrack without a bound, and matching runs on
/// the server's isolate, so a `notify` pattern is not a regular expression
/// handed to `RegExp`. It is a small allow-listed grammar whose matcher is
/// linear by construction:
///
/// ```text
/// pattern := ["(?i)"] branch ("|" branch)*
/// branch  := ["^"] item* ["$"]
/// item    := atom [quantifier]      -- at most one quantifier per branch
/// atom    := literal | escape | "[" class "]" | "."
/// quantifier := "*" | "+" | "?" | "{n}" | "{n,}" | "{n,m}"
/// ```
///
/// A branch with one quantifier is a fixed prefix, one repeated atom and a
/// fixed suffix, so whether it matches a line of n characters is decided in
/// O(n × pattern length): no step depends on an earlier choice.
library;

/// A parsed `notify` pattern ([NotifyPattern.parse]).
final class NotifyPattern {
  NotifyPattern._(this._branches, {required this.ignoreCase});

  /// The prefix that makes the whole pattern ignore case.
  static const String ignoreCasePrefix = '(?i)';

  /// The largest repeat count `{n,m}` accepts.
  static const int maxCount = 1000;

  /// The most atoms outside a quantifier over all branches (a count at a
  /// branch's edge counts its repeats).
  static const int maxFixedChars = 200;

  /// What the language accepts, for a refusal.
  static const String grammar =
      'notify takes a simple pattern, not a full regular expression: literal '
      'text, character classes ([a-z], [^0-9], \\d, \\w, \\s and their '
      'capitals), ".", "^" at the start and "\$" at the end of a branch, '
      'branches joined with "|", "(?i)" at the very start to ignore case, and '
      'at most one "*", "+", "?" or "{n,m}" per branch, right after a single '
      'character, class or "." (one on a branch\'s first or last item is '
      'free). Groups, backreferences and lookarounds are '
      'not accepted. Examples: error|FAILED, listening on .*:\\d+, '
      '^\\[ready\\].';

  final List<_Branch> _branches;

  /// Whether case is ignored (`(?i)`).
  final bool ignoreCase;

  /// Parses [source]; returns the pattern, or the reason it is refused.
  static ({NotifyPattern? pattern, String? refusal}) parse(String source) {
    try {
      final p = _Parser(source).parse();
      return (pattern: p, refusal: null);
    } on _Refused catch (e) {
      return (pattern: null, refusal: '${e.message} $grammar');
    }
  }

  /// Whether some part of [line] matches.
  bool hasMatch(String line) {
    final text = ignoreCase ? line.toLowerCase() : line;
    for (final b in _branches) {
      if (b.matches(text)) {
        return true;
      }
    }
    return false;
  }
}

final class _Refused implements Exception {
  _Refused(this.message);
  final String message;
}

/// One position of a branch: a set of code units.
abstract final class _Atom {
  bool accepts(int unit);
}

final class _Literal extends _Atom {
  _Literal(this.unit);
  final int unit;
  @override
  bool accepts(int unit) => unit == this.unit;
}

final class _Any extends _Atom {
  @override
  bool accepts(int unit) =>
      unit != 0x0A && unit != 0x0D && unit != 0x2028 && unit != 0x2029;
}

final class _Class extends _Atom {
  _Class(this.ranges, {required this.negated});

  /// Inclusive (lo, hi) code unit ranges.
  final List<(int, int)> ranges;
  final bool negated;

  @override
  bool accepts(int unit) {
    var inside = false;
    for (final (lo, hi) in ranges) {
      if (unit >= lo && unit <= hi) {
        inside = true;
        break;
      }
    }
    return inside != negated;
  }
}

final class _Branch {
  _Branch({
    required this.prefix,
    required this.repeated,
    required this.min,
    required this.max,
    required this.suffix,
    required this.atStart,
    required this.atEnd,
  });

  final List<_Atom> prefix;

  /// The one quantified atom, or null for a fixed-length branch.
  final _Atom? repeated;
  final int min;

  /// Null for no upper bound.
  final int? max;
  final List<_Atom> suffix;
  final bool atStart;
  final bool atEnd;

  static bool _run(List<_Atom> atoms, String text, int at) {
    if (at < 0 || at + atoms.length > text.length) {
      return false;
    }
    for (var i = 0; i < atoms.length; i++) {
      if (!atoms[i].accepts(text.codeUnitAt(at + i))) {
        return false;
      }
    }
    return true;
  }

  bool matches(String text) {
    final n = text.length;
    final q = repeated;
    if (q == null) {
      final len = prefix.length;
      if (atStart || atEnd) {
        final at = atStart ? 0 : n - len;
        return (!atStart || !atEnd || len == n) && _run(prefix, text, at);
      }
      for (var i = 0; i + len <= n; i++) {
        if (_run(prefix, text, i)) {
          return true;
        }
      }
      return false;
    }
    final p = prefix.length;
    final s = suffix.length;
    if (p + min + s > n) {
      return false;
    }
    // ends[k]: how many k' <= k where the prefix ends at k'.
    final ends = List<int>.filled(n + 2, 0);
    for (var k = 0; k <= n; k++) {
      final here = k >= p && (!atStart || k == p) && _run(prefix, text, k - p);
      ends[k + 1] = ends[k] + (here ? 1 : 0);
    }
    // run: how many characters right before j the repeated atom accepts.
    var run = 0;
    for (var j = 0; j <= n - s; j++) {
      if (j > 0) {
        run = q.accepts(text.codeUnitAt(j - 1)) ? run + 1 : 0;
      }
      if (atEnd && j != n - s) {
        continue;
      }
      final hi = j - min;
      if (hi < p) {
        continue;
      }
      final span = max == null ? run : (run < max! ? run : max!);
      var lo = j - span;
      if (lo < p) {
        lo = p;
      }
      if (lo > hi) {
        continue;
      }
      if (ends[hi + 1] - ends[lo] > 0 && _run(suffix, text, j)) {
        return true;
      }
    }
    return false;
  }
}

final class _Parser {
  _Parser(this.source);

  final String source;
  int _at = 0;
  bool _ignoreCase = false;

  /// Atoms outside a quantifier, over every branch.
  int _fixed = 0;

  NotifyPattern parse() {
    if (source.startsWith(NotifyPattern.ignoreCasePrefix)) {
      _ignoreCase = true;
      _at = NotifyPattern.ignoreCasePrefix.length;
    }
    final branches = <_Branch>[];
    while (true) {
      branches.add(_branch());
      if (_at >= source.length) {
        break;
      }
      _at++; // '|'
    }
    return NotifyPattern._(branches, ignoreCase: _ignoreCase);
  }

  _Branch _branch() {
    final atStart = _peek('^');
    if (atStart) {
      _at++;
    }
    final items = <(_Atom, (int, int?)?)>[];
    var atEnd = false;
    while (_at < source.length && source[_at] != '|') {
      if (source[_at] == r'$') {
        _at++;
        if (_at < source.length && source[_at] != '|') {
          throw _Refused('"\$" may only end a branch.');
        }
        atEnd = true;
        break;
      }
      items.add((_atom(), _quantifier()));
    }
    // A search finds a match anywhere in the line, so a quantifier on the
    // first item of a branch without "^", or on the last of one without
    // "\$", matches as its fewest repeats would: `\s*error` is `error`,
    // `port \d+` is `port \d`.
    if (!atStart && items.isNotEmpty) {
      if (items.first case (final atom, (final lo, _)?)) {
        items
          ..removeAt(0)
          ..insertAll(0, List.filled(lo, (atom, null)));
      }
    }
    if (!atEnd && items.isNotEmpty) {
      if (items.last case (final atom, (final lo, _)?)) {
        items
          ..removeLast()
          ..addAll(List.filled(lo, (atom, null)));
      }
    }
    final prefix = <_Atom>[];
    final suffix = <_Atom>[];
    _Atom? repeated;
    var min = 0;
    int? max = 0;
    for (final (atom, bounds) in items) {
      if (bounds == null) {
        (repeated == null ? prefix : suffix).add(atom);
        continue;
      }
      if (repeated != null) {
        throw _Refused('A branch may hold only one quantifier.');
      }
      repeated = atom;
      (min, max) = bounds;
    }
    _fixed += prefix.length + suffix.length;
    if (_fixed > NotifyPattern.maxFixedChars) {
      throw _Refused(
        'The pattern may name at most ${NotifyPattern.maxFixedChars} '
        'characters, counts included.',
      );
    }
    final canBeEmpty =
        prefix.isEmpty && suffix.isEmpty && (repeated == null || min == 0);
    if (canBeEmpty) {
      throw _Refused('A branch would match every line.');
    }
    return _Branch(
      prefix: prefix,
      repeated: repeated,
      min: min,
      max: max,
      suffix: suffix,
      atStart: atStart,
      atEnd: atEnd,
    );
  }

  bool _peek(String c) => _at < source.length && source[_at] == c;

  (int, int?)? _quantifier() {
    if (_at >= source.length) {
      return null;
    }
    switch (source[_at]) {
      case '*':
        _at++;
        return (0, null);
      case '+':
        _at++;
        return (1, null);
      case '?':
        _at++;
        return (0, 1);
      case '{':
        final m = RegExp(
          r'\{(\d{1,4})(,(\d{0,4}))?\}',
        ).matchAsPrefix(source, _at);
        if (m == null) {
          throw _Refused('"{" must start a count such as {2} or {1,3}.');
        }
        _at = m.end;
        final lo = int.parse(m.group(1)!);
        final hiText = m.group(3);
        final hi = m.group(2) == null
            ? lo
            : (hiText == null || hiText.isEmpty ? null : int.parse(hiText));
        if (lo > NotifyPattern.maxCount ||
            (hi != null && (hi > NotifyPattern.maxCount || hi < lo))) {
          throw _Refused(
            'A count must be at most ${NotifyPattern.maxCount}, low to high.',
          );
        }
        return (lo, hi);
    }
    return null;
  }

  _Atom _atom() {
    final c = source[_at];
    switch (c) {
      case '.':
        _at++;
        return _Any();
      case '[':
        return _class();
      case r'\':
        return _escapeAtom();
      case '(' || ')':
        throw _Refused('Groups are not accepted.');
      case '*' || '+' || '?' || '{':
        throw _Refused('"$c" must follow a single character, class or ".".');
      case ']' || '}':
        throw _Refused('A lone "$c" must be escaped as "\\$c".');
      case '^':
        throw _Refused('"^" may only start a branch.');
    }
    _at++;
    return _literal(c.codeUnitAt(0));
  }

  _Atom _literal(int unit) {
    if (!_ignoreCase) {
      return _Literal(unit);
    }
    final lower = String.fromCharCode(unit).toLowerCase();
    return _Literal(lower.length == 1 ? lower.codeUnitAt(0) : unit);
  }

  _Atom _escapeAtom() {
    final ranges = _escape();
    if (ranges.$2 case final literal?) {
      return _literal(literal);
    }
    return _Class(_folded(ranges.$1), negated: ranges.$3);
  }

  /// Reads one escape: (ranges, a literal code unit, negated).
  (List<(int, int)>, int?, bool) _escape() {
    _at++; // '\'
    if (_at >= source.length) {
      throw _Refused('The pattern ends with "\\".');
    }
    final c = source[_at];
    _at++;
    switch (c) {
      case 'd':
        return (_digits, null, false);
      case 'D':
        return (_digits, null, true);
      case 'w':
        return (_word, null, false);
      case 'W':
        return (_word, null, true);
      case 's':
        return (_space, null, false);
      case 'S':
        return (_space, null, true);
      case 't':
        return (const [], 0x09, false);
      case 'r':
        return (const [], 0x0D, false);
      case 'n':
        return (const [], 0x0A, false);
      case 'f':
        return (const [], 0x0C, false);
      case 'v':
        return (const [], 0x0B, false);
      case 'x':
        return (const [], _hex(2), false);
      case 'u':
        return (const [], _hex(4), false);
    }
    final unit = c.codeUnitAt(0);
    final alnum = RegExp('[A-Za-z0-9]').hasMatch(c);
    if (alnum) {
      throw _Refused(
        '"\\$c" is not accepted (no backreferences, word boundaries or '
        'other escapes beyond \\d \\w \\s \\t \\x \\u).',
      );
    }
    return (const [], unit, false);
  }

  int _hex(int digits) {
    final m = RegExp('[0-9A-Fa-f]{$digits}').matchAsPrefix(source, _at);
    if (m == null) {
      throw _Refused('A hex escape needs $digits hex digits.');
    }
    _at = m.end;
    return int.parse(m.group(0)!, radix: 16);
  }

  _Atom _class() {
    _at++; // '['
    final negated = _peek('^');
    if (negated) {
      _at++;
    }
    final ranges = <(int, int)>[];
    final negatedParts = <List<(int, int)>>[];
    var first = true;
    while (true) {
      if (_at >= source.length) {
        throw _Refused('A "[" class is not closed.');
      }
      final c = source[_at];
      if (c == ']' && !first) {
        _at++;
        break;
      }
      if (c == ']') {
        throw _Refused('A class may not be empty.');
      }
      first = false;
      int lo;
      if (c == r'\') {
        final (set, literal, neg) = _escape();
        if (literal == null) {
          if (neg) {
            negatedParts.add(set);
          } else {
            ranges.addAll(set);
          }
          continue;
        }
        lo = literal;
      } else {
        _surrogateCheck(c);
        lo = c.codeUnitAt(0);
        _at++;
      }
      if (_peek('-') && _at + 1 < source.length && source[_at + 1] != ']') {
        _at++;
        int hi;
        if (source[_at] == r'\') {
          final (_, literal, _) = _escape();
          if (literal == null) {
            throw _Refused('A range must end with a single character.');
          }
          hi = literal;
        } else {
          _surrogateCheck(source[_at]);
          hi = source.codeUnitAt(_at);
          _at++;
        }
        if (hi < lo) {
          throw _Refused('A range must run low to high.');
        }
        ranges.add((lo, hi));
      } else {
        ranges.add((lo, lo));
      }
    }
    // A negated escape inside a class ([\D]) is its complement.
    for (final part in negatedParts) {
      ranges.addAll(_complement(part));
    }
    return _Class(_folded(ranges), negated: negated);
  }

  void _surrogateCheck(String c) {
    final u = c.codeUnitAt(0);
    if (u >= 0xD800 && u <= 0xDFFF) {
      throw _Refused('A class may hold only characters of the basic plane.');
    }
  }

  /// With `(?i)` the line is lower-cased, so a class gains the lower case of
  /// every capital it holds.
  List<(int, int)> _folded(List<(int, int)> ranges) {
    if (!_ignoreCase) {
      return ranges;
    }
    final extra = <(int, int)>[];
    for (final (lo, hi) in ranges) {
      final a = lo < 0x41 ? 0x41 : lo;
      final b = hi > 0x5A ? 0x5A : hi;
      if (a <= b) {
        extra.add((a + 0x20, b + 0x20));
      }
    }
    return [...ranges, ...extra];
  }

  static List<(int, int)> _complement(List<(int, int)> set) {
    final sorted = [...set]..sort((x, y) => x.$1.compareTo(y.$1));
    final out = <(int, int)>[];
    var next = 0;
    for (final (lo, hi) in sorted) {
      if (lo > next) {
        out.add((next, lo - 1));
      }
      if (hi + 1 > next) {
        next = hi + 1;
      }
    }
    if (next <= 0xFFFF) {
      out.add((next, 0xFFFF));
    }
    return out;
  }

  static const _digits = [(0x30, 0x39)];
  static const _word = [(0x30, 0x39), (0x41, 0x5A), (0x5F, 0x5F), (0x61, 0x7A)];
  static const _space = [
    (0x09, 0x0D),
    (0x20, 0x20),
    (0xA0, 0xA0),
    (0x1680, 0x1680),
    (0x2000, 0x200A),
    (0x2028, 0x2029),
    (0x202F, 0x202F),
    (0x205F, 0x205F),
    (0x3000, 0x3000),
    (0xFEFF, 0xFEFF),
  ];
}
