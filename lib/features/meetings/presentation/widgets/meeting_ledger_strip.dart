import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_format.dart';
import 'package:control_center/features/meetings/presentation/utils/meeting_theme.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// The capture ledger: meetings this week, time recorded, open action items and
/// decisions logged, as one hairline-separated line of machine truth.
///
/// These four numbers used to be four equal stat cards — the gradient-free but
/// otherwise textbook SaaS hero-metric grid DESIGN.md rules out, and ~110px of
/// chrome above the list you came to read. As a mono ledger they cost a single
/// ~28px line, stay legible at a glance and read as instrument panel rather than
/// dashboard. Open action items take the accent because they are the only one of
/// the four that asks for something.
class MeetingLedgerStrip extends StatelessWidget {
  /// Creates a [MeetingLedgerStrip].
  const MeetingLedgerStrip({
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
    final ds = context.ds;
    final entries = <Widget>[
      _LedgerEntry(label: l10n.meetingsStatThisWeek, value: '$thisWeek'),
      _LedgerEntry(
        label: l10n.meetingsStatRecorded,
        value: MeetingFormat.totalLabel(recorded),
      ),
      _LedgerEntry(
        label: l10n.meetingsLedgerOpenActions,
        value: '$openActions',
        // The one actionable number of the four, and the screen's single
        // accent spend outside the record CTA — so it only lights up when
        // there is actually something open.
        accent: openActions > 0,
      ),
      _LedgerEntry(label: l10n.meetingsLedgerDecisions, value: '$decisions'),
    ];

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.sm,
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) _LedgerRule(color: ds.borderSecondary),
          entries[i],
        ],
      ],
    );
  }
}

/// One `LABEL value` pair in the ledger.
class _LedgerEntry extends StatelessWidget {
  const _LedgerEntry({
    required this.label,
    required this.value,
    this.accent = false,
  });

  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          label.toUpperCase(),
          style: meetingMono(
            context,
            fontSize: 11,
            color: ds.muted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          value,
          style: meetingMono(
            context,
            fontSize: 13,
            color: accent ? ds.accent : ds.fg,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// A 1px vertical hairline — the ledger's separator.
///
/// `CcDivider` is horizontal; this is its vertical twin, kept private to the
/// ledger both because it is the only place in meetings that needs one and
/// because a public `VerticalDivider` would collide with Material's.
class _LedgerRule extends StatelessWidget {
  const _LedgerRule({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 1, height: 14, child: ColoredBox(color: color));
}
