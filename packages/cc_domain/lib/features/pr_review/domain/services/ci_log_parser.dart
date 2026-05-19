// CI logs → structured failure signals: the join between a red check and the
// diff that turned it red.
//
// "3 checks failed" makes a reviewer go and read three logs. "lib/auth.dart:88
// — AuthService refreshes on 401" puts the failure on the line that caused it,
// which is the only form a reviewer can act on without leaving the page. This
// file is the parsing half of that: logs in (already fetched and tail-truncated
// by the caller), typed signals out.
//
// Best-effort by construction, with a deliberately asymmetric contract: every
// recognizer here is a heuristic over an unstable, vendor-specific text format,
// so a miss costs a reviewer nothing (the panel shows what was found) while a
// false positive points at an innocent file and burns the panel's credibility.
// When in doubt this parser reports NOTHING. An empty result means "found
// nothing" — callers distinguish that from "unavailable" on their own, and can
// only keep doing so if we never pad the result to look useful.
//
// Pure: string matching over an in-memory log. No I/O, no natives.

/// One stack/source frame extracted from a CI log.
class CiFrame {
  /// Creates a frame naming [filePath], optionally at [line].
  const CiFrame({required this.filePath, this.line, this.evidence = ''});

  /// The path exactly as the log spelled it.
  ///
  /// Deliberately un-normalized: a log says `package:my_pkg/src/foo.dart` or
  /// `/runner/work/repo/lib/src/foo.dart` and both are true statements about a
  /// machine we do not have. Turning either into a repo-relative path requires
  /// the changed-file list, so that happens in
  /// [CiLogParser.correlate] and not here.
  final String filePath;

  /// 1-based line number, or null when the log named a file without one.
  final int? line;

  /// The failing test name (or error line) this frame appeared under.
  ///
  /// Provenance, not identity: two frames at the same location are the same
  /// frame whatever narrated them, so this is excluded from equality and the
  /// first-seen evidence survives de-duplication.
  final String evidence;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CiFrame && other.filePath == filePath && other.line == line;

  @override
  int get hashCode => Object.hash(filePath, line);

  @override
  String toString() => 'CiFrame($filePath${line == null ? '' : ':$line'})';
}

/// What one parse pass found in one job's logs.
class CiSignals {
  /// Creates a signal set. All three lists default to empty, which is the
  /// honest result for a log this parser did not recognize.
  const CiSignals({
    this.failingTests = const [],
    this.errorLines = const [],
    this.frames = const [],
  });

  /// A signal set that found nothing.
  static const CiSignals empty = CiSignals();

  /// Names of the tests the log reported as failing, first-seen order.
  final List<String> failingTests;

  /// Error lines, trimmed as they appeared (minus CI transport markup),
  /// first-seen order.
  final List<String> errorLines;

  /// Source locations named by the log, first-seen order.
  final List<CiFrame> frames;

  /// Whether nothing at all was recognized.
  bool get isEmpty =>
      failingTests.isEmpty && errorLines.isEmpty && frames.isEmpty;
}

/// A frame matched onto one of the PR's changed files.
class CiCorrelation {
  /// Creates a correlation pointing at [filePath].
  const CiCorrelation({required this.filePath, this.line, this.evidence = ''});

  /// The CHANGED file's path, repo-relative and spelled the way the caller
  /// spelled it — never the raw log path, which is only a means of getting
  /// here.
  final String filePath;

  /// 1-based line number in the changed file, when the frame carried one.
  final int? line;

  /// The failing test name or error line that produced this match, so the UI
  /// can say WHY a file is implicated instead of merely that it is.
  final String evidence;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CiCorrelation &&
          other.filePath == filePath &&
          other.line == line &&
          other.evidence == evidence;

  @override
  int get hashCode => Object.hash(filePath, line, evidence);

  @override
  String toString() =>
      'CiCorrelation($filePath${line == null ? '' : ':$line'})';
}

/// Parses already-fetched CI job logs into failure signals and maps those
/// signals onto a PR's changed files.
class CiLogParser {
  /// Creates a [CiLogParser].
  const CiLogParser();

  /// Maximum number of entries kept in each list of a [CiSignals].
  ///
  /// A stuck retry loop can emit the same traceback thousands of times and the
  /// result of a parse is serialized to every connected client, so the payload
  /// is bounded here rather than at the render site.
  static const int maxEntries = 50;

  /// Parses [logs] into the failing tests, error lines and source frames it
  /// names.
  ///
  /// Recognizes Dart/Flutter `package:test`, jest/vitest, pytest and a generic
  /// prefix fallback (`Error:`, `ERROR`, `FAILED`, `##[error]`, …). ANSI colour
  /// and GitHub Actions' per-line timestamp prefix are stripped first, because
  /// CI logs are coloured and timestamped and neither is content.
  ///
  /// Never throws. Unrecognized input — empty, binary, a single line — yields
  /// empty lists.
  CiSignals parse(String logs) {
    if (logs.isEmpty) {
      return CiSignals.empty;
    }

    // Set literals are insertion-ordered, which gives first-seen-order
    // de-duplication for free; Set.add keeps the incumbent, which is what
    // preserves a frame's earliest evidence.
    final failingTests = <String>{};
    final errorLines = <String>{};
    final frames = <CiFrame>{};

    String? lastFailingTest;
    String? lastErrorLine;

    try {
      // Split on any line terminator: the Dart test reporter redraws its
      // progress line with a bare \r, so splitting on \n alone would hand every
      // update to the recognizers as one giant line.
      for (final raw in logs.split(_lineBreak)) {
        if (failingTests.length >= maxEntries &&
            errorLines.length >= maxEntries &&
            frames.length >= maxEntries) {
          break;
        }

        final line = _clean(raw);
        if (line.isEmpty) {
          continue;
        }
        final trimmed = line.trim();

        final failing = _failingTest(trimmed);
        if (failing != null) {
          lastFailingTest = failing;
          _addCapped(failingTests, failing);
        } else {
          final error = _errorLine(trimmed);
          if (error != null) {
            lastErrorLine = error;
            _addCapped(errorLines, error);
          }
        }

        if (frames.length >= maxEntries) {
          continue;
        }
        // Evidence prefers a failing test over an error line even when the
        // error line is nearer: a test name identifies the failure, while
        // `E   AssertionError` merely describes it.
        final evidence = lastFailingTest ?? lastErrorLine ?? '';
        for (final frame in _frames(line, evidence)) {
          if (frames.length >= maxEntries) {
            break;
          }
          frames.add(frame);
        }
      }
    } on Object catch (_) {
      // A parser fed arbitrary bytes from arbitrary CI vendors must degrade to
      // "found less" rather than take down the caller's request. Whatever was
      // recognized before the surprise is still true.
    }

    if (failingTests.isEmpty && errorLines.isEmpty && frames.isEmpty) {
      return CiSignals.empty;
    }
    return CiSignals(
      failingTests: List<String>.unmodifiable(failingTests),
      errorLines: List<String>.unmodifiable(errorLines),
      frames: List<CiFrame>.unmodifiable(frames),
    );
  }

  /// Maps [signals]' frames onto [changedFiles] by path suffix.
  ///
  /// A log path (`package:my_pkg/src/foo.dart`, `/runner/work/repo/lib/foo.dart`)
  /// and a PR path (`lib/src/foo.dart`) share a tail and nothing else, so
  /// matching compares path SEGMENTS from the end. A single shared segment (the
  /// basename) is accepted only when the frame itself names no directory and
  /// exactly one changed file carries that basename — `foo.dart` matching one of
  /// three `foo.dart`s is a coin flip, and a coin flip that blames a file is
  /// worse than no answer.
  ///
  /// Returns an empty list when there is nothing to match against.
  List<CiCorrelation> correlate(CiSignals signals, List<String> changedFiles) {
    if (changedFiles.isEmpty || signals.frames.isEmpty) {
      return const [];
    }

    final candidates = <_ChangedPath>[];
    final basenameCounts = <String, int>{};
    for (final path in changedFiles) {
      final segments = _segments(path);
      if (segments.isEmpty) {
        continue;
      }
      candidates.add(_ChangedPath(path, segments));
      final basename = segments.last;
      basenameCounts[basename] = (basenameCounts[basename] ?? 0) + 1;
    }
    if (candidates.isEmpty) {
      return const [];
    }

    final result = <CiCorrelation>[];
    final seen = <String>{};
    for (final frame in signals.frames) {
      final segments = _segments(frame.filePath);
      if (segments.isEmpty) {
        continue;
      }
      final match = segments.length == 1
          ? _matchByBasename(segments.single, candidates, basenameCounts)
          : _matchBySuffix(segments, candidates);
      if (match == null) {
        continue;
      }
      final key = '${match.original} ${frame.line}';
      if (!seen.add(key)) {
        continue;
      }
      result.add(
        CiCorrelation(
          filePath: match.original,
          line: frame.line,
          evidence: frame.evidence,
        ),
      );
    }
    return result;
  }

  /// The single changed file named [basename], or null when zero or several
  /// carry it (ambiguous, and this frame offers nothing to disambiguate with).
  _ChangedPath? _matchByBasename(
    String basename,
    List<_ChangedPath> candidates,
    Map<String, int> basenameCounts,
  ) {
    if (basenameCounts[basename] != 1) {
      return null;
    }
    for (final candidate in candidates) {
      if (candidate.segments.last == basename) {
        return candidate;
      }
    }
    return null;
  }

  /// The changed file sharing the longest segment suffix with [segments].
  ///
  /// Ties are dropped, not broken: two changed files ending in the same
  /// `src/foo.dart` are indistinguishable from a frame that only says
  /// `src/foo.dart`. A candidate whose whole path is consumed by the match
  /// beats one that is merely as long, because a changed path is repo-relative
  /// and a complete match of it is the stronger claim.
  _ChangedPath? _matchBySuffix(
    List<String> segments,
    List<_ChangedPath> candidates,
  ) {
    _ChangedPath? best;
    var bestScore = 0;
    var bestComplete = false;
    var tied = false;
    for (final candidate in candidates) {
      final score = _commonSuffixLength(segments, candidate.segments);
      if (score < 2) {
        continue;
      }
      final complete = score == candidate.segments.length;
      if (best == null ||
          score > bestScore ||
          (score == bestScore && complete && !bestComplete)) {
        best = candidate;
        bestScore = score;
        bestComplete = complete;
        tied = false;
      } else if (score == bestScore && complete == bestComplete) {
        tied = true;
      }
    }
    return tied ? null : best;
  }

  /// The failing-test name [trimmed] announces, or null when it announces none.
  ///
  /// The first recognizer to claim a line owns it: `FAILED tests/x.py::y` is a
  /// test name, and also counting it as a generic error line would report one
  /// failure twice under two headings.
  String? _failingTest(String trimmed) {
    final dart = _dartTestFailure.firstMatch(trimmed);
    if (dart != null) {
      final name = dart.group(1)?.trim();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }
    final pytest = _pytestFailed.firstMatch(trimmed);
    if (pytest != null) {
      return pytest.group(1);
    }
    final jestCross = _jestFailedTest.firstMatch(trimmed);
    if (jestCross != null) {
      final name = jestCross.group(1)?.trim();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }
    final jestBullet = _jestBullet.firstMatch(trimmed);
    if (jestBullet != null) {
      final name = jestBullet.group(1)?.trim();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }
    final jestSuite = _jestFailSuite.firstMatch(trimmed);
    if (jestSuite != null) {
      // Kept prefixed: `FAIL src/foo.test.ts` reads as a failure in a list,
      // where a bare path reads as a file someone opened.
      return 'FAIL ${jestSuite.group(1)}';
    }
    return null;
  }

  /// The error text [trimmed] carries, or null when it carries none.
  String? _errorLine(String trimmed) {
    final actions = _actionsError.firstMatch(trimmed);
    if (actions != null) {
      // `##[error]` is GitHub Actions' transport markup, not the vendor's
      // message; keeping it would put the same failure under two spellings
      // depending on which runner produced the log.
      final rest = trimmed.substring(actions.end).trim();
      return rest.isEmpty ? trimmed : rest;
    }
    if (_dartSuiteFailed.hasMatch(trimmed)) {
      // Reported canonically: the compact reporter prefixes this verdict with a
      // live counter (`00:03 +12 -1: Some tests failed.`), so the raw line
      // differs between two runs that said the same thing.
      return 'Some tests failed.';
    }
    if (_pytestErrorLine.hasMatch(trimmed)) {
      return trimmed;
    }
    for (final prefix in _errorPrefixes) {
      if (trimmed.startsWith(prefix)) {
        return trimmed;
      }
    }
    return null;
  }

  /// Every source location [line] names, in the order they appear on it.
  List<CiFrame> _frames(String line, String evidence) {
    final found = <CiFrame>[];
    for (final match in _fileUriFrame.allMatches(line)) {
      found.add(
        CiFrame(
          filePath: match.group(1)!,
          line: int.tryParse(match.group(2)!),
          evidence: evidence,
        ),
      );
    }
    for (final match in _dartFrame.allMatches(line)) {
      found.add(
        CiFrame(
          filePath: match.group(1)!,
          line: int.tryParse(match.group(2)!),
          evidence: evidence,
        ),
      );
    }
    for (final match in _jsFrame.allMatches(line)) {
      found.add(
        CiFrame(
          filePath: match.group(1)!,
          line: int.tryParse(match.group(2)!),
          evidence: evidence,
        ),
      );
    }
    for (final match in _pyTracebackFrame.allMatches(line)) {
      found.add(
        CiFrame(
          filePath: match.group(1)!,
          line: int.tryParse(match.group(2)!),
          evidence: evidence,
        ),
      );
    }
    final pyLocation = _pyLocationFrame.firstMatch(line.trimLeft());
    if (pyLocation != null) {
      found.add(
        CiFrame(
          filePath: pyLocation.group(1)!,
          line: int.tryParse(pyLocation.group(2)!),
          evidence: evidence,
        ),
      );
    }
    return found;
  }

  /// Strips what CI wraps around a line but is not part of it.
  String _clean(String raw) {
    var line = raw;
    if (line.endsWith('\r')) {
      line = line.substring(0, line.length - 1);
    }
    if (line.contains('\x1B')) {
      line = line.replaceAll(_ansi, '');
    }
    return line.replaceFirst(_actionsTimestamp, '');
  }

  /// Adds [value] to [target] unless the cap has been reached.
  void _addCapped(Set<String> target, String value) {
    if (target.length < maxEntries) {
      target.add(value);
    }
  }

  /// How many trailing segments [a] and [b] share.
  int _commonSuffixLength(List<String> a, List<String> b) {
    var shared = 0;
    while (shared < a.length &&
        shared < b.length &&
        a[a.length - 1 - shared] == b[b.length - 1 - shared]) {
      shared++;
    }
    return shared;
  }

  /// Splits a path into comparable segments.
  ///
  /// `package:` is dropped rather than rewritten to `lib/`: the mapping holds
  /// for a plain package and not for one with a custom layout, and suffix
  /// matching does not need the guess to be right.
  List<String> _segments(String path) {
    var normalized = path.replaceAll(r'\', '/');
    if (normalized.startsWith('file://')) {
      normalized = normalized.substring('file://'.length);
    }
    normalized = normalized.replaceFirst(_packagePrefix, '');
    return [
      for (final segment in normalized.split('/'))
        if (segment.isNotEmpty && segment != '.') segment,
    ];
  }
}

/// A changed file pre-split into segments, so correlate does the split once
/// instead of once per frame.
class _ChangedPath {
  const _ChangedPath(this.original, this.segments);

  final String original;
  final List<String> segments;
}

final RegExp _lineBreak = RegExp(r'\r\n|\r|\n');

/// CSI escape sequences — colour, cursor moves, line erases.
final RegExp _ansi = RegExp(r'\x1B\[[0-9;?]*[ -/]*[@-~]');

/// `2026-08-20T12:34:56.7890123Z ` — GitHub Actions stamps every raw log line.
final RegExp _actionsTimestamp = RegExp(
  r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z ?',
);

final RegExp _actionsError = RegExp(r'^##\[error\]');

/// `00:03 +12 -1: path/to/foo_test.dart: some test name [E]`
final RegExp _dartTestFailure = RegExp(
  r'^\d+:\d{2}\s+[+\-~\d\s]+:\s*(.+?)\s*\[E\]$',
);

/// `Some tests failed.`, bare or behind the compact reporter's counter.
final RegExp _dartSuiteFailed = RegExp(
  r'^(?:\d+:\d{2}\s+[+\-~\d\s]+:\s*)?Some tests failed\.?$',
);

/// `package:my_pkg/src/foo.dart 12:5` / `test/foo_test.dart 9:11`. The leading
/// boundary keeps `dart:async/zone.dart 1234:5` out — an SDK frame is never a
/// changed file and would only spend cap budget.
final RegExp _dartFrame = RegExp(
  r'(?:^|\s)((?:package:)?[A-Za-z0-9_./\-]+\.dart)\s+(\d+):(\d+)',
);

/// `file:///abs/path/foo.dart:12:5`
final RegExp _fileUriFrame = RegExp(r'file://([^\s:)\]]+):(\d+):(\d+)');

/// `✕ some test name (5 ms)` — the timing suffix is dropped so a retried test
/// de-duplicates instead of appearing once per attempt.
final RegExp _jestFailedTest = RegExp(
  r'^[✕×]\s+(.+?)(?:\s+\(\d+(?:\.\d+)?\s*m?s\))?$',
);

/// `● Some suite › test name`
final RegExp _jestBullet = RegExp(r'^●\s+(.+)$');

/// `FAIL src/foo.test.ts`
final RegExp _jestFailSuite = RegExp(r'^FAIL\s+(\S+)');

/// `at Object.<anonymous> (src/foo.ts:3:1)` and `at src/foo.ts:3:1`
final RegExp _jsFrame = RegExp(
  r'(?:^|\s)at\s+(?:[^()]*\()?([^()\s]+):(\d+):(\d+)\)?',
);

/// `FAILED tests/test_foo.py::test_bar - AssertionError: ...`. The `::` is what
/// separates a pytest test id from a bare `FAILED something`, which is only an
/// error line.
final RegExp _pytestFailed = RegExp(r'^FAILED\s+(\S+::\S+)');

/// `E   AssertionError`
final RegExp _pytestErrorLine = RegExp(r'^E\s{2,}\S');

/// `  File "app/foo.py", line 12, in bar`
final RegExp _pyTracebackFrame = RegExp(r'File\s+"([^"]+)",\s+line\s+(\d+)');

/// `app/foo.py:12: AssertionError`
final RegExp _pyLocationFrame = RegExp(r'^([A-Za-z0-9_./\-]+\.py):(\d+):');

final RegExp _packagePrefix = RegExp(r'^package:[^/]+/');

const List<String> _errorPrefixes = [
  'Error:',
  'error:',
  'ERROR',
  'FAILED',
  '✗',
];
