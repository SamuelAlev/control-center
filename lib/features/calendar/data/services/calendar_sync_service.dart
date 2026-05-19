import 'dart:async';

import 'package:control_center/core/domain/events/calendar_events.dart';
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/network/google_calendar_api_client.dart';
import 'package:control_center/core/network/models/google_calendar_event.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/calendar/domain/entities/calendar_event.dart';
import 'package:control_center/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:uuid/uuid.dart';

/// Periodically syncs the active workspace's connected Google Calendar
/// (read-only) into the local store and publishes [CalendarEventsRefreshed].
///
/// Mirrors `PrPollingService`: a [Timer.periodic] plus an immediate run on
/// start. A no-op when there is no active workspace or no connected account.
class CalendarSyncService {
  /// Creates a [CalendarSyncService].
  CalendarSyncService({
    required GoogleCalendarApiClient apiClient,
    required CalendarRepository repository,
    required DomainEventBus eventBus,
    required String? Function() activeWorkspaceId,
    Duration interval = const Duration(minutes: 7),
    Duration lookBack = const Duration(days: 60),
    Duration lookAhead = const Duration(days: 90),
    Uuid? uuid,
  })  : _apiClient = apiClient,
        _repository = repository,
        _eventBus = eventBus,
        _activeWorkspaceId = activeWorkspaceId,
        _interval = interval,
        _lookBack = lookBack,
        _lookAhead = lookAhead,
        _uuid = uuid ?? const Uuid();

  final GoogleCalendarApiClient _apiClient;
  final CalendarRepository _repository;
  final DomainEventBus _eventBus;
  final String? Function() _activeWorkspaceId;
  final Duration _interval;

  /// How far into the past to fetch events. Without this the Google API's
  /// `timeMin` would exclude every event whose end is before "now" — so
  /// already-finished meetings (including earlier-today ones) would never be
  /// stored and could not be shown in the week/month/day views.
  final Duration _lookBack;
  final Duration _lookAhead;
  final Uuid _uuid;

  Timer? _timer;

  /// Date ranges already fetched on demand (for the [_coveredWorkspaceId]),
  /// so navigating back to a previously-loaded month doesn't refetch.
  final List<({DateTime start, DateTime end})> _covered = [];

  /// Ranges currently being fetched (keyed) — guards against firing the same
  /// on-demand fetch twice while one is in flight.
  final Set<String> _inFlight = {};

  /// The workspace [_covered] applies to. The service instance outlives a
  /// workspace switch, so coverage is reset when the active workspace changes.
  String? _coveredWorkspaceId;

  /// Starts the periodic sync (runs an immediate sync too).
  void start() {
    if (_timer != null) {
      return;
    }
    _timer = Timer.periodic(_interval, (_) => unawaited(_sync()));
    unawaited(_sync());
  }

  /// Stops the periodic sync.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Whether the sync loop is running.
  bool get isRunning => _timer != null;

  /// Triggers an immediate sync (used after connecting + for manual refresh).
  Future<void> refreshNow() => _sync();

  /// Ensures events for `[from, to]` are loaded for [workspaceId], fetching
  /// them on demand. Used when the user navigates the calendar to a month
  /// outside the rolling sync window so past/future months lazily populate.
  ///
  /// No-op when the range is already inside the rolling window (the periodic
  /// sync covers it) or was already fetched on demand this session.
  Future<void> ensureRangeLoaded(
    String workspaceId,
    DateTime from,
    DateTime to,
  ) async {
    _resetCoverageIfWorkspaceChanged(workspaceId);
    if (_isWithinRollingWindow(from, to) || _isCovered(from, to)) {
      return;
    }
    final key = '${from.toIso8601String()}/${to.toIso8601String()}';
    if (!_inFlight.add(key)) {
      return; // an identical fetch is already running
    }
    try {
      final accounts = await _repository.getAccounts(workspaceId);
      if (accounts.isEmpty) {
        return;
      }
      for (final account in accounts) {
        await _fetchAndUpsert(workspaceId, account.id, from, to);
      }
      _covered.add((start: from, end: to));
    } on Object catch (e) {
      AppLog.w('calendar_sync', 'Range load failed for $workspaceId: $e');
    } finally {
      _inFlight.remove(key);
    }
  }

  Future<void> _sync() async {
    final workspaceId = _activeWorkspaceId();
    if (workspaceId == null) {
      return;
    }
    _resetCoverageIfWorkspaceChanged(workspaceId);
    final accounts = await _repository.getAccounts(workspaceId);
    if (accounts.isEmpty) {
      return; // not connected
    }
    final now = DateTime.now();
    for (final account in accounts) {
      try {
        await _fetchAndUpsert(
          workspaceId,
          account.id,
          now.subtract(_lookBack),
          now.add(_lookAhead),
        );
        await _repository.setLastSyncedAt(workspaceId, account.id, now);
      } on Object catch (e) {
        // One account failing (e.g. revoked token) must not block the others.
        AppLog.w('calendar_sync', 'Sync failed for ${account.id}: $e');
      }
    }
  }

  /// Fetches `[from, to]` from the provider and upserts the result, then
  /// publishes [CalendarEventsRefreshed]. Throws on API/store failure (callers
  /// decide how to log).
  Future<void> _fetchAndUpsert(
    String workspaceId,
    String accountId,
    DateTime from,
    DateTime to,
  ) async {
    final now = DateTime.now();

    // Sync every calendar the user has (not just `primary`) so secondary
    // calendars — Family, Sports, holidays… — show up and can be toggled.
    // `freeBusyReader` calendars expose no event details, so skip them.
    final calendarIds = <String>[];
    try {
      final calendars = await _apiClient.listCalendars(accountId: accountId);
      for (final c in calendars) {
        if (c.accessRole != 'freeBusyReader') {
          calendarIds.add(c.id);
        }
      }
    } on Object catch (e) {
      AppLog.w('calendar_sync', 'listCalendars failed for $accountId: $e');
    }
    if (calendarIds.isEmpty) {
      calendarIds.add('primary');
    }

    for (final calendarId in calendarIds) {
      final dtos = await _apiClient.listEvents(
        accountId: accountId,
        calendarId: calendarId,
        timeMin: from,
        timeMax: to,
      );
      final events = dtos
          .map((dto) => _toDomain(dto, workspaceId, accountId, now, calendarId))
          .toList(growable: false);
      await _repository.upsertEvents(events);
      // Reconcile deletions: the provider returns only live events for the
      // window, so anything we still hold for this calendar+window that the
      // fetch didn't return was deleted (or moved out of range) on the server.
      // Scoped to this calendar + window so we never drop events another
      // calendar owns or events outside the fetched range.
      await _repository.deleteEventsMissingFrom(
        workspaceId: workspaceId,
        accountId: accountId,
        calendarId: calendarId,
        from: from,
        to: to,
        keepExternalIds: {for (final e in events) e.externalEventId},
      );
    }
    _eventBus.publish(
      CalendarEventsRefreshed(workspaceId: workspaceId, occurredAt: now),
    );
  }

  void _resetCoverageIfWorkspaceChanged(String workspaceId) {
    if (_coveredWorkspaceId != workspaceId) {
      _coveredWorkspaceId = workspaceId;
      _covered.clear();
    }
  }

  bool _isWithinRollingWindow(DateTime from, DateTime to) {
    final now = DateTime.now();
    return !from.isBefore(now.subtract(_lookBack)) &&
        !to.isAfter(now.add(_lookAhead));
  }

  bool _isCovered(DateTime from, DateTime to) {
    for (final r in _covered) {
      if (!from.isBefore(r.start) && !to.isAfter(r.end)) {
        return true;
      }
    }
    return false;
  }

  CalendarEvent _toDomain(
    GoogleCalendarEvent dto,
    String workspaceId,
    String accountId,
    DateTime now,
    String calendarId,
  ) {
    final start = dto.start.resolved;
    var end = dto.end.resolved;
    if (end.isBefore(start)) {
      end = start;
    }
    return CalendarEvent(
      id: _uuid.v4(),
      workspaceId: workspaceId,
      accountId: accountId,
      externalEventId: dto.id,
      calendarId: calendarId,
      title: dto.summary,
      description: dto.description,
      location: dto.location,
      startTime: start,
      endTime: end,
      isAllDay: dto.isAllDay,
      attendees: dto.attendees
          .map(
            (a) => CalendarAttendee(
              email: a.email,
              displayName: a.displayName,
              responseStatus: a.responseStatus,
              self: a.self,
              organizer: a.organizer,
            ),
          )
          .toList(growable: false),
      meetingUrl: dto.meetUrl,
      status: CalendarEventStatus.fromStorage(dto.status),
      recurringEventId: dto.recurringEventId,
      updatedAt: dto.updated ?? now,
    );
  }

  /// Disposes the timer.
  void dispose() => stop();
}
