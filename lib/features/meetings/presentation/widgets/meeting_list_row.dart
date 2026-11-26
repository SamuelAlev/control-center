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

/// A single meeting row: status glyph, the title over a meta line,
/// then the signal pills and a right-aligned duration column.
///
/// The whole row is the affordance and says so with a hover wash; it carries no
/// "Open" button and no chevron. On a wide list the pills sit on the title's
/// own line, so a meeting costs two lines of text instead of three and the
/// pills and durations read as columns down a day. A narrow list drops the
/// pills under the meta line.
///
/// The trailing slot earns a button only where there is a distinct action to
/// take: killing an in-flight summary.
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

  /// Width from which the pills share the title's line.
  static const double _inlineSignalsBreakpoint = 640;

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

    return CcTappable(
      onPressed: onTap,
      // Not a container: the hint lands on the tappable's own node. The whole
      // row is the affordance, so the action it performs is announced as a tap
      // hint rather than folded into the label (which would re-read the title).
      builder: (context, states) => Semantics(
        onTapHint: l10n.meetingsOpenAction,
        child: AnimatedContainer(
          duration: CcMotion.resolveFade(context, CcMotion.fast),
          curve: CcMotion.standard,
          color: states.contains(WidgetState.pressed)
              ? ds.hoverStrong
              : states.contains(WidgetState.hovered)
              ? ds.hover
              : ds.hover.withValues(alpha: 0),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final inline = constraints.maxWidth >= _inlineSignalsBreakpoint;
              final signals = isProcessing
                  ? _ProcessingTag(l10n: l10n)
                  : _SignalRow(meeting: meeting, inline: inline);
              return Row(
                crossAxisAlignment: inline
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: inline ? 0 : 1),
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
                            fontWeight: FontWeight.w500,
                            color: ds.fg,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _MetaLine(meeting: meeting, now: now),
                        if (!inline)
                          if (isProcessing)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.sm,
                              ),
                              child: signals,
                            )
                          else
                            signals,
                      ],
                    ),
                  ),
                  if (inline) ...[
                    const SizedBox(width: AppSpacing.lg),
                    signals,
                  ],
                  const SizedBox(width: AppSpacing.lg),
                  // Trailing column: the recorded length, end
                  // aligned in a fixed slot so a day of meetings reads as a
                  // scannable column. While summarizing it gives way to the
                  // one action that meeting still accepts.
                  if (meeting.status == MeetingStatus.processing)
                    _StopProcessingButton(meeting: meeting, l10n: l10n)
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 56),
                      child: Text(
                        duration,
                        textAlign: TextAlign.end,
                        style: meetingMeta(
                          context,
                          fontSize: 12,
                          color: ds.muted,
                        ),
                      ),
                    ),
                ],
              );
            },
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
    // A weekday names a day only within the current week; past that it is
    // ambiguous ("Sun" of which week?), so older meetings carry their date.
    final whenPrefix = switch (bucket) {
      MeetingDayBucket.today => l10n.meetingsBucketToday,
      MeetingDayBucket.yesterday => l10n.meetingsBucketYesterday,
      MeetingDayBucket.earlierThisWeek => DateFormat.E(
        locale,
      ).format(meeting.startedAt),
      MeetingDayBucket.lastWeek || MeetingDayBucket.older => DateFormat.MMMd(
        locale,
      ).format(meeting.startedAt),
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
          child: Text('$whenPrefix · $timeLabel', style: meetingMeta(context)),
        ),
        if (meeting.sourceApp != null && meeting.sourceApp!.isNotEmpty) ...[
          dot(),
          _SourceChip(label: meeting.sourceApp!),
        ],
      ],
    );
  }
}
