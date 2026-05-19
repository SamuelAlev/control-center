import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/calendar/domain/entities/calendar_event.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_rsvp_provider.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_ui_providers.dart';
import 'package:control_center/features/calendar/presentation/utils/html_description.dart';
import 'package:control_center/features/calendar/presentation/widgets/agenda_panel.dart'
    show unawaitedLaunch;
import 'package:control_center/features/calendar/providers/google_auth_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// How many participants are shown before the list collapses behind a
/// "See all" expander. A roster of this size or smaller is shown in full.
const int _kParticipantPreview = 5;

/// Detail pane for a selected calendar event: when/where, conferencing, the
/// participant roster with RSVP state, the user's own RSVP, the
/// record-and-link action, and the event description. Laid out as a quiet
/// operator inspector — dense rows, hairline section breaks, mono for the
/// machine facts (times, counts, meeting codes), accent rationed to the user's
/// own controls.
class CalendarEventDetailPanel extends ConsumerWidget {
  /// Creates a [CalendarEventDetailPanel].
  const CalendarEventDetailPanel({
    super.key,
    required this.workspaceId,
    required this.eventId,
    required this.onStartRecording,
  });

  /// The owning workspace.
  final String workspaceId;

  /// The selected event id, or null when nothing is selected.
  final String? eventId;

  /// Called when "Start recording & link" is pressed.
  final ValueChanged<CalendarEvent> onStartRecording;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();

    final id = eventId;
    if (id == null) {
      return _EmptyState(message: l10n.calendarEmptyNoEvents);
    }

    final event = ref
        .watch(
          calendarEventByIdProvider((workspaceId: workspaceId, eventId: id)),
        )
        .asData
        ?.value;
    if (event == null) {
      return _EmptyState(message: l10n.calendarEmptyNoEvents);
    }

    final linkedMeetingId = ref
        .watch(meetingIdForEventProvider(
          (workspaceId: workspaceId, eventId: id),
        ))
        .asData
        ?.value;

    final accountEmail = _accountEmail(ref, event.accountId);
    final calendarColor =
        ref.watch(calendarColorsProvider)[calendarKey(event.accountId, event.calendarId)];

    final description = event.description == null
        ? const ParsedDescription(text: '', links: [])
        : parseEventDescription(event.description!);

    return DecoratedBox(
      decoration: BoxDecoration(color: t.bgPrimary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderBar(label: l10n.calendarEventLabel),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _WhenBlock(event: event, l10n: l10n),
                  ..._metaRows(event, l10n),
                  if (event.meetingUrl != null) ...[
                    const SizedBox(height: 14),
                    _ConferenceCard(url: event.meetingUrl!, l10n: l10n),
                  ],
                  if (event.attendees.isNotEmpty) ...[
                    const _SectionBreak(),
                    _ParticipantsSection(event: event, l10n: l10n),
                  ],
                  if (CalendarRsvpService.canRespond(event)) ...[
                    const SizedBox(height: 14),
                    _RsvpControls(event: event),
                  ],
                  const _SectionBreak(),
                  _MeetingNoteAction(
                    event: event,
                    linkedMeetingId: linkedMeetingId,
                    onStartRecording: onStartRecording,
                    l10n: l10n,
                  ),
                  if (!description.isEmpty) ...[
                    const _SectionBreak(),
                    _Description(parsed: description),
                  ],
                  if (accountEmail != null) ...[
                    const SizedBox(height: 20),
                    _CalendarSourceRow(email: accountEmail, color: calendarColor),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The connected account's email for [accountId], or null when unresolved.
  String? _accountEmail(WidgetRef ref, String accountId) {
    final accounts =
        ref.watch(googleAccountsProvider).asData?.value ?? const <CalendarAccount>[];
    for (final account in accounts) {
      if (account.id == accountId) {
        return account.accountEmail;
      }
    }
    return null;
  }

  /// The quiet meta rows below the time block: location, recurrence, time zone.
  List<Widget> _metaRows(CalendarEvent event, AppLocalizations l10n) {
    final rows = <Widget>[];
    if (event.location != null && event.location!.trim().isNotEmpty) {
      rows.add(_MetaRow(icon: LucideIcons.mapPin, text: event.location!.trim()));
    }
    if (event.recurringEventId != null) {
      rows.add(_MetaRow(icon: LucideIcons.repeat, text: l10n.calendarRecurring));
    }
    if (!event.isAllDay) {
      rows.add(
        _MetaRow(
          icon: LucideIcons.globe,
          text: _gmtLabel(event.startTime.toLocal()),
          mono: true,
        ),
      );
    }
    if (rows.isEmpty) {
      return const [];
    }
    return [const SizedBox(height: 8), ...rows];
  }
}

/// The fixed top bar: a mono "EVENT" eyebrow and a close affordance that
/// deselects the event (returns to the bare calendar).
class _HeaderBar extends StatelessWidget {
  const _HeaderBar({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.borderSecondary)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 10, 0),
      height: 44,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.codeStyle(
                fontSize: 11,
                color: t.textTertiary,
                letterSpacing: 1,
              ),
            ),
          ),
          Semantics(
            button: true,
            label: l10n.close,
            child: Tooltip(
              message: l10n.close,
              child: InkWell(
                borderRadius: AppRadii.brSm,
                onTap: () => context.go(calendarRoute),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(LucideIcons.x, size: 16, color: t.textSecondary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The when block: a leading clock, the start → end times in mono with a
/// duration tag, and the human date beneath.
class _WhenBlock extends StatelessWidget {
  const _WhenBlock({required this.event, required this.l10n});

  final CalendarEvent event;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final start = event.startTime.toLocal();
    final end = event.endTime.toLocal();
    final sameDay =
        start.year == end.year && start.month == end.month && start.day == end.day;

    final Widget primary;
    if (event.isAllDay) {
      primary = Text(
        l10n.calendarAllDay,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: t.textPrimary,
        ),
      );
    } else {
      primary = Row(
        children: [
          Flexible(
            child: Text(
              DateFormat.jm().format(start),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _timeStyle(t),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(LucideIcons.arrowRight, size: 13, color: t.textTertiary),
          ),
          Flexible(
            child: Text(
              DateFormat.jm().format(end),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _timeStyle(t),
            ),
          ),
          const SizedBox(width: 8),
          _DurationTag(label: _durationLabel(end.difference(start))),
        ],
      );
    }

    final dateLabel = event.isAllDay || sameDay
        ? DateFormat.MMMEd().format(start)
        : '${DateFormat.MMMEd().format(start)} – ${DateFormat.MMMEd().format(end)}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(LucideIcons.clock, size: 16, color: t.textTertiary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              primary,
              const SizedBox(height: 3),
              Text(
                dateLabel,
                style: TextStyle(fontSize: 12.5, color: t.textTertiary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  TextStyle _timeStyle(DesignSystemTokens t) => AppFonts.codeStyle(
        fontSize: 14,
        color: t.textPrimary,
      );
}

/// A small mono tag for the meeting's duration (e.g. `15m`, `1h 30m`).
class _DurationTag extends StatelessWidget {
  const _DurationTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: t.hoverStrong,
        borderRadius: AppRadii.brSm,
      ),
      child: Text(
        label,
        style: AppFonts.codeStyle(fontSize: 11, color: t.textSecondary),
      ),
    );
  }
}

/// A tappable conferencing card: a neutral glyph, the provider label, the
/// joinable meeting code in mono, and a launch affordance. The whole row opens
/// the meeting URL.
class _ConferenceCard extends StatelessWidget {
  const _ConferenceCard({required this.url, required this.l10n});

  final String url;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final code = _meetCode(url);
    return InkWell(
      borderRadius: AppRadii.brSm,
      onTap: () => unawaitedLaunch(url),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
        decoration: BoxDecoration(
          color: t.panel,
          borderRadius: AppRadii.brSm,
          border: Border.all(color: t.borderSecondary),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: t.bgSecondary,
                borderRadius: AppRadii.brSm,
              ),
              child: Icon(LucideIcons.video, size: 15, color: t.textSecondary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _conferenceLabel(url, l10n),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: t.textPrimary,
                    ),
                  ),
                  if (code != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.codeStyle(fontSize: 11.5, color: t.textTertiary),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(LucideIcons.arrowUpRight, size: 15, color: t.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// The participant roster: a count + RSVP tally header, then a list of
/// attendees with their response state, collapsing behind "See all" past
/// [_kParticipantPreview].
class _ParticipantsSection extends StatefulWidget {
  const _ParticipantsSection({required this.event, required this.l10n});

  final CalendarEvent event;
  final AppLocalizations l10n;

  @override
  State<_ParticipantsSection> createState() => _ParticipantsSectionState();
}

class _ParticipantsSectionState extends State<_ParticipantsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = widget.l10n;
    final sorted = _sortedAttendees(widget.event.attendees);
    // Show everyone when there's barely more than the preview — hiding a single
    // row behind a toggle is more friction than it's worth.
    final collapsible = sorted.length > _kParticipantPreview + 1;
    final visible = (!collapsible || _expanded)
        ? sorted
        : sorted.sublist(0, _kParticipantPreview);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(LucideIcons.users, size: 15, color: t.textTertiary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.calendarParticipantsCount(sorted.length),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: t.textPrimary,
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      final tally = _rsvpTally(sorted, l10n);
                      if (tally == null) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          tally,
                          style: AppFonts.codeStyle(
                            fontSize: 11,
                            color: t.textTertiary,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final attendee in visible)
          _ParticipantRow(attendee: attendee, l10n: l10n),
        if (collapsible)
          Padding(
            padding: const EdgeInsets.only(left: 25, top: 2),
            child: InkWell(
              borderRadius: AppRadii.brSm,
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  _expanded
                      ? l10n.calendarShowFewer
                      : l10n.calendarSeeAllParticipants(sorted.length),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: t.textSecondary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Organizer first, then the local user, then everyone else alphabetically.
  List<CalendarAttendee> _sortedAttendees(List<CalendarAttendee> attendees) {
    int rank(CalendarAttendee a) => a.organizer
        ? 0
        : a.self
            ? 1
            : 2;
    return [...attendees]..sort((a, b) {
        final byRank = rank(a).compareTo(rank(b));
        if (byRank != 0) {
          return byRank;
        }
        return _attendeeName(a).toLowerCase().compareTo(
              _attendeeName(b).toLowerCase(),
            );
      });
  }

  /// "3 yes · 1 maybe · 1 awaiting", omitting empty buckets; null when there's
  /// nothing meaningful to tally.
  String? _rsvpTally(List<CalendarAttendee> attendees, AppLocalizations l10n) {
    var yes = 0, no = 0, maybe = 0, awaiting = 0;
    for (final a in attendees) {
      switch (a.responseStatus) {
        case 'accepted':
          yes++;
        case 'declined':
          no++;
        case 'tentative':
          maybe++;
        default:
          awaiting++;
      }
    }
    final parts = <String>[
      if (yes > 0) l10n.calendarRsvpCountYes(yes),
      if (maybe > 0) l10n.calendarRsvpCountMaybe(maybe),
      if (no > 0) l10n.calendarRsvpCountNo(no),
      if (awaiting > 0) l10n.calendarRsvpCountAwaiting(awaiting),
    ];
    // A lone "N awaiting" repeats the count already shown — not worth a row.
    if (parts.isEmpty || (parts.length == 1 && awaiting > 0)) {
      return null;
    }
    return parts.join(' · ');
  }
}

/// One attendee row: avatar, name with an organizer / you tag, and the response
/// glyph (shape + color, never color alone).
class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({required this.attendee, required this.l10n});

  final CalendarAttendee attendee;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final status = _statusVisual(attendee.responseStatus, t);
    final statusLabel = _statusLabel(attendee.responseStatus, l10n);
    final tag = attendee.organizer
        ? l10n.calendarOrganizer
        : attendee.self
            ? l10n.calendarYou
            : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          FAvatar.raw(
            size: 26,
            child: Text(
              _initials(attendee),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: t.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    _attendeeName(attendee),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: t.textPrimary),
                  ),
                ),
                if (tag != null) ...[
                  const SizedBox(width: 6),
                  _Tag(label: tag),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: statusLabel,
            child: Icon(status.icon, size: 16, color: status.color),
          ),
        ],
      ),
    );
  }
}

/// A faint mono tag (organizer / you) sitting beside a participant's name.
class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadii.brSm,
      ),
      child: Text(
        label.toUpperCase(),
        style: AppFonts.codeStyle(
          fontSize: 9,
          color: t.textTertiary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// The signature record-and-link action: open the linked meeting note when one
/// already exists, otherwise start a recording bound to this event.
class _MeetingNoteAction extends StatelessWidget {
  const _MeetingNoteAction({
    required this.event,
    required this.linkedMeetingId,
    required this.onStartRecording,
    required this.l10n,
  });

  final CalendarEvent event;
  final String? linkedMeetingId;
  final ValueChanged<CalendarEvent> onStartRecording;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (linkedMeetingId != null) {
      return FButton(
        variant: FButtonVariant.outline,
        size: FButtonSizeVariant.sm,
        onPress: () => context.go(meetingDetailRoute(linkedMeetingId!)),
        prefix: const Icon(LucideIcons.audioLines, size: 16),
        child: Text(l10n.calendarLinkedMeeting),
      );
    }
    return FButton(
      variant: FButtonVariant.primary,
      size: FButtonSizeVariant.sm,
      onPress: () => onStartRecording(event),
      prefix: const Icon(LucideIcons.circleDot, size: 16),
      child: Text(l10n.calendarStartRecordingAndLink),
    );
  }
}

/// Yes / No / Maybe RSVP control for an invitation, highlighting the user's
/// current response. Surfaces a snackbar if the write fails (e.g. the account
/// was connected before the write scope was added).
class _RsvpControls extends ConsumerStatefulWidget {
  const _RsvpControls({required this.event});

  final CalendarEvent event;

  @override
  ConsumerState<_RsvpControls> createState() => _RsvpControlsState();
}

class _RsvpControlsState extends ConsumerState<_RsvpControls> {
  bool _busy = false;

  Future<void> _respond(RsvpResponse response) async {
    if (_busy) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(calendarRsvpServiceProvider).respond(widget.event, response);
    } on Object {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.calendarRsvpFailed)),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final current = CalendarRsvpService.currentResponse(widget.event);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          l10n.calendarRsvpGoing,
          style: TextStyle(fontSize: 13, color: t.textSecondary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            children: [
              _RsvpButton(
                label: l10n.calendarRsvpYes,
                selected: current == 'accepted',
                onTap: _busy ? null : () => _respond(RsvpResponse.accepted),
              ),
              const SizedBox(width: 6),
              _RsvpButton(
                label: l10n.calendarRsvpNo,
                selected: current == 'declined',
                onTap: _busy ? null : () => _respond(RsvpResponse.declined),
              ),
              const SizedBox(width: 6),
              _RsvpButton(
                label: l10n.calendarRsvpMaybe,
                selected: current == 'tentative',
                onTap: _busy ? null : () => _respond(RsvpResponse.tentative),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RsvpButton extends StatelessWidget {
  const _RsvpButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        enabled: onTap != null,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? t.accent : t.bgSecondary,
              borderRadius: AppRadii.brSm,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? t.accentOn : t.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders a (usually HTML) event description as readable text plus tappable
/// link rows.
class _Description extends StatelessWidget {
  const _Description({required this.parsed});

  final ParsedDescription parsed;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parsed.text.isNotEmpty)
          Text(
            parsed.text,
            style: TextStyle(fontSize: 13, height: 1.45, color: t.textSecondary),
          ),
        for (final link in parsed.links)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: InkWell(
              borderRadius: AppRadii.brSm,
              onTap: () => unawaitedLaunch(link.url),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(LucideIcons.link, size: 14, color: t.textTertiary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      link.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: t.textSecondary,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        decorationColor: t.borderPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// The footer row identifying the source calendar: its color chip and the
/// connected account's email.
class _CalendarSourceRow extends StatelessWidget {
  const _CalendarSourceRow({required this.email, required this.color});

  final String email;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color ?? t.idle,
            borderRadius: AppRadii.brXs,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: t.textTertiary),
          ),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text, this.mono = false});

  final IconData icon;
  final String text;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 15, color: t.textTertiary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: mono
                  ? AppFonts.codeStyle(fontSize: 12, color: t.textSecondary)
                  : TextStyle(fontSize: 13, color: t.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// A hairline section break with consistent vertical rhythm.
class _SectionBreak extends StatelessWidget {
  const _SectionBreak();

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Container(height: 1, color: t.borderSecondary),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Center(
      child: Text(
        message,
        style: TextStyle(fontSize: 13, color: t.textTertiary),
      ),
    );
  }
}

/// The display name for an attendee, falling back to the email.
String _attendeeName(CalendarAttendee a) {
  final name = a.displayName?.trim();
  return (name != null && name.isNotEmpty) ? name : a.email;
}

/// Up-to-two-letter initials for an attendee's avatar.
String _initials(CalendarAttendee a) {
  final source = _attendeeName(a);
  final parts = source.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.length >= 2) {
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
  if (parts.isEmpty) {
    return '?';
  }
  final word = parts.first;
  return (word.length >= 2 ? word.substring(0, 2) : word).toUpperCase();
}

/// The icon + color for a participant's RSVP state. Shape always distinguishes
/// states, so meaning never rides on color alone.
({IconData icon, Color color}) _statusVisual(
  String? responseStatus,
  DesignSystemTokens t,
) {
  switch (responseStatus) {
    case 'accepted':
      return (icon: LucideIcons.circleCheck, color: t.success);
    case 'declined':
      return (icon: LucideIcons.circleX, color: t.textTertiary);
    case 'tentative':
      return (icon: LucideIcons.circleHelp, color: t.fgWarningPrimary);
    default:
      return (icon: LucideIcons.circleDashed, color: t.idle);
  }
}

/// The localized label for a participant's RSVP state, used as the response
/// glyph's tooltip / accessible label.
String _statusLabel(String? responseStatus, AppLocalizations l10n) {
  switch (responseStatus) {
    case 'accepted':
      return l10n.calendarRsvpYes;
    case 'declined':
      return l10n.calendarRsvpNo;
    case 'tentative':
      return l10n.calendarRsvpMaybe;
    default:
      return l10n.calendarRsvpAwaiting;
  }
}

/// A compact, machine-styled duration: `45m`, `1h`, `1h 30m`.
String _durationLabel(Duration d) {
  final mins = d.inMinutes;
  if (mins <= 0) {
    return '0m';
  }
  if (mins < 60) {
    return '${mins}m';
  }
  final hours = mins ~/ 60;
  final rem = mins % 60;
  return rem == 0 ? '${hours}h' : '${hours}h ${rem}m';
}

/// The local UTC offset as a `GMT±H[:MM]` label — the zone the times render in.
String _gmtLabel(DateTime local) {
  final offset = local.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final hours = offset.inHours.abs();
  final minutes = offset.inMinutes.abs() % 60;
  return minutes == 0
      ? 'GMT$sign$hours'
      : 'GMT$sign$hours:${minutes.toString().padLeft(2, '0')}';
}

/// The conferencing provider label for a meeting [url], derived from its host.
/// Known providers use their brand name (a proper noun, untranslated); an
/// unrecognized link falls back to the generic localized "Join meeting".
String _conferenceLabel(String url, AppLocalizations l10n) {
  final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
  if (host.contains('meet.google.com')) {
    return l10n.calendarGoogleMeet;
  }
  if (host.contains('zoom.')) {
    return 'Zoom';
  }
  if (host.contains('teams.microsoft.') || host.contains('teams.live.')) {
    return 'Microsoft Teams';
  }
  if (host.contains('webex.')) {
    return 'Webex';
  }
  return l10n.calendarJoinMeet;
}

/// Extracts a Google Meet code (`abc-defg-hij`) from a meeting [url], or null
/// when the link isn't a canonical Meet URL — so a Zoom/Teams id is never
/// mono-styled as if it were a meeting code.
String? _meetCode(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null ||
      !uri.host.toLowerCase().contains('meet.google.com') ||
      uri.pathSegments.isEmpty) {
    return null;
  }
  final segment = uri.pathSegments.last.trim().toLowerCase();
  return RegExp(r'^[a-z]{3}-[a-z]{4}-[a-z]{3}$').hasMatch(segment)
      ? segment
      : null;
}
