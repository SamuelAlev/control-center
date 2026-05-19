import 'package:control_center/features/calendar/domain/entities/calendar_event.dart';
import 'package:control_center/features/calendar/presentation/widgets/agenda_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_wrap.dart';

CalendarEvent _event({
  required String id,
  required String title,
  required DateTime start,
}) {
  return CalendarEvent(
    id: id,
    workspaceId: 'ws',
    accountId: 'acc',
    externalEventId: id,
    calendarId: 'primary',
    title: title,
    startTime: start,
    endTime: start.add(const Duration(minutes: 30)),
    updatedAt: start,
  );
}

void main() {
  group('AgendaPanel', () {
    testWidgets('shows Start recording only for a starting-soon event',
        (tester) async {
      final now = DateTime.now();
      final events = [
        _event(id: 'soon', title: 'Soon meeting', start: now.add(const Duration(minutes: 3))),
        _event(id: 'later', title: 'Later meeting', start: now.add(const Duration(hours: 2))),
      ];

      await tester.pumpWidget(testWrap(
        Scaffold(
          body: AgendaPanel(
            events: events,
            now: now,
            onOpenEvent: (_) {},
            onStartRecording: (_) {},
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('Soon meeting'), findsOneWidget);
      expect(find.text('Later meeting'), findsOneWidget);
      expect(find.text('Start recording'), findsOneWidget);
    });

    testWidgets('tapping a row invokes onOpenEvent', (tester) async {
      final now = DateTime.now();
      final opened = <CalendarEvent>[];
      final event = _event(
        id: 'e1',
        title: 'Tap me',
        start: now.add(const Duration(hours: 1)),
      );

      await tester.pumpWidget(testWrap(
        Scaffold(
          body: AgendaPanel(
            events: [event],
            now: now,
            onOpenEvent: opened.add,
            onStartRecording: (_) {},
          ),
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('Tap me'));
      await tester.pump();

      expect(opened, hasLength(1));
      expect(opened.single.id, 'e1');
    });

    testWidgets('renders an empty state when there are no events',
        (tester) async {
      await tester.pumpWidget(testWrap(
        Scaffold(
          body: AgendaPanel(
            events: const [],
            now: DateTime.now(),
            onOpenEvent: (_) {},
            onStartRecording: (_) {},
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('No events in this range'), findsOneWidget);
    });
  });
}
