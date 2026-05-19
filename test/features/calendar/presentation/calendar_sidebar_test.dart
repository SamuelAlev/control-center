import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_sidebar.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/active_workspace.dart';
import '../../../helpers/test_wrap.dart';
import '../fake_calendar_repository.dart';

void main() {
  const ws = kTestWorkspaceId;

  late FakeCalendarRepository repository;

  Widget sidebar() {
    return ProviderScope(
      overrides: [
        activeWorkspaceIdOverride(ws),
        calendarRepositoryProvider.overrideWithValue(repository),
      ],
      child: testWrap(const CalendarSidebar(workspaceId: ws)),
    );
  }

  setUp(() {
    repository = FakeCalendarRepository()
      ..account = CalendarAccount(
        id: 'acc-1',
        workspaceId: ws,
        providerId: 'google',
        accountEmail: 'a@example.com',
        lastSyncedAt: DateTime(2026, 8, 11, 9),
      );
    repository.upsertSources(
      workspaceId: ws,
      accountId: 'acc-1',
      sources: const [
        CalendarSource(
          workspaceId: ws,
          accountId: 'acc-1',
          id: 'primary',
          summary: 'a@example.com',
          primary: true,
        ),
        CalendarSource(
          workspaceId: ws,
          accountId: 'acc-1',
          id: 'famille',
          summary: 'Famille',
        ),
      ],
    );
  });

  Future<TestGesture> hover(WidgetTester tester, Finder target) async {
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(target));
    await tester.pump();
    return gesture;
  }

  group('CalendarSidebar visibility toggle', () {
    testWidgets('the eye is hidden at rest, revealed on hover and tapping it '
        'hides the calendar with a permanently visible crossed eye', (
      tester,
    ) async {
      await tester.pumpWidget(sidebar());
      await tester.pumpAndSettle();

      final row = find.text('Famille');
      expect(row, findsOneWidget);
      // At rest a visible calendar shows no eye — but reserves its slot.
      final nameRectAtRest = tester.getRect(row);
      expect(find.byIcon(AppIcons.eye), findsNothing);

      final gesture = await hover(tester, row);
      expect(find.byIcon(AppIcons.eye), findsOneWidget);
      // The reveal consumed the reserved slot: the row did not move.
      expect(tester.getRect(row), nameRectAtRest);

      await tester.tap(find.byIcon(AppIcons.eye));
      await tester.pumpAndSettle();
      expect(find.byIcon(AppIcons.eyeOff), findsOneWidget);

      // Hidden: the crossed eye stays even once the pointer leaves the row.
      await gesture.moveTo(const Offset(1, 1));
      await tester.pump();
      expect(find.byIcon(AppIcons.eyeOff), findsOneWidget);
      expect(find.byIcon(AppIcons.eye), findsNothing);

      // Clicking the crossed eye reveals the calendar again.
      await tester.tap(find.byIcon(AppIcons.eyeOff));
      await tester.pumpAndSettle();
      expect(find.byIcon(AppIcons.eyeOff), findsNothing);
      expect(find.byIcon(AppIcons.eye), findsNothing);
    });
  });
}
