import 'dart:async';

import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/calendar/domain/entities/calendar_event.dart';
import 'package:control_center/features/calendar/presentation/calendar_view_mode.dart';
import 'package:control_center/features/calendar/presentation/utils/calendar_format.dart';
import 'package:control_center/features/calendar/providers/calendar_sync_providers.dart';
import 'package:control_center/features/calendar/providers/google_auth_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter/material.dart' show Color, DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The persisted calendar view mode (month / week / agenda).
final calendarViewModeProvider =
    NotifierProvider<CalendarViewModeNotifier, CalendarViewMode>(
  CalendarViewModeNotifier.new,
);

/// Persists the calendar view mode via SharedPreferences.
class CalendarViewModeNotifier extends Notifier<CalendarViewMode> {
  @override
  CalendarViewMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return CalendarViewMode.fromStorage(prefs.getString(calendarViewModeKey));
  }

  /// Sets and persists the view mode.
  void setMode(CalendarViewMode mode) {
    if (mode == state) {
      return;
    }
    ref.read(sharedPreferencesProvider).setString(
          calendarViewModeKey,
          mode.toStorageString(),
        );
    state = mode;
  }
}

/// The day the calendar is focused on (date-only). Drives month/week framing
/// and the agenda's starting point. Ephemeral (not persisted).
final selectedDateProvider =
    NotifierProvider<SelectedDateNotifier, DateTime>(SelectedDateNotifier.new);

/// Holds the focused calendar day.
class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Focuses [date] (normalized to date-only).
  void select(DateTime date) =>
      state = DateTime(date.year, date.month, date.day);
}

/// Identifies a workspace + date range to stream events for.
typedef CalendarRangeRef = ({String workspaceId, DateTimeRange range});

/// Streams the events overlapping a range for a workspace (earliest first).
final eventsInRangeProvider =
    StreamProvider.family<List<CalendarEvent>, CalendarRangeRef>((ref, args) {
  return ref.watch(calendarRepositoryProvider).watchEventsInRange(
        args.workspaceId,
        args.range.start,
        args.range.end,
      );
});

/// Identifies a workspace + meeting (for the calendar link lookups).
typedef CalendarMeetingRef = ({String workspaceId, String meetingId});

/// Identifies a workspace + calendar event.
typedef CalendarEventRef = ({String workspaceId, String eventId});

/// Streams a single event by id, with no time window, so the detail panel
/// resolves any event — including a past one outside the synced range, or one
/// reached by deep link / notification.
final calendarEventByIdProvider =
    StreamProvider.family<CalendarEvent?, CalendarEventRef>((ref, args) {
  return ref
      .watch(calendarRepositoryProvider)
      .watchEventById(args.workspaceId, args.eventId);
});

/// The calendar event a meeting was recorded for (null if unlinked). Powers the
/// "From calendar" chip on the meeting detail screen.
final eventForMeetingProvider =
    FutureProvider.family<CalendarEvent?, CalendarMeetingRef>((ref, args) {
  return ref
      .watch(calendarRepositoryProvider)
      .getEventForMeeting(args.workspaceId, args.meetingId);
});

/// The id of the meeting recorded for an event (null if none). Powers the
/// "linked meeting" affordance on the event detail.
final meetingIdForEventProvider =
    FutureProvider.family<String?, CalendarEventRef>((ref, args) {
  return ref
      .watch(calendarRepositoryProvider)
      .getMeetingIdForEvent(args.workspaceId, args.eventId);
});

/// The date range the calendar should load for a given [mode] focused on
/// [selected]. Month loads the full 6-week grid; week loads the Monday-started
/// 7-day span; agenda loads the next 30 days from [selected].
DateTimeRange visibleRangeFor(CalendarViewMode mode, DateTime selected) {
  switch (mode) {
    case CalendarViewMode.month:
      final start = startOfMonthGrid(selected);
      return DateTimeRange(start: start, end: start.add(const Duration(days: 42)));
    case CalendarViewMode.week:
      final start = startOfWeek(selected);
      return DateTimeRange(start: start, end: start.add(const Duration(days: 7)));
    case CalendarViewMode.day:
      final start = dayKey(selected);
      return DateTimeRange(start: start, end: start.add(const Duration(days: 1)));
    case CalendarViewMode.agenda:
      final start = dayKey(selected);
      return DateTimeRange(start: start, end: start.add(const Duration(days: 30)));
  }
}

/// The workspace + range the calendar is currently framing (null when no
/// workspace is active). Recomputed when the view mode or focused date changes.
final calendarVisibleRangeProvider = Provider<CalendarRangeRef?>((ref) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return null;
  }
  final mode = ref.watch(calendarViewModeProvider);
  final selected = ref.watch(selectedDateProvider);
  return (workspaceId: workspaceId, range: visibleRangeFor(mode, selected));
});

/// Lazily loads events for the framed range as the user navigates, so months
/// outside the rolling sync window (further into the past or future) populate
/// on demand. Watch this from the calendar screen to keep it active.
final calendarRangeLoaderProvider = Provider<void>((ref) {
  ref.listen<CalendarRangeRef?>(
    calendarVisibleRangeProvider,
    (_, next) {
      if (next == null) {
        return;
      }
      unawaited(
        ref.read(calendarSyncServiceProvider).ensureRangeLoaded(
              next.workspaceId,
              next.range.start,
              next.range.end,
            ),
      );
    },
    fireImmediately: true,
  );
});

/// One of the user's calendars (id, display name, accent color), as shown in
/// the sidebar. A presentation projection of the provider's calendar list.
class CalendarSource {
  /// Creates a [CalendarSource].
  const CalendarSource({
    required this.accountId,
    required this.accountEmail,
    required this.id,
    required this.summary,
    required this.color,
    required this.primary,
    required this.writable,
  });

  /// The owning connected account id.
  final String accountId;

  /// The owning account's email (for grouping in the sidebar).
  final String accountEmail;

  /// The provider calendar id (`primary` for the account's main calendar).
  final String id;

  /// Display name.
  final String summary;

  /// The calendar's accent color (parsed from the provider's hex), or null.
  final Color? color;

  /// Whether this is the account's primary calendar.
  final bool primary;

  /// Whether the user can write to it (RSVP is only meaningful when writable).
  final bool writable;

  /// Stable key combining account + calendar — calendar ids like `primary`
  /// repeat across accounts, so views key colors/visibility on this.
  String get key => calendarKey(accountId, id);
}

/// The composite key identifying a calendar within a specific account. Used for
/// per-calendar color and visibility, since `primary` is not unique across
/// accounts.
String calendarKey(String accountId, String calendarId) =>
    '$accountId|$calendarId';

/// Parses a `#rrggbb` hex string into a [Color], or null when absent/invalid.
Color? parseHexColor(String? hex) {
  if (hex == null || hex.isEmpty) {
    return null;
  }
  final cleaned = hex.startsWith('#') ? hex.substring(1) : hex;
  if (cleaned.length != 6) {
    return null;
  }
  final value = int.tryParse(cleaned, radix: 16);
  return value == null ? null : Color(0xFF000000 | value);
}

/// Identifies a connected account for the calendar-list lookup.
typedef CalendarAccountListRef = ({String accountId, String accountEmail});

/// One account's calendars (primary first, then alphabetical). Backed by the
/// Google `calendarList` endpoint, fetched with that account's token.
final calendarListProvider = FutureProvider.family<List<CalendarSource>,
    CalendarAccountListRef>((ref, account) async {
  final entries = await ref
      .watch(googleCalendarApiClientProvider)
      .listCalendars(accountId: account.accountId);
  final sources = entries
      .map(
        (e) => CalendarSource(
          accountId: account.accountId,
          accountEmail: account.accountEmail,
          id: e.id,
          summary: e.summary,
          color: parseHexColor(e.backgroundColor),
          primary: e.primary,
          writable: e.accessRole == 'owner' || e.accessRole == 'writer',
        ),
      )
      .toList()
    ..sort((a, b) {
      if (a.primary != b.primary) {
        return a.primary ? -1 : 1;
      }
      return a.summary.toLowerCase().compareTo(b.summary.toLowerCase());
    });
  return sources;
});

/// All of the active workspace's calendars across every connected account
/// (each tagged with its account), for the sidebar list.
final allCalendarsProvider = Provider<List<CalendarSource>>((ref) {
  final accounts = ref.watch(googleAccountsProvider).asData?.value ?? const [];
  final all = <CalendarSource>[];
  for (final account in accounts) {
    final sources = ref
            .watch(calendarListProvider(
              (accountId: account.id, accountEmail: account.accountEmail),
            ))
            .asData
            ?.value ??
        const [];
    all.addAll(sources);
  }
  return all;
});

/// Map of `calendarKey(accountId, calendarId) → color`, so event tiles take
/// their calendar's color (falling back to the brand accent when unknown).
final calendarColorsProvider = Provider<Map<String, Color>>((ref) {
  return {
    for (final s in ref.watch(allCalendarsProvider))
      if (s.color != null) s.key: s.color!,
  };
});

/// The set of calendar ids the user has hidden in the active workspace,
/// persisted via SharedPreferences. Hidden calendars stay synced; they're just
/// filtered from the views.
final hiddenCalendarsProvider =
    NotifierProvider<HiddenCalendarsNotifier, Set<String>>(
  HiddenCalendarsNotifier.new,
);

/// Loads/persists hidden-calendar ids for the active workspace.
class HiddenCalendarsNotifier extends Notifier<Set<String>> {
  String? _workspaceId;

  String _key(String workspaceId) => 'calendar_hidden__$workspaceId';

  @override
  Set<String> build() {
    _workspaceId = ref.watch(activeWorkspaceIdProvider);
    final prefs = ref.watch(sharedPreferencesProvider);
    final ws = _workspaceId;
    if (ws == null) {
      return const <String>{};
    }
    return (prefs.getStringList(_key(ws)) ?? const <String>[]).toSet();
  }

  /// Shows/hides [calendarId] and persists the change.
  void toggle(String calendarId) {
    final ws = _workspaceId;
    if (ws == null) {
      return;
    }
    final next = <String>{...state};
    if (!next.remove(calendarId)) {
      next.add(calendarId);
    }
    ref.read(sharedPreferencesProvider).setStringList(_key(ws), next.toList());
    state = next;
  }
}
