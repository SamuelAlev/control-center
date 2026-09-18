import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/external_link.dart';
import 'package:cc_remote/format.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// Facts, join button, attendees, and description for one calendar event.
class EventDetailBody extends StatelessWidget {
  /// Creates an [EventDetailBody].
  const EventDetailBody({super.key, required this.event});

  /// The event to render.
  final CalendarEventDto event;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final start = DateTime.tryParse(event.startTime);
    final end = DateTime.tryParse(event.endTime);
    final attendees = event.attendees;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          event.title,
          style: TextStyle(
            fontSize: 20,
            height: 1.3,
            fontWeight: FontWeight.w700,
            color: t.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        if (start != null)
          _Fact(
            icon: AppIcons.clock,
            label: _when(context, event, start, end),
            secondary: dayHeading(context, start),
          ),
        if ((event.location ?? '').isNotEmpty)
          _Fact(icon: AppIcons.mapPin, label: event.location!),
        if ((event.meetingUrl ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          CcButton(
            fullWidth: true,
            icon: AppIcons.video,
            onPressed: () => openExternal(event.meetingUrl),
            child: Text(l10n.joinMeeting),
          ),
        ],
        if (attendees.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            l10n.attendeesCount(attendees.length),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: t.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          for (final a in attendees)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _AttendeeRow(attendee: a),
            ),
        ],
        if ((event.description ?? '').isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            l10n.details,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: t.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            event.description!,
            style: TextStyle(fontSize: 14, height: 1.5, color: t.textSecondary),
          ),
        ],
      ],
    );
  }

  String _when(
    BuildContext context,
    CalendarEventDto event,
    DateTime start,
    DateTime? end,
  ) {
    final l10n = AppLocalizations.of(context);
    if (event.isAllDay) {
      return l10n.allDay;
    }
    final from = clockTime(context, start);
    if (end == null) {
      return from;
    }
    return l10n.eventTimeRange(
      from,
      clockTime(context, end),
      shortDuration(context, end.difference(start)),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, this.secondary});

  final IconData icon;
  final String label;
  final String? secondary;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 15, color: t.fgTertiary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: t.textPrimary,
                  ),
                ),
                if (secondary != null)
                  Text(
                    secondary!,
                    style: TextStyle(fontSize: 12, color: t.textTertiary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendeeRow extends StatelessWidget {
  const _AttendeeRow({required this.attendee});

  final CalendarAttendeeDto attendee;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final (icon, color, word) = switch (attendee.responseStatus) {
      'accepted' => (
        AppIcons.circleCheck,
        t.textSuccessPrimary,
        l10n.attendeeAccepted,
      ),
      'declined' => (
        AppIcons.circleX,
        t.textErrorPrimary,
        l10n.attendeeDeclined,
      ),
      'tentative' => (
        AppIcons.circleDot,
        t.textWarningPrimary,
        l10n.attendeeMaybe,
      ),
      _ => (AppIcons.clock, t.fgTertiary, l10n.attendeeNoReply),
    };
    final name = (attendee.displayName ?? '').isNotEmpty
        ? attendee.displayName!
        : attendee.email;
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: t.textPrimary,
              fontWeight: attendee.self ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        if (attendee.organizer) ...[
          CcBadge(label: l10n.organizer, variant: CcBadgeVariant.neutral),
          const SizedBox(width: 6),
        ],
        Text(word, style: TextStyle(fontSize: 11, color: t.textTertiary)),
      ],
    );
  }
}
