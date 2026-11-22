import 'package:cc_domain/cc_domain.dart' show AgentDto;
import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_schedule_repository.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_when.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_remote/format.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/plan_goal/plan_review.dart';
import 'package:cc_remote/widgets/work/work_text.dart';
import 'package:cc_remote/work_kind_text.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What wakes a schedule, in words. Null when the trigger is a form this
/// version cannot word (the caller shows it in code style).
String? scheduleTriggerText(BuildContext context, WakeRuleView rule) {
  final l = AppLocalizations.of(context);
  final colon = rule.trigger.indexOf(':');
  final value = colon < 0 ? '' : rule.trigger.substring(colon + 1);
  switch (rule.triggerKind) {
    case 'every':
      final interval = parseWakeDuration(value);
      return interval == null
          ? null
          : l.scheduleEvery(shortDuration(context, interval));
    case 'self_paced':
      return l.scheduleSelfPacedLoop;
    case 'cron':
      return l.scheduleCron;
    case 'at':
      final at = parseWakeInstant(value);
      return at == null ? null : l.scheduleOnce(workTime(context, at));
    case 'on_event':
      final event = value.split(':').first;
      final name = switch (event) {
        'pr_checks' => l.scheduleWatchPrChecks,
        'pr_review' => l.scheduleWatchPrReview,
        'pr_merged' => l.scheduleWatchPrMerged,
        'environment' => l.scheduleWatchEnvironment,
        'ticket' => l.scheduleWatchTicket,
        'pipeline_run' => l.scheduleWatchPipelineRun,
        _ => null,
      };
      return name == null ? null : l.scheduleWatch(name);
  }
  return null;
}

String scheduleStatusLabel(AppLocalizations l, WakeRuleStatus status) =>
    switch (status) {
      WakeRuleStatus.active => l.scheduleStatusActive,
      WakeRuleStatus.paused => l.scheduleStatusPaused,
      WakeRuleStatus.ended => l.scheduleStatusEnded,
    };

/// One schedule or watch: what wakes it and which agent, its status, next
/// and last run, runs and money against their caps, when it ends, whom it
/// acts for, and (in [full]) its note, its cron or watch target and why it
/// ended. The note is the person's or the agent's own text.
class ScheduleSummary extends ConsumerWidget {
  const ScheduleSummary({super.key, required this.rule, this.full = false});

  final WakeRuleView rule;
  final bool full;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l = AppLocalizations.of(context);
    final agents = ref.watch(agentsProvider).value ?? const <AgentDto>[];
    final users = ref.watch(remoteUsersProvider).value ?? const {};
    final agent = agents.where((a) => a.id == rule.agentId).firstOrNull;
    final trigger = scheduleTriggerText(context, rule);
    final caption = CcTypography.caption.copyWith(color: t.textSecondary);
    final ended = rule.status == WakeRuleStatus.ended;
    final owner = rule.ownerUserId == null ? null : users[rule.ownerUserId];
    final ownerName = owner == null
        ? null
        : owner.displayName.isEmpty
        ? owner.handle
        : owner.displayName;
    final codePart =
        rule.triggerKind == 'cron' || rule.triggerKind == 'on_event'
        ? rule.trigger
        : null;
    final endText = wakeRuleEndSentence(l, rule.endReason?.wire);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: trigger == null
                  ? WorkCode(rule.trigger)
                  : Text(
                      trigger,
                      style: CcTypography.body.copyWith(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            CcBadge(
              label: scheduleStatusLabel(l, rule.status),
              variant: rule.status == WakeRuleStatus.active
                  ? CcBadgeVariant.success
                  : CcBadgeVariant.neutral,
            ),
          ],
        ),
        if (full && codePart != null && trigger != null) ...[
          const SizedBox(height: 4),
          WorkCode(codePart),
        ],
        const SizedBox(height: 6),
        if (agent != null) Text(l.scheduleWakes(agent.name), style: caption),
        Wrap(
          spacing: 10,
          runSpacing: 2,
          children: [
            if (!ended && rule.nextFireAt != null)
              Text(
                l.scheduleNext(workTime(context, rule.nextFireAt!)),
                style: caption,
              ),
            if (rule.lastFiredAt != null)
              Text(
                l.scheduleLast(shortAgo(context, rule.lastFiredAt)),
                style: caption,
              ),
            Text(
              rule.maxRuns == null
                  ? l.scheduleRuns(rule.runCount)
                  : l.scheduleRunsOf(rule.runCount, rule.maxRuns!),
              style: caption,
            ),
            if (rule.skipCount > 0)
              Text(l.scheduleSkipped(rule.skipCount), style: caption),
            Text(
              l.goalMoney(
                planMoney(context, rule.costMicros),
                planMoney(context, rule.costCapMicros),
              ),
              style: caption,
            ),
            if (!ended)
              Text(
                l.scheduleEnds(workTime(context, rule.expiresAt)),
                style: caption,
              ),
          ],
        ),
        if (ended && endText != null) ...[
          const SizedBox(height: 4),
          Text(endText, style: caption),
        ],
        if (full) ...[
          const SizedBox(height: 10),
          if (rule.ownerUserId == null)
            Text(l.scheduleActsForBot, style: caption)
          else if (ownerName != null)
            Text(l.scheduleActsFor(ownerName), style: caption),
          if (rule.goalId != null) Text(l.scheduleGoalBound, style: caption),
          if (rule.lineageRunsLeft != null && rule.lineageEndsAt != null)
            Text(
              l.scheduleChain(
                rule.lineageRunsLeft!,
                workTime(context, rule.lineageEndsAt!),
              ),
              style: caption,
            ),
          if (rule.note.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              rule.noteAuthor == WakeRuleOrigin.agent
                  ? l.scheduleNoteAgent
                  : l.scheduleNotePerson,
              style: caption,
            ),
            const SizedBox(height: 4),
            WorkQuote(rule.note),
          ],
        ] else if (rule.note.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          WorkQuote(rule.note, maxLines: 2),
        ],
      ],
    );
  }
}
