part of 'meeting_list_row.dart';

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
    final stats =
        ref
            .watch(meetingActionItemStatsProvider(meeting.workspaceId))
            .asData
            ?.value ??
        const <String, MeetingActionItemStats>{};
    final decisionCounts =
        ref
            .watch(meetingDecisionCountsProvider(meeting.workspaceId))
            .asData
            ?.value ??
        const <String, int>{};
    final actionStat = stats[meeting.id] ?? (total: 0, done: 0);
    final total = actionStat.total;
    final doneCount = actionStat.done;
    final open = total - doneCount;
    final decisionCount = decisionCounts[meeting.id] ?? 0;

    final pills = <Widget>[
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
    ];
    // A meeting with nothing extracted from it reserves no space for pills —
    // the fixed 9px gap under every row was most of what made a quiet list
    // look padded.
    if (pills.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: pills,
      ),
    );
  }
}

/// Trailing "Stop" button shown on a `processing` meeting row, occupying the
/// slot the duration uses on a finished meeting. Kills the in-flight
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
