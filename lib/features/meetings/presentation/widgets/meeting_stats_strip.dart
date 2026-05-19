import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_format.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_common.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The four-card capture-stats strip at the top of the meetings list:
/// meetings this week, time recorded, open action items (accented), and
/// decisions logged. Collapses to two columns on narrow widths.
class MeetingStatsStrip extends StatelessWidget {
  /// Creates a [MeetingStatsStrip].
  const MeetingStatsStrip({
    super.key,
    required this.thisWeek,
    required this.recorded,
    required this.openActions,
    required this.decisions,
  });

  /// Meetings captured this week.
  final int thisWeek;

  /// Total recorded/transcribed time.
  final Duration recorded;

  /// Open (pending) action items across all meetings.
  final int openActions;

  /// Decisions extracted across all meetings.
  final int decisions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cards = [
      _StatCard(
        icon: LucideIcons.calendar,
        eyebrow: l10n.meetingsStatThisWeek,
        value: '$thisWeek',
        unit: l10n.meetingsStatThisWeekUnit,
      ),
      _StatCard(
        icon: LucideIcons.clock,
        eyebrow: l10n.meetingsStatRecorded,
        value: MeetingFormat.totalLabel(recorded),
        unit: l10n.meetingsStatRecordedUnit,
      ),
      _StatCard(
        icon: LucideIcons.listChecks,
        eyebrow: l10n.meetingsStatOpen,
        value: '$openActions',
        unit: l10n.meetingsStatOpenUnit,
        accentValue: true,
      ),
      _StatCard(
        icon: LucideIcons.flag,
        eyebrow: l10n.meetingsStatLogged,
        value: '$decisions',
        unit: l10n.meetingsStatLoggedUnit,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 720 ? 2 : 4;
        const gap = AppSpacing.md;
        final cardWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards)
              SizedBox(width: cardWidth, child: card),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.eyebrow,
    required this.value,
    required this.unit,
    this.accentValue = false,
  });

  final IconData icon;
  final String eyebrow;
  final String value;
  final String unit;
  final bool accentValue;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: ds.muted),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: MeetingEyebrow(eyebrow)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: meetingMono(
              context,
              fontSize: 30,
              color: accentValue ? ds.accent : ds.fg,
              fontWeight: FontWeight.w500,
            ).copyWith(height: 1),
          ),
          const SizedBox(height: 6),
          Text(
            unit,
            style: TextStyle(fontSize: 12, color: ds.muted),
          ),
        ],
      ),
    );
  }
}
