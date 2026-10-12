/// Ingestion-time observation shaping: compact, task-useful model-visible text
/// plus a recoverable reference to the original.
///
/// **The contract with the loop.** One call per tool result, at the point where
/// the loop today calls `truncateToolOutput` for the model copy. The raw result
/// keeps flowing to the UI event unchanged, so machine consumers (a `bash`
/// pipeline's stdout, the transcript pane, logs) are never handed a model-shaped
/// summary — the failure class the Claude Code cost study documents, where a
/// "friendly" search summary was substituted for raw grep output.
///
/// **Order of operations.** Store first, then compact. Compaction needs the
/// handle to put in its marker; and if the original cannot be stored, the
/// compacted text must say so instead of pointing at a handle that does not
/// exist.
///
/// **What is never compacted.** Error results and small results. An error's
/// exact text is what the next turn reasons about (a failed edit's anchors, a
/// failed write's reason), and rewriting it to save tokens trades a certain
/// correctness loss for an uncertain token win. Errors are only cut when they
/// exceed the tool's own hard ceiling, and then their head stays verbatim and
/// the rest is recoverable.
library;

import 'dart:math';

import 'package:cc_harness/src/context/token_estimator.dart';
import 'package:cc_harness/src/context/tool_output_reference.dart';
import 'package:cc_harness/src/context/tool_output_store.dart';
import 'package:cc_harness/src/context/tool_output_truncation.dart';
import 'package:cc_harness/src/tools/tool.dart';

/// The estimated-token floor at which an observation that FITS inline is still
/// stored, so a later masking pass can replace it with a recoverable handle.
///
/// Shared with ContextPolicies' `maskMinObservationTokens` on purpose: the two
/// thresholds are one policy seen from two sides. Set retention above the
/// masking floor and the compactor can meet an observation it cannot store
/// (`stored ⇒ maskable` breaks); set it below and the store fills with text the
/// compactor will never touch. Equal values give the useful invariant
/// **stored ⇔ maskable** for non-error observations, evaluated with the same
/// [TokenEstimator] (3.8 chars/token), so "200" means one thing in both places.
const int kToolOutputRetentionMinTokens = 200;

/// A tool observation after ingestion: what the model sees, and how (or
/// whether) the original can be retrieved.
class ToolObservation {
  /// Creates a [ToolObservation].
  const ToolObservation({
    required this.content,
    this.reference,
    this.truncated = false,
    this.storageFailure,
  });

  /// The bounded text to place in the `tool_result` block.
  final String content;

  /// The durable handle for the original, or `null` when the original is not
  /// retrievable. Attach this to `HarnessToolResultBlock.outputReference` so a
  /// compactor can later mask this observation recoverably and so nothing ever
  /// claims recoverability it does not have.
  ///
  /// It is non-null in two situations, and [truncated] tells them apart:
  /// * [truncated] `true` — the text was cut and this handle is how the model
  ///   gets the rest back.
  /// * [truncated] `false` — the text is intact and inline, and the handle
  ///   exists so a later masking pass may replace it (see
  ///   [kToolOutputRetentionMinTokens]).
  final ToolOutputReference? reference;

  /// Whether [content] is a compaction of a longer original (a marker was
  /// inserted and/or useful ranges were selected instead of the whole text).
  ///
  /// `false` with a non-null [reference] means the observation still fits and
  /// its text is byte-identical to the tool's output.
  final bool truncated;

  /// The exact original length in chars, when the original was stored (`null`
  /// otherwise) — for accounting that wants to know what was dropped or is
  /// masked out without re-reading the reference metadata.
  int? get rawCharLength => reference?.charLength;

  /// Why the original could not be stored, when compaction made that matter.
  ///
  /// Set only when [content] is a COMPACTION and storage was attempted and
  /// failed (or there was no scope/store): that is the case where text is
  /// genuinely unrecoverable. A result that merely missed the retention floor,
  /// or whose retention write failed, reports nothing here — its text is
  /// intact, so there is no loss to warn about. The parent surfaces this as a
  /// host diagnostic; it must never be turned into a handle.
  final String? storageFailure;

  /// Whether the original observation is retrievable through a handle.
  bool get recoverable => reference != null;
}

/// Ingests tool results: compacts over-long observations and stores originals.
///
/// Stateless apart from its configuration, so the loop can hold one instance
/// per run and every call is independent.
class ToolObservationIngest {
  /// Creates an ingest.
  ///
  /// [_store] is optional: without one, compaction still happens but the text
  /// says the original was not stored, and [ToolObservation.reference] stays
  /// null. That is the shipped behaviour when a host wired no store, and it is
  /// deliberately not a "no-op store" — a nullable port keeps the
  /// not-stored path visible instead of burying it behind a fake success.
  ///
  /// [_retainMinTokens] is the estimated-token floor at which a result that fits
  /// inline is stored anyway (see [kToolOutputRetentionMinTokens]). `<= 0` turns
  /// retention off and stores only observations that had to be cut.
  ToolObservationIngest({
    this._store,
    this._limits = ToolOutputLimitTable.defaults,
    this._formatter = const ToolObservationFormatter(),
    this._retainMinTokens = kToolOutputRetentionMinTokens,
    this._estimator = TokenEstimator.instance,
  });

  final ToolOutputStore? _store;
  final ToolOutputLimitTable _limits;
  final ToolObservationFormatter _formatter;
  final int _retainMinTokens;
  final TokenEstimator _estimator;

  /// Ingests one tool result.
  ///
  /// [context] supplies the workspace/conversation/agent scope — never the
  /// model's arguments, which are untrusted input and must not be able to
  /// choose whose observation store a handle lands in.
  Future<ToolObservation> ingest({
    required String toolName,
    Map<String, dynamic> args = const {},
    required HarnessToolResult result,
    required HarnessToolContext context,
    String? toolUseId,
  }) async {
    final content = result.content;
    final limits = _limits.forTool(toolName);
    final fit = truncateToolOutput(content, limits);
    if (!fit.truncated) {
      // It fits inline, so nothing is dropped and the text is passed through
      // untouched. Big-enough non-error observations are still persisted: they
      // are the ones a masking pass wants to replace later, and a mask is only
      // allowed when the original is retrievable.
      if (result.isError ||
          content.isEmpty ||
          _retainMinTokens <= 0 ||
          _estimator.estimate(content) < _retainMinTokens) {
        return ToolObservation(content: content);
      }
      final persisted = await _persist(
        toolName: toolName,
        result: result,
        context: context,
        toolUseId: toolUseId,
      );
      return ToolObservation(content: content, reference: persisted.reference);
    }

    final persisted = await _persist(
      toolName: toolName,
      result: result,
      context: context,
      toolUseId: toolUseId,
    );

    final text = _formatter.formatObservation(
      toolName: toolName,
      args: args,
      result: result,
      limits: limits,
      reference: persisted.reference,
    );
    return ToolObservation(
      content: text,
      // The inline preview is the part of the original still shown verbatim at
      // the point of the reference; a masking pass keeps exactly that much head.
      reference: persisted.reference?.copyWith(
        previewChars: _commonPrefixLength(content, text),
      ),
      truncated: true,
      storageFailure: persisted.failure,
    );
  }

  Future<({ToolOutputReference? reference, String? failure})> _persist({
    required String toolName,
    required HarnessToolResult result,
    required HarnessToolContext context,
    required String? toolUseId,
  }) async {
    final store = _store;
    if (store == null) {
      return (
        reference: null,
        failure: 'no tool-output store is wired for this run',
      );
    }
    final scope = buildToolOutputScope(context);
    if (scope == null) {
      // No boundary means no checkable handle. Refusing here is what keeps a
      // handle from being readable by a run it does not belong to.
      return (
        reference: null,
        failure: 'run has no workspace scope, so the original was not stored',
      );
    }
    try {
      final reference = await store.put(
        ToolOutputWrite(
          scope: scope,
          toolName: toolName,
          content: result.content,
          isError: result.isError,
          toolUseId: toolUseId,
        ),
      );
      if (reference == null) {
        return (
          reference: null,
          failure:
              'tool-output store declined the write '
              '(output too large for the store, or the write failed)',
        );
      }
      return (reference: reference, failure: null);
    } on Object catch (e) {
      // Storage must never fail a run: the observation is still delivered,
      // compacted, with an explicit "not stored" note.
      return (reference: null, failure: 'tool-output store failed: $e');
    }
  }

  static int _commonPrefixLength(String a, String b) {
    final max = a.length < b.length ? a.length : b.length;
    var i = 0;
    while (i < max && a.codeUnitAt(i) == b.codeUnitAt(i)) {
      i++;
    }
    return i;
  }
}

/// Renders a bounded, task-useful observation for the model.
///
/// Each tool family gets the shape its consumer actually needs — search keeps
/// exact `line: text` matches grouped by file, command output keeps its exit
/// status and diagnostics instead of a blind head/tail of build noise, file
/// reads keep the numbered head with an exact resume offset. Everything else
/// keeps the existing head/tail policy.
class ToolObservationFormatter {
  /// Creates a formatter.
  const ToolObservationFormatter({
    this.maxDiagnostics = 40,
    this.maxSearchFiles = 25,
    this.maxMatchesPerFile = 8,
    this.maxDiagnosticScanLines = 20000,
  });

  /// How many diagnostic lines a compacted command output keeps.
  final int maxDiagnostics;

  /// How many files a compacted search result lists.
  final int maxSearchFiles;

  /// How many matches per file a compacted search result lists.
  final int maxMatchesPerFile;

  /// How many leading lines a diagnostics scan reads before giving up (a
  /// pathological stream must not turn compaction into a full parse).
  final int maxDiagnosticScanLines;

  /// Formats [result] for the model, naming [reference] when the original was
  /// stored.
  String formatObservation({
    required String toolName,
    Map<String, dynamic> args = const {},
    required HarnessToolResult result,
    required ToolOutputLimits limits,
    ToolOutputReference? reference,
  }) {
    final content = result.content;
    if (content.isEmpty) {
      return content;
    }
    if (result.isError) {
      // Exact error text, head-preserved: the beginning of an error is the
      // message; the rest is recoverable when (rarely) it is enormous.
      return _headSlice(content, limits, reference);
    }
    final normalized = normalizeToolName(toolName);
    switch (normalized) {
      case 'search':
      case 'grep':
        final grouped = _searchObservation(content, limits, reference);
        if (grouped != null) {
          return grouped;
        }
        return _genericObservation(content, limits, reference);
      case 'bash':
      case 'shell':
        return _commandObservation(content, limits, reference);
      case 'read':
        return _headSlice(content, limits, reference);
      default:
        return _genericObservation(content, limits, reference);
    }
  }

  /// Keeps the head verbatim up to the binding cap, then a marker naming the
  /// exact resume offset (a prefix, so the offset is exact).
  ///
  /// The char cap binds most of the time; when it does not — an observation
  /// with many short lines trips the line cap first — the cut moves to lines so
  /// a line-capped input is not "compacted" into a marker claiming zero
  /// characters were dropped.
  String _headSlice(
    String content,
    ToolOutputLimits limits,
    ToolOutputReference? reference,
  ) {
    final budget = _charBudget(limits, content.length);
    if (content.length > budget) {
      final kept = content.substring(0, budget);
      final marker = omittedOutputMarker(
        reference,
        omittedChars: content.length - kept.length,
        resumeOffsetChars: kept.length,
      );
      return '$kept\n$marker';
    }
    final lineLimit = limits.lineLimit;
    if (lineLimit <= 0) {
      return content;
    }
    final lines = content.split('\n');
    if (lines.length <= lineLimit) {
      return content;
    }
    final kept = lines.take(lineLimit).join('\n');
    final marker = omittedOutputMarker(
      reference,
      omittedChars: content.length - kept.length,
      resumeOffsetChars: kept.length,
    );
    return '$kept\n$marker';
  }

  /// Search results as `file (n matches)` groups with exact line numbers.
  ///
  /// Returns `null` when the content does not look like `path:line:text`
  /// matches, so the caller falls back to the generic slice rather than eating
  /// a different tool's output.
  String? _searchObservation(
    String content,
    ToolOutputLimits limits,
    ToolOutputReference? reference,
  ) {
    final parsed = parseSearchMatches(content);
    if (parsed.matches.length < 2) {
      return null;
    }
    final budget = _charBudget(limits, content.length);
    final buffer = StringBuffer();
    var used = 0;
    var keptOriginal = 0;
    var listedMatches = 0;
    var listedFiles = 0;
    final keptPerFile = <String, int>{};
    var omittedMatches = 0;
    String? currentPath;

    for (final match in parsed.matches) {
      final keptForFile = keptPerFile[match.path] ?? 0;
      if (keptForFile >= maxMatchesPerFile ||
          (keptForFile == 0 && keptPerFile.length >= maxSearchFiles)) {
        omittedMatches++;
        continue;
      }
      final startsNewFile = match.path != currentPath;
      final header = startsNewFile ? '${match.path}\n' : '';
      final separator = startsNewFile && buffer.isNotEmpty ? '\n' : '';
      final line = '  ${match.line}: ${match.text}\n';
      final added = header.length + separator.length + line.length;
      if (used + added > budget) {
        omittedMatches++;
        continue;
      }
      buffer
        ..write(separator)
        ..write(header)
        ..write(line);
      currentPath = match.path;
      keptPerFile[match.path] = keptForFile + 1;
      listedFiles = keptPerFile.length;
      used += added;
      listedMatches++;
      // Synthetic headers do not count as retained original output.
      keptOriginal += match.path.length + 1 + '${match.line}'.length + 1;
      keptOriginal += match.text.length + 1;
    }

    final omitted = parsed.matches.length - listedMatches;
    if (omitted <= 0) {
      return null;
    }
    buffer.write(
      '\n[${parsed.matches.length} matches in '
      '${parsed.fileCount} files; showing $listedMatches in $listedFiles files',
    );
    if (omittedMatches > 0) {
      buffer.write(
        '; $omittedMatches matches hidden by the per-file and '
        'per-result caps (narrow the pattern or pass a `glob`)',
      );
    }
    buffer
      ..write(']\n')
      ..write(
        omittedOutputMarker(
          reference,
          omittedChars: content.length - keptOriginal,
          // Grouping is not a prefix of the original, so the honest resume
          // offset is the start of the file.
          resumeOffsetChars: 0,
        ),
      );
    return buffer.toString();
  }

  /// Command output: exit status first, then the diagnostics that matter.
  String _commandObservation(
    String content,
    ToolOutputLimits limits,
    ToolOutputReference? reference,
  ) {
    final budget = _charBudget(limits, content.length);
    final firstBreak = content.indexOf('\n');
    final statusLine = firstBreak == -1
        ? content
        : content.substring(0, firstBreak);
    if (!_exitStatusPattern.hasMatch(statusLine)) {
      // Not CC's `bash` shape (a bridged shell tool, or an odd result): the
      // generic slice is the honest fallback.
      return _genericObservation(content, limits, reference);
    }
    final body = firstBreak == -1 ? '' : content.substring(firstBreak + 1);
    final diagnostics = _collectDiagnostics(body);
    if (diagnostics.isEmpty) {
      // Nothing in the output names a failure, so nothing is known to be more
      // useful than the rest: keep the tool's configured head/tail policy
      // rather than guessing that the beginning is what matters.
      return _genericObservation(content, limits, reference);
    }

    // Chars of the original actually reproduced, for an honest omission count
    // (the compaction header is synthetic and is not counted).
    var keptOriginal = statusLine.length + 1;
    final buffer = StringBuffer()..writeln(statusLine);
    var used = keptOriginal;
    final header =
        '[compacted ${_lineCount(body)} output lines; '
        '${diagnostics.length} diagnostic '
        '${diagnostics.length == 1 ? 'line' : 'lines'}]';
    if (used + header.length + 1 <= budget) {
      buffer.writeln(header);
      used += header.length + 1;
    }
    for (final diagnostic in diagnostics) {
      if (used + diagnostic.length + 1 > budget) {
        break;
      }
      buffer.writeln(diagnostic);
      used += diagnostic.length + 1;
      keptOriginal += diagnostic.length + 1;
    }
    buffer.write(
      omittedOutputMarker(
        reference,
        omittedChars: content.length - keptOriginal,
        // Diagnostics are excerpts from all over the output, not a prefix, so
        // the only honest resume point is the start.
        resumeOffsetChars: 0,
      ),
    );
    return buffer.toString().trimRight();
  }

  /// Every line that names a failure, error, or exception, in order.
  ///
  /// Deliberately pattern-based rather than a parser: test runners, compilers
  /// and package managers all disagree on format, but they agree that a
  /// failure line says so. Bounded by [maxDiagnostics] so one pathological log
  /// cannot re-fill the window it was compacted out of.
  List<String> _collectDiagnostics(String body) {
    final kept = <String>[];
    var scanned = 0;
    for (final line in body.split('\n')) {
      if (++scanned > maxDiagnosticScanLines || kept.length >= maxDiagnostics) {
        break;
      }
      if (line.isEmpty) {
        continue;
      }
      if (_diagnosticPattern.hasMatch(line)) {
        kept.add(line.length > 500 ? '${line.substring(0, 500)}…' : line);
      }
    }
    return kept;
  }

  /// Head/tail over lines (the pre-existing terminal-output policy), with an
  /// exact resume offset instead of a bare omission count.
  String _genericObservation(
    String content,
    ToolOutputLimits limits,
    ToolOutputReference? reference,
  ) {
    final charLimit = limits.characterLimit > 0
        ? limits.characterLimit
        : content.length;
    if (content.length > charLimit) {
      final budget = _charBudget(limits, content.length);
      switch (limits.direction) {
        case TruncateDirection.head:
          return _headSlice(content, limits, reference);
        case TruncateDirection.tail:
          final kept = content.substring(content.length - budget);
          return '${omittedOutputMarker(reference, omittedChars: content.length - kept.length, resumeOffsetChars: 0)}\n'
              '$kept';
        case TruncateDirection.headAndTail:
          final head = max(1, (budget * limits.headRatio).floor());
          final tail = max(0, budget - head);
          final keptHead = content.substring(0, head);
          final keptTail = content.substring(content.length - tail);
          return '$keptHead\n'
              '${omittedOutputMarker(reference, omittedChars: content.length - head - tail, resumeOffsetChars: head)}\n'
              '$keptTail';
      }
    }

    final lineLimit = limits.lineLimit;
    if (lineLimit <= 0) {
      return _headSlice(content, limits, reference);
    }
    final lines = content.split('\n');
    final int headCount;
    final int tailCount;
    switch (limits.direction) {
      case TruncateDirection.head:
        headCount = lineLimit;
        tailCount = 0;
      case TruncateDirection.tail:
        headCount = 0;
        tailCount = lineLimit;
      case TruncateDirection.headAndTail:
        headCount = max(1, (lineLimit * limits.headRatio).floor());
        tailCount = max(0, lineLimit - headCount);
    }
    final keptHead = lines.take(headCount).join('\n');
    final keptTail = tailCount == 0
        ? ''
        : lines.skip(lines.length - tailCount).join('\n');
    final keptChars =
        keptHead.length + (keptTail.isEmpty ? 0 : keptTail.length);
    final marker = omittedOutputMarker(
      reference,
      omittedChars: content.length - keptChars,
      resumeOffsetChars: headCount == 0 ? 0 : keptHead.length,
    );
    return keptTail.isEmpty
        ? '$keptHead\n$marker'
        : '$keptHead\n$marker\n$keptTail';
  }

  /// The char ceiling for a compacted observation, leaving room for the marker.
  ///
  /// A disabled (`<= 0`) char cap, or one that does not bind, returns the whole
  /// content length — callers then fall through to their line-aware branch
  /// instead of cutting at an artificial boundary.
  static int _charBudget(ToolOutputLimits limits, int contentLength) {
    final limit = limits.characterLimit;
    if (limit <= 0 || limit >= contentLength) {
      return contentLength;
    }
    // The marker itself is text the model pays for; keep it inside the budget.
    final budget = limit - 200;
    return budget < 1 ? 1 : budget;
  }

  static int _lineCount(String body) =>
      body.isEmpty ? 0 : '\n'.allMatches(body).length + 1;
}

/// One `path:line: text` match inside a search observation.
class SearchMatchLine {
  /// Creates a [SearchMatchLine].
  const SearchMatchLine({
    required this.path,
    required this.line,
    required this.text,
    required this.occurrencesInFile,
  });

  /// The file the match is in (as printed by the tool).
  final String path;

  /// The 1-based line number.
  final int line;

  /// The matched line's text, exactly as the tool printed it.
  final String text;

  /// How many matches this file has in total (so the producer can apply the
  /// per-file cap without a second pass).
  final int occurrencesInFile;
}

/// The parsed shape of a search observation.
class ParsedSearchOutput {
  /// Creates a [ParsedSearchOutput].
  const ParsedSearchOutput({required this.matches, required this.fileCount});

  /// Matches in printed order.
  final List<SearchMatchLine> matches;

  /// Distinct files represented.
  final int fileCount;
}

/// Parses `path:line:text` match lines out of a search observation.
///
/// Anything else (the `(N total matches; …)` trailer, `No matches for …`) is
/// ignored: those lines are kept by the caller when it re-renders, and a line
/// that happens to contain a colon must not be mistaken for a match.
ParsedSearchOutput parseSearchMatches(String content) {
  final raw = <({String path, int line, String text})>[];
  for (final line in content.split('\n')) {
    final match = _matchLinePattern.firstMatch(line);
    if (match == null) {
      continue;
    }
    final path = match.group(1)!;
    // A path may contain a space, a line of prose containing "word:12:" may
    // not — a doubled space or a leading/trailing space in the "path" is the
    // tell, and treating prose as a match would make the grouped rendering
    // actively misleading rather than merely unhelpful.
    if (path.trim() != path || path.contains('  ')) {
      continue;
    }
    final number = int.tryParse(match.group(2)!);
    if (number == null) {
      continue;
    }
    raw.add((path: path, line: number, text: match.group(3)!));
  }
  // The per-file count is only known once the whole file is scanned, so it is
  // filled in a second pass; the cap then applies to the file, not to whatever
  // prefix happened to be listed first.
  final totals = <String, int>{};
  for (final match in raw) {
    totals[match.path] = (totals[match.path] ?? 0) + 1;
  }
  return ParsedSearchOutput(
    matches: [
      for (final match in raw)
        SearchMatchLine(
          path: match.path,
          line: match.line,
          text: match.text,
          occurrencesInFile: totals[match.path]!,
        ),
    ],
    fileCount: totals.length,
  );
}

final RegExp _matchLinePattern = RegExp(r'^(.+?):(\d+):(.*)$');
final RegExp _exitStatusPattern = RegExp(r'^exit code -?\d+');
final RegExp _diagnosticPattern = RegExp(
  r'(^|[^A-Za-z])(error|Error|ERROR|failed|Failed|FAILED|Failure|failures?|'
  r'panic|Exception|Traceback|AssertionError|not ok|✗|×|FAIL)\b',
);
