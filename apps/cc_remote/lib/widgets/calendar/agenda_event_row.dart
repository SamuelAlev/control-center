import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/format.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Day label with a trailing rule, used to section the agenda list.
class AgendaDayHeader extends StatelessWidget {
  /// Creates an [AgendaDayHeader].
  const AgendaDayHeader({super.key, required this.day});

  /// Calendar day this section covers.
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final isToday = sameDay(day, DateTime.now());
    return Row(
      children: [
        Text(
          dayHeading(context, day),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isToday ? t.accent : t.textSecondary,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: CcDivider()),
      ],
    );
  }
}

/// One agenda row: time, title, duration, optional video glyph.
class AgendaEventRow extends StatelessWidget {
  /// Creates an [AgendaEventRow].
  const AgendaEventRow({super.key, required this.event});

  /// The event this row represents.
  final CalendarEventDto event;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final start = DateTime.tryParse(event.startTime);
    final end = DateTime.tryParse(event.endTime);
    final declined = event.attendees.any(
      (a) => a.self && a.responseStatus == 'declined',
    );

    return CcTappable(
      onPressed: () => context.push('/event/${event.id}'),
      semanticLabel: event.title,
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 46,
              child: Text(
                event.isAllDay || start == null
                    ? AppLocalizations.of(context).allDay
                    : clockTime(context, start),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: t.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: declined ? t.textTertiary : t.textPrimary,
                      // A declined invite still occupies the slot but is not
                      // yours — struck through so it reads as such without
                      // relying on the (subtle) colour shift alone.
                      decoration: declined
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  if (start != null && end != null && !event.isAllDay) ...[
                    const SizedBox(height: 2),
                    Text(
                      shortDuration(context, end.difference(start)),
                      style: TextStyle(fontSize: 11, color: t.textTertiary),
                    ),
                  ],
                ],
              ),
            ),
            if ((event.meetingUrl ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 8, top: 1),
                child: Icon(AppIcons.video, size: 14, color: t.fgTertiary),
              ),
          ],
        ),
      ),
    );
  }
}
