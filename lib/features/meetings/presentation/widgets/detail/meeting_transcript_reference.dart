import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_common.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_transcript_row.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';

/// The Notes tab's transcript excerpt: the opening lines of the transcript and
/// a link to the full Transcript tab, which only appears when there is one.
class MeetingTranscriptReference extends StatelessWidget {
  /// Creates a [MeetingTranscriptReference].
  const MeetingTranscriptReference({
    super.key,
    required this.segments,
    required this.onViewFullTranscript,
  });

  /// The meeting's transcript segments; the first few are shown.
  final List<MeetingSegment> segments;

  /// Switches to the Transcript tab.
  final VoidCallback onViewFullTranscript;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    final preview = segments.take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: kMeetingNotesHeadingHeight,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: MeetingEyebrow(l10n.meetingTabTranscript),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: AppRadii.brMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (preview.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      l10n.meetingTranscriptEmpty,
                      style: TextStyle(color: ds.muted),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 420),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: preview.length,
                      separatorBuilder: (_, _) =>
                          CcDivider(color: ds.borderSecondary),
                      itemBuilder: (context, i) =>
                          MeetingTranscriptRow.fromSegment(
                            preview[i],
                            compact: true,
                            timeColumnWidth: 46,
                          ),
                    ),
                  ),
                if (preview.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: ds.borderSecondary),
                      ),
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: CcButton(
                        variant: CcButtonVariant.secondary,
                        size: CcButtonSize.sm,
                        onPressed: onViewFullTranscript,
                        child: Text(l10n.meetingViewFullTranscript),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
