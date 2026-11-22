import 'package:cc_domain/features/dispatch/domain/repositories/goal_run_view.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:control_center/features/dispatch/presentation/screens/goals_screen.dart';
import 'package:control_center/features/dispatch/presentation/screens/improvements_screen.dart';
import 'package:control_center/features/dispatch/presentation/screens/schedules_screen.dart';
import 'package:control_center/features/dispatch/presentation/widgets/goals/goal_page.dart';
import 'package:control_center/features/settings/settings_nav.dart';
import 'package:control_center/features/shell/breadcrumbs/breadcrumb_registry.dart';
import 'package:control_center/features/shell/route_titles/route_title_registry.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/app_router.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';
import 'long_work_harness.dart';

void main() {
  final paths = [
    goalsRoute(workspaceIdParam),
    goalRoute(workspaceIdParam, ':recordId'),
    schedulesRoute(workspaceIdParam),
    scheduleRoute(workspaceIdParam, ':recordId'),
    improvementsRoute(workspaceIdParam),
    improvementRoute(workspaceIdParam, ':recordId'),
  ];

  test('every record route is registered with a breadcrumb and a title', () {
    expect(workRecordRoutes().map((r) => r.path).toList(), paths);
    for (final p in paths) {
      expect(breadcrumbRegistry.containsKey(p), isTrue, reason: p);
      expect(routeTitleRegistry.containsKey(p), isTrue, reason: p);
    }
  });

  test('the schedules settings page is a workspace settings destination', () {
    final item = kSettingsNavItems.firstWhere(
      (i) => i.id == 'workspace.schedules',
    );
    expect(item.route('ws-1'), settingsSchedulesRoute('ws-1'));
    expect(
      settingsSchedulesRoute('ws-1'),
      '/workspaces/ws-1/settings/workspace/schedules',
    );
  });

  Future<void> go(WidgetTester tester, String location) async {
    final router = historyTestRouter(
      initialLocation: location,
      routes: workRecordRoutes(),
    );
    addTearDown(router.dispose);
    tester.view.physicalSize = const Size(1400, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: longWorkOverrides(
          goalViews: [
            GoalRunView(
              goal: goalFixture(status: AgentGoalStatus.paused),
              canResume: true,
              canApprove: true,
            ),
          ],
        ),
        child: testRouterWrap(router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('each list route opens its screen', (tester) async {
    await go(tester, goalsRoute(kTestWorkspaceId));
    expect(find.byType(GoalsScreen), findsOneWidget);
    await go(tester, schedulesRoute(kTestWorkspaceId));
    expect(find.byType(SchedulesScreen), findsOneWidget);
    await go(tester, improvementsRoute(kTestWorkspaceId));
    expect(find.byType(ImprovementsScreen), findsOneWidget);
  });

  testWidgets('a goal link with ?edit=contract opens the contract editor', (
    tester,
  ) async {
    await go(
      tester,
      '${goalRoute(kTestWorkspaceId, 'goal-1')}?$goalContractEditQuery',
    );
    final page = tester.widget<GoalPage>(find.byType(GoalPage));
    expect(page.openContractEditor, isTrue);
    final l = AppLocalizations.of(tester.element(find.byType(GoalPage)));
    expect(find.text(l.goalContractEditTitle), findsOneWidget);
  });
}
