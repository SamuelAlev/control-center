import 'package:cc_domain/features/dispatch/domain/repositories/improvement_proposal_view.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_values.dart';
import 'package:control_center/di/conversation_work_providers.dart';
import 'package:control_center/features/inbox/presentation/models/inbox_attention_item.dart';
import 'package:control_center/features/inbox/providers/inbox_providers.dart';
import 'package:control_center/features/messaging/providers/goal_card_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/app_router.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The workspace's improvement proposals still waiting for a decision.
final proposedImprovementsProvider = StreamProvider.autoDispose
    .family<List<ImprovementProposalView>, String>(
      (ref, workspaceId) => ref
          .watch(improvementInboxRepositoryProvider)
          .watchForWorkspace(workspaceId, status: ImprovementStatus.proposed),
    );

/// Goals waiting for this person: in review when the server says this viewer
/// may approve its completion (`can_approve`), or needing a person when it
/// says they may resume it (`can_resume`), so the strip never lists another
/// person's goal as theirs to act on. Each opens the goal.
class GoalsNeedingPersonSource implements InboxAttentionSource {
  @override
  String get id => 'goals-needing-person';

  @override
  List<InboxAttentionItem> buildItems(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return const [];
    }
    final views =
        ref.watch(workspaceGoalRunsProvider(workspaceId)).asData?.value ??
        const [];
    final router = ref.read(routerProvider);
    return [
      for (final v in views)
        if (!v.goal.status.isTerminal &&
            switch (v.goal.hold) {
              GoalHold.needsReview => v.canApprove,
              GoalHold.person => v.canResume,
              _ => false,
            })
          InboxAttentionItem(
            id: 'goal:${v.goal.id}',
            severity: InboxAttentionSeverity.blocking,
            title: v.goal.hold == GoalHold.needsReview
                ? l10n.inboxGoalNeedsReview
                : l10n.inboxGoalNeedsPerson,
            subtitle: v.goal.userText,
            icon: AppIcons.target,
            actionLabel: l10n.inboxReview,
            waitingSince: v.goal.updatedAt,
            onAction: () => router.go(goalRoute(workspaceId, v.goal.id)),
          ),
    ];
  }
}

/// Improvement proposals waiting for a decision. Each opens the proposal,
/// whose page says when deciding takes an admin.
class ImprovementsProposedSource implements InboxAttentionSource {
  @override
  String get id => 'improvements-proposed';

  @override
  List<InboxAttentionItem> buildItems(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return const [];
    }
    final proposals =
        ref.watch(proposedImprovementsProvider(workspaceId)).asData?.value ??
        const [];
    final router = ref.read(routerProvider);
    return [
      for (final ImprovementProposalView(proposal: p) in proposals)
        InboxAttentionItem(
          id: 'improvement:${p.id}',
          severity: InboxAttentionSeverity.info,
          title: l10n.inboxImprovementProposed,
          subtitle: p.expected,
          icon: AppIcons.lightbulb,
          actionLabel: l10n.inboxReview,
          waitingSince: p.createdAt,
          onAction: () => router.go(improvementRoute(workspaceId, p.id)),
        ),
    ];
  }
}
