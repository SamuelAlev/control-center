import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_limits.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_trigger.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/utils/money_format.dart';
import 'package:control_center/features/dispatch/providers/long_work_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/features/messaging/providers/composer_command_refusal.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What fires the command, in words: the same sentences the schedules page
/// uses. A wall clock and a cron are placed in time by the server, which
/// knows the workspace's zone; until it answers a clock reads as written
/// and a cron as its kind.
class CommandTriggerReading extends ConsumerWidget {
  /// Creates the reading.
  const CommandTriggerReading({
    super.key,
    required this.reading,
    required this.now,
  });

  /// The command.
  final WakeCommandReading reading;

  /// The instant the strip was built at.
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    final style = CcTypography.caption.copyWith(
      color: ds.fgSecondary,
      fontWeight: FontWeight.w600,
    );
    Widget once(DateTime at) => WorkTime(
      at: at,
      text: l10n.scheduleTriggerOnce(workTimeLabel(context, at)),
      style: style,
    );
    final clock = reading.draft.clock;
    switch (reading.trigger) {
      case OnceAt(:final at):
        return once(at);
      case Every(:final interval):
        return Text(
          l10n.scheduleTriggerEvery(workDurationLabel(interval)),
          style: style,
        );
      case SelfPaced():
        return Text(l10n.scheduleTriggerSelfPaced, style: style);
      case Cron(:final expression):
        final fires = _fires(ref, expression);
        return Text(
          fires.isEmpty
              ? l10n.scheduleWhenCron
              : l10n.scheduleNextFires(
                  fires
                      .take(3)
                      .map((f) => workTimeLabel(context, f))
                      .join(' · '),
                ),
          style: style,
        );
      case null when clock != null:
        // The next HH:MM in the workspace's zone is the next fire of the
        // cron that fires daily at HH:MM there.
        final fires = _fires(ref, '${clock.minute} ${clock.hour} * * *');
        if (fires.isNotEmpty) {
          return once(fires.first);
        }
        final today = DateTime.now();
        final written = DateTime(
          today.year,
          today.month,
          today.day,
          clock.hour,
          clock.minute,
        );
        return Text(
          l10n.scheduleTriggerOnce(workTimeLabel(context, written)),
          style: style,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// The next fires of [expression] in the workspace's zone, as the server
  /// computes them; empty until it answers.
  List<DateTime> _fires(WidgetRef ref, String expression) {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return const [];
    }
    final preview = ref
        .watch(
          cronPreviewProvider((
            workspaceId: workspaceId,
            expression: expression,
            timeZone: '',
          )),
        )
        .value;
    return [
      for (final f in preview?.nextFires ?? const <DateTime>[])
        if (f.isAfter(now)) f,
    ];
  }
}

/// What the strip says about [issue]: the name of the step still to write
/// while it is only a hint, the sentence about what is wrong once it is
/// [named]. Null when there is nothing to say.
String? commandIssueText(
  AppLocalizations l10n,
  WakeCommandIssue? issue, {
  required bool named,
  required String? option,
  required String locale,
}) => switch (issue) {
  null => null,
  WakeCommandIssue.when => l10n.scheduleWhenLabel,
  WakeCommandIssue.prompt => l10n.scheduleNoteLabel,
  WakeCommandIssue.tooOften => l10n.scheduleDurationHelp,
  WakeCommandIssue.duration =>
    named ? l10n.scheduleDurationInvalid : l10n.scheduleWhenLabel,
  WakeCommandIssue.time =>
    named ? l10n.scheduleTimeInvalid : l10n.scheduleWhenLabel,
  WakeCommandIssue.cron =>
    named ? l10n.scheduleCronInvalid : l10n.scheduleWhenLabel,
  WakeCommandIssue.maxRuns =>
    named
        ? l10n.scheduleMaxRunsRange(WakeRuleBounds.maxRunsCeiling)
        : l10n.scheduleMaxRuns,
  WakeCommandIssue.days =>
    named
        ? l10n.scheduleDaysRange(WakeRuleBounds.personMaxExpiry.inDays)
        : l10n.scheduleExpiresInDays,
  WakeCommandIssue.budget =>
    named
        ? l10n.scheduleCostCapRange(
            fmtMicros(WakeRuleLimits.maxCostCapMicros, locale: locale),
          )
        : l10n.scheduleCostCap,
  WakeCommandIssue.option =>
    named && option != null ? l10n.scheduleOptionUnknown(option) : null,
};
