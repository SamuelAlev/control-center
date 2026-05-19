import 'package:control_center/features/meetings/presentation/widgets/meeting_level_meter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  group('MeetingLevelMeter', () {
    testWidgets('renders when active', (tester) async {
      await tester.pumpWidget(testWrap(
        const MeetingLevelMeter(active: true, color: Colors.orange),
      ));

      expect(find.byType(MeetingLevelMeter), findsOneWidget);
    });

    testWidgets('renders when inactive', (tester) async {
      await tester.pumpWidget(testWrap(
        const MeetingLevelMeter(active: false, color: Colors.blue),
      ));

      expect(find.byType(MeetingLevelMeter), findsOneWidget);
    });

    testWidgets('renders custom bar count', (tester) async {
      await tester.pumpWidget(testWrap(
        const MeetingLevelMeter(
          active: true,
          color: Colors.red,
          barCount: 3,
        ),
      ));

      expect(find.byType(MeetingLevelMeter), findsOneWidget);
    });

    testWidgets('renders with custom height and seed', (tester) async {
      await tester.pumpWidget(testWrap(
        const MeetingLevelMeter(
          active: true,
          color: Colors.purple,
          height: 32,
          seed: 1.5,
        ),
      ));

      expect(find.byType(MeetingLevelMeter), findsOneWidget);
    });
  });
}
