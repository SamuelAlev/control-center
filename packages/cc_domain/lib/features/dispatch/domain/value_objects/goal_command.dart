import 'package:cc_domain/core/domain/value_objects/money.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_unattended_policy.dart';
import 'package:cc_domain/src/errors/app_exceptions.dart';

/// The refusal kind of a `/goal` body the server cannot read: an unknown
/// flag, a flag without its value, a value out of range, or a contract
/// section past its limits.
const String goalCommandInvalidKind = 'goal_command_invalid';

/// A `/goal` body, read: the objective and what its flags and its guided
/// sections say.
///
/// Grammar (plan section 8, "Flags"), one line:
///
/// ```text
/// /goal [--max N] [--budget D] [--days N] [--check "<cmd>"]… [--checker <agent>] [--fresh] [--unattended wait|assume] <objective>
/// ```
///
/// Flags may stand anywhere outside inline code and code blocks (a person
/// typing `/goal fix it --budget 10` means the flag); any other `--word`
/// there is refused, so a mistyped flag never silently becomes part of the
/// objective. To keep a literal `--word` in the objective, put it in
/// backticks. A value with spaces is quoted (`"…"`, `'…'` or backticks).
///
/// The guided dialog writes its answers as markdown sections; three become
/// the [contract] and leave the objective: `## Success criteria` (one item
/// per line or bullet), `## Boundaries` and `## Stop conditions`. A
/// `## Checks` section (written by the dialog from the checks a person
/// entered: `` - `cmd` (900 s) `` or `` - environment task `name` (300 s) ``)
/// adds checks. `## Objective`, `## Verification` and anything else stay in
/// the objective text.
final class GoalCommand {
  /// Creates a parsed command.
  GoalCommand({
    required this.objective,
    this.maxRuns,
    this.budgetMicros,
    this.days,
    this.contract,
    this.checkerRef,
    this.fresh = false,
    this.unattended,
  });

  /// The most `--check` flags and `## Checks` lines together.
  static const int maxChecks = GoalContract.maxChecks;

  /// Every flag the grammar knows.
  static const List<String> knownFlags = [
    '--max',
    '--budget',
    '--days',
    '--check',
    '--checker',
    '--fresh',
    '--unattended',
  ];

  /// The `## Checks` section heading.
  static const String checksHeading = '## Checks';

  /// The objective with the flags and the contract sections taken out.
  /// Empty when the body had none.
  final String objective;

  /// `--max N`: the run budget, or null for none.
  final int? maxRuns;

  /// `--budget D` in micro-dollars, or null for the default.
  final int? budgetMicros;

  /// `--days N`: the deadline in days from the start, or null for none.
  final int? days;

  /// What done means, from the sections and the `--check` flags; null when
  /// the body states none of it.
  final GoalContract? contract;

  /// `--checker <agent>` as typed (a name or an id), resolved in the
  /// workspace by the caller; null when not given.
  final String? checkerRef;

  /// `--fresh`: every segment starts without the conversation's history.
  final bool fresh;

  /// `--unattended wait|assume`, or null for the default.
  final GoalUnattendedPolicy? unattended;

  /// Reads [body] (the text after `/goal `). Throws [ValidationException]
  /// (code [goalCommandInvalidKind]) with a person-readable message for an
  /// unknown flag, a missing or bad value, a repeated flag, more than
  /// [maxChecks] checks, or a contract section past its limits.
  static GoalCommand parse(String body) {
    final code = _codeRanges(body);
    final tokens = _tokenize(body, code);
    final removed = <(int, int)>[];
    int? maxRuns;
    int? budgetMicros;
    int? days;
    String? checkerRef;
    var fresh = false;
    GoalUnattendedPolicy? unattended;
    final checks = <GoalCheck>[];
    final seen = <String>{};

    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (!token.isFlagShaped) {
        continue;
      }
      final flag = token.raw;
      if (!knownFlags.contains(flag)) {
        throw _refuse(
          'Unknown flag $flag. /goal knows ${knownFlags.join(', ')}. To keep '
          'it as part of the objective, put it in backticks.',
        );
      }
      if (flag != '--check' && !seen.add(flag)) {
        throw _refuse('$flag is given twice.');
      }
      if (flag == '--fresh') {
        fresh = true;
        removed.add((token.start, token.end));
        continue;
      }
      final value = i + 1 < tokens.length ? tokens[i + 1] : null;
      if (value == null || (value.isFlagShaped && !value.quoted)) {
        throw _refuse('$flag needs ${_valueName(flag)}.');
      }
      final text = value.value;
      switch (flag) {
        case '--max':
          maxRuns = _positiveInt(text, flag, 'a whole number of runs');
        case '--days':
          days = _positiveInt(text, flag, 'a whole number of days');
        case '--budget':
          final micros = parseDollarsToMicros(text);
          if (micros == null || micros <= 0) {
            throw _refuse(
              '--budget needs an amount in dollars, such as 12.50; got '
              '"$text".',
            );
          }
          budgetMicros = micros;
        case '--check':
          checks.add(_check(text, GoalCheckLocation.worktree, flag));
        case '--checker':
          if (text.trim().isEmpty) {
            throw _refuse('--checker needs an agent name or id.');
          }
          checkerRef = text.trim();
        case '--unattended':
          unattended = switch (text) {
            'wait' => GoalUnattendedPolicy.wait,
            'assume' => GoalUnattendedPolicy.assume,
            _ => throw _refuse(
              '--unattended takes wait or assume; got "$text".',
            ),
          };
      }
      removed.add((token.start, value.end));
      i++;
    }

    final sections = _GuidedSections.split(_without(body, removed));
    final contractChecks = [...sections.checks, ...checks];
    if (contractChecks.length > maxChecks) {
      throw _refuse(
        'A goal has at most $maxChecks checks; this one has '
        '${contractChecks.length}.',
      );
    }
    final GoalContract? contract;
    if (sections.criteria.isEmpty &&
        contractChecks.isEmpty &&
        sections.boundaries == null &&
        sections.stopWhen == null) {
      contract = null;
    } else {
      contract = GoalContract(
        criteria: sections.criteria,
        checks: contractChecks,
        boundaries: sections.boundaries,
        stopWhen: sections.stopWhen,
      );
    }
    return GoalCommand(
      objective: sections.rest,
      maxRuns: maxRuns,
      budgetMicros: budgetMicros,
      days: days,
      contract: contract,
      checkerRef: checkerRef,
      fresh: fresh,
      unattended: unattended,
    );
  }

  /// The `## Checks` section for [checks], as the guided dialog appends it
  /// to an objective; [parse] reads it back to the same checks.
  static String checksSection(List<GoalCheck> checks) {
    final out = StringBuffer(checksHeading);
    for (final check in checks) {
      final run = _inlineCode(check.run);
      out.write(
        check.where == GoalCheckLocation.environment
            ? '\n- environment task $run (${check.timeoutSeconds} s)'
            : '\n- $run (${check.timeoutSeconds} s)',
      );
    }
    return out.toString();
  }

  static String _inlineCode(String text) {
    final line = text.trim().replaceAll(RegExp(r'\s*[\r\n]+\s*'), ' ');
    var fence = '`';
    while (line.contains(fence)) {
      fence += '`';
    }
    return fence.length == 1 ? '`$line`' : '$fence $line $fence';
  }

  static String _valueName(String flag) => switch (flag) {
    '--max' => 'a whole number of runs',
    '--days' => 'a whole number of days',
    '--budget' => 'an amount in dollars',
    '--check' => 'a command, in quotes when it has spaces',
    '--checker' => 'an agent name or id',
    _ => 'wait or assume',
  };

  static int _positiveInt(String text, String flag, String what) {
    final value = int.tryParse(text);
    if (value == null || value < 1) {
      throw _refuse('$flag needs $what, at least 1; got "$text".');
    }
    return value;
  }

  static GoalCheck _check(String run, GoalCheckLocation where, String from) {
    try {
      return GoalCheck(run: run.trim(), where: where);
    } on ArgumentError catch (e) {
      throw _refuse('$from: ${e.message}.');
    }
  }
}

ValidationException _refuse(String message) =>
    ValidationException(message, code: goalCommandInvalidKind);

/// One whitespace-separated token of a `/goal` body.
final class _Token {
  _Token({
    required this.start,
    required this.end,
    required this.raw,
    required this.value,
    required this.quoted,
    required this.inCode,
  });

  final int start;
  final int end;
  final String raw;

  /// [raw] without its quotes.
  final String value;
  final bool quoted;

  /// Whether any of it lies in inline code or a code block.
  final bool inCode;

  static final RegExp _flagShape = RegExp(r'^--[a-z][a-z0-9-]*$');

  bool get isFlagShaped => !quoted && !inCode && _flagShape.hasMatch(raw);
}

/// The ranges of [text] inside inline code or code blocks: a run of
/// backticks up to the next run of the same length.
List<(int, int)> _codeRanges(String text) {
  final ranges = <(int, int)>[];
  var i = 0;
  while (i < text.length) {
    if (text.codeUnitAt(i) != 0x60) {
      i++;
      continue;
    }
    final open = _runLength(text, i);
    var j = i + open;
    var closed = -1;
    while (j < text.length) {
      if (text.codeUnitAt(j) == 0x60) {
        final run = _runLength(text, j);
        if (run == open) {
          closed = j + run;
          break;
        }
        j += run;
      } else {
        j++;
      }
    }
    if (closed < 0) {
      i += open;
      continue;
    }
    ranges.add((i, closed));
    i = closed;
  }
  return ranges;
}

int _runLength(String text, int from) {
  var n = 0;
  while (from + n < text.length && text.codeUnitAt(from + n) == 0x60) {
    n++;
  }
  return n;
}

bool _isSpace(int c) => c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D;

List<_Token> _tokenize(String text, List<(int, int)> code) {
  bool overlapsCode(int start, int end) =>
      code.any((r) => r.$1 < end && start < r.$2);
  (int, int)? codeAt(int index) {
    for (final r in code) {
      if (r.$1 == index) {
        return r;
      }
    }
    return null;
  }

  final tokens = <_Token>[];
  var i = 0;
  while (i < text.length) {
    if (_isSpace(text.codeUnitAt(i))) {
      i++;
      continue;
    }
    final start = i;
    final first = text[i];
    var quoted = false;
    String? inner;
    if (first == '"' || first == "'") {
      final close = text.indexOf(first, i + 1);
      if (close > i) {
        quoted = true;
        inner = text.substring(i + 1, close);
        i = close + 1;
      }
    } else if (codeAt(i) case final range?) {
      final fence = _runLength(text, i);
      quoted = true;
      inner = text.substring(i + fence, range.$2 - fence).trim();
      i = range.$2;
    }
    final quoteEnd = i;
    while (i < text.length && !_isSpace(text.codeUnitAt(i))) {
      i++;
    }
    final raw = text.substring(start, i);
    final rest = quoted ? text.substring(quoteEnd, i) : '';
    tokens.add(
      _Token(
        start: start,
        end: i,
        raw: raw,
        value: quoted ? '$inner$rest' : raw,
        quoted: quoted,
        inCode: !quoted && overlapsCode(start, i),
      ),
    );
  }
  return tokens;
}

/// [text] with the [removed] ranges cut out, each with the spaces before
/// it; a line left empty by a cut goes too.
String _without(String text, List<(int, int)> removed) {
  if (removed.isEmpty) {
    return text.trim();
  }
  final out = StringBuffer();
  var last = 0;
  for (final (start, end) in removed) {
    var from = start;
    while (from > last &&
        (text.codeUnitAt(from - 1) == 0x20 ||
            text.codeUnitAt(from - 1) == 0x09)) {
      from--;
    }
    out.write(text.substring(last, from));
    last = end;
  }
  out.write(text.substring(last));
  return out
      .toString()
      .split('\n')
      .where((line) => line.trim().isNotEmpty || line.isEmpty)
      .join('\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

/// The guided dialog's sections of an objective.
final class _GuidedSections {
  _GuidedSections({
    required this.rest,
    required this.criteria,
    required this.boundaries,
    required this.stopWhen,
    required this.checks,
  });

  final String rest;
  final List<String> criteria;
  final String? boundaries;
  final String? stopWhen;
  final List<GoalCheck> checks;

  static const _criteria = 'success criteria';
  static const _boundaries = 'boundaries';
  static const _stop = 'stop conditions';
  static const _checks = 'checks';
  static const _taken = {_criteria, _boundaries, _stop, _checks};

  static final RegExp _heading = RegExp(r'^##\s+(.+?)\s*#*\s*$');

  static _GuidedSections split(String text) {
    final kept = <String>[];
    final bodies = <String, List<String>>{};
    String? current;
    var inFence = false;
    for (final line in text.split('\n')) {
      if (line.trimLeft().startsWith('```')) {
        inFence = !inFence;
      }
      final heading = inFence ? null : _heading.firstMatch(line.trim());
      if (heading != null) {
        final name = heading.group(1)!.toLowerCase();
        current = _taken.contains(name) ? name : null;
        if (current != null) {
          if (bodies.containsKey(current)) {
            throw _refuse(
              'The section "## ${heading.group(1)}" is there twice.',
            );
          }
          bodies[current] = [];
          continue;
        }
      }
      if (current != null) {
        bodies[current]!.add(line);
      } else {
        kept.add(line);
      }
    }
    return _GuidedSections(
      rest: kept.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim(),
      criteria: _items(bodies[_criteria]),
      boundaries: _text(bodies[_boundaries], 'Boundaries'),
      stopWhen: _text(bodies[_stop], 'Stop conditions'),
      checks: _checksOf(bodies[_checks]),
    );
  }

  static final RegExp _bullet = RegExp(
    r'^\s*(?:[-*+]|\d+[.)])\s+(?:\[[ xX]\]\s+)?(.*)$',
  );

  /// One item per bullet (a line under a bullet continues it), or per line
  /// when there are no bullets.
  static List<String> _items(List<String>? lines) {
    if (lines == null) {
      return const [];
    }
    final nonEmpty = [
      for (final line in lines)
        if (line.trim().isNotEmpty) line,
    ];
    final bulleted = nonEmpty.any(_bullet.hasMatch);
    final items = <String>[];
    for (final line in nonEmpty) {
      final bullet = _bullet.firstMatch(line);
      if (bullet != null) {
        items.add(bullet.group(1)!.trim());
      } else if (bulleted && items.isNotEmpty) {
        items[items.length - 1] = '${items.last} ${line.trim()}';
      } else {
        items.add(line.trim());
      }
    }
    final kept = [
      for (final item in items)
        if (item.isNotEmpty) item,
    ];
    if (kept.length > GoalContract.maxCriteria) {
      throw _refuse(
        'Success criteria: at most ${GoalContract.maxCriteria} items; this '
        'has ${kept.length}. Merge or drop some.',
      );
    }
    for (var i = 0; i < kept.length; i++) {
      if (kept[i].length > GoalContract.maxCriterionLength) {
        throw _refuse(
          'Success criteria: each item is at most '
          '${GoalContract.maxCriterionLength} characters; item ${i + 1} has '
          '${kept[i].length}. Shorten it or split it.',
        );
      }
    }
    return kept;
  }

  static String? _text(List<String>? lines, String name) {
    if (lines == null) {
      return null;
    }
    final text = lines.join('\n').trim();
    if (text.isEmpty) {
      return null;
    }
    if (text.length > GoalContract.maxTextLength) {
      throw _refuse(
        '$name: at most ${GoalContract.maxTextLength} characters; this has '
        '${text.length}. Shorten it.',
      );
    }
    return text;
  }

  static final RegExp _checkLine = RegExp(
    r'^(environment task\s+)?(`+)(.+?)\2'
    r'(?:\s*\(\s*(?:(worktree|environment)\s*,\s*)?(\d+)\s*s\s*\))?\s*$',
  );

  static List<GoalCheck> _checksOf(List<String>? lines) {
    if (lines == null) {
      return const [];
    }
    final checks = <GoalCheck>[];
    var n = 0;
    for (final line in lines) {
      if (line.trim().isEmpty) {
        continue;
      }
      n++;
      final bullet = _bullet.firstMatch(line);
      final match = _checkLine.firstMatch((bullet?.group(1) ?? line).trim());
      if (match == null) {
        throw _refuse(
          '## Checks: line $n is not a check. Write each one as '
          '- `command` (300 s) or - environment task `name` (300 s).',
        );
      }
      final environment =
          match.group(1) != null || match.group(4) == 'environment';
      final seconds = match.group(5);
      final timeout = seconds == null
          ? GoalCheck.defaultTimeoutSeconds
          : int.tryParse(seconds) ?? -1;
      try {
        checks.add(
          GoalCheck(
            run: match.group(3)!.trim(),
            where: environment
                ? GoalCheckLocation.environment
                : GoalCheckLocation.worktree,
            timeoutSeconds: timeout,
          ),
        );
      } on ArgumentError catch (e) {
        throw _refuse('## Checks: line $n: ${e.message}.');
      }
    }
    return checks;
  }
}
