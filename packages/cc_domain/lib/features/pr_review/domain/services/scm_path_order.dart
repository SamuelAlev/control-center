// The order VS Code's Source Control view lists changed files in: the list
// view's default "sort by path" (`scm.defaultViewSortKey: path`), which hands
// each resource's path to `comparePaths` from `vs/base/common/comparers.ts`.
//
// That comparer walks the path one segment at a time. Directory segments
// compare case-insensitively by code unit; the final segment (the file name)
// goes through `Intl.Collator(undefined, {numeric: true, sensitivity: 'base'})`.
// A file sorts before any subdirectory at the same depth, so `src/a.ts` comes
// before `src/lib/b.ts`. The git extension mixes untracked files into the
// Changes group (`git.untrackedChanges: mixed`), so they sort with the rest
// rather than trailing at the end.
//
// Dart has no ICU collator, so [compareScmFileNames] approximates the root
// collation at base strength: punctuation and symbols first (in CLDR root
// order for ASCII), then digit runs by numeric value, then letters ignoring
// case.

/// Compares two repo-relative paths the way VS Code's Source Control list
/// orders them. Use as a `List.sort` comparator.
int compareScmPaths(String a, String b) {
  final aParts = a.split('/');
  final bParts = b.split('/');
  final aLast = aParts.length - 1;
  final bLast = bParts.length - 1;
  for (var i = 0; ; i++) {
    final aEnd = i == aLast;
    final bEnd = i == bLast;
    if (aEnd && bEnd) {
      return compareScmFileNames(aParts[i], bParts[i]);
    }
    if (aEnd) {
      return -1;
    }
    if (bEnd) {
      return 1;
    }
    final dir = aParts[i].toLowerCase().compareTo(bParts[i].toLowerCase());
    if (dir != 0) {
      return dir;
    }
  }
}

/// Compares two file names like VS Code's `compareFileNames`: a numeric,
/// case-insensitive collation, with names it considers equal split by length
/// and then by code unit so the order is total.
int compareScmFileNames(String a, String b) {
  final collated = _collate(a, b);
  if (collated != 0) {
    return collated;
  }
  if (a.length != b.length) {
    return a.length < b.length ? -1 : 1;
  }
  return a.compareTo(b);
}

int _collate(String a, String b) {
  var i = 0;
  var j = 0;
  while (i < a.length && j < b.length) {
    final ca = a.codeUnitAt(i);
    final cb = b.codeUnitAt(j);
    if (_isDigit(ca) && _isDigit(cb)) {
      final aEnd = _digitRunEnd(a, i);
      final bEnd = _digitRunEnd(b, j);
      final byValue = _compareDigitRuns(a, i, aEnd, b, j, bEnd);
      if (byValue != 0) {
        return byValue;
      }
      i = aEnd;
      j = bEnd;
      continue;
    }
    final byClass = _charClass(ca).compareTo(_charClass(cb));
    if (byClass != 0) {
      return byClass;
    }
    final byWeight = _charWeight(ca).compareTo(_charWeight(cb));
    if (byWeight != 0) {
      return byWeight;
    }
    i++;
    j++;
  }
  final aRest = a.length - i;
  final bRest = b.length - j;
  return aRest == bRest ? 0 : (aRest < bRest ? -1 : 1);
}

/// ASCII punctuation and symbols in CLDR root collation order. Everything not
/// listed here (non-ASCII symbols) falls back to its code unit after these.
const String _symbolOrder = '\t\n\v\f\r _-,;:!?.\'"()[]{}@*/\\&#%`^+<=>|~\$';

const int _classSymbol = 0;
const int _classDigit = 1;
const int _classLetter = 2;

int _charClass(int c) {
  if (_isDigit(c)) {
    return _classDigit;
  }
  if (_symbolOrder.contains(String.fromCharCode(c))) {
    return _classSymbol;
  }
  // Remaining ASCII control characters sort with the symbols; anything else
  // (letters, including non-ASCII ones) sorts as a letter.
  return c < 0x80 && !_isAsciiLetter(c) ? _classSymbol : _classLetter;
}

int _charWeight(int c) {
  final symbol = _symbolOrder.indexOf(String.fromCharCode(c));
  if (symbol >= 0) {
    return symbol;
  }
  if (_isAsciiLetter(c)) {
    return c | 0x20;
  }
  final lower = String.fromCharCode(c).toLowerCase();
  return 0x10000 + (lower.length == 1 ? lower.codeUnitAt(0) : c);
}

bool _isDigit(int c) => c >= 0x30 && c <= 0x39;

bool _isAsciiLetter(int c) => (c | 0x20) >= 0x61 && (c | 0x20) <= 0x7a;

int _digitRunEnd(String s, int start) {
  var end = start;
  while (end < s.length && _isDigit(s.codeUnitAt(end))) {
    end++;
  }
  return end;
}

/// Compares two digit runs by numeric value without parsing (runs can exceed
/// any integer width). Leading zeros are not significant, as at base strength.
int _compareDigitRuns(
  String a,
  int aStart,
  int aEnd,
  String b,
  int bStart,
  int bEnd,
) {
  while (aStart < aEnd - 1 && a.codeUnitAt(aStart) == 0x30) {
    aStart++;
  }
  while (bStart < bEnd - 1 && b.codeUnitAt(bStart) == 0x30) {
    bStart++;
  }
  final aLen = aEnd - aStart;
  final bLen = bEnd - bStart;
  if (aLen != bLen) {
    return aLen < bLen ? -1 : 1;
  }
  for (var k = 0; k < aLen; k++) {
    final d = a.codeUnitAt(aStart + k) - b.codeUnitAt(bStart + k);
    if (d != 0) {
      return d < 0 ? -1 : 1;
    }
  }
  return 0;
}
