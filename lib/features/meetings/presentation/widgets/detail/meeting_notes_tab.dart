import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_decision.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_markdown/cc_markdown.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/features/meetings/presentation/widgets/detail/meeting_notes_editor.dart';
import 'package:control_center/features/meetings/presentation/widgets/detail/meeting_notes_empty_state.dart';
import 'package:control_center/features/meetings/presentation/widgets/detail/meeting_overview_rail.dart';
import 'package:control_center/features/meetings/presentation/widgets/detail/meeting_transcript_reference.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_common.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/markdown/markdown_image.dart';
import 'package:control_center/shared/widgets/markdown/markdown_registries.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';

/// Which version of the notes the Notes tab is showing.
enum MeetingNotesMode {
  /// The AI-augmented notes.
  enhanced,

  /// The user's own raw notes (editable).
  yours,
}

/// The Notes tab, the meeting's overview: the notes editor (Enhanced ↔ Your
/// notes toggle), a transcript excerpt and the [MeetingOverviewRail] of
/// speakers, action items and decisions.
///
/// Wide windows lay the three side by side; mid-width ones keep notes and
/// transcript paired and run the overview as a band beneath them; narrow ones
/// stack everything.
class MeetingNotesTab extends StatelessWidget {
  /// Creates a [MeetingNotesTab].
  const MeetingNotesTab({
    super.key,
    required this.meeting,
    required this.mode,
    required this.onModeChanged,
    required this.notesController,
    required this.onNotesChanged,
    required this.savingLabel,
    required this.segments,
    required this.actionItems,
    required this.decisions,
    required this.onViewFullTranscript,
    required this.onViewActionItems,
    required this.onViewDecisions,
    required this.onGenerateNotes,
  });

  /// The meeting being viewed.
  final Meeting meeting;

  /// The active notes mode.
  final MeetingNotesMode mode;

  /// Invoked when the Enhanced/Your-notes toggle changes.
  final ValueChanged<MeetingNotesMode> onModeChanged;

  /// Controller for the editable "your notes" field.
  final TextEditingController notesController;

  /// Invoked as the user edits their notes.
  final ValueChanged<String> onNotesChanged;

  /// "Saved locally" / "Saving…" status text.
  final String savingLabel;

  /// Transcript segments (first few are shown as a reference).
  final List<MeetingSegment> segments;

  /// The meeting's action items, previewed in the overview.
  final List<MeetingActionItem> actionItems;

  /// The meeting's decisions, previewed in the overview.
  final List<MeetingDecision> decisions;

  /// Invoked when "View full transcript" is pressed.
  final VoidCallback onViewFullTranscript;

  /// Switches to the Action items tab.
  final VoidCallback onViewActionItems;

  /// Switches to the Decisions tab.
  final VoidCallback onViewDecisions;

  /// Starts the summary pipeline from the empty Enhanced pane.
  final VoidCallback onGenerateNotes;

  /// Width at which the overview becomes a third column.
  static const double _wideBreakpoint = 1400;

  /// Width below which everything stacks.
  static const double _narrowBreakpoint = 880;

  /// Width of the overview column on wide windows.
  static const double _railWidth = 320;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final notes = _NotesColumn(
          meeting: meeting,
          mode: mode,
          onModeChanged: onModeChanged,
          notesController: notesController,
          onNotesChanged: onNotesChanged,
          savingLabel: savingLabel,
          hasTranscript: segments.isNotEmpty,
          onGenerateNotes: onGenerateNotes,
        );
        // A finished meeting with no transcript has nothing to excerpt, and
        // the notes pane already says so; the column would only repeat it.
        final transcribed =
            meeting.status == MeetingStatus.done ||
            meeting.status == MeetingStatus.failed;
        final transcript = segments.isEmpty && transcribed
            ? null
            : MeetingTranscriptReference(
                segments: segments,
                onViewFullTranscript: onViewFullTranscript,
              );
        MeetingOverviewRail overview(MeetingOverviewLayout layout) =>
            MeetingOverviewRail(
              meeting: meeting,
              segments: segments,
              actionItems: actionItems,
              decisions: decisions,
              onViewActionItems: onViewActionItems,
              onViewDecisions: onViewDecisions,
              layout: layout,
            );
        final width = constraints.maxWidth;
        if (width < _narrowBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              notes,
              if (transcript != null) ...[
                const SizedBox(height: AppSpacing.lg),
                transcript,
              ],
              const SizedBox(height: AppSpacing.lg),
              overview(MeetingOverviewLayout.stacked),
            ],
          );
        }
        final pair = [
          Expanded(flex: 118, child: notes),
          if (transcript != null) ...[
            const SizedBox(width: AppSpacing.lg),
            Expanded(flex: 82, child: transcript),
          ],
        ];
        if (width < _wideBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: pair),
              const SizedBox(height: AppSpacing.lg),
              overview(MeetingOverviewLayout.row),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...pair,
            const SizedBox(width: AppSpacing.lg),
            SizedBox(
              width: _railWidth,
              child: Padding(
                // Clears the column headings beside it so the three panels
                // share a top edge.
                padding: const EdgeInsets.only(
                  top: kMeetingNotesHeadingHeight + AppSpacing.md,
                ),
                child: overview(MeetingOverviewLayout.stacked),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NotesColumn extends StatelessWidget {
  const _NotesColumn({
    required this.meeting,
    required this.mode,
    required this.onModeChanged,
    required this.notesController,
    required this.onNotesChanged,
    required this.savingLabel,
    required this.hasTranscript,
    required this.onGenerateNotes,
  });

  final Meeting meeting;
  final MeetingNotesMode mode;
  final ValueChanged<MeetingNotesMode> onModeChanged;
  final TextEditingController notesController;
  final ValueChanged<String> onNotesChanged;
  final String savingLabel;
  final bool hasTranscript;
  final VoidCallback onGenerateNotes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: kMeetingNotesHeadingHeight,
          child: Row(
            children: [
              MeetingEyebrow(l10n.meetingTabNotes),
              const Spacer(),
              CcSegmentedToggle<MeetingNotesMode>(
                value: mode,
                onChanged: onModeChanged,
                segments: [
                  CcSegment(
                    value: MeetingNotesMode.enhanced,
                    label: l10n.meetingNotesEnhancedToggle,
                  ),
                  CcSegment(
                    value: MeetingNotesMode.yours,
                    label: l10n.meetingNotesYoursToggle,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: mode == MeetingNotesMode.enhanced
              ? _EnhancedNotes(
                  meeting: meeting,
                  hasTranscript: hasTranscript,
                  onGenerate: onGenerateNotes,
                  onWriteOwn: () => onModeChanged(MeetingNotesMode.yours),
                )
              : _YourNotes(
                  controller: notesController,
                  onChanged: onNotesChanged,
                  savingLabel: savingLabel,
                ),
        ),
      ],
    );
  }
}

class _EnhancedNotes extends StatelessWidget {
  const _EnhancedNotes({
    required this.meeting,
    required this.hasTranscript,
    required this.onGenerate,
    required this.onWriteOwn,
  });

  final Meeting meeting;
  final bool hasTranscript;
  final VoidCallback onGenerate;
  final VoidCallback onWriteOwn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pending =
        meeting.status == MeetingStatus.processing ||
        meeting.status == MeetingStatus.recording;
    if (pending || !meeting.isEnhanced) {
      return MeetingNotesEmptyState(
        meeting: meeting,
        hasTranscript: hasTranscript,
        onGenerate: onGenerate,
        onWriteOwn: onWriteOwn,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EnhancedTag(label: l10n.meetingEnhancedByAgent),
        const SizedBox(height: AppSpacing.lg),
        CcMarkdown(
          data: meeting.enhancedNotes!,
          selectable: true,
          style: _notesStyle(context),
          plugins: githubMarkdownPlugins,
          options: githubMarkdownOptions,
          builders: githubMarkdownBuilders,
          imageBuilder: appMarkdownImageBuilder,
          codeBuilder: sharedCodeBuilder(),
        ),
      ],
    );
  }
}

class _EnhancedTag extends StatelessWidget {
  const _EnhancedTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: context.mAccentSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.sparkles, size: 12, color: context.mAccent),
          const SizedBox(width: 5),
          Text(
            label,
            style: meetingMono(context, fontSize: 11, color: context.mAccent),
          ),
        ],
      ),
    );
  }
}

class _YourNotes extends StatelessWidget {
  const _YourNotes({
    required this.controller,
    required this.onChanged,
    required this.savingLabel,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String savingLabel;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MeetingNotesEditor(
          controller: controller,
          onChanged: onChanged,
          hintText: l10n.meetingNotesHint,
          minLines: 10,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: ds.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(savingLabel, style: meetingMono(context, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

/// A compact [CcMarkdownStyle] for enhanced notes: mono uppercase headings
/// and orange list markers, matching the design.
///
/// Derived from the unified [appMarkdownStyle] (so code/inline-chip styling
/// stays identical to PR descriptions, chat and ticket surfaces) with the
/// bespoke mono-heading / accent-bullet treatment layered on top.
CcMarkdownStyle _notesStyle(BuildContext context) {
  final ds = context.ds;
  final base = appMarkdownStyle(context);
  final mono = meetingMono(
    context,
    fontSize: 11,
    color: ds.muted,
    letterSpacing: 0.8,
  );
  const headingPad = EdgeInsets.only(top: 18);
  return base.copyWith(
    paragraph: TextStyle(fontSize: 14, height: 1.62, color: ds.fg),
    h1: mono,
    h2: mono,
    h3: mono,
    h4: mono,
    h5: mono,
    h6: mono,
    h1Padding: headingPad,
    h2Padding: headingPad,
    h3Padding: headingPad,
    h4Padding: headingPad,
    listBullet: TextStyle(fontSize: 14, height: 1.62, color: ds.accent),
    listIndent: 18,
    bold: TextStyle(fontWeight: FontWeight.w600, color: ds.fg),
    italic: TextStyle(fontStyle: FontStyle.italic, color: ds.fg),
    blockquoteDecoration: BoxDecoration(
      border: BorderDirectional(
        start: BorderSide(color: ds.borderSecondary, width: 3),
      ),
    ),
  );
}
