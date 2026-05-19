import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The per-workspace calendar event snapshot cache (stale-while-revalidate).
///
/// `eventsInRangeProvider` is an RPC subscription: every new range key starts
/// empty and only fills in when the server's first emission lands, which is
/// what made the all-day header pop open and push the calendar body down.
/// This cache keeps the last-known events per workspace — in memory for the
/// session, persisted via [AppPreferences] across restarts — so the calendar
/// can render synchronously from a (possibly stale) snapshot while the stream
/// refreshes underneath it.
final calendarEventCacheProvider = Provider<CalendarEventCache>((ref) {
  final cache = CalendarEventCache(ref.watch(appPreferencesProvider));
  ref.onDispose(cache.dispose);
  return cache;
});

/// Keeps the last-known calendar events per workspace, in memory and on disk.
class CalendarEventCache {
  /// Creates a cache backed by the given preferences store.
  CalendarEventCache(this._prefs);

  final AppPreferences _prefs;

  static const String _keyPrefix = 'calendar_events_snapshot__';

  /// Upper bound on persisted events per workspace, so the snapshot stays
  /// small no matter how many ranges were visited. Beyond the cap the
  /// earliest-ending events are evicted first (they are the least likely to be
  /// navigated back to).
  static const int _maxEventsPerWorkspace = 2000;

  /// Debounce for persisting after a range refresh, coalescing bursts of
  /// stream emissions into one preferences write.
  static const Duration _persistDebounce = Duration(seconds: 1);

  /// workspaceId → (eventId → event).
  final Map<String, Map<String, CalendarEvent>> _byWorkspace = {};

  /// Workspaces whose persisted snapshot has been read into [_byWorkspace].
  final Set<String> _loaded = {};

  /// Pending debounced persist per workspace.
  final Map<String, Timer> _persistTimers = {};

  /// Cancels pending persist timers (pending writes are simply dropped; the
  /// last persisted snapshot stays valid).
  void dispose() {
    for (final timer in _persistTimers.values) {
      timer.cancel();
    }
    _persistTimers.clear();
  }

  /// The cached events overlapping `[start, end)` (earliest first), or null
  /// when nothing was ever cached for [workspaceId] (first-ever run).
  List<CalendarEvent>? overlapping(
    String workspaceId,
    DateTime start,
    DateTime end,
  ) {
    _ensureLoaded(workspaceId);
    final events = _byWorkspace[workspaceId];
    if (events == null) {
      return null;
    }
    return events.values
        .where((e) => _overlaps(e, start, end))
        .toList(growable: false)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Replaces the cached slice for `[start, end)` with [fresh]: the range
  /// stream is authoritative for its window, so cached events overlapping it
  /// that are absent from [fresh] were moved away or deleted. Other slices are
  /// left untouched. Persists (debounced) only when something changed.
  void replaceRange(
    String workspaceId,
    DateTime start,
    DateTime end,
    List<CalendarEvent> fresh,
  ) {
    _ensureLoaded(workspaceId);
    final events = _byWorkspace.putIfAbsent(
      workspaceId,
      () => <String, CalendarEvent>{},
    );
    var changed = false;
    final stale = [
      for (final entry in events.entries)
        if (_overlaps(entry.value, start, end)) entry.key,
    ];
    if (stale.isNotEmpty) {
      changed = true;
      for (final id in stale) {
        events.remove(id);
      }
    }
    for (final event in fresh) {
      if (events[event.id] != event) {
        changed = true;
        events[event.id] = event;
      }
    }
    if (changed) {
      _evictOverflow(events);
      _schedulePersist(workspaceId);
    }
  }

  static bool _overlaps(CalendarEvent event, DateTime start, DateTime end) =>
      event.endTime.isAfter(start) && event.startTime.isBefore(end);

  /// Drops the earliest-ending events once past [_maxEventsPerWorkspace].
  static void _evictOverflow(Map<String, CalendarEvent> events) {
    if (events.length <= _maxEventsPerWorkspace) {
      return;
    }
    final byEnd = events.values.toList()
      ..sort((a, b) => a.endTime.compareTo(b.endTime));
    for (final event in byEnd.take(events.length - _maxEventsPerWorkspace)) {
      events.remove(event.id);
    }
  }

  /// Reads the persisted snapshot for [workspaceId] once, synchronously
  /// (AppPreferences reads are in-memory). A corrupt snapshot reads as empty
  /// and is overwritten by the next persist — it must never break the screen.
  void _ensureLoaded(String workspaceId) {
    if (!_loaded.add(workspaceId)) {
      return;
    }
    final raw = _prefs.getString('$_keyPrefix$workspaceId');
    if (raw == null) {
      return;
    }
    final events = _byWorkspace.putIfAbsent(
      workspaceId,
      () => <String, CalendarEvent>{},
    );
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return;
      }
      final list = decoded['events'];
      if (list is! List) {
        return;
      }
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          final event = _eventFromJson(workspaceId, item);
          if (event != null) {
            events[event.id] = event;
          }
        }
      }
    } on FormatException {
      // Corrupt snapshot: ignore; the next persist overwrites it.
    }
  }

  void _schedulePersist(String workspaceId) {
    _persistTimers[workspaceId]?.cancel();
    _persistTimers[workspaceId] = Timer(_persistDebounce, () {
      _persistTimers.remove(workspaceId);
      final events = _byWorkspace[workspaceId];
      if (events == null) {
        return;
      }
      _prefs.setString(
        '$_keyPrefix$workspaceId',
        jsonEncode({
          'v': 1,
          'events': [for (final event in events.values) _eventToJson(event)],
        }),
      );
    });
  }

  static Map<String, dynamic> _eventToJson(CalendarEvent event) => {
    'id': event.id,
    'accountId': event.accountId,
    'externalEventId': event.externalEventId,
    'calendarId': event.calendarId,
    'title': event.title,
    if (event.description != null) 'description': event.description,
    if (event.location != null) 'location': event.location,
    if (event.meetingUrl != null) 'meetingUrl': event.meetingUrl,
    if (event.recurringEventId != null)
      'recurringEventId': event.recurringEventId,
    'startTime': event.startTime.toIso8601String(),
    'endTime': event.endTime.toIso8601String(),
    'updatedAt': event.updatedAt.toIso8601String(),
    if (event.isAllDay) 'isAllDay': true,
    if (event.status != CalendarEventStatus.confirmed)
      'status': event.status.toStorage(),
    if (event.attendees.isNotEmpty)
      'attendees': [
        for (final a in event.attendees)
          {
            'email': a.email,
            if (a.displayName != null) 'displayName': a.displayName,
            if (a.responseStatus != null) 'responseStatus': a.responseStatus,
            if (a.self) 'self': true,
            if (a.organizer) 'organizer': true,
          },
      ],
  };

  static CalendarEvent? _eventFromJson(
    String workspaceId,
    Map<String, dynamic> json,
  ) {
    final id = json['id'];
    final accountId = json['accountId'];
    final externalEventId = json['externalEventId'];
    final calendarId = json['calendarId'];
    final title = json['title'];
    final startTime = DateTime.tryParse(json['startTime'] as String? ?? '');
    final endTime = DateTime.tryParse(json['endTime'] as String? ?? '');
    if (id is! String ||
        accountId is! String ||
        externalEventId is! String ||
        calendarId is! String ||
        title is! String ||
        startTime == null ||
        endTime == null) {
      return null;
    }
    final attendeesJson = json['attendees'];
    return CalendarEvent(
      id: id,
      workspaceId: workspaceId,
      accountId: accountId,
      externalEventId: externalEventId,
      calendarId: calendarId,
      title: title,
      description: json['description'] as String?,
      location: json['location'] as String?,
      meetingUrl: json['meetingUrl'] as String?,
      recurringEventId: json['recurringEventId'] as String?,
      startTime: startTime,
      endTime: endTime,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? startTime,
      isAllDay: json['isAllDay'] == true,
      status: CalendarEventStatus.fromStorage(json['status'] as String?),
      attendees: [
        if (attendeesJson is List)
          for (final a in attendeesJson)
            if (a is Map<String, dynamic> && a['email'] is String)
              CalendarAttendee(
                email: a['email'] as String,
                displayName: a['displayName'] as String?,
                responseStatus: a['responseStatus'] as String?,
                self: a['self'] == true,
                organizer: a['organizer'] == true,
              ),
      ],
    );
  }
}
