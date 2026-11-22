/// The steps of a `/loop` or `/schedule` after its name, as queries over the
/// words being written at the caret: when it fires, then (on `--`) its
/// limits. Pure text: `WakeArgumentSource` turns a query into the rows of
/// the composer's suggestion list.
///
/// Nothing here decides what a command means: the reading is
/// `readWakeRuleCommandDraft`'s.
library;

import 'package:cc_domain/features/dispatch/domain/services/wake_rule_command.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_when.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_trigger.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';

/// Which step of the command a [WakeArgumentQuery] is about.
enum WakeArgumentStep {
  /// When it fires: `in 2h`, `at 09:00`, `cron "…"`, `every 30m`.
  when,

  /// A limit: `--max`, `--days`, `--budget`.
  option,
}

/// A query over the words being written at one step of a `/loop` or
/// `/schedule`. [tokens] are what may be written there, already narrowed to
/// what was typed; a pick replaces the typed words with one of them.
class WakeArgumentQuery extends MentionQuery {
  /// Creates the query.
  const WakeArgumentQuery({
    required this.step,
    required this.tokens,
    required super.partial,
    required super.start,
    required super.end,
  }) : super(trigger: MentionTrigger.argument);

  /// The step the caret is in.
  final WakeArgumentStep step;

  /// What fits there, in the order offered. Never empty.
  final List<String> tokens;
}

/// The cron schedules offered by name.
const String wakeCronWeekdays = '0 9 * * 1-5';

/// Every day at 09:00.
const String wakeCronDaily = '0 9 * * *';

/// Every hour, on the hour.
const String wakeCronHourly = '0 * * * *';

const List<String> _options = ['--max', '--days', '--budget'];

/// The step of a `/loop` or `/schedule` the caret is in, as a query over
/// the words being written there. Null when [text] is no such command, the
/// caret is elsewhere (in the name, in the prompt), or nothing fits what was
/// typed.
WakeArgumentQuery? wakeArgumentQuery(String text, int caret) {
  if (caret < 0 || caret > text.length) {
    return null;
  }
  final head = text.substring(0, caret);
  final draft = readWakeRuleCommandDraft(head);
  if (draft == null ||
      head.substring(0, draft.argumentsStart).trimRight().length ==
          draft.argumentsStart) {
    // Not a command, or no space after its name yet: the caret is in it.
    return null;
  }
  return _optionQuery(head, draft) ?? _whenQuery(head, draft);
}

WakeArgumentQuery? _optionQuery(String head, WakeRuleCommandDraft draft) {
  final wordStart = head.lastIndexOf(RegExp(r'\s')) + 1;
  final word = head.substring(wordStart);
  if (!word.startsWith('-') || wordStart < draft.argumentsStart) {
    return null;
  }
  // An option goes between the when and the prompt: everything before the
  // word reads, and no prompt has begun.
  final before = readWakeRuleCommandDraft(head.substring(0, wordStart));
  if (before == null ||
      !before.hasWhen ||
      before.problem != WakeRuleCommandProblem.prompt) {
    return null;
  }
  final taken = {
    if (before.maxRuns != null) '--max',
    if (before.days != null) '--days',
    if (before.budgetMicros != null) '--budget',
  };
  final tokens = [
    for (final option in _options)
      if (option.startsWith(word) && !taken.contains(option)) option,
  ];
  if (tokens.isEmpty) {
    return null;
  }
  return WakeArgumentQuery(
    step: WakeArgumentStep.option,
    tokens: tokens,
    partial: word,
    start: wordStart,
    end: head.length,
  );
}

WakeArgumentQuery? _whenQuery(String head, WakeRuleCommandDraft draft) {
  // A /loop without "every" reads as self-paced with its first words as the
  // prompt; until an option is written those words may still become "every".
  final mayTakeEvery =
      draft.when == 'next' && draft.optionsEnd == draft.argumentsStart;
  final writing = switch (draft.problem) {
    WakeRuleCommandProblem.when ||
    WakeRuleCommandProblem.duration ||
    WakeRuleCommandProblem.time ||
    WakeRuleCommandProblem.cron => !draft.problemSettled,
    // A when just finished, the caret still on it: one row confirms it.
    WakeRuleCommandProblem.prompt =>
      mayTakeEvery ||
          draft.optionsEnd == draft.whenEnd && draft.whenEnd == head.length,
    null => mayTakeEvery,
    _ => false,
  };
  if (!writing) {
    return null;
  }
  final partial = head.substring(draft.argumentsStart);
  final tokens = wakeWhenTokens(draft.command, partial);
  if (tokens.isEmpty) {
    return null;
  }
  return WakeArgumentQuery(
    step: WakeArgumentStep.when,
    tokens: tokens,
    partial: partial,
    start: draft.argumentsStart,
    end: head.length,
  );
}

/// The `when` forms that fit [typed] for `/loop` or `/schedule`
/// ([command]), each a complete, readable `when`.
List<String> wakeWhenTokens(String command, String typed) {
  final p = typed.replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  if (command == 'loop') {
    return [
      for (final token in _durations('every', p, const ['10m', '30m', '1h']))
        if (_repeatable(token)) token,
    ];
  }
  if (p.isEmpty) {
    return const ['in 30m', 'in 2h', 'at 09:00', 'cron "$wakeCronWeekdays"'];
  }
  return [
    ..._durations('in', p, const ['15m', '30m', '1h', '2h', '1d']),
    ..._clocks(p),
    for (final cron in const [wakeCronWeekdays, wakeCronDaily, wakeCronHourly])
      if ('cron "$cron"'.startsWith(p)) 'cron "$cron"',
  ];
}

bool _repeatable(String token) {
  final d = parseWakeDuration(token.substring('every '.length));
  return d != null && d >= Every.minInterval;
}

final RegExp _digits = RegExp(r'^\d{1,4}$');
final RegExp _openGroup = RegExp(r'^(?:\d+[smhd])+\d+$');

/// `<word> <duration>` forms: the defaults while only the word is written,
/// then the typed number in each unit, then the duration itself once it
/// reads.
List<String> _durations(String word, String p, List<String> defaults) {
  if (word.startsWith(p)) {
    return [for (final d in defaults) '$word $d'];
  }
  if (!p.startsWith('$word ')) {
    return const [];
  }
  final value = p.substring(word.length + 1);
  if (value.isEmpty) {
    return [for (final d in defaults) '$word $d'];
  }
  if (_digits.hasMatch(value)) {
    return [
      for (final unit in const ['m', 'h', 'd']) '$word $value$unit',
    ];
  }
  if (parseWakeDuration(value) != null) {
    return ['$word $value'];
  }
  // `1h30` is on its way to `1h30m`.
  return _openGroup.hasMatch(value) ? ['$word ${value}m'] : const [];
}

final RegExp _clock = RegExp(r'^(\d{1,2})(?::([0-5]?)(\d?))?$');

/// `at HH:MM` forms: a few common hours while only `at` is written, then the
/// typed hour on the hour and the half hour, then the time itself.
List<String> _clocks(String p) {
  const defaults = ['at 09:00', 'at 13:00', 'at 17:00'];
  if ('at'.startsWith(p)) {
    return defaults;
  }
  if (!p.startsWith('at ')) {
    return const [];
  }
  final value = p.substring(3);
  if (value.isEmpty) {
    return defaults;
  }
  final m = _clock.firstMatch(value);
  final hour = m == null ? null : int.parse(m.group(1)!);
  if (m == null || hour == null || hour > 23) {
    return const [];
  }
  final hh = hour.toString().padLeft(2, '0');
  final tens = m.group(2) ?? '';
  final ones = m.group(3) ?? '';
  if (tens.isEmpty) {
    // `9`, `09`, `9:`, and `9:7` (a minute past 59 never matched above).
    return ones.isEmpty ? ['at $hh:00', 'at $hh:30'] : const [];
  }
  return ones.isEmpty ? ['at $hh:${tens}0'] : ['at $hh:$tens$ones'];
}
