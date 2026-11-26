import 'package:cc_domain/features/dispatch/domain/repositories/goal_run_view.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/dispatch/presentation/widgets/goals/goal_contract_section.dart';
import 'package:control_center/features/dispatch/presentation/widgets/goals/goal_edit_dialogs.dart';
import 'package:control_center/features/dispatch/presentation/widgets/goals/goal_overview_section.dart';
import 'package:control_center/features/dispatch/presentation/widgets/goals/goal_page_header.dart';
import 'package:control_center/features/dispatch/presentation/widgets/goals/goal_schedules_section.dart';
import 'package:control_center/features/dispatch/presentation/widgets/goals/goal_verification_section.dart';
import 'package:control_center/features/dispatch/presentation/widgets/work_record_states.dart';
import 'package:control_center/features/dispatch/providers/long_work_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One goal's page: loading, refused (the watch's refusal in words), not
/// found, or the goal. With [openContractEditor] the contract editor opens
/// once, as soon as the goal is paused, for a viewer who may change it
/// (`can_resume`).
class GoalPage extends ConsumerStatefulWidget {
  /// Creates the page of [goalId] in [workspaceId].
  const GoalPage({
    super.key,
    required this.workspaceId,
    required this.goalId,
    this.openContractEditor = false,
  });

  /// The workspace.
  final String workspaceId;

  /// The goal.
  final String goalId;

  /// Whether the link asked for the contract editor.
  final bool openContractEditor;

  @override
  ConsumerState<GoalPage> createState() => _GoalPageState();
}

class _GoalPageState extends ConsumerState<GoalPage> {
  bool _editorOpened = false;

  void _maybeOpenEditor(GoalRunView view) {
    if (!widget.openContractEditor ||
        _editorOpened ||
        !view.canResume ||
        view.goal.status != AgentGoalStatus.paused) {
      return;
    }
    _editorOpened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showGoalContractDialog(context, view.goal);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final view = ref.watch(
      goalRunViewProvider((workspaceId: widget.workspaceId, id: widget.goalId)),
    );
    return WorkRecordStates<GoalRunView>(
      value: view,
      notFound: l10n.goalNotFound,
      builder: (v) {
        _maybeOpenEditor(v);
        final goal = v.goal;
        return ListView(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          children: [
            GoalPageHeader(view: v),
            const SizedBox(height: AppSpacing.lg),
            GoalOverviewSection(goal: goal),
            GoalContractSection(goal: goal, canChange: v.canResume),
            GoalVerificationSection(goal: goal),
            GoalSchedulesSection(goal: goal),
          ],
        );
      },
    );
  }
}
