import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The Enhanced notes pane when there are no enhanced notes: why, and the next
/// step. With a transcript that is generating notes from it (or writing your
/// own); without one there is nothing to summarize, so only your own notes are
/// offered. Holds a document-sized minimum height so the notes column still
/// reads as the page's main surface while it is empty.
class MeetingNotesEmptyState extends StatelessWidget {
  /// Creates a [MeetingNotesEmptyState].
  const MeetingNotesEmptyState({
    super.key,
    required this.meeting,
    required this.hasTranscript,
    required this.onGenerate,
    required this.onWriteOwn,
  });

  /// The meeting being viewed.
  final Meeting meeting;

  /// Whether the meeting has any transcript to summarize.
  final bool hasTranscript;

  /// Starts the summary pipeline.
  final VoidCallback onGenerate;

  /// Switches the pane to "Your notes".
  final VoidCallback onWriteOwn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pending =
        meeting.status == MeetingStatus.processing ||
        meeting.status == MeetingStatus.recording;
    final writeOwn = CcButton(
      variant: CcButtonVariant.secondary,
      size: CcButtonSize.sm,
      icon: AppIcons.notebookPen,
      onPressed: onWriteOwn,
      child: Text(
        meeting.userNotes.trim().isEmpty
            ? l10n.meetingNotesWriteOwn
            : l10n.meetingNotesYoursToggle,
      ),
    );

    final Widget state;
    if (pending) {
      state = CcEmptyState(
        icon: AppIcons.sparkles,
        iconSize: 28,
        message: l10n.meetingEnhancedPending,
      );
    } else if (hasTranscript) {
      state = CcEmptyState(
        icon: AppIcons.sparkles,
        iconSize: 28,
        maxWidth: 420,
        message: l10n.meetingNotesEmpty,
        description: l10n.meetingNotesEmptyDescription,
        action: Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            CcButton(
              size: CcButtonSize.sm,
              icon: AppIcons.sparkles,
              onPressed: onGenerate,
              child: Text(l10n.meetingNotesGenerate),
            ),
            writeOwn,
          ],
        ),
      );
    } else {
      state = CcEmptyState(
        icon: AppIcons.audioLines,
        iconSize: 28,
        maxWidth: 420,
        message: l10n.meetingNothingTranscribed,
        description: l10n.meetingNothingTranscribedDescription,
        action: writeOwn,
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 320),
      child: Center(child: state),
    );
  }
}
