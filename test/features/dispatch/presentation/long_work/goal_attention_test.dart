import 'package:cc_domain/features/dispatch/domain/repositories/goal_run_view.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:control_center/features/inbox/providers/work_attention_sources.dart';
import 'package:control_center/router/app_router.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'long_work_harness.dart';

/// The inbox's goals strip lists a goal in review only for a viewer who may
/// approve it (`can_approve`), and a goal held on a person only for one who
/// may resume it (`can_resume`).
void main() {
  GoalRunView view(
    String id,
    GoalHold hold, {
    required bool canResume,
    required bool canApprove,
  }) => GoalRunView(
    goal: goalFixture(id: id, status: AgentGoalStatus.paused, hold: hold),
    canResume: canResume,
    canApprove: canApprove,
  );

  Future<List<String>> itemsFor(
    WidgetTester tester,
    List<GoalRunView> views,
  ) async {
    late List<String> ids;
    await pumpLongWork(
      tester,
      Consumer(
        builder: (context, ref, _) {
          ids = [
            for (final item in GoalsNeedingPersonSource().buildItems(
              context,
              ref,
            ))
              item.id,
          ];
          return const SizedBox();
        },
      ),
      overrides: [
        ...longWorkOverrides(goalViews: views),
        routerProvider.overrideWithValue(
          GoRouter(
            routes: [GoRoute(path: '/', builder: (_, _) => const SizedBox())],
          ),
        ),
      ],
    );
    return ids;
  }

  testWidgets('review goals follow can_approve, person goals can_resume', (
    tester,
  ) async {
    final ids = await itemsFor(tester, [
      view(
        'review-mine',
        GoalHold.needsReview,
        canResume: false,
        canApprove: true,
      ),
      view(
        'review-theirs',
        GoalHold.needsReview,
        canResume: true,
        canApprove: false,
      ),
      view('person-mine', GoalHold.person, canResume: true, canApprove: false),
      view(
        'person-theirs',
        GoalHold.person,
        canResume: false,
        canApprove: true,
      ),
    ]);
    expect(ids, ['goal:review-mine', 'goal:person-mine']);
  });
}
