import 'package:cc_domain/core/domain/events/calendar_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:control_center/features/calendar/data/services/meeting_alert_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_calendar_repository.dart';

CalendarEvent _event(String id) => CalendarEvent(
      id: id,
      workspaceId: 'ws-A',
      accountId: 'acc-1',
      externalEventId: 'ext-$id',
      calendarId: 'primary',
      title: 'Event $id',
      startTime: DateTime.now().add(const Duration(minutes: 3)),
      endTime: DateTime.now().add(const Duration(minutes: 33)),
      updatedAt: DateTime.now(),
    );

void main() {
  group('MeetingAlertScheduler', () {
    late FakeCalendarRepository repo;
    late DomainEventBus bus;

    setUp(() {
      repo = FakeCalendarRepository();
      bus = DomainEventBus();
    });

    tearDown(() => bus.dispose());

    MeetingAlertScheduler scheduler() => MeetingAlertScheduler(
          repository: repo,
          eventBus: bus,
          activeWorkspaceId: () => 'ws-A',
          leadTimeMinutes: () async => 5,
        );

    test('publishes MeetingStartingSoon once per due event and marks alerted',
        () async {
      repo.upcoming = [_event('a')];
      final fired = <MeetingStartingSoon>[];
      bus.on<MeetingStartingSoon>().listen(fired.add);

      await scheduler().runOnce();
      await Future<void>.delayed(Duration.zero);

      expect(fired, hasLength(1));
      expect(fired.single.eventId, 'a');
      expect(fired.single.workspaceId, 'ws-A');
      expect(repo.alerted.map((a) => a.eventId), ['a']);
    });

    test('does not re-fire after an event is marked alerted', () async {
      repo.upcoming = [_event('a')];
      final fired = <MeetingStartingSoon>[];
      bus.on<MeetingStartingSoon>().listen(fired.add);

      final s = scheduler();
      await s.runOnce();
      await s.runOnce(); // upcoming now empty (markAlerted removed it)
      await Future<void>.delayed(Duration.zero);

      expect(fired, hasLength(1));
    });

    test('is a no-op when there are no due events', () async {
      final fired = <MeetingStartingSoon>[];
      bus.on<MeetingStartingSoon>().listen(fired.add);

      await scheduler().runOnce();
      await Future<void>.delayed(Duration.zero);

      expect(fired, isEmpty);
      expect(repo.alerted, isEmpty);
    });

    test('is a no-op when there is no active workspace', () async {
      repo.upcoming = [_event('a')];
      final scheduler = MeetingAlertScheduler(
        repository: repo,
        eventBus: bus,
        activeWorkspaceId: () => null,
        leadTimeMinutes: () async => 5,
      );
      await scheduler.runOnce();
      expect(repo.alerted, isEmpty);
    });
  });
}
