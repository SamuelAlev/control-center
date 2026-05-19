
import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_ui_providers.dart'
    show calendarKey;
import 'package:control_center/features/calendar/presentation/utils/calendar_format.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Day-grouped chronological list of events. Read-only; the only action is the
/// inline "Start recording" affordance on events that are starting soon.
class AgendaPanel extends StatelessWidget {
  /// Creates an [AgendaPanel].
  const AgendaPanel({
    super.key,
    required this.events,
    required this.now,
    required this.onOpenEvent,
    required this.onStartRecording,
    this.calendarColors = const {},
  });

  /// The events to list.
  final List<CalendarEvent> events;

  /// The reference "now" (drives today highlighting + starting-soon).
  final DateTime now;

  /// Per-calendar accent colors, keyed by `calendarId`.
  final Map<String, Color> calendarColors;

  /// Called when a row is tapped.
  final ValueChanged<CalendarEvent> onOpenEvent;

  /// Called when the "Start recording" action is pressed for an event.
  final ValueChanged<CalendarEvent> onStartRecording;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();

    if (events.isEmpty) {
      return Center(
        child: Text(
          l10n.calendarEmptyNoEvents,
          style: TextStyle(fontSize: 13, color: t.textTertiary),
        ),
      );
    }

    final grouped = groupEventsByDay(events);
    final today = dayKey(now);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        for (final entry in grouped.entries) ...[
          _DayHeader(
            day: entry.key,
            isToday: entry.key == today,
            todayLabel: l10n.calendarToday,
          ),
          for (final event in entry.value)
            _EventRow(
              event: event,
              now: now,
              color: calendarColors[calendarKey(event.accountId, event.calendarId)],
              onOpen: () => onOpenEvent(event),
              onStartRecording: () => onStartRecording(event),
            ),
        ],
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.day,
    required this.isToday,
    required this.todayLabel,
  });

  final DateTime day;
  final bool isToday;
  final String todayLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final label = '${DateFormat.EEEE().format(day)}, '
        '${DateFormat.MMMMd().format(day)}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          Text(
            isToday ? todayLabel : label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isToday ? t.fgBrandPrimary : t.textSecondary,
            ),
          ),
          if (isToday) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: t.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.now,
    required this.color,
    required this.onOpen,
    required this.onStartRecording,
  });

  final CalendarEvent event;
  final DateTime now;
  final Color? color;
  final VoidCallback onOpen;
  final VoidCallback onStartRecording;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final startingSoon = isStartingSoon(event, now);
    final cancelled = event.status == CalendarEventStatus.cancelled;

    final meta = <String>[
      if (event.location != null && event.location!.isNotEmpty) event.location!,
      if (event.attendees.isNotEmpty)
        l10n.calendarAttendeesCount(event.attendees.length),
    ].join(' · ');

    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 64,
              child: Text(
                event.isAllDay
                    ? l10n.calendarAllDay
                    : DateFormat.jm().format(event.startTime.toLocal()),
                style: TextStyle(
                  fontSize: 12,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: t.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              margin: const EdgeInsets.only(top: 4, right: 10),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color ?? t.fgBrandPrimary,
                borderRadius: AppRadii.brXs,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: t.textPrimary,
                      decoration:
                          cancelled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (meta.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        meta,
                        style: TextStyle(fontSize: 12, color: t.textTertiary),
                      ),
                    ),
                  if (event.meetingUrl != null) ...[
                    const SizedBox(height: 4),
                    _MeetLink(url: event.meetingUrl!, label: l10n.calendarJoinMeet),
                  ],
                ],
              ),
            ),
            if (startingSoon) ...[
              const SizedBox(width: 8),
              CcButton(
                variant: CcButtonVariant.secondary,
                size: CcButtonSize.sm,
                onPressed: onStartRecording,
                icon: AppIcons.circleDot,
                child: Text(l10n.calendarStartRecording),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MeetLink extends StatelessWidget {
  const _MeetLink({required this.url, required this.label});

  final String url;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return InkWell(
      borderRadius: AppRadii.brSm,
      onTap: () => unawaitedLaunch(url),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.video, size: 13, color: t.fgBrandPrimary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: t.fgBrandPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fire-and-forget external URL launch (the Meet/Zoom link).
void unawaitedLaunch(String url) {
  openExternalUrl(url);
}
