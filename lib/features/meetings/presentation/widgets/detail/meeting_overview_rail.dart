import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_decision.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/meetings/presentation/widgets/detail/meeting_overview_lists.dart';
import 'package:control_center/features/meetings/presentation/widgets/detail/meeting_overview_speakers.dart';
import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How [MeetingOverviewRail] arranges its sections.
enum MeetingOverviewLayout {
  /// One panel, sections stacked top to bottom (the side rail, or phone).
  stacked,

  /// Sections side by side under the notes (mid-width windows).
  row,
}

/// The facts a reader wants beside the notes: who spoke and for how long, the
/// open action items and the decisions. Each section previews its tab and links
/// to it, and the empty ones offer the hand-entry the tab would.
class MeetingOverviewRail extends ConsumerWidget {
  /// Creates a [MeetingOverviewRail].
  const MeetingOverviewRail({
    super.key,
    required this.meeting,
    required this.segments,
    required this.actionItems,
    required this.decisions,
    required this.onViewActionItems,
    required this.onViewDecisions,
    this.layout = MeetingOverviewLayout.stacked,
  });

  /// The meeting being viewed.
  final Meeting meeting;

  /// Transcript segments, for the talk-time breakdown.
  final List<MeetingSegment> segments;

  /// The meeting's action items.
  final List<MeetingActionItem> actionItems;

  /// The meeting's decisions.
  final List<MeetingDecision> decisions;

  /// Switches to the Action items tab.
  final VoidCallback onViewActionItems;

  /// Switches to the Decisions tab.
  final VoidCallback onViewDecisions;

  /// Stacked or side by side.
  final MeetingOverviewLayout layout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.ds;
    final speakers =
        ref
            .watch(
              meetingSpeakersProvider((
                workspaceId: meeting.workspaceId,
                meetingId: meeting.id,
              )),
            )
            .asData
            ?.value ??
        const [];
    final names = {for (final s in speakers) s.label: s.displayName};
    final sections = <Widget>[
      MeetingOverviewSpeakers(
        talk: MeetingTalkTime.from(segments),
        names: names,
      ),
      MeetingOverviewActionItems(
        meeting: meeting,
        items: actionItems,
        onViewAll: onViewActionItems,
      ),
      MeetingOverviewDecisions(
        meeting: meeting,
        decisions: decisions,
        onViewAll: onViewDecisions,
      ),
    ];
    if (layout == MeetingOverviewLayout.row) {
      return SectionCard(
        padding: EdgeInsets.zero,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < sections.length; i++) ...[
                if (i > 0)
                  CcDivider(axis: Axis.vertical, color: ds.borderSecondary),
                Expanded(child: sections[i]),
              ],
            ],
          ),
        ),
      );
    }
    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) CcDivider(color: ds.borderSecondary),
            sections[i],
          ],
        ],
      ),
    );
  }
}
