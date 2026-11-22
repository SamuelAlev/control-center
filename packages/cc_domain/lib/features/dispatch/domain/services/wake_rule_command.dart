/// The person commands that create wake rules from a composer message (plan
/// section 9, "Commands"):
///
/// ```text
/// /loop [every <interval>] [--max N] [--days N] [--budget D] <prompt>
/// /schedule <in 2h | at <time> | cron "<expr>"> [--max N] [--days N] [--budget D] <prompt>
/// ```
///
/// `/loop` without `every` is self-paced. `at` takes an ISO time or a wall
/// clock `HH:MM` (the next one, in the workspace's zone). A cron's five
/// fields may also be written without the quotes. `--budget` is in US
/// dollars. Only a signed-in person's own message is read this way; text
/// from anything else is ordinary text, and the caller decides that.
///
/// [readWakeRuleCommandDraft] reads the same grammar as far as it has been
/// written, for a composer that guides the person through it;
/// [parseWakeRuleCommand] is that reading held to a finished command.
library;

import 'package:cc_domain/features/dispatch/domain/services/wake_when.dart';
import 'package:cc_domain/features/pipelines/domain/services/cron_schedule.dart';

/// Whether [prompt] opens with `/loop` or `/schedule` followed by more text.
bool isWakeRuleCommand(String prompt) {
  final text = prompt.trimLeft();
  return RegExp(r'^/(loop|schedule)\s').hasMatch(text);
}

/// What a `/loop` or `/schedule` message asks for.
sealed class WakeRuleCommand {
  const WakeRuleCommand();
}

/// A readable command: [when] is in the `when` grammar (`every:30m`, `next`,
/// `in:2h`, `at:<ISO>`, `cron:<expr>`), or null with [clock] set for
/// `at HH:MM`. [prompt] is the text each run starts with.
final class WakeRuleCommandRequest extends WakeRuleCommand {
  /// Creates the reading.
  const WakeRuleCommandRequest({
    required this.command,
    required this.when,
    required this.prompt,
    this.clock,
    this.maxRuns,
    this.days,
    this.budgetMicros,
  });

  /// `loop` or `schedule`.
  final String command;

  /// The trigger in the `when` grammar; null for an `at HH:MM`.
  final String? when;

  /// An `at HH:MM`: the hour and minute of the next such wall-clock time.
  final ({int hour, int minute})? clock;

  /// The text each run starts with (never empty).
  final String prompt;

  /// `--max N`.
  final int? maxRuns;

  /// `--days N`: the rule ends that many days after it is created.
  final int? days;

  /// `--budget D`, in micro-dollars.
  final int? budgetMicros;
}

/// A command that could not be read; [message] says how to write it.
final class WakeRuleCommandInvalid extends WakeRuleCommand {
  /// Creates the reading.
  const WakeRuleCommandInvalid(this.message, {required this.problem});

  /// What was wrong, and the usage.
  final String message;

  /// Which part was wrong or missing.
  final WakeRuleCommandProblem problem;
}

/// The part of a `/loop` or `/schedule` that is wrong or still missing.
enum WakeRuleCommandProblem {
  /// `/schedule` without `in`, `at` or `cron`.
  when,

  /// `every` or `in` without a duration.
  duration,

  /// `at` without a wall clock or an ISO time.
  time,

  /// `cron` without five fields that make a cron.
  cron,

  /// `--max` without a whole number.
  maxRuns,

  /// `--days` without a whole number.
  days,

  /// `--budget` without an amount.
  budget,

  /// A `--flag` that is not an option.
  option,

  /// No text for the runs to start from.
  prompt,
}

/// A `/loop` or `/schedule` as far as it has been written: what was read,
/// where each part ends, and the first thing wrong or missing.
///
/// Offsets count from the start of the text given to
/// [readWakeRuleCommandDraft].
final class WakeRuleCommandDraft {
  /// Creates the reading.
  const WakeRuleCommandDraft({
    required this.command,
    required this.when,
    required this.clock,
    required this.maxRuns,
    required this.days,
    required this.budgetMicros,
    required this.prompt,
    required this.problem,
    required this.message,
    required this.option,
    required this.problemSettled,
    required this.argumentsStart,
    required this.whenEnd,
    required this.optionsEnd,
  });

  /// `loop` or `schedule`.
  final String command;

  /// The trigger in the `when` grammar, once read; null for an `at HH:MM`
  /// ([clock]) and for a `when` not read yet.
  final String? when;

  /// An `at HH:MM`, once read.
  final ({int hour, int minute})? clock;

  /// `--max N`, once read.
  final int? maxRuns;

  /// `--days N`, once read.
  final int? days;

  /// `--budget D` in micro-dollars, once read.
  final int? budgetMicros;

  /// The text each run starts with; empty until it is written, and whenever
  /// [problem] names an earlier part.
  final String prompt;

  /// The first part that is wrong or missing; null for a finished command.
  final WakeRuleCommandProblem? problem;

  /// [problem] in words, with the usage; null for a finished command.
  final String? message;

  /// The flag a [WakeRuleCommandProblem.option] is about.
  final String? option;

  /// Whether text follows the part [problem] names: the person wrote it and
  /// moved on, rather than being in the middle of writing it.
  final bool problemSettled;

  /// Where the `when` begins: past the command word and the space after it.
  final int argumentsStart;

  /// Just past the `when`; [argumentsStart] while none is read (and for a
  /// self-paced `/loop`, which has none).
  final int whenEnd;

  /// Just past the last option read; [whenEnd] while there is none. An
  /// option goes here, and the prompt begins after it.
  final int optionsEnd;

  /// Whether a `when` was read (a self-paced `/loop` counts: it needs none).
  bool get hasWhen => when != null || clock != null;
}

/// How `/loop` is written.
const String loopCommandUsage =
    '/loop [every <interval>] [--max N] [--days N] [--budget D] <prompt> '
    '(for example /loop every 30m --days 3 check the deploy). Without '
    '"every" the agent picks its own pace.';

/// How `/schedule` is written.
const String scheduleCommandUsage =
    '/schedule <in 2h | at 09:00 | at 2026-11-20T09:00Z | cron "0 9 * * 1-5"> '
    '[--max N] [--days N] [--budget D] <prompt>';

/// Reads [prompt]; null when it is not a `/loop` or `/schedule` command.
WakeRuleCommand? parseWakeRuleCommand(String prompt) {
  if (!isWakeRuleCommand(prompt)) {
    return null;
  }
  final draft = readWakeRuleCommandDraft(prompt)!;
  final problem = draft.problem;
  if (problem != null) {
    return WakeRuleCommandInvalid(draft.message!, problem: problem);
  }
  return WakeRuleCommandRequest(
    command: draft.command,
    when: draft.when,
    clock: draft.clock,
    prompt: draft.prompt,
    maxRuns: draft.maxRuns,
    days: draft.days,
    budgetMicros: draft.budgetMicros,
  );
}

final RegExp _commandWord = RegExp(r'^/(loop|schedule)(?=\s|$)');

/// Reads [text] as far as it goes; null when it does not open with `/loop`
/// or `/schedule` as a whole word. Unlike [isWakeRuleCommand], the bare
/// command counts: it is a command with nothing written yet.
WakeRuleCommandDraft? readWakeRuleCommandDraft(String text) {
  final lead = text.length - text.trimLeft().length;
  final head = _commandWord.firstMatch(text.substring(lead));
  if (head == null) {
    return null;
  }
  final command = head.group(1)!;
  final usage = command == 'loop' ? loopCommandUsage : scheduleCommandUsage;
  final scanner = _Scanner(text, lead + head.end).._skipSpace();
  final argumentsStart = scanner._at;
  var whenEnd = argumentsStart;
  var optionsEnd = argumentsStart;
  String? when;
  ({int hour, int minute})? clock;
  int? maxRuns;
  int? days;
  int? budgetMicros;

  WakeRuleCommandDraft result({
    WakeRuleCommandProblem? problem,
    String? message,
    String? option,
    String prompt = '',
    bool settled = false,
  }) => WakeRuleCommandDraft(
    command: command,
    when: when,
    clock: clock,
    maxRuns: maxRuns,
    days: days,
    budgetMicros: budgetMicros,
    prompt: prompt,
    problem: problem,
    message: message == null ? null : '$message $usage',
    option: option,
    problemSettled: settled,
    argumentsStart: argumentsStart,
    whenEnd: whenEnd,
    optionsEnd: optionsEnd,
  );

  // A problem with the part just scanned.
  WakeRuleCommandDraft bad(
    WakeRuleCommandProblem problem,
    String message, {
    String? option,
  }) => result(
    problem: problem,
    message: message,
    option: option,
    settled: scanner.rest().trim().isNotEmpty,
  );

  if (command == 'loop') {
    if (scanner.peekWord() == 'every') {
      scanner.word();
      final raw = scanner.word();
      final d = raw == null ? null : parseWakeDuration(raw);
      if (d == null) {
        return bad(
          WakeRuleCommandProblem.duration,
          '"every" needs an interval such as 30m or 2h.',
        );
      }
      when = 'every:${formatWakeDuration(d)}';
      whenEnd = scanner._at;
    } else {
      when = 'next';
    }
  } else {
    final form = scanner.word();
    switch (form) {
      case 'in':
        final raw = scanner.word();
        final d = raw == null ? null : parseWakeDuration(raw);
        if (d == null) {
          return bad(
            WakeRuleCommandProblem.duration,
            '"in" needs a delay such as 20m or 2h.',
          );
        }
        when = 'in:${formatWakeDuration(d)}';
      case 'at':
        final raw = scanner.word();
        final hm = raw == null
            ? null
            : RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$').firstMatch(raw);
        if (hm != null) {
          clock = (
            hour: int.parse(hm.group(1)!),
            minute: int.parse(hm.group(2)!),
          );
        } else if (raw != null && parseWakeInstant(raw) != null) {
          when = 'at:$raw';
        } else {
          return bad(
            WakeRuleCommandProblem.time,
            '"at" needs a time such as 09:00 or 2026-11-20T09:00Z.',
          );
        }
      case 'cron':
        final expr = scanner.cron();
        if (expr == null) {
          // Fields still being written are not a mistake to move on from.
          return result(
            problem: WakeRuleCommandProblem.cron,
            message:
                '"cron" needs its five fields in quotes: '
                'cron "0 9 * * 1-5".',
            settled: scanner.cronSettled(),
          );
        }
        when = 'cron:$expr';
      default:
        return result(
          problem: WakeRuleCommandProblem.when,
          message: 'Say when:',
          settled: form != null && scanner.rest().trim().isNotEmpty,
        );
    }
    whenEnd = scanner._at;
  }
  optionsEnd = whenEnd;

  while (scanner.peekWord()?.startsWith('--') ?? false) {
    final flag = scanner.word()!;
    switch (flag) {
      case '--max':
        final n = _positiveInt(scanner.word());
        if (n == null) {
          return bad(
            WakeRuleCommandProblem.maxRuns,
            '--max needs a whole number.',
          );
        }
        maxRuns = n;
      case '--days':
        final n = _positiveInt(scanner.word());
        if (n == null) {
          return bad(
            WakeRuleCommandProblem.days,
            '--days needs a whole number.',
          );
        }
        days = n;
      case '--budget':
        final micros = _dollarsToMicros(scanner.word());
        if (micros == null) {
          return bad(
            WakeRuleCommandProblem.budget,
            '--budget needs an amount in US dollars, such as 5 or 2.50.',
          );
        }
        budgetMicros = micros;
      default:
        return bad(
          WakeRuleCommandProblem.option,
          '$flag is not an option.',
          option: flag,
        );
    }
    optionsEnd = scanner._at;
  }

  final rest = scanner.rest().trim();
  if (rest.isEmpty) {
    return result(
      problem: WakeRuleCommandProblem.prompt,
      message: 'Say what to do each time.',
    );
  }
  return result(prompt: rest);
}

int? _positiveInt(String? raw) {
  final n = raw == null ? null : int.tryParse(raw);
  return n == null || n <= 0 ? null : n;
}

int? _dollarsToMicros(String? raw) {
  if (raw == null) {
    return null;
  }
  final text = raw.startsWith(r'$') ? raw.substring(1) : raw;
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text)) {
    return null;
  }
  final dollars = double.parse(text);
  final micros = (dollars * 1000000).round();
  return micros <= 0 ? null : micros;
}

class _Scanner {
  _Scanner(this._text, this._at);

  final String _text;
  int _at;

  void _skipSpace() {
    while (_at < _text.length && _isSpace(_text.codeUnitAt(_at))) {
      _at++;
    }
  }

  static bool _isSpace(int c) =>
      c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D;

  String? peekWord() {
    final saved = _at;
    final w = word();
    _at = saved;
    return w;
  }

  String? word() {
    _skipSpace();
    if (_at >= _text.length) {
      return null;
    }
    final start = _at;
    while (_at < _text.length && !_isSpace(_text.codeUnitAt(_at))) {
      _at++;
    }
    return _text.substring(start, _at);
  }

  /// A `"…"` or `'…'` run of text; null (consuming nothing) when absent or
  /// unclosed.
  String? quoted() {
    _skipSpace();
    if (_at >= _text.length) {
      return null;
    }
    final quote = _text[_at];
    if (quote != '"' && quote != "'") {
      return null;
    }
    final end = _text.indexOf(quote, _at + 1);
    if (end < 0) {
      return null;
    }
    final inner = _text.substring(_at + 1, end).trim();
    _at = end + 1;
    return inner.isEmpty ? null : inner;
  }

  /// A cron's five fields, in quotes or as the next five words; null
  /// (consuming nothing) when what follows is not a five-field cron.
  String? cron() {
    final saved = _at;
    final inQuotes = quoted();
    if (inQuotes != null) {
      if (CronSchedule.tryParse(inQuotes) != null) {
        return inQuotes.split(RegExp(r'\s+')).join(' ');
      }
      _at = saved;
      return null;
    }
    final fields = <String>[];
    for (var i = 0; i < 5; i++) {
      final w = word();
      if (w == null) {
        break;
      }
      fields.add(w);
    }
    final bare = fields.join(' ');
    if (fields.length == 5 && CronSchedule.tryParse(bare) != null) {
      return bare;
    }
    _at = saved;
    return null;
  }

  /// Whether a cron that [cron] could not read is finished being written:
  /// a closed quote, or five words, with more text after them. An open
  /// quote or fewer words is someone still writing the fields.
  bool cronSettled() {
    final saved = _at;
    try {
      _skipSpace();
      if (_at >= _text.length) {
        return false;
      }
      final quote = _text[_at];
      if (quote == '"' || quote == "'") {
        final end = _text.indexOf(quote, _at + 1);
        return end >= 0 && _text.substring(end + 1).trim().isNotEmpty;
      }
      for (var i = 0; i < 5; i++) {
        if (word() == null) {
          return false;
        }
      }
      return rest().trim().isNotEmpty;
    } finally {
      _at = saved;
    }
  }

  String rest() => _text.substring(_at);
}
