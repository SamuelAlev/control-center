import 'dart:async';

import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/events/calendar_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/user_preferences_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_domain/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:cc_server_core/src/meeting_alert_sweep.dart';
import 'package:test/test.dart';

final _now = DateTime.utc(2026, 11, 13, 9);

class _Calendar implements CalendarRepository {
  final List<CalendarEvent> events = [];
  final List<CalendarAccount> accounts = [];
  final Map<String, DateTime> alerted = {};

  @override
  Future<List<CalendarEvent>> getUpcomingEventsNeedingAlert(
    String workspaceId,
    DateTime windowStart,
    DateTime windowEnd,
  ) async => [
    for (final e in events)
      if (e.workspaceId == workspaceId &&
          !alerted.containsKey(e.id) &&
          !e.isAllDay &&
          !e.startTime.isBefore(windowStart) &&
          !e.startTime.isAfter(windowEnd))
        e,
  ];

  @override
  Future<void> markAlerted(
    String workspaceId,
    String eventId,
    DateTime at,
  ) async => alerted[eventId] = at;

  @override
  Future<List<CalendarAccount>> getAccounts(String workspaceId) async => [
    for (final a in accounts)
      if (a.workspaceId == workspaceId) a,
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _Workspaces implements WorkspaceRepository {
  @override
  Stream<List<Workspace>> watchAll() => Stream.value([
    Workspace(id: 'ws1', name: 'One', createdAt: _now, updatedAt: _now),
  ]);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _Preferences implements UserPreferencesRepository {
  final Map<String, Map<String, String>> values = {};

  @override
  Future<String?> get(String userId, String key) async => values[userId]?[key];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

CalendarEvent _event(
  String id, {
  required Duration startsIn,
  String accountId = 'acc-ann',
  CalendarEventStatus status = CalendarEventStatus.confirmed,
  List<CalendarAttendee> attendees = const [],
}) => CalendarEvent(
  id: id,
  workspaceId: 'ws1',
  accountId: accountId,
  externalEventId: 'ext-$id',
  calendarId: 'ann@example.com',
  title: 'Meeting $id',
  startTime: _now.add(startsIn),
  endTime: _now.add(startsIn + const Duration(minutes: 30)),
  updatedAt: _now,
  status: status,
  attendees: attendees,
);

void main() {
  late _Calendar calendar;
  late _Preferences preferences;
  late DomainEventBus bus;
  late List<MeetingStartingSoon> published;
  late StreamSubscription<MeetingStartingSoon> sub;
  late MeetingAlertSweep sweep;

  setUp(() {
    calendar = _Calendar()
      ..accounts.addAll(const [
        CalendarAccount(
          id: 'acc-ann',
          workspaceId: 'ws1',
          userId: 'ann',
          providerId: 'google',
          accountEmail: 'ann@example.com',
        ),
        CalendarAccount(
          id: 'acc-bob',
          workspaceId: 'ws1',
          userId: 'bob',
          providerId: 'google',
          accountEmail: 'bob@example.com',
        ),
      ]);
    preferences = _Preferences();
    bus = DomainEventBus();
    published = [];
    sub = bus.on<MeetingStartingSoon>().listen(published.add);
    sweep = MeetingAlertSweep(
      calendarRepository: calendar,
      workspaceRepository: _Workspaces(),
      userPreferences: preferences,
      eventBus: bus,
      clock: () => _now,
    );
  });

  tearDown(() async {
    sweep.dispose();
    await sub.cancel();
  });

  Future<void> run() async {
    await sweep.sweep();
    await Future<void>.delayed(Duration.zero);
  }

  test('alerts the calendar owner once, inside the default lead', () async {
    calendar.events.addAll([
      _event('soon', startsIn: const Duration(minutes: 4)),
      _event('later', startsIn: const Duration(minutes: 20)),
    ]);

    await run();
    await run();

    expect(published.map((e) => e.eventId), ['soon']);
    expect(published.single.forUserId, 'ann');
    expect(calendar.alerted.keys, ['soon']);
  });

  test("uses each owner's own lead time", () async {
    preferences.values['bob'] = {meetingAlertLeadPreferenceKey: '30'};
    calendar.events.addAll([
      _event('ann', startsIn: const Duration(minutes: 20)),
      _event(
        'bob',
        startsIn: const Duration(minutes: 20),
        accountId: 'acc-bob',
      ),
    ]);

    await run();

    expect(published.map((e) => (e.eventId, e.forUserId)), [('bob', 'bob')]);
  });

  test('skips cancelled and declined meetings', () async {
    calendar.events.addAll([
      _event(
        'cancelled',
        startsIn: const Duration(minutes: 2),
        status: CalendarEventStatus.cancelled,
      ),
      _event(
        'declined',
        startsIn: const Duration(minutes: 2),
        attendees: const [
          CalendarAttendee(
            email: 'ann@example.com',
            responseStatus: 'declined',
            self: true,
          ),
        ],
      ),
    ]);

    await run();

    expect(published, isEmpty);
  });
}
