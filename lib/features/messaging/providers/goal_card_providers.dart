import 'package:cc_domain/features/dispatch/domain/repositories/goal_run_view.dart';
import 'package:control_center/di/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every durable goal of a workspace as this viewer sees it, newest first
/// (`agentGoalRuns.watchForWorkspace`): the goal and the server's
/// `can_resume` for the viewer.
final workspaceGoalRunsProvider = StreamProvider.autoDispose
    .family<List<GoalRunView>, String>(
      (ref, workspaceId) => ref
          .watch(agentGoalRunRepositoryProvider)
          .watchForWorkspace(workspaceId),
    );
