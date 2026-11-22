import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/features/dispatch/domain/services/wake_rule_command.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_when.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_command.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_limits.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_trigger.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What stops a `/loop` or `/schedule` from being sent as it stands.
enum WakeCommandIssue {
  /// `/schedule` does not say when.
  when,

  /// `every` or `in` has no duration.
  duration,

  /// `every` repeats faster than a schedule may.
  tooOften,

  /// `at` has no time, or one that is already past.
  time,

  /// `cron` has no five fields that fire.
  cron,

  /// `--max` has no number in range.
  maxRuns,

  /// `--days` has no number in range.
  days,

  /// `--budget` has no amount in range.
  budget,

  /// A `--flag` that is not an option.
  option,

  /// Nothing says what each run starts from.
  prompt,
}

/// A `/loop` or `/schedule` as the composer reads it while it is written:
/// the same domain reading the server makes of the sent message, plus the
/// limits the server would refuse it for.
class WakeCommandReading {
  /// Creates the reading.
  const WakeCommandReading({
    required this.draft,
    required this.trigger,
    required this.issue,
    required this.settled,
  });

  /// What was read, and where each part ends in the text.
  final WakeRuleCommandDraft draft;

  /// What fires it, once its `when` reads. Null until then, and for an
  /// `at HH:MM`: the next such time depends on the workspace's zone, which
  /// only the server knows.
  final WakeTrigger? trigger;

  /// What stops it from being sent; null when nothing does.
  final WakeCommandIssue? issue;

  /// Whether text follows the part [issue] names: the person wrote it and
  /// moved on, rather than being in the middle of writing it.
  final bool settled;

  /// Whether it fires more than once.
  bool get repeats => draft.command == 'loop' || trigger is Cron;
}

/// Reads [text] as a `/loop` or `/schedule`; null when it is neither. [now]
/// is the instant an `in` counts from and an `at` must be ahead of.
WakeCommandReading? readWakeCommand(String text, {required DateTime now}) {
  final draft = readWakeRuleCommandDraft(text);
  if (draft == null) {
    return null;
  }
  WakeTrigger? trigger;
  WakeCommandIssue? whenIssue;
  final whenText = draft.when;
  if (whenText != null) {
    switch (parseWakeWhen(whenText, now: now)) {
      case WakeWhenTrigger(trigger: final read):
        trigger = read;
      case WakeWhenNext():
        trigger = const SelfPaced();
      case WakeWhenTooShort():
        whenIssue = WakeCommandIssue.tooOften;
      case WakeWhenInvalid():
        whenIssue = whenText.startsWith('cron:')
            ? WakeCommandIssue.cron
            : WakeCommandIssue.time;
    }
  }
  if (whenIssue != null) {
    return WakeCommandReading(
      draft: draft,
      trigger: null,
      issue: whenIssue,
      settled: text.substring(draft.whenEnd).trim().isNotEmpty,
    );
  }
  // An option out of range comes before whatever the parser found after
  // the options (a missing prompt), in the order the command is written.
  final rangeIssue = _optionOutOfRange(draft);
  final parsed = switch (draft.problem) {
    null => null,
    WakeRuleCommandProblem.when => WakeCommandIssue.when,
    WakeRuleCommandProblem.duration => WakeCommandIssue.duration,
    WakeRuleCommandProblem.time => WakeCommandIssue.time,
    WakeRuleCommandProblem.cron => WakeCommandIssue.cron,
    WakeRuleCommandProblem.maxRuns => WakeCommandIssue.maxRuns,
    WakeRuleCommandProblem.days => WakeCommandIssue.days,
    WakeRuleCommandProblem.budget => WakeCommandIssue.budget,
    WakeRuleCommandProblem.option => WakeCommandIssue.option,
    WakeRuleCommandProblem.prompt => WakeCommandIssue.prompt,
  };
  if (rangeIssue != null) {
    return WakeCommandReading(
      draft: draft,
      trigger: trigger,
      issue: rangeIssue,
      settled: text.substring(draft.optionsEnd).trim().isNotEmpty,
    );
  }
  return WakeCommandReading(
    draft: draft,
    trigger: trigger,
    issue: parsed,
    settled: draft.problemSettled,
  );
}

WakeCommandIssue? _optionOutOfRange(WakeRuleCommandDraft draft) {
  if ((draft.maxRuns ?? 1) > WakeRuleBounds.maxRunsCeiling) {
    return WakeCommandIssue.maxRuns;
  }
  if ((draft.days ?? 1) > WakeRuleBounds.personMaxExpiry.inDays) {
    return WakeCommandIssue.days;
  }
  if ((draft.budgetMicros ?? 1) > WakeRuleLimits.maxCostCapMicros) {
    return WakeCommandIssue.budget;
  }
  return null;
}

/// The parser's own words (data-layer text) about a `/goal` that does not
/// read; null when it reads, or when [text] is no `/goal`.
String? goalCommandProblem(String text) {
  final trimmed = text.trimLeft();
  if (!trimmed.startsWith('/goal ')) {
    return null;
  }
  final body = trimmed.substring('/goal '.length);
  if (body.trim().isEmpty) {
    return null;
  }
  try {
    GoalCommand.parse(body);
    return null;
  } on ValidationException catch (e) {
    return e.message;
  }
}

/// Whether [text] is a `/goal`, `/loop` or `/schedule` the server could not
/// act on either: the same domain parsers it runs, run first so the person
/// keeps the draft and reads why in the composer instead of in a row after
/// the send.
bool workCommandBlocked(String text, {required DateTime now}) =>
    goalCommandProblem(text) != null ||
    readWakeCommand(text, now: now)?.issue != null;

/// Whether the last Enter in one conversation's composer was refused for its
/// command, which is when the composer's command strip stops hinting and
/// says what is wrong. Cleared by the next send that goes through and by the
/// strip, once the draft reads.
class ComposerCommandRefusalNotifier extends Notifier<bool> {
  /// Creates the holder for [key].
  ComposerCommandRefusalNotifier(this.key);

  /// The conversation.
  final ConversationRef key;

  @override
  bool build() => false;

  /// Checks [text]: remembers the refusal and returns false when it cannot
  /// be sent, forgets any earlier one and returns true otherwise.
  bool check(String text) {
    state = workCommandBlocked(text, now: DateTime.now().toUtc());
    return !state;
  }

  /// Forgets the refusal.
  void clear() => state = false;
}

/// The per-conversation composer command refusal.
final composerCommandRefusalProvider =
    NotifierProvider.family<
      ComposerCommandRefusalNotifier,
      bool,
      ConversationRef
    >(ComposerCommandRefusalNotifier.new);
