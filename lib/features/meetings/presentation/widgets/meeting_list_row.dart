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
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
part 'meeting_list_row_signals.dart';

/// A single meeting row: status glyph, then the title over a monospaced meta
/// line and its signal pills, then a right-aligned tabular duration column.
///
/// The row carries no "Open" button. One appeared on every finished meeting,
/// duplicating the row's own tap target and turning a dense list into a column
/// of buttons; the duration that replaces it is real information and lets the
/// eye scan a day's meetings by length. The trailing slot still earns a button
/// where there is a distinct action to take: killing an in-flight summary.
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

  /// Invoked when the row is activated.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    final isProcessing =
        meeting.status == MeetingStatus.processing ||
        meeting.status == MeetingStatus.recording;
    final duration = MeetingFormat.clock(
      MeetingFormat.duration(meeting.startedAt, meeting.endedAt, now),
    );

    return Semantics(
      // The whole row is the affordance now that the per-row button is gone,
      // so the action it performs is announced as a tap hint rather than
      // folded into the label (which would re-read the title).
      onTapHint: l10n.meetingsOpenAction,
      child: GestureDetector(
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
                      style: TextStyle(
                        fontSize: 14,
                        color: ds.fg,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    _MetaLine(meeting: meeting, now: now),
                    if (isProcessing) ...[
                      const SizedBox(height: 9),
                      _ProcessingTag(l10n: l10n),
                    ] else
                      _SignalRow(meeting: meeting),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Trailing column: the recorded length as tabular mono, so a day
              // of meetings reads as a scannable column. While summarizing it
              // gives way to the one action that meeting still accepts.
              if (meeting.status == MeetingStatus.processing)
                _StopProcessingButton(meeting: meeting, l10n: l10n)
              else
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        duration,
                        style: meetingMono(context, fontSize: 12, color: ds.fg),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        AppIcons.chevronRight,
                        size: 14,
                        color: ds.fgQuaternary,
                      ),
                    ],
                  ),
                ),
            ],
          ),
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
        AppTimestamp(
          dateTime: meeting.startedAt,
          child: Text('$whenPrefix · $timeLabel', style: meetingMono(context)),
        ),
        if (meeting.sourceApp != null && meeting.sourceApp!.isNotEmpty) ...[
          dot(),
          _SourceChip(label: meeting.sourceApp!),
        ],
      ],
    );
  }
}
