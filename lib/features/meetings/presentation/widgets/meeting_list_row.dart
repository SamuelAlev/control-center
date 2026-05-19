import 'dart:async';

import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_controller.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_format.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_common.dart';
import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// A single meeting row in the list: status glyph, title, a monospaced meta
/// line (when · duration · source), and a signal row of decision / action-item
/// / enhanced pills — or a live "transcribing & summarizing…" tag while the
/// meeting is still processing.
class MeetingListRow extends ConsumerWidget {
  /// Creates a [MeetingListRow].
  const MeetingListRow({
    super.key,
    required this.meeting,
    required this.now,
    required this.onTap,
  });

  /// The meeting to render.
  final Meeting meeting;

  /// The reference "now" for relative time + duration.
  final DateTime now;

  /// Invoked when the row (or its Open button) is activated.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    final isProcessing = meeting.status == MeetingStatus.processing ||
        meeting.status == MeetingStatus.recording;

    return InkWell(
      borderRadius: AppRadii.brMd,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: MeetingStatusGlyph(status: meeting.status),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meeting.title,
                    style: TextStyle(fontSize: 14, color: ds.fg, height: 1.35),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  _MetaLine(meeting: meeting, now: now),
                  const SizedBox(height: 9),
                  if (isProcessing)
                    _ProcessingTag(l10n: l10n)
                  else
                    _SignalRow(meeting: meeting),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // While summarizing, the trailing slot offers "Stop" (kill the
            // pipeline) instead of "Open"; a still-recording meeting is driven
            // from the record screen, so it gets no trailing action here.
            if (meeting.status == MeetingStatus.processing)
              _StopProcessingButton(meeting: meeting, l10n: l10n)
            else if (!isProcessing)
              CcButton(
                variant: CcButtonVariant.secondary,
                size: CcButtonSize.sm,
                onPressed: onTap,
                child: Text(l10n.meetingsOpenAction),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.meeting, required this.now});

  final Meeting meeting;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    final locale = Localizations.localeOf(context).toString();
    final bucket = MeetingFormat.bucketFor(meeting.startedAt, now);
    final timeLabel = DateFormat.Hm(locale).format(meeting.startedAt);
    final whenPrefix = switch (bucket) {
      MeetingDayBucket.today => l10n.meetingsBucketToday,
      MeetingDayBucket.yesterday => l10n.meetingsBucketYesterday,
      _ => DateFormat.E(locale).format(meeting.startedAt),
    };
    final duration = MeetingFormat.clock(
      MeetingFormat.duration(meeting.startedAt, meeting.endedAt, now),
    );

    Widget dot() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: ds.muted.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
        );

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('$whenPrefix · $timeLabel', style: meetingMono(context)),
        dot(),
        Text(duration, style: meetingMono(context)),
        if (meeting.sourceApp != null && meeting.sourceApp!.isNotEmpty) ...[
          dot(),
          _SourceChip(label: meeting.sourceApp!),
        ],
      ],
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: ds.surface,
        borderRadius: AppRadii.brSm,
        border: Border.all(color: ds.borderSecondary),
      ),
      child: Text(
        label,
        style: meetingMono(context, fontSize: 11, color: ds.fg),
      ),
    );
  }
}

class _SignalRow extends ConsumerWidget {
  const _SignalRow({required this.meeting});

  final Meeting meeting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final stats = ref
            .watch(meetingActionItemStatsProvider(meeting.workspaceId))
            .asData
            ?.value ??
        const <String, MeetingActionItemStats>{};
    final decisionCounts = ref
            .watch(meetingDecisionCountsProvider(meeting.workspaceId))
            .asData
            ?.value ??
        const <String, int>{};
    final actionStat = stats[meeting.id] ?? (total: 0, done: 0);
    final total = actionStat.total;
    final doneCount = actionStat.done;
    final open = total - doneCount;
    final decisionCount = decisionCounts[meeting.id] ?? 0;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        if (decisionCount > 0)
          MeetingSignalPill(
            icon: AppIcons.flag,
            label: l10n.meetingsDecisionsCount(decisionCount),
          ),
        if (total > 0)
          MeetingSignalPill(
            icon: AppIcons.listChecks,
            label: l10n.meetingsActionItemsProgress(doneCount, total),
            tone: open > 0 ? MeetingPillTone.warn : MeetingPillTone.success,
          ),
        if (meeting.isEnhanced)
          MeetingSignalPill(
            icon: AppIcons.sparkles,
            label: l10n.meetingsEnhancedPill,
            tone: MeetingPillTone.accent,
          ),
      ],
    );
  }
}

/// Trailing "Stop" button shown on a `processing` meeting row, occupying the
/// slot the "Open" button uses on a finished meeting. Kills the in-flight
/// `meeting_summary` pipeline run; the reconciler then finalizes the meeting to
/// `done` (keeping the transcript), so the row stops showing the live tag.
class _StopProcessingButton extends ConsumerWidget {
  const _StopProcessingButton({required this.meeting, required this.l10n});

  final Meeting meeting;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CcButton(
      variant: CcButtonVariant.destructive,
      size: CcButtonSize.sm,
      icon: AppIcons.square,
      onPressed: () => unawaited(
        ref
            .read(meetingRecorderControllerProvider.notifier)
            .cancelProcessing(meeting.id),
      ),
      child: Text(l10n.meetingsStopProcessing),
    );
  }
}

class _ProcessingTag extends StatelessWidget {
  const _ProcessingTag({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MeetingEqualizerBars(color: context.mAccent, height: 10),
        const SizedBox(width: 6),
        Text(
          l10n.meetingsTranscribing,
          style: meetingMono(context, fontSize: 11, color: context.mAccent),
        ),
      ],
    );
  }
}
