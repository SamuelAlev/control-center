import 'package:control_center/features/dispatch/presentation/settings/dispatch_settings_view.dart';
import 'package:control_center/features/dispatch/presentation/widgets/schedules/schedule_page.dart';
import 'package:control_center/features/dispatch/presentation/widgets/schedules/schedules_list.dart';
import 'package:control_center/features/dispatch/presentation/widgets/improvements/improvement_page.dart';
import 'package:control_center/features/settings/settings_nav.dart';
import 'package:control_center/features/shell/breadcrumbs/breadcrumb_registry.dart';
import 'package:control_center/features/shell/route_titles/route_title_registry.dart';
import 'package:control_center/router/app_router.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';
import 'long_work_harness.dart';

void main() {
  final paths = [
    settingsSchedulesRoute(workspaceIdParam),
    scheduleRoute(workspaceIdParam, ':recordId'),
  ];

  test(
    'every schedule and memory improvement route has breadcrumb and title',
    () {
      expect(scheduleSettingsRoutes().map((r) => r.path).toList(), paths);
      final improvementPath = memoryImprovementRoute(
        workspaceIdParam,
        ':proposalId',
      );
      expect(memoryRoutes().map((r) => r.path), contains(improvementPath));
      for (final p in [...paths, improvementPath]) {
        expect(breadcrumbRegistry.containsKey(p), isTrue, reason: p);
        expect(routeTitleRegistry.containsKey(p), isTrue, reason: p);
      }
    },
  );

  test('the schedules settings page is a workspace settings destination', () {
    final item = kSettingsNavItems.firstWhere(
      (i) => i.id == 'workspace.schedules',
    );
    expect(item.route('ws-1'), settingsSchedulesRoute('ws-1'));
    expect(
      settingsSchedulesRoute('ws-1'),
      '/workspaces/ws-1/settings/workspace/schedules',
    );
    expect(
      scheduleRoute('ws-1', 'rule-1'),
      '/workspaces/ws-1/settings/workspace/schedules/rule-1',
    );
    expect(item.matchesSubroutes, isTrue);
    expect(
      item.detailRoutes.single('ws-1'),
      scheduleRoute('ws-1', ':recordId'),
    );
  });

  Future<void> go(WidgetTester tester, String location) async {
    final router = historyTestRouter(
      initialLocation: location,
      routes: [...scheduleSettingsRoutes(), ...memoryRoutes()],
    );
    addTearDown(router.dispose);
    tester.view.physicalSize = const Size(1400, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: longWorkOverrides(),
        child: testRouterWrap(router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the schedules settings route lists schedules and offers a new '
      'one', (tester) async {
    await go(tester, settingsSchedulesRoute(kTestWorkspaceId));
    expect(find.byType(DispatchSettingsView), findsOneWidget);
    expect(find.byType(SchedulesList), findsOneWidget);
    expect(find.byType(NewScheduleButton), findsOneWidget);
    expect(find.byType(SchedulePage), findsNothing);
  });

  testWidgets('a schedule route opens its page over the mounted list', (
    tester,
  ) async {
    await go(tester, scheduleRoute(kTestWorkspaceId, 'rule-1'));
    expect(find.byType(SchedulePage), findsOneWidget);
    expect(find.byType(SchedulesList, skipOffstage: false), findsOneWidget);
  });

  testWidgets('memory improvement route opens ImprovementPage', (tester) async {
    await go(tester, memoryImprovementRoute(kTestWorkspaceId, 'prop-1'));
    expect(find.byType(ImprovementPage), findsOneWidget);
  });
}
