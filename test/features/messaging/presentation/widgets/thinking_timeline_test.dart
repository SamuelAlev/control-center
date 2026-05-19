import 'package:control_center/core/domain/value_objects/thinking_event.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/thinking_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        body: FTheme(data: FThemes.zinc.light.desktop, child: child),
      ),
    );

void main() {
  group('ThinkingTimeline', () {
    final baseTime = DateTime(2026, 1, 1, 12, 0);

    testWidgets('renders summary with thought duration and tool count',
        (tester) async {
      final events = [
        ThinkingEvent(
          kind: ThinkingEventKind.reasoning,
          content: 'Considering the request.',
          timestamp: baseTime,
          duration: const Duration(seconds: 4),
        ),
        ThinkingEvent(
          kind: ThinkingEventKind.toolCall,
          content: 'read_file',
          timestamp: baseTime.add(const Duration(seconds: 4)),
          duration: const Duration(seconds: 2),
          toolName: 'read_file',
          inputs: const {'path': 'lib/main.dart'},
        ),
      ];

      await tester.pumpWidget(_host(ThinkingTimeline(events: events)));
      await tester.pump();

      expect(find.textContaining('Thought for'), findsOneWidget);
      expect(find.textContaining('1 tool call'), findsOneWidget);
    });

    testWidgets('expands the body when header is tapped', (tester) async {
      final events = [
        ThinkingEvent(
          kind: ThinkingEventKind.toolCall,
          content: 'read_file',
          timestamp: baseTime,
          duration: const Duration(seconds: 1),
          toolName: 'read_file',
          inputs: const {'path': 'lib/main.dart'},
        ),
      ];

      await tester.pumpWidget(_host(ThinkingTimeline(events: events)));
      await tester.pump();

      expect(find.textContaining('read_file(path:'), findsNothing);

      await tester.tap(find.textContaining('Thought for'));
      await tester.pumpAndSettle();

      expect(find.textContaining('read_file('), findsOneWidget);
    });

    testWidgets('shows Thinking… while live and no events yet', (tester) async {
      await tester.pumpWidget(_host(
        const ThinkingTimeline(events: [], isLive: true),
      ));
      await tester.pump();

      expect(find.text('Thinking…'), findsOneWidget);
    });

    testWidgets('renders empty when no events and not live', (tester) async {
      await tester.pumpWidget(_host(const ThinkingTimeline(events: [])));
      await tester.pump();

      expect(find.byType(ThinkingTimeline), findsOneWidget);
      expect(find.textContaining('Thought'), findsNothing);
      expect(find.text('Thinking…'), findsNothing);
    });
  });
}
