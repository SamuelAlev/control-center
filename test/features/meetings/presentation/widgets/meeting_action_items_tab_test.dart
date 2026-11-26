import 'dart:ui';

import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/meetings/presentation/widgets/detail/meeting_action_items_tab.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_hover_reveal.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/test_wrap.dart';

final _meeting = Meeting(
  id: 'm1',
  workspaceId: 'ws1',
  title: 'Daily',
  status: MeetingStatus.done,
  createdAt: DateTime(2026, 6, 10, 10),
  updatedAt: DateTime(2026, 6, 10, 11),
  startedAt: DateTime(2026, 6, 10, 10),
  endedAt: DateTime(2026, 6, 10, 11),
);

MeetingActionItem _item(String id, String content, {String? ticketId}) =>
    MeetingActionItem(
      id: id,
      meetingId: 'm1',
      workspaceId: 'ws1',
      content: content,
      ticketId: ticketId,
      createdAt: DateTime(2026, 6, 10, 11),
    );

double _actionsOpacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(
      find
          .descendant(
            of: find.byType(SettingsHoverReveal),
            matching: find.byType(AnimatedOpacity),
          )
          .first,
    )
    .opacity;

void main() {
  tearDown(SettingsHoverReveal.debugForgetMouse);

  testWidgets('row actions appear only while the row is hovered', (
    tester,
  ) async {
    await tester.pumpWidget(
      testWrap(
        SingleChildScrollView(
          child: MeetingActionItemsTab(
            meeting: _meeting,
            actionItems: [_item('a1', 'Ping the reviewer')],
          ),
        ),
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(790, 590));
    addTearDown(mouse.removePointer);
    await tester.pumpAndSettle();

    // No "+" on the ticket button: the row's only plus is the add footer.
    expect(find.text('Create ticket'), findsOneWidget);
    expect(find.byIcon(AppIcons.plus), findsOneWidget);
    expect(find.byType(CcIconButton), findsNWidgets(2));
    expect(_actionsOpacity(tester), 0);

    await mouse.moveTo(tester.getCenter(find.text('Ping the reviewer')));
    await tester.pumpAndSettle();
    expect(_actionsOpacity(tester), 1);
  });

  testWidgets('a filed ticket replaces the create action and stays visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      testWrap(
        SingleChildScrollView(
          child: MeetingActionItemsTab(
            meeting: _meeting,
            actionItems: [_item('a1', 'Ping the reviewer', ticketId: 'eng-12')],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create ticket'), findsNothing);
    expect(find.text('ENG'), findsOneWidget);
  });
}
