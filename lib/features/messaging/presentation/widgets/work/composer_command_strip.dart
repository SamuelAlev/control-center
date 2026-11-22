import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_limits.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/composer_command_reading.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/composer_command_strip_parts.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_kind_text.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/features/messaging/providers/composer_command_refusal.dart';
import 'package:control_center/features/messaging/providers/wake_command_arguments.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Inside the composer, above the field: what the `/loop` or `/schedule`
/// being written will do, and the part it still needs. After a refused Enter
/// it says what is wrong instead of hinting; a refused `/goal` says why here
/// too. Renders nothing for any other draft, and nothing while the
/// composer's suggestion list is offering the very step it would name.
///
/// The draft's text is the only state: every token and menu row here writes
/// command text into the field, and the strip reads the field back.
class ComposerCommandStrip extends ConsumerStatefulWidget {
  /// Creates the strip.
  const ComposerCommandStrip({
    super.key,
    required this.spaceId,
    required this.conversationId,
    required this.controller,
    required this.focusNode,
  });

  /// The space.
  final String spaceId;

  /// The conversation whose composer this sits in.
  final String conversationId;

  /// The composer's text.
  final TextEditingController controller;

  /// The composer's field, which keeps the focus after a token is written.
  final FocusNode focusNode;

  @override
  ConsumerState<ComposerCommandStrip> createState() =>
      _ComposerCommandStripState();
}

class _ComposerCommandStripState extends ConsumerState<ComposerCommandStrip> {
  late String _text = widget.controller.text;
  late int _caret = widget.controller.selection.baseOffset;

  ({String spaceId, String conversationId}) get _key =>
      (spaceId: widget.spaceId, conversationId: widget.conversationId);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(covariant ComposerCommandStrip old) {
    super.didUpdateWidget(old);
    if (!identical(old.controller, widget.controller)) {
      old.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
      _text = widget.controller.text;
      _caret = widget.controller.selection.baseOffset;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    super.dispose();
  }

  void _onText() {
    final text = widget.controller.text;
    final caret = widget.controller.selection.baseOffset;
    if (text == _text && caret == _caret) {
      return;
    }
    final edited = text != _text;
    setState(() {
      _text = text;
      _caret = caret;
    });
    if (!edited) {
      return;
    }
    // A refusal is about the draft that was refused: once the draft reads,
    // a later mistake starts again as a hint.
    if (ref.read(composerCommandRefusalProvider(_key)) &&
        !workCommandBlocked(text, now: DateTime.now().toUtc())) {
      ref.read(composerCommandRefusalProvider(_key).notifier).clear();
    }
  }

  /// Replaces `[start, end)` of the draft with [token] and a space, and
  /// leaves the caret after it, in the field.
  void _write(int start, int end, String token) {
    final text = widget.controller.text;
    final before = text.substring(0, start.clamp(0, text.length));
    final after = text.substring(end.clamp(start, text.length)).trimLeft();
    final gap = before.isEmpty || before.endsWith(' ') ? '' : ' ';
    final written = '$before$gap$token ';
    widget.controller.value = TextEditingValue(
      text: '$written$after',
      selection: TextSelection.collapsed(offset: written.length),
    );
    widget.focusNode.requestFocus();
  }

  /// Whether the composer's suggestion list is the one talking: the
  /// command's name is still being written (the list offers the commands),
  /// or the caret is on a when that does not read yet (the list offers its
  /// forms under the same heading this strip would show).
  bool _defersToList(String command, {required bool whenRead}) {
    if (_text.trimLeft().length == command.length + 1) {
      return true;
    }
    return !whenRead &&
        wakeArgumentQuery(_text, _caret)?.step == WakeArgumentStep.when;
  }

  @override
  Widget build(BuildContext context) {
    final refused = ref.watch(composerCommandRefusalProvider(_key));
    final now = DateTime.now().toUtc();
    final wake = readWakeCommand(_text, now: now);
    if (wake != null) {
      return _wake(context, wake, now: now, refused: refused);
    }
    final goal = refused ? goalCommandProblem(_text) : null;
    if (goal == null) {
      return const SizedBox.shrink();
    }
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    return CommandStripFrame(
      icon: AppIcons.triangleAlert,
      iconColor: ds.warn,
      children: [
        Text(
          goalRefusalSentence(l10n, 'goal_command_invalid')!,
          style: CcTypography.caption.copyWith(color: ds.textPrimary),
        ),
        Text(
          inertText(goal, singleLine: true),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: CcTypography.caption.copyWith(color: ds.textTertiary),
        ),
      ],
    );
  }

  Widget _wake(
    BuildContext context,
    WakeCommandReading wake, {
    required DateTime now,
    required bool refused,
  }) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    final draft = wake.draft;
    final issue = wake.issue;
    // A hint names the step that comes next; once the person has moved past
    // a part (or pressed Enter on it), the strip says what is wrong with it.
    final shout = refused && issue != null;
    final named = shout || (issue != null && wake.settled);
    final whenRead =
        draft.hasWhen &&
        issue != WakeCommandIssue.tooOften &&
        issue != WakeCommandIssue.time &&
        issue != WakeCommandIssue.cron;
    final sendable = issue == null || issue == WakeCommandIssue.prompt;
    if (!shout && _defersToList(draft.command, whenRead: whenRead)) {
      return const SizedBox.shrink();
    }
    final note = commandIssueText(
      l10n,
      issue,
      named: named,
      option: draft.option,
      locale: Localizations.localeOf(context).toString(),
    );
    final ends = now.add(
      Duration(days: draft.days ?? WakeRuleBounds.personDefaultExpiry.inDays),
    );
    final quiet = CcTypography.caption.copyWith(color: ds.textTertiary);
    final missing = [
      if (draft.maxRuns == null) '--max',
      if (draft.days == null) '--days',
      if (draft.budgetMicros == null) '--budget',
    ];
    // A token replaces what is being written; past a part left behind it
    // goes in front, so the words after it stay the prompt.
    final whenEnd = wake.settled ? draft.argumentsStart : _text.length;
    final optionStart =
        draft.optionsEnd +
        _text.substring(draft.optionsEnd).length -
        _text.substring(draft.optionsEnd).trimLeft().length;
    return CommandStripFrame(
      icon: shout
          ? AppIcons.triangleAlert
          : wake.repeats
          ? AppIcons.repeat
          : AppIcons.calendarClock,
      iconColor: shout ? ds.warn : ds.fgSecondary,
      trailing: whenRead && sendable && missing.isNotEmpty
          ? CommandLimitsMenu(
              options: missing,
              onSelected: (option) =>
                  _write(draft.optionsEnd, draft.optionsEnd, option),
            )
          : null,
      children: [
        if (whenRead) CommandTriggerReading(reading: wake, now: now),
        if (whenRead && sendable && wake.repeats)
          WorkTime(
            at: ends,
            text: l10n.scheduleExpires(workTimeLabel(context, ends)),
            style: quiet,
          ),
        if (note != null)
          Text(
            note,
            style: CcTypography.caption.copyWith(
              color: shout
                  ? ds.textPrimary
                  : named
                  ? ds.textSecondary
                  : ds.textTertiary,
            ),
          ),
        if (issue == WakeCommandIssue.when)
          for (final token in const [
            'in 2h',
            'at 09:00',
            'cron "$wakeCronWeekdays"',
          ])
            CommandStripToken(
              token,
              onPressed: () => _write(draft.argumentsStart, whenEnd, token),
            ),
        if (issue == WakeCommandIssue.option && named)
          for (final option in missing)
            CommandStripToken(
              option,
              onPressed: () => _write(
                optionStart,
                optionStart + (draft.option?.length ?? 0),
                option,
              ),
            ),
      ],
    );
  }
}
