import 'dart:async';

import 'package:cc_domain/features/dispatch/domain/repositories/goal_run_view.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/improvement_proposal_view.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_schedule_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_limits.dart';
import 'package:control_center/di/conversation_work_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/providers/goal_card_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One record of a workspace: the key of the Goals, Schedules and
/// Improvements pages.
typedef WorkRecordKey = ({String workspaceId, String id});

/// One goal as this viewer sees it, live: loading while the workspace's
/// goals load, an error when the watch is refused, and null when the goal is
/// not among those the viewer may see (gone, or in a space they cannot read).
final goalRunViewProvider = Provider.autoDispose
    .family<AsyncValue<GoalRunView?>, WorkRecordKey>(
      (ref, key) => ref
          .watch(workspaceGoalRunsProvider(key.workspaceId))
          .whenData(
            (goals) => goals.where((v) => v.goal.id == key.id).firstOrNull,
          ),
    );

/// Every schedule and watch of the workspace in a space the viewer may read,
/// newest first (`wakeRules.watchForWorkspace`).
final workspaceWakeRulesProvider = StreamProvider.autoDispose
    .family<List<WakeRuleView>, String>(
      (ref, workspaceId) => ref
          .watch(wakeRuleScheduleRepositoryProvider)
          .watchForWorkspace(workspaceId),
    );

/// One schedule, live, like [goalRunViewProvider].
final wakeRuleViewProvider = Provider.autoDispose
    .family<AsyncValue<WakeRuleView?>, WorkRecordKey>(
      (ref, key) => ref
          .watch(workspaceWakeRulesProvider(key.workspaceId))
          .whenData((rules) => rules.where((r) => r.id == key.id).firstOrNull),
    );

/// The workspace's limits on schedules (`wakeRules.getLimits`).
final wakeRuleLimitsProvider = FutureProvider.autoDispose
    .family<WakeRuleLimits, String>(
      (ref, workspaceId) =>
          ref.watch(wakeRuleScheduleRepositoryProvider).limits(workspaceId),
    );

/// A draft cron schedule the New schedule dialog previews, or (empty
/// expression) a zone the dialog or the limits section checks.
typedef CronPreviewKey = ({
  String workspaceId,
  String expression,
  String timeZone,
});

/// How long the dialog waits after the last keystroke before it asks.
const cronPreviewDebounce = Duration(milliseconds: 400);

/// The next fire times of a draft cron and the verdict on its zone,
/// computed by the server (`wakeRules.previewCron`; an empty expression
/// asks about the zone alone): the client carries no zone database. Asked
/// [cronPreviewDebounce] after the key last changed, so typing does not
/// send an op per keystroke; a key left before then asks nothing.
final cronPreviewProvider = FutureProvider.autoDispose
    .family<CronPreview, CronPreviewKey>((ref, key) async {
      final repo = ref.watch(wakeRuleScheduleRepositoryProvider);
      final waited = Completer<bool>();
      final timer = Timer(cronPreviewDebounce, () => waited.complete(true));
      ref.onDispose(() {
        timer.cancel();
        if (!waited.isCompleted) {
          waited.complete(false);
        }
      });
      if (!await waited.future) {
        return (nextFires: const <DateTime>[], zoneKnown: true);
      }
      return repo.previewCron(
        key.workspaceId,
        expression: key.expression,
        timeZone: key.timeZone,
      );
    });

/// Every improvement proposal of the workspace the viewer may read, newest
/// first, each with the server's `needs_admin`
/// (`improvements.watchForWorkspace`).
final workspaceImprovementsProvider = StreamProvider.autoDispose
    .family<List<ImprovementProposalView>, String>(
      (ref, workspaceId) => ref
          .watch(improvementInboxRepositoryProvider)
          .watchForWorkspace(workspaceId, status: null),
    );

/// One proposal, live, like [goalRunViewProvider].
final improvementViewProvider = Provider.autoDispose
    .family<AsyncValue<ImprovementProposalView?>, WorkRecordKey>(
      (ref, key) => ref
          .watch(workspaceImprovementsProvider(key.workspaceId))
          .whenData(
            (all) => all.where((v) => v.proposal.id == key.id).firstOrNull,
          ),
    );

/// A member's display name in a workspace, or null while the members load or
/// when the person is no longer a member. Names are data: plain text.
final workMemberNameProvider = Provider.autoDispose
    .family<String?, ({String workspaceId, String userId})>((ref, key) {
      final members = ref
          .watch(workspaceMembersProvider(key.workspaceId))
          .asData
          ?.value;
      for (final m in members ?? const <Never>[]) {
        if (m.userId == key.userId) {
          final name = m.displayName?.trim();
          return name == null || name.isEmpty ? m.email : name;
        }
      }
      return null;
    });

/// Where a record lives, in words: the space's name and the conversation's
/// title (`Space · Conversation`), or whichever is known while they load.
final workConversationLabelProvider = Provider.autoDispose
    .family<
      String?,
      ({String workspaceId, String spaceId, String conversationId})
    >((ref, key) {
      final spaces = ref
          .watch(workspaceSpacesProvider(key.workspaceId))
          .asData
          ?.value;
      final space = spaces?.where((s) => s.id == key.spaceId).firstOrNull;
      final conversations = key.spaceId.isEmpty
          ? null
          : ref.watch(spaceConversationsProvider(key.spaceId)).asData?.value;
      final conversation = conversations
          ?.where((c) => c.id == key.conversationId)
          .firstOrNull;
      final parts = [
        if (space != null && space.name.trim().isNotEmpty) space.name.trim(),
        if (conversation != null && conversation.title.trim().isNotEmpty)
          conversation.title.trim(),
      ];
      return parts.isEmpty ? null : parts.join(' · ');
    });
