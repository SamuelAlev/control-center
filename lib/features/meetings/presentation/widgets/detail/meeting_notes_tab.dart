import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/features/meetings/domain/entities/meeting.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_segment.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_common.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_transcript_row.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:control_center/shared/widgets/segmented_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Which version of the notes the Notes tab is showing.
enum MeetingNotesMode {
  /// The AI-augmented notes.
  enhanced,

  /// The user's own raw notes (editable).
  yours,
}

/// The Notes tab: a split of the notes editor (Enhanced ↔ Your notes toggle)
/// beside a reference excerpt of the transcript. Stacks vertically when narrow.
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
    required this.onViewFullTranscript,
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

  /// Invoked when "View full transcript" is pressed.
  final VoidCallback onViewFullTranscript;

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
        );
        final transcript = _TranscriptReference(
          segments: segments,
          onViewFullTranscript: onViewFullTranscript,
        );
        if (constraints.maxWidth < 880) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [notes, const SizedBox(height: AppSpacing.lg), transcript],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 118, child: notes),
            const SizedBox(width: AppSpacing.lg),
            Expanded(flex: 82, child: transcript),
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
  });

  final Meeting meeting;
  final MeetingNotesMode mode;
  final ValueChanged<MeetingNotesMode> onModeChanged;
  final TextEditingController notesController;
  final ValueChanged<String> onNotesChanged;
  final String savingLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 28,
          child: Row(
            children: [
              MeetingEyebrow(l10n.meetingTabNotes),
              const Spacer(),
              SegmentedToggle<MeetingNotesMode>(
                value: mode,
                onChanged: onModeChanged,
                segments: [
                  (
                    value: MeetingNotesMode.enhanced,
                    label: l10n.meetingNotesEnhancedToggle,
                  ),
                  (
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
              ? _EnhancedNotes(meeting: meeting)
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
  const _EnhancedNotes({required this.meeting});

  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (meeting.status == MeetingStatus.processing ||
        meeting.status == MeetingStatus.recording) {
      return Text(
        l10n.meetingEnhancedPending,
        style: TextStyle(color: context.ds.muted),
      );
    }
    if (!meeting.isEnhanced) {
      return Text(
        l10n.meetingNotesEmpty,
        style: TextStyle(color: context.ds.muted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EnhancedTag(label: l10n.meetingEnhancedByAgent),
        const SizedBox(height: AppSpacing.lg),
        MarkdownBody(
          data: meeting.enhancedNotes!,
          selectable: true,
          styleSheet: _notesStyleSheet(context),
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
          Icon(LucideIcons.sparkles, size: 12, color: context.mAccent),
          const SizedBox(width: 5),
          Text(label, style: meetingMono(context, fontSize: 11, color: context.mAccent)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 220),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: null,
            cursorColor: ds.accent,
            style: TextStyle(fontSize: 14, height: 1.7, color: ds.fg),
            decoration: const InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
            ),
          ),
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

class _TranscriptReference extends StatelessWidget {
  const _TranscriptReference({
    required this.segments,
    required this.onViewFullTranscript,
  });

  final List<MeetingSegment> segments;
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
          height: 28,
          child: Align(
            alignment: Alignment.centerLeft,
            child: MeetingEyebrow(l10n.meetingTabTranscript),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: AppRadii.brLg,
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
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        thickness: 1,
                        color: ds.borderSecondary,
                      ),
                      itemBuilder: (context, i) => MeetingTranscriptRow.fromSegment(
                        preview[i],
                        compact: true,
                        timeColumnWidth: 46,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: ds.borderSecondary)),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FButton(
                      variant: FButtonVariant.outline,
                      size: FButtonSizeVariant.sm,
                      onPress: onViewFullTranscript,
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

/// A compact markdown stylesheet for enhanced notes: mono uppercase headings
/// and orange list markers, matching the design.
MarkdownStyleSheet _notesStyleSheet(BuildContext context) {
  final theme = Theme.of(context);
  final ds = context.ds;
  final base = MarkdownStyleSheet.fromTheme(theme);
  final mono = meetingMono(
    context,
    fontSize: 11,
    color: ds.muted,
    letterSpacing: 0.8,
  );
  return base.copyWith(
    p: TextStyle(fontSize: 14, height: 1.62, color: ds.fg),
    pPadding: const EdgeInsets.only(bottom: 10),
    h1: mono,
    h2: mono,
    h3: mono,
    h4: mono,
    h5: mono,
    h6: mono,
    h1Padding: const EdgeInsets.only(top: 18, bottom: 8),
    h2Padding: const EdgeInsets.only(top: 18, bottom: 8),
    h3Padding: const EdgeInsets.only(top: 18, bottom: 8),
    h4Padding: const EdgeInsets.only(top: 18, bottom: 8),
    listBullet: TextStyle(fontSize: 14, height: 1.62, color: ds.accent),
    listIndent: 18,
    strong: TextStyle(fontWeight: FontWeight.w600, color: ds.fg),
    em: TextStyle(fontStyle: FontStyle.italic, color: ds.fg),
    blockquoteDecoration: BoxDecoration(
      border: Border(left: BorderSide(color: ds.borderSecondary, width: 3)),
    ),
  );
}
