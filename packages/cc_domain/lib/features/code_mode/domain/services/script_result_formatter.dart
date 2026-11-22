import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_outcome.dart';
import 'package:cc_harness/context.dart';

/// The text the model reads after a `repl` call.
class ScriptResult {
  /// Creates a result.
  const ScriptResult({
    required this.text,
    required this.isError,
    required this.truncated,
    required this.outputChars,
    this.images = const [],
  });

  /// The full result text.
  final String text;

  /// Whether the model reads it as an error result.
  final bool isError;

  /// Whether the output was cut to its head and tail.
  final bool truncated;

  /// The length of the untruncated output section, in UTF-16 code units.
  final int outputChars;

  /// The images that reach the model, at most
  /// [CodeModeLimits.maxImagesToModel], in output order.
  final List<ScriptImageOutput> images;
}

/// Builds the result text the model reads from a [CodeExecutionOutcome],
/// as plan section 5 "Result format" lays it out:
///
/// ```text
/// Script completed in 2.4 s · 7 tool calls (6 ok, 1 failed)
/// <output>
///
/// Script error:
/// TypeError: Cannot read properties of undefined (reading 'path')
///     at repl.js:14:22
///
/// Tool calls made before the failure (they are not undone): search (ok), …
/// ```
///
/// Only the output section counts against the token budget. The first line,
/// the error, the call list and the questions are bounded by other limits
/// and are never cut, because they are what the model needs to decide its
/// next step.
///
/// Storing the full output is the caller's job, and has to happen first: call
/// [renderOutput], [exceedsBudget], store the text in `ToolOutputStore` when
/// it does, then [format] with the reference. The reference's offsets point
/// into exactly the text [renderOutput] returned.
class ScriptResultFormatter {
  /// Creates a formatter.
  const ScriptResultFormatter({this.estimator = TokenEstimator.instance});

  /// Counts tokens for the budget.
  final TokenEstimator estimator;

  /// The most call groups the "tool calls made before" list shows.
  static const int maxListedCallGroups = 30;

  /// The full output section: output items in order, then the return value.
  ///
  /// Console `warn`, `error` and `debug` lines are prefixed with their level
  /// so the model can tell a diagnostic from a result; an image is a
  /// placeholder line, and the image itself rides beside the text.
  String renderOutput(CodeExecutionOutcome outcome) {
    final lines = <String>[];
    for (final item in outcome.output) {
      lines.add(switch (item) {
        ScriptTextOutput(:final text) => text,
        ScriptConsoleOutput(:final level, :final text) => switch (level) {
          ScriptConsoleLevel.log || ScriptConsoleLevel.info => text,
          _ => '[${level.wire}] $text',
        },
        ScriptImageOutput(:final mediaType, :final approximateBytes) =>
          '[image: $mediaType, ${_kib(approximateBytes)}]',
      });
    }
    final value = outcome.returnValue;
    if (value != null) {
      lines.add(value.text);
    }
    return lines.join('\n');
  }

  /// Whether [output] is over [budgetTokens].
  bool exceedsBudget(String output, int budgetTokens) =>
      estimator.estimate(output) > budgetTokens;

  /// The most characters of output a result of [budgetTokens] keeps whole
  /// (before any notes take their share): one more and [exceedsBudget] is
  /// true, so the output is cut to its head and tail. A script reads it as
  /// `limits().returnBudgetChars`.
  int returnBudgetChars(int budgetTokens) =>
      (budgetTokens * estimator.charsPerToken).floor();

  /// The notes of [outcome] that fit beside its output in [budgetTokens]:
  /// together they take at most half of it, dropping from the end.
  List<String> notesWithin(CodeExecutionOutcome outcome, int budgetTokens) {
    var notes = outcome.notes;
    while (notes.isNotEmpty &&
        estimator.estimate(_notesBlock(notes)) > budgetTokens ~/ 2) {
      notes = notes.sublist(0, notes.length - 1);
    }
    return notes;
  }

  /// The tokens [outcome]'s output may take in a result of [budgetTokens]:
  /// the budget less what its notes take ([notesWithin]). The output is cut
  /// to this, so a caller deciding whether to store the full output asks
  /// [exceedsBudget] with it.
  int outputBudget(CodeExecutionOutcome outcome, int budgetTokens) {
    final notes = notesWithin(outcome, budgetTokens);
    return notes.isEmpty
        ? budgetTokens
        : budgetTokens - estimator.estimate(_notesBlock(notes));
  }

  static String _notesBlock(List<String> notes) =>
      notes.map((n) => 'Note: $n').join('\n');

  /// Builds the result.
  ///
  /// [budgetTokens] is the effective `max_output_tokens`, shared by the
  /// output and the notes ([outputBudget]). [fullOutput] names where the
  /// untruncated [renderOutput] text was stored; without it a cut says the
  /// original was not kept. [ScriptResult.truncated] is true when the output
  /// or the notes were cut.
  ScriptResult format(
    CodeExecutionOutcome outcome, {
    required int budgetTokens,
    ToolOutputReference? fullOutput,
  }) {
    final notes = notesWithin(outcome, budgetTokens);
    final forOutput = outputBudget(outcome, budgetTokens);
    final sections = <String>[];
    final head = StringBuffer(firstLine(outcome));
    final detail = outcome.detail;
    if (detail != null &&
        detail.isNotEmpty &&
        outcome.status != CodeExecutionStatus.refused &&
        outcome.status != CodeExecutionStatus.completed) {
      head
        ..write('\n')
        ..write(detail);
    }

    final full = renderOutput(outcome);
    var truncated = notes.length < outcome.notes.length;
    if (full.isNotEmpty) {
      var shown = full;
      if (exceedsBudget(full, forOutput)) {
        shown = truncate(full, budgetTokens: forOutput, reference: fullOutput);
        truncated = true;
      }
      head
        ..write('\n')
        ..write(shown);
    }
    sections.add(head.toString());

    final error = outcome.error;
    if (error != null) {
      sections.add(_errorBlock(error));
    }
    if (outcome.status != CodeExecutionStatus.completed &&
        outcome.calls.isNotEmpty) {
      final when = outcome.status == CodeExecutionStatus.failed
          ? 'before the failure'
          : 'before the script stopped';
      sections.add(
        'Tool calls made $when (they are not undone): '
        '${_callList(outcome.calls)}',
      );
    }
    final hint = _hint(outcome);
    if (hint != null) {
      sections.add(hint);
    }
    if (outcome.questions.isNotEmpty) {
      sections.add(_questions(outcome.questions));
    }
    if (notes.isNotEmpty) {
      sections.add(_notesBlock(notes));
    }

    return ScriptResult(
      text: sections.join('\n\n'),
      isError: outcome.status.isError,
      truncated: truncated,
      outputChars: full.length,
      images: [
        for (final item in outcome.output)
          if (item is ScriptImageOutput) item,
      ].take(CodeModeLimits.maxImagesToModel).toList(),
    );
  }

  /// The first line: how the script ended, how long it took and its calls.
  String firstLine(CodeExecutionOutcome outcome) {
    final took = _duration(outcome.durationMs);
    final calls = _callCounts(outcome.calls);
    return switch (outcome.status) {
      // CodeExecutionOutcome refuses a running status: a script that has not
      // ended has no result to format.
      CodeExecutionStatus.running => throw StateError(
        'A running script has no result to format.',
      ),
      CodeExecutionStatus.completed => 'Script completed in $took · $calls',
      CodeExecutionStatus.failed => 'Script failed after $took · $calls',
      CodeExecutionStatus.timedOut => 'Script timed out after $took · $calls',
      CodeExecutionStatus.cancelled => 'Script cancelled after $took · $calls',
      CodeExecutionStatus.memoryExceeded =>
        'Script ran out of memory after $took · $calls',
      CodeExecutionStatus.outputExceeded =>
        'Script stopped after $took: too much output · $calls',
      CodeExecutionStatus.sandboxError =>
        'Script sandbox failed after $took · $calls',
      CodeExecutionStatus.refused =>
        'Script refused: ${outcome.detail ?? 'it was not run'}',
    };
  }

  /// Cuts [full] to its head and tail so it fits [budgetTokens], with the
  /// standard omission marker between them.
  ///
  /// Roughly 60% of the room goes to the head, where a script's summary
  /// usually starts, and the rest to the tail, where its final state and
  /// errors land. Both cuts move to a line break when one is near, so no
  /// line is split in the middle unless it is very long.
  String truncate(
    String full, {
    required int budgetTokens,
    ToolOutputReference? reference,
  }) {
    final room = returnBudgetChars(budgetTokens) - 160;
    if (room <= 0) {
      return omittedOutputMarker(
        reference,
        omittedChars: full.length,
        resumeOffsetChars: 0,
      );
    }
    var headEnd = (room * 0.6).floor();
    var tailStart = full.length - (room - headEnd);
    final headBreak = full.lastIndexOf('\n', headEnd);
    if (headBreak > 0 && headEnd - headBreak < headEnd ~/ 5) {
      headEnd = headBreak;
    }
    final tailBreak = full.indexOf('\n', tailStart);
    if (tailBreak >= 0 &&
        tailBreak - tailStart < (full.length - tailStart) ~/ 5) {
      tailStart = tailBreak + 1;
    }
    headEnd = _safeCut(full, headEnd);
    tailStart = _safeCut(full, tailStart);
    final marker = omittedOutputMarker(
      reference,
      omittedChars: tailStart - headEnd,
      resumeOffsetChars: headEnd,
    );
    return '${full.substring(0, headEnd)}\n$marker\n${full.substring(tailStart)}';
  }

  String _errorBlock(ScriptError error) {
    final b = StringBuffer('Script error:\n')
      ..write(
        error.message.isEmpty ? error.name : '${error.name}: ${error.message}',
      );
    final stack = error.stack;
    if (stack != null && stack.trim().isNotEmpty) {
      b
        ..write('\n')
        ..write(stack.trimRight());
    } else if (error.line != null) {
      b
        ..write('\n    at repl.js:')
        ..write(error.line)
        ..write(error.column == null ? '' : ':${error.column}');
    }
    return b.toString();
  }

  /// `search (ok), edit (ok) ×3, bash (failed)`: consecutive repeats are
  /// grouped, and a very long list keeps its start and end.
  String _callList(List<ScriptCallSummary> calls) {
    final groups = <(String, int)>[];
    for (final call in calls) {
      final label = '${call.name} (${call.status.label})';
      if (groups.isNotEmpty && groups.last.$1 == label) {
        groups[groups.length - 1] = (label, groups.last.$2 + 1);
      } else {
        groups.add((label, 1));
      }
    }
    String show((String, int) g) => g.$2 == 1 ? g.$1 : '${g.$1} ×${g.$2}';
    if (groups.length <= maxListedCallGroups) {
      return groups.map(show).join(', ');
    }
    const headCount = 20;
    const tailCount = maxListedCallGroups - headCount - 1;
    final skipped = groups
        .sublist(headCount, groups.length - tailCount)
        .fold<int>(0, (sum, g) => sum + g.$2);
    return [
      ...groups.take(headCount).map(show),
      '… $skipped more …',
      ...groups.skip(groups.length - tailCount).map(show),
    ].join(', ');
  }

  String _callCounts(List<ScriptCallSummary> calls) {
    if (calls.isEmpty) {
      return 'no tool calls';
    }
    final counts = <String, int>{};
    for (final call in calls) {
      counts[call.status.label] = (counts[call.status.label] ?? 0) + 1;
    }
    const order = ['ok', 'failed', 'denied', 'timed out', 'cancelled'];
    final parts = [
      for (final label in order)
        if (counts[label] != null) '${counts[label]} $label',
    ];
    final noun = calls.length == 1 ? 'tool call' : 'tool calls';
    return '${calls.length} $noun (${parts.join(', ')})';
  }

  static final RegExp _importLike = RegExp(
    r'^\s*(import|export)\b|\brequire\s*\(',
    multiLine: true,
  );

  static final List<RegExp> _typeScriptLike = [
    RegExp(r'\b(const|let|var)\s+[A-Za-z_$][\w$]*\s*:\s*[A-Za-z_${[(]'),
    RegExp(
      r'[(,]\s*[A-Za-z_$][\w$]*\s*\??:\s*(string|number|boolean|any|unknown|object|[A-Z][\w$]*)\b',
    ),
    RegExp(
      r'\)\s*:\s*(string|number|boolean|void|any|unknown|never|Promise\b|[A-Z][\w$]*)',
    ),
    RegExp(
      r'^\s*(export\s+)?(interface|type)\s+[A-Za-z_$][\w$]*\s*[={<]',
      multiLine: true,
    ),
    RegExp(r'\bas\s+(string|number|boolean|any|unknown|const|[A-Z][\w$]*)\b'),
    RegExp(
      r'<\s*(string|number|boolean|any|unknown|[A-Z][\w$]*)\s*(\[\s*\])?\s*>\s*\(',
    ),
  ];

  /// A hint for a `SyntaxError` that looks like a module import or a
  /// TypeScript annotation, the two mistakes a model makes most in plain
  /// JavaScript.
  String? _hint(CodeExecutionOutcome outcome) {
    final error = outcome.error;
    final source = outcome.source;
    if (error == null || error.name != 'SyntaxError' || source == null) {
      return null;
    }
    if (_importLike.hasMatch(source)) {
      return 'Hint: scripts cannot `import`, `export` or `require` anything. '
          'Call tools as `await tools.<name>(args)`; everything else is '
          'plain JavaScript built-ins.';
    }
    if (_typeScriptLike.any((r) => r.hasMatch(source))) {
      return 'Hint: this looks like TypeScript. Scripts are plain JavaScript: '
          'remove type annotations (`: string`, `as Foo`, `<T>`), '
          '`interface` and `type` declarations. The declarations in the tool '
          'description are documentation only.';
    }
    return null;
  }

  String _questions(List<ScriptQuestionRecord> questions) {
    final b = StringBuffer(
      questions.length == 1
          ? 'The script asked the person a question. Their answer, verbatim:'
          : 'The script asked the person ${questions.length} questions. '
                'Their answers, verbatim:',
    );
    var n = 0;
    for (final q in questions) {
      n++;
      b
        ..write('\n\nQuestion $n: ')
        ..write(q.question);
      if (q.options.isNotEmpty) {
        b
          ..write('\nOptions: ')
          ..write(q.options.join(', '));
      }
      if (!q.answered) {
        b.write('\nNo answer: the question timed out or was dismissed.');
        continue;
      }
      if (q.skipped) {
        b.write('\nSkipped: they left the choice to you.');
      }
      if (q.selected.isNotEmpty) {
        b
          ..write('\nSelected: ')
          ..write(q.selected.join(', '));
      }
      final text = q.text;
      if (text != null && text.isNotEmpty) {
        b
          ..write('\nWrote: ')
          ..write(text);
      }
      if (!q.skipped && q.selected.isEmpty && (text == null || text.isEmpty)) {
        b.write('\nAnswered with nothing.');
      }
    }
    return b.toString();
  }

  /// `0.3 s`, `2.4 s`, `12 s`, `5 min 3 s`.
  static String _duration(int ms) {
    if (ms < 10000) {
      return '${(ms / 1000).toStringAsFixed(1)} s';
    }
    final seconds = (ms / 1000).round();
    if (seconds < 120) {
      return '$seconds s';
    }
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return rest == 0 ? '$minutes min' : '$minutes min $rest s';
  }

  static String _kib(int bytes) =>
      bytes < 1024 ? '$bytes B' : '${(bytes / 1024).round()} KiB';

  /// Moves [index] off the low half of a surrogate pair.
  static int _safeCut(String text, int index) {
    if (index > 0 && index < text.length) {
      final unit = text.codeUnitAt(index);
      if (unit >= 0xDC00 && unit <= 0xDFFF) {
        return index - 1;
      }
    }
    return index;
  }
}
