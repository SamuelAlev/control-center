import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_schedule_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_trigger.dart';
import 'package:control_center/core/utils/money_format.dart';
import 'package:control_center/features/dispatch/presentation/schedule_text.dart';
import 'package:control_center/features/dispatch/presentation/widgets/work_section.dart';
import 'package:control_center/features/dispatch/providers/long_work_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/features/messaging/providers/conversation_work_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A schedule's facts: who it wakes and where, its owner, its next fire (a
/// cron's next three in the viewer's zone), runs, skips, money, end, what a
/// busy fire does, and, for a rule in a chain, the chain's runs left and end
/// (a chain's first rule says its spend counts the whole chain).
class ScheduleFactsSection extends ConsumerWidget {
  /// Creates the section.
  const ScheduleFactsSection({super.key, required this.rule});

  /// The schedule.
  final WakeRuleView rule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final ws = rule.workspaceId;
    String time(DateTime t) => workTimeLabel(context, t);
    final agent =
        ref.watch(
          workAgentNameProvider((workspaceId: ws, agentId: rule.agentId)),
        ) ??
        l10n.workAgentUnknown;
    final where = ref.watch(
      workConversationLabelProvider((
        workspaceId: ws,
        spaceId: rule.spaceId,
        conversationId: rule.conversationId,
      )),
    );
    final owner = rule.ownerUserId == null
        ? null
        : ref.watch(
            workMemberNameProvider((
              workspaceId: ws,
              userId: rule.ownerUserId!,
            )),
          );
    final trigger = ruleTrigger(rule);
    final open = rule.status != WakeRuleStatus.ended;
    final fires = trigger is Cron && open
        ? upcomingFires(rule, DateTime.now().toUtc())
        : const <DateTime>[];
    final next = rule.nextFireAt;
    final last = rule.lastFiredAt;
    final chainEnds = rule.lineageEndsAt;
    // A chain's first schedule counts the runs of every schedule it started
    // in its spend; the page says so when it can see one of them.
    final startsChain =
        rule.rootRuleId == null &&
        (ref
                .watch(workspaceWakeRulesProvider(ws))
                .asData
                ?.value
                .any((r) => r.rootRuleId == rule.id) ??
            false);
    final spent = fmtMicros(rule.costMicros, decimals: 2, locale: locale);
    final cap = fmtMicros(rule.costCapMicros, decimals: 2, locale: locale);
    return WorkSection(
      title: l10n.scheduleSectionFacts,
      child: WorkFactGrid(
        facts: [
          (l10n.scheduleFactAgent, agent),
          (
            l10n.scheduleFactConversation,
            where ?? l10n.scheduleConversationUnknown,
          ),
          (l10n.scheduleFactOwner, owner ?? l10n.scheduleNoOwner),
          if (fires.isNotEmpty)
            (l10n.scheduleFactNextFires, fires.map(time).join(' · '))
          else if (next != null && open)
            (l10n.scheduleFactNext, time(next)),
          if (last != null) (l10n.scheduleFactLast, time(last)),
          (
            l10n.scheduleFactRuns,
            rule.maxRuns == null
                ? l10n.scheduleRunsNoCap(rule.runCount)
                : l10n.scheduleRunsOfCap(rule.runCount, rule.maxRuns!),
          ),
          (l10n.scheduleFactSkips, l10n.scheduleSkips(rule.skipCount)),
          (
            l10n.scheduleFactSpent,
            startsChain
                ? l10n.scheduleSpentWithChain(spent, cap)
                : l10n.goalCardMoney(spent, cap),
          ),
          (l10n.scheduleFactEnds, time(rule.expiresAt)),
          (
            l10n.scheduleFactWhenBusy,
            scheduleWhenBusyLabel(l10n, rule.whenBusy),
          ),
          (l10n.scheduleFactDeliver, scheduleDeliverLabel(l10n, rule.deliver)),
          if (rule.rootRuleId != null)
            (
              l10n.scheduleFactChain,
              l10n.scheduleChainLeft(
                rule.lineageRunsLeft ?? 0,
                chainEnds == null ? '' : time(chainEnds),
              ),
            ),
          (l10n.scheduleFactCreated, time(rule.createdAt)),
        ],
        timestamps: {
          l10n.scheduleFactNext: ?next,
          l10n.scheduleFactLast: ?last,
          l10n.scheduleFactEnds: rule.expiresAt,
          l10n.scheduleFactCreated: rule.createdAt,
        },
      ),
    );
  }
}
