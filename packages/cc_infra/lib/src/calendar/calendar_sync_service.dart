import 'dart:async';

import 'package:cc_domain/core/domain/events/calendar_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_domain/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/network/google_calendar_api_client.dart';
import 'package:cc_infra/src/network/models/google_calendar_event.dart';
import 'package:uuid/uuid.dart';

/// Periodically syncs the active workspace's connected Google Calendar
/// (read-only) into the local store and publishes [CalendarEventsRefreshed].
///
/// Mirrors `PrPollingService`: a [Timer.periodic] plus an immediate run on
/// start. A no-op when there is no active workspace or no connected account.
///
/// The rolling-window sweep is **incremental**: the first pass per calendar
/// does a full window fetch and captures Google's `nextSyncToken`; subsequent
/// passes present the token and receive only the changed/cancelled instances
/// since — which is what makes the short [_interval] affordable (an unchanged
/// calendar costs one near-empty response instead of a 150-day re-fetch).
/// Because the token freezes the original request's window, a full re-sync
/// re-anchors it every [_reAnchorAfter] (and whenever Google answers 410).
class CalendarSyncService {
  /// Creates a [CalendarSyncService].
  CalendarSyncService({
    required GoogleCalendarApiClient apiClient,
    required CalendarRepository repository,
    required DomainEventBus eventBus,
    required String? Function() activeWorkspaceId,
    Duration interval = const Duration(minutes: 2),
    Duration lookBack = const Duration(days: 60),
    Duration lookAhead = const Duration(days: 90),
    Duration reAnchorAfter = const Duration(hours: 24),
    Uuid? uuid,
  }) : _apiClient = apiClient,
       _repository = repository,
       _eventBus = eventBus,
       _activeWorkspaceId = activeWorkspaceId,
       _interval = interval,
       _lookBack = lookBack,
       _lookAhead = lookAhead,
       _reAnchorAfter = reAnchorAfter,
       _uuid = uuid ?? const Uuid();

  final GoogleCalendarApiClient _apiClient;
  final CalendarRepository _repository;
  final DomainEventBus _eventBus;
  final String? Function() _activeWorkspaceId;
  final Duration _interval;

  /// How long a calendar's sync token is trusted before the window is
  /// re-anchored with a fresh full sync.
  final Duration _reAnchorAfter;

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
        // On-demand range loads use the plain windowed fetch: the range lies
        // outside the rolling window, so it must not disturb the per-calendar
        // sync tokens (which encode the rolling window).
        await _fetchAndUpsert(
          workspaceId,
          account.id,
          from,
          to,
          incremental: false,
        );
      }
      _covered.add((start: from, end: to));
    } on Object catch (e) {
      CcInfraLog.warning(
        'calendar_sync: Range load failed for $workspaceId: $e',
      );
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
          incremental: true,
        );
        await _repository.setLastSyncedAt(workspaceId, account.id, now);
      } on Object catch (e) {
        // One account failing (e.g. revoked token) must not block the others.
        CcInfraLog.warning('calendar_sync: Sync failed for ${account.id}: $e');
      }
    }
  }

  /// Fetches `[from, to]` from the provider and upserts the result, then
  /// publishes [CalendarEventsRefreshed]. Throws on API/store failure (callers
  /// decide how to log). With [incremental] the per-calendar sync tokens drive
  /// a changes-only fetch (full fetch only to mint/re-anchor a token); without
  /// it every calendar re-fetches the window (the on-demand range path).
  Future<void> _fetchAndUpsert(
    String workspaceId,
    String accountId,
    DateTime from,
    DateTime to, {
    required bool incremental,
  }) async {
    final now = DateTime.now();

    // Sync every calendar the user has (not just `primary`) so secondary
    // calendars — Family, Sports, holidays… — show up and can be toggled.
    // `freeBusyReader` calendars expose no event details, so skip them.
    final calendarIds = <String>[];
    try {
      final calendars = await _apiClient.listCalendars(accountId: accountId);
      // Persist the full per-account calendar list (the sidebar's source list).
      // The host owns the OAuth tokens, so thin clients read this via
      // `calendar.watchSources` instead of calling the provider directly.
      await _repository.upsertSources(
        workspaceId: workspaceId,
        accountId: accountId,
        sources: calendars
            .map(
              (c) => CalendarSource(
                workspaceId: workspaceId,
                accountId: accountId,
                id: c.id,
                summary: c.summary,
                backgroundColor: c.backgroundColor,
                primary: c.primary,
                writable: c.accessRole == 'owner' || c.accessRole == 'writer',
              ),
            )
            .toList(growable: false),
      );
      for (final c in calendars) {
        if (c.accessRole != 'freeBusyReader') {
          calendarIds.add(c.id);
        }
      }
    } on Object catch (e) {
      CcInfraLog.warning(
        'calendar_sync: listCalendars failed for $accountId: $e',
      );
    }
    if (calendarIds.isEmpty) {
      calendarIds.add('primary');
    }

    for (final calendarId in calendarIds) {
      if (incremental) {
        await _syncCalendarIncremental(
          workspaceId,
          accountId,
          calendarId,
          from,
          to,
          now,
        );
      } else {
        await _fetchWindow(workspaceId, accountId, calendarId, from, to, now);
      }
    }
    // Keep linked meetings' titles in sync with their event (unless the user
    // renamed the meeting). Cheap, idempotent and scoped to this workspace.
    await _repository.syncLinkedMeetingTitles(workspaceId);
    _eventBus.publish(
      CalendarEventsRefreshed(workspaceId: workspaceId, occurredAt: now),
    );
  }

  /// The plain windowed fetch + deletion reconcile (the pre-incremental
  /// behavior): used by on-demand range loads, which target windows outside
  /// the rolling one.
  Future<void> _fetchWindow(
    String workspaceId,
    String accountId,
    String calendarId,
    DateTime from,
    DateTime to,
    DateTime now,
  ) async {
    final dtos = await _apiClient.listEvents(
      accountId: accountId,
      calendarId: calendarId,
      timeMin: from,
      timeMax: to,
    );
    final events = dtos
        .where((dto) => !_isCancelled(dto))
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

  /// Token-driven sweep of one calendar: incremental (changes-only) when a
  /// fresh-enough token is held; a token-minting full window sync otherwise
  /// (first pass, [_reAnchorAfter] expiry, or a 410 from Google).
  Future<void> _syncCalendarIncremental(
    String workspaceId,
    String accountId,
    String calendarId,
    DateTime from,
    DateTime to,
    DateTime now,
  ) async {
    final state = await _repository.getSyncState(
      workspaceId,
      accountId,
      calendarId,
    );
    final mintedAt = state?.mintedAt;
    final tokenFresh =
        state != null &&
        mintedAt != null &&
        now.difference(mintedAt) < _reAnchorAfter;

    if (tokenFresh) {
      try {
        final result = await _apiClient.listEventsSync(
          accountId: accountId,
          calendarId: calendarId,
          syncToken: state.token,
        );
        final cancelled = <String>{
          for (final dto in result.events)
            if (_isCancelled(dto)) dto.id,
        };
        final live = result.events
            .where((dto) => !_isCancelled(dto))
            .map(
              (dto) => _toDomain(dto, workspaceId, accountId, now, calendarId),
            )
            .toList(growable: false);
        if (live.isNotEmpty) {
          await _repository.upsertEvents(live);
        }
        if (cancelled.isNotEmpty) {
          await _repository.deleteEventsByExternalIds(
            workspaceId: workspaceId,
            accountId: accountId,
            calendarId: calendarId,
            externalIds: cancelled,
          );
        }
        final nextToken = result.nextSyncToken;
        if (nextToken != null && nextToken != state.token) {
          // Keep the original mintedAt: the re-anchor clock runs from the
          // last FULL sync (the token still encodes that window).
          await _repository.setSyncState(
            workspaceId,
            accountId,
            calendarId,
            token: nextToken,
            mintedAt: mintedAt,
          );
        }
        return;
      } on CalendarSyncTokenExpired {
        CcInfraLog.info(
          'calendar_sync: sync token expired for $calendarId — full re-sync',
        );
        // Fall through to the token-minting full sync below.
      }
    }

    // Full window sync that mints a fresh token (no `orderBy`, so Google
    // returns `nextSyncToken` on the last page).
    final result = await _apiClient.listEventsSync(
      accountId: accountId,
      calendarId: calendarId,
      timeMin: from,
      timeMax: to,
    );
    final events = result.events
        .where((dto) => !_isCancelled(dto))
        .map((dto) => _toDomain(dto, workspaceId, accountId, now, calendarId))
        .toList(growable: false);
    await _repository.upsertEvents(events);
    await _repository.deleteEventsMissingFrom(
      workspaceId: workspaceId,
      accountId: accountId,
      calendarId: calendarId,
      from: from,
      to: to,
      keepExternalIds: {for (final e in events) e.externalEventId},
    );
    await _repository.setSyncState(
      workspaceId,
      accountId,
      calendarId,
      token: result.nextSyncToken,
      mintedAt: result.nextSyncToken == null ? null : now,
    );
  }

  static bool _isCancelled(GoogleCalendarEvent dto) =>
      dto.status == 'cancelled';

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
      attendees: _resolveAttendees(dto),
      meetingUrl: dto.meetUrl,
      status: CalendarEventStatus.fromStorage(dto.status),
      recurringEventId: dto.recurringEventId,
      updatedAt: dto.updated ?? now,
    );
  }

  /// Maps the DTO's attendees to domain attendees, backfilling any missing
  /// per-attendee display name from the top-level organizer/creator objects —
  /// Google often provides the real name only there, while invitee entries
  /// carry just an email.
  List<CalendarAttendee> _resolveAttendees(GoogleCalendarEvent dto) {
    final nameByEmail = <String, String>{};
    for (final p in [dto.organizer, dto.creator]) {
      final name = p?.displayName?.trim();
      if (p != null && p.email.isNotEmpty && name != null && name.isNotEmpty) {
        nameByEmail.putIfAbsent(p.email.toLowerCase(), () => name);
      }
    }
    return dto.attendees
        .map((a) {
          final existing = a.displayName?.trim();
          final resolved = (existing != null && existing.isNotEmpty)
              ? existing
              : nameByEmail[a.email.toLowerCase()];
          return CalendarAttendee(
            email: a.email,
            displayName: resolved,
            responseStatus: a.responseStatus,
            self: a.self,
            organizer: a.organizer,
          );
        })
        .toList(growable: false);
  }

  /// Disposes the timer.
  void dispose() => stop();
}
