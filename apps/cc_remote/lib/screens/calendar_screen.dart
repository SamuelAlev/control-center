import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/calendar_providers.dart';
import 'package:cc_remote/external_link.dart';
import 'package:cc_remote/format.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/touch_target.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Calendar tab: the synced agenda for the active workspace.
///
/// An AGENDA, not a month grid. The desktop's calendar is a planning surface —
/// you drag, you compare weeks, you see shape. A phone calendar answers a
/// narrower question, usually while walking: what is next, where is it, and
/// what is the join link. So the phone renders one scrolling list of days with
/// an "up next" card pinned on top, over exactly the same synced rows
/// (`calendar.watchEventsInRange`) the desktop reads.
///
/// Connecting an account stays on the desktop: the OAuth device-code flow
/// stores a refresh token server-side, and a phone that could add accounts
/// but not manage their scopes would be a half-feature. The phone says so
/// rather than showing an empty week that looks like a free schedule.
class CalendarScreen extends ConsumerStatefulWidget {
  /// Creates a [CalendarScreen].
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  bool _refreshing = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // "In 45m" and "Happening now" are computed from `DateTime.now()`, and
    // nothing else on this screen changes while a meeting approaches — the
    // event stream only emits when the SYNC changes. Without a clock the card
    // would still read "In 45m" when the call has already started, which is
    // the one thing a calendar must not do. Half a minute is finer than the
    // labels' own resolution, so no minute is ever shown late.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final client = ref.read(rpcClientProvider).value;
    final workspaceId = ref.read(activeWorkspaceIdProvider).value;
    if (client == null || workspaceId == null || _refreshing) {
      return;
    }
    setState(() => _refreshing = true);
    try {
      await RemoteCalendarRepository(
        client,
      ).refreshNow(workspaceId: workspaceId);
    } catch (_) {
      // The synced rows keep rendering; the host re-syncs on its own cadence.
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final accounts = ref.watch(calendarAccountsProvider);
    final days = ref.watch(agendaDaysProvider);
    final next = ref.watch(nextEventProvider);

    return ColoredBox(
      color: t.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _toolbar(t),
          if (accounts.hasValue && accounts.value!.isEmpty)
            const _NoAccountsNotice()
          else if (accounts.value?.any((a) => a.authExpiredAt != null) ?? false)
            const _ReauthNotice(),
          Expanded(
            child: days.when(
              loading: () => const Center(child: CcSpinner(size: 24)),
              error: (e, _) => CcEmptyState(
                icon: AppIcons.triangleAlert,
                message: "Couldn't load your calendar",
                description: e.toString(),
              ),
              data: (agenda) {
                if (agenda.isEmpty) {
                  return const CcEmptyState(
                    icon: AppIcons.calendarDays,
                    message: 'Nothing scheduled',
                    description:
                        'Events from your connected calendars appear here.',
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    if (next != null) ...[
                      _UpNextCard(event: next),
                      const SizedBox(height: 20),
                    ],
                    for (final day in agenda) ...[
                      _DayHeader(day: day.day),
                      const SizedBox(height: 8),
                      for (final event in day.events)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _EventRow(event: event),
                        ),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbar(DesignSystemTokens t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 4, 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Agenda',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: t.textPrimary,
              ),
            ),
          ),
          PhoneIconButton(
            icon: AppIcons.refreshCw,
            semanticLabel: 'Sync calendars now',
            onPressed: _refreshing ? null : _refresh,
            color: _refreshing ? t.fgDisabled : t.fgSecondary,
            iconSize: 18,
          ),
        ],
      ),
    );
  }
}

/// `/event/:eventId` — one event, with everything a phone is asked for while
/// standing up: when, where, the join link, who is coming.
class EventDetailScreen extends ConsumerWidget {
  /// Creates an [EventDetailScreen].
  const EventDetailScreen({super.key, required this.eventId});

  /// The calendar event id from the route.
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    // Resolved from the live agenda rather than a per-event watch: the row is
    // already in memory and updates in place with the rest of the agenda.
    final event = ref
        .watch(agendaEventsProvider)
        .value
        ?.where((e) => e.id == eventId)
        .firstOrNull;

    return SafeArea(
      child: ColoredBox(
        color: t.canvas,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DetailHeader(title: event?.title ?? 'Event'),
            if (event == null)
              const Expanded(
                child: CcEmptyState(
                  icon: AppIcons.calendar,
                  message: 'Event not found',
                  description:
                      'It may be outside the agenda window, or removed '
                      'upstream.',
                ),
              )
            else
              Expanded(child: _body(t, event)),
          ],
        ),
      ),
    );
  }

  Widget _body(DesignSystemTokens t, CalendarEventDto event) {
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
            label: _when(event, start, end),
            secondary: dayHeading(start),
          ),
        if ((event.location ?? '').isNotEmpty)
          _Fact(icon: AppIcons.mapPin, label: event.location!),
        if ((event.meetingUrl ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          CcButton(
            fullWidth: true,
            icon: AppIcons.video,
            onPressed: () => openExternal(event.meetingUrl),
            child: const Text('Join meeting'),
          ),
        ],
        if (attendees.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Attendees (${attendees.length})',
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
            'Details',
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

  String _when(CalendarEventDto event, DateTime start, DateTime? end) {
    if (event.isAllDay) {
      return 'All day';
    }
    final from = clockTime(start);
    if (end == null) {
      return from;
    }
    return '$from – ${clockTime(end)} · ${shortDuration(end.difference(start))}';
  }
}

/// The card above the agenda: the meeting happening now, or the next one.
class _UpNextCard extends StatelessWidget {
  const _UpNextCard({required this.event});

  final CalendarEventDto event;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final start = DateTime.tryParse(event.startTime);
    final end = DateTime.tryParse(event.endTime);
    final now = DateTime.now();
    final live =
        start != null && end != null && !start.isAfter(now) && end.isAfter(now);
    // A countdown is only useful while it is short. Past half a day
    // "In 71h" is arithmetic the reader has to undo — the day name is the
    // answer they wanted.
    final away = start == null ? Duration.zero : start.difference(now);
    final lead = start == null
        ? ''
        : live
        ? 'Happening now'
        : away.inHours >= 12
        ? dayHeading(start)
        : 'In ${shortDuration(away)}';

    return CcCard(
      interactive: true,
      semanticLabel: '$lead: ${event.title}',
      onPressed: () => context.push('/event/${event.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                live ? AppIcons.circleDot : AppIcons.clock,
                size: 14,
                // Paired with the words "Happening now" — a live meeting is
                // never signalled by colour alone.
                color: live ? t.textSuccessPrimary : t.accent,
              ),
              const SizedBox(width: 6),
              Text(
                lead,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: live ? t.textSuccessPrimary : t.accent,
                ),
              ),
              const Spacer(),
              if (start != null)
                Text(
                  event.isAllDay ? 'All day' : clockTime(start),
                  style: TextStyle(fontSize: 12, color: t.textTertiary),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            event.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: t.textPrimary,
            ),
          ),
          if ((event.location ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(AppIcons.mapPin, size: 12, color: t.fgTertiary),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    event.location!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: t.textTertiary),
                  ),
                ),
              ],
            ),
          ],
          if ((event.meetingUrl ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            CcButton(
              fullWidth: true,
              size: CcButtonSize.sm,
              icon: AppIcons.video,
              onPressed: () => openExternal(event.meetingUrl),
              child: const Text('Join'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final isToday = sameDay(day, DateTime.now());
    return Row(
      children: [
        Text(
          dayHeading(day),
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

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

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
                event.isAllDay || start == null ? 'All day' : clockTime(start),
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
                      shortDuration(end.difference(start)),
                      style: TextStyle(fontSize: 11, color: t.textTertiary),
                    ),
                  ],
                ],
              ),
            ),
            if ((event.meetingUrl ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 1),
                child: Icon(AppIcons.video, size: 14, color: t.fgTertiary),
              ),
          ],
        ),
      ),
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
    final (icon, color, word) = switch (attendee.responseStatus) {
      'accepted' => (AppIcons.circleCheck, t.textSuccessPrimary, 'accepted'),
      'declined' => (AppIcons.circleX, t.textErrorPrimary, 'declined'),
      'tentative' => (AppIcons.circleDot, t.textWarningPrimary, 'maybe'),
      _ => (AppIcons.clock, t.fgTertiary, 'no reply'),
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
          const CcBadge(label: 'organizer', variant: CcBadgeVariant.neutral),
          const SizedBox(width: 6),
        ],
        Text(word, style: TextStyle(fontSize: 11, color: t.textTertiary)),
      ],
    );
  }
}

/// No calendar account is connected on the server, so there is nothing to
/// sync. Distinguishing that from "a free week" is the whole job of this
/// notice.
class _NoAccountsNotice extends StatelessWidget {
  const _NoAccountsNotice();

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return _Notice(
      icon: AppIcons.calendarDays,
      color: t.textWarningPrimary,
      text:
          'No calendar is connected for this workspace. Connect one from the '
          'desktop app — the sign-in stores its token on the server.',
    );
  }
}

/// An account's credential expired: the rows on screen are the last good sync,
/// not the current state, and only a desktop re-auth fixes it.
class _ReauthNotice extends StatelessWidget {
  const _ReauthNotice();

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return _Notice(
      icon: AppIcons.triangleAlert,
      color: t.textWarningPrimary,
      text:
          'A calendar account needs to be reconnected — what you see below may '
          'be out of date. Reconnect it from the desktop app.',
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.warnSoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: t.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.topbar,
        border: Border(bottom: BorderSide(color: t.borderSoft)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            PhoneIconButton(
              icon: AppIcons.arrowLeft,
              semanticLabel: 'Back',
              onPressed: () => context.pop(),
              color: t.fgSecondary,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
