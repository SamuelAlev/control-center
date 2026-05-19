import 'package:control_center/features/meetings/presentation/screens/meetings_screen.dart';
import 'package:control_center/features/meetings/presentation/widgets/meeting_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  group('MeetingToolbar', () {
    testWidgets('renders with All filter selected', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(testWrap(
        MeetingToolbar(
          filter: MeetingListFilter.all,
          searchController: controller,
          onFilterChanged: (_) {},
        ),
      ));
      addTearDown(controller.dispose);

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Processing'), findsOneWidget);
    });

    testWidgets('renders with processing filter selected', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(testWrap(
        MeetingToolbar(
          filter: MeetingListFilter.processing,
          searchController: controller,
          onFilterChanged: (_) {},
        ),
      ));
      addTearDown(controller.dispose);

      expect(find.byType(MeetingToolbar), findsOneWidget);
    });

    testWidgets('typing search text updates the shared controller',
        (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(testWrap(
        MeetingToolbar(
          filter: MeetingListFilter.all,
          searchController: controller,
          onFilterChanged: (_) {},
        ),
      ));
      addTearDown(controller.dispose);

      // The search field is wired to the shared controller; the owning
      // screen listens to it to drive live filtering.
      await tester.enterText(find.byType(EditableText), 'standup');
      await tester.pump();

      expect(controller.text, 'standup');
    });

    testWidgets('calls onFilterChanged when a segment is tapped', (tester) async {
      final controller = TextEditingController();
      MeetingListFilter? tapped;
      await tester.pumpWidget(testWrap(
        MeetingToolbar(
          filter: MeetingListFilter.all,
          searchController: controller,
          onFilterChanged: (v) => tapped = v,
        ),
      ));
      addTearDown(controller.dispose);

      await tester.tap(find.text('Done'));
      await tester.pump();
      expect(tapped, MeetingListFilter.done);
    });
  });
}
