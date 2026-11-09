import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_domain/features/calendar/domain/entities/calendar_event_reschedule.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_event_write_provider.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_rsvp_provider.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_ui_providers.dart';
import 'package:control_center/features/calendar/presentation/providers/record_and_link_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Whether [event] belongs to one of the person's own connected accounts —
/// the only events they may answer or delete.
bool isOwnCalendarEvent(WidgetRef ref, CalendarEvent event) =>
    ref.watch(allCalendarsProvider).any((c) => c.accountId == event.accountId);

/// Moves [event] to the span it was dropped on, then opens it so the new
/// time reads back. False (after a toast) when the host refused, so the grid
/// puts the tile back.
Future<bool> moveCalendarEvent(
  BuildContext context,
  WidgetRef ref,
  CalendarEvent event,
  CalendarSlot to,
) async {
  final l10n = AppLocalizations.of(context);
  final workspaceId = context.currentWorkspaceId!;
  try {
    await ref
        .read(calendarEventWriteServiceProvider)
        .move(
          event,
          CalendarEventReschedule(
            eventId: event.id,
            start: to.start,
            end: to.end,
            isAllDay: to.allDay,
          ),
        );
  } on Object {
    if (context.mounted) {
      CcToastScope.of(
        context,
      ).show(l10n.calendarMoveFailed, variant: CcToastVariant.danger);
    }
    return false;
  }
  if (context.mounted) {
    context.go(calendarDetailRoute(workspaceId, event.id));
  }
  return true;
}

/// Starts a local recording seeded from [event] and links the two. Closed on
/// public demo workspaces: only the Meetings page starts the scripted
/// session there.
Future<void> startCalendarRecording(
  BuildContext context,
  WidgetRef ref,
  CalendarEvent event,
) async {
  final l10n = AppLocalizations.of(context);
  final ws = context.currentWorkspaceId!;
  if (ref.read(isDemoServerProvider)) {
    CcToastScope.of(context).show(l10n.demoUnavailableTitle);
    return;
  }
  final result = await ref
      .read(calendarRecordAndLinkProvider)
      .startRecordingForEvent(event);
  if (!context.mounted) {
    return;
  }
  if (result.meetingId != null) {
    context.go(meetingsRecordRoute(ws));
  } else {
    CcToastScope.of(context).show(
      result.error ?? l10n.calendarConnectError,
      variant: CcToastVariant.danger,
    );
  }
}

/// The detail header's delete action, shown for events on a calendar the
/// person may write to. Confirms first, naming who else is affected.
class CalendarDeleteEventButton extends ConsumerStatefulWidget {
  /// Creates a [CalendarDeleteEventButton] for [event].
  const CalendarDeleteEventButton({super.key, required this.event});

  /// The event to delete.
  final CalendarEvent event;

  @override
  ConsumerState<CalendarDeleteEventButton> createState() => _DeleteState();
}

class _DeleteState extends ConsumerState<CalendarDeleteEventButton> {
  bool _busy = false;

  /// The consequence line: an organizer cancels for every guest; a guest only
  /// clears their own copy; a recurring occurrence leaves the series.
  String _consequence(AppLocalizations l10n) {
    final event = widget.event;
    final me = event.attendees.where((a) => a.self).firstOrNull;
    final hasGuests = event.attendees.any((a) => !a.self);
    final base = me != null && !me.organizer
        ? l10n.calendarDeleteConfirmInvite
        : hasGuests
        ? l10n.calendarDeleteConfirmGuests
        : l10n.calendarDeleteConfirmBody;
    return event.recurringEventId == null
        ? base
        : '$base ${l10n.calendarDeleteConfirmRecurring}';
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final toaster = CcToastScope.of(context);
    final workspaceId = context.currentWorkspaceId!;
    final confirmed = await showCcConfirmDialog(
      context: context,
      title: l10n.calendarDeleteConfirmTitle(widget.event.title),
      message: _consequence(l10n),
      confirmLabel: l10n.calendarDeleteEvent,
      cancelLabel: l10n.cancel,
      danger: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(calendarEventWriteServiceProvider).delete(widget.event);
      if (mounted) {
        context.go(calendarRoute(workspaceId));
      }
    } on Object {
      toaster.show(l10n.calendarDeleteFailed, variant: CcToastVariant.danger);
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(isDemoServerProvider) ||
        !canDeleteCalendarEvent(
          widget.event,
          ref.watch(writableCalendarsProvider),
        )) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return CcIconButton(
      icon: AppIcons.trash2,
      variant: CcButtonVariant.ghost,
      size: CcButtonSize.sm,
      tooltip: l10n.calendarDeleteEvent,
      semanticLabel: l10n.calendarDeleteEvent,
      onPressed: _busy ? null : _delete,
    );
  }
}

/// Yes / No / Maybe RSVP control for an invitation, highlighting the user's
/// current response. Shows a toast if the write fails.
class CalendarRsvpControls extends ConsumerStatefulWidget {
  /// Creates a [CalendarRsvpControls] for [event].
  const CalendarRsvpControls({super.key, required this.event});

  /// The invitation being answered.
  final CalendarEvent event;

  @override
  ConsumerState<CalendarRsvpControls> createState() => _RsvpControlsState();
}

class _RsvpControlsState extends ConsumerState<CalendarRsvpControls> {
  bool _busy = false;

  Future<void> _respond(RsvpResponse response) async {
    if (_busy) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final toaster = CcToastScope.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(calendarRsvpServiceProvider)
          .respond(widget.event, response);
    } on Object {
      toaster.show(l10n.calendarRsvpFailed, variant: CcToastVariant.danger);
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
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: IgnorePointer(
              ignoring: _busy,
              child: Opacity(
                opacity: _busy ? 0.5 : 1.0,
                child: CcSegmentedToggle<String>(
                  value: current ?? '',
                  onChanged: (response) {
                    switch (response) {
                      case 'accepted':
                        _respond(RsvpResponse.accepted);
                      case 'declined':
                        _respond(RsvpResponse.declined);
                      case 'tentative':
                        _respond(RsvpResponse.tentative);
                    }
                  },
                  segments: [
                    CcSegment(value: 'accepted', label: l10n.calendarRsvpYes),
                    CcSegment(value: 'declined', label: l10n.calendarRsvpNo),
                    CcSegment(
                      value: 'tentative',
                      label: l10n.calendarRsvpMaybe,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
