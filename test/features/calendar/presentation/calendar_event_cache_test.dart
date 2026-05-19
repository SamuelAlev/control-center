import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_event_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ws = 'ws-1';
  final day = DateTime(2026, 8, 11);

  CalendarEvent event(
    String id, {
    DateTime? start,
    DateTime? end,
    String title = 'Event',
    bool isAllDay = false,
    CalendarEventStatus status = CalendarEventStatus.confirmed,
    List<CalendarAttendee> attendees = const [],
  }) => CalendarEvent(
    id: id,
    workspaceId: ws,
    accountId: 'acc-1',
    externalEventId: 'ext-$id',
    calendarId: 'primary',
    title: title,
    startTime: start ?? day.add(const Duration(hours: 9)),
    endTime: end ?? day.add(const Duration(hours: 10)),
    updatedAt: day,
    isAllDay: isAllDay,
    status: status,
    attendees: attendees,
  );

  group('CalendarEventCache', () {
    test('overlapping is null before anything is cached', () {
      final cache = CalendarEventCache(AppPreferences(InMemoryStorage()));
      expect(
        cache.overlapping(ws, day, day.add(const Duration(days: 1))),
        isNull,
      );
    });

    test(
      'replaceRange seeds overlapping, earliest first, out-of-range excluded',
      () {
        final cache = CalendarEventCache(AppPreferences(InMemoryStorage()));
        final later = event('b', start: day.add(const Duration(hours: 14)));
        final earlier = event('a');
        final outside = event(
          'z',
          start: day.add(const Duration(days: 10)),
          end: day.add(const Duration(days: 10, hours: 1)),
        );
        cache.replaceRange(ws, day, day.add(const Duration(days: 1)), [
          later,
          earlier,
          outside,
        ]);

        final result = cache.overlapping(
          ws,
          day,
          day.add(const Duration(days: 1)),
        );
        expect(result, [earlier, later]);
        // A wider query still sees the out-of-range event.
        expect(cache.overlapping(ws, day, day.add(const Duration(days: 30))), [
          earlier,
          later,
          outside,
        ]);
      },
    );

    test('replaceRange removes events that left the refreshed range', () {
      final cache = CalendarEventCache(AppPreferences(InMemoryStorage()));
      final rangeEnd = day.add(const Duration(days: 1));
      cache.replaceRange(ws, day, rangeEnd, [event('a'), event('b')]);
      // Refresh the same range: 'b' was deleted/moved away remotely.
      cache.replaceRange(ws, day, rangeEnd, [event('a')]);
      expect(cache.overlapping(ws, day, rangeEnd)?.map((e) => e.id), ['a']);
    });

    test('events outside the refreshed range survive it', () {
      final cache = CalendarEventCache(AppPreferences(InMemoryStorage()));
      final nextWeek = day.add(const Duration(days: 7));
      cache.replaceRange(ws, day, day.add(const Duration(days: 1)), [
        event('a'),
      ]);
      cache.replaceRange(ws, nextWeek, nextWeek.add(const Duration(days: 1)), [
        event(
          'w',
          start: nextWeek.add(const Duration(hours: 9)),
          end: nextWeek.add(const Duration(hours: 10)),
        ),
      ]);
      expect(cache.overlapping(ws, day, day.add(const Duration(days: 1))), [
        event('a'),
      ]);
    });

    test('snapshot persists and reloads through preferences', () async {
      final prefs = AppPreferences(InMemoryStorage());
      final cache = CalendarEventCache(prefs);
      final allDay = event(
        'ad',
        start: day,
        end: day.add(const Duration(days: 2)),
        title: 'Offsite',
        isAllDay: true,
        status: CalendarEventStatus.tentative,
        attendees: const [
          CalendarAttendee(
            email: 'ada@example.com',
            displayName: 'Ada',
            responseStatus: 'accepted',
            self: true,
            organizer: true,
          ),
        ],
      );
      cache.replaceRange(ws, day, day.add(const Duration(days: 7)), [allDay]);
      // The debounced persist fires after 1s; pump past it.
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      // A fresh cache over the same preferences restores the snapshot.
      final reloaded = CalendarEventCache(prefs);
      final result = reloaded.overlapping(
        ws,
        day,
        day.add(const Duration(days: 7)),
      );
      expect(result, [allDay]);
      expect(result!.single.isAllDay, isTrue);
      expect(result.single.status, CalendarEventStatus.tentative);
      expect(result.single.attendees.single.self, isTrue);
      expect(result.single.attendees.single.displayName, 'Ada');
    });

    test('a corrupt persisted snapshot reads as empty, never throws', () {
      final prefs = AppPreferences(InMemoryStorage());
      prefs.setString('calendar_events_snapshot__$ws', 'not json');
      final cache = CalendarEventCache(prefs);
      expect(
        cache.overlapping(ws, day, day.add(const Duration(days: 1))),
        isEmpty,
      );
    });

    test('snapshots are isolated per workspace', () async {
      final prefs = AppPreferences(InMemoryStorage());
      final cache = CalendarEventCache(prefs);
      cache.replaceRange(ws, day, day.add(const Duration(days: 1)), [
        event('a'),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      final reloaded = CalendarEventCache(prefs);
      expect(
        reloaded.overlapping('ws-2', day, day.add(const Duration(days: 1))),
        isNull,
      );
    });
  });
}
