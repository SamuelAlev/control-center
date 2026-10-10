import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_decision.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/features/meetings/presentation/widgets/detail/meeting_action_items_tab.dart';
import 'package:control_center/features/meetings/presentation/widgets/detail/meeting_decisions_tab.dart';
import 'package:control_center/features/meetings/presentation/widgets/detail/meeting_overview_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The open action items, checkable in place, with links to the tab and to
/// add one by hand.
class MeetingOverviewActionItems extends ConsumerWidget {
  /// Creates a [MeetingOverviewActionItems].
  const MeetingOverviewActionItems({
    super.key,
    required this.meeting,
    required this.items,
    required this.onViewAll,
  });

  /// The meeting the items belong to.
  final Meeting meeting;

  /// All of the meeting's action items, done or not.
  final List<MeetingActionItem> items;

  /// Switches to the Action items tab.
  final VoidCallback onViewAll;

  static const _shown = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    final open = items.where((i) => !i.done).toList();
    final Widget body;
    if (items.isEmpty) {
      body = MeetingOverviewNote(l10n.meetingActionItemsEmpty);
    } else if (open.isEmpty) {
      body = Row(
        children: [
          Icon(AppIcons.circleCheck, size: 14, color: ds.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: MeetingOverviewNote(l10n.meetingOverviewActionItemsAllDone),
          ),
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in open.take(_shown))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CcCheckbox(
                    value: false,
                    semanticLabel: item.content,
                    onChanged: (_) => ref
                        .read(meetingRepositoryProvider)
                        .setActionItemDone(
                          workspaceId: meeting.workspaceId,
                          id: item.id,
                          done: true,
                        ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: ds.fg,
                          ),
                        ),
                        if (item.owner != null && item.owner!.isNotEmpty)
                          Text(
                            item.owner!,
                            style: meetingMono(context, fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }
    return MeetingOverviewSection(
      title: l10n.meetingTabActionItems,
      count: items.isEmpty ? null : items.length,
      footer: [
        if (items.isNotEmpty)
          MeetingOverviewLink(
            label: l10n.meetingOverviewViewAll(items.length),
            onPressed: onViewAll,
          ),
        MeetingOverviewLink(
          icon: AppIcons.plus,
          label: l10n.meetingAddActionItem,
          onPressed: () =>
              showAddMeetingActionItemDialog(context, ref, meeting),
        ),
      ],
      child: body,
    );
  }
}

/// The first few decisions, with links to the tab and to add one by hand.
class MeetingOverviewDecisions extends ConsumerWidget {
  /// Creates a [MeetingOverviewDecisions].
  const MeetingOverviewDecisions({
    super.key,
    required this.meeting,
    required this.decisions,
    required this.onViewAll,
  });

  /// The meeting the decisions belong to.
  final Meeting meeting;

  /// The meeting's decisions.
  final List<MeetingDecision> decisions;

  /// Switches to the Decisions tab.
  final VoidCallback onViewAll;

  static const _shown = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    return MeetingOverviewSection(
      title: l10n.meetingTabDecisions,
      count: decisions.isEmpty ? null : decisions.length,
      footer: [
        if (decisions.isNotEmpty)
          MeetingOverviewLink(
            label: l10n.meetingOverviewViewAll(decisions.length),
            onPressed: onViewAll,
          ),
        MeetingOverviewLink(
          icon: AppIcons.plus,
          label: l10n.meetingAddDecision,
          onPressed: () => showAddMeetingDecisionDialog(context, ref, meeting),
        ),
      ],
      child: decisions.isEmpty
          ? MeetingOverviewNote(l10n.meetingDecisionsEmpty)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final d in decisions.take(_shown))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Icon(AppIcons.flag, size: 12, color: ds.muted),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            d.content,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: ds.fg,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
