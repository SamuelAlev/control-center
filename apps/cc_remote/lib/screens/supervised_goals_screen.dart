import 'package:cc_domain/features/dispatch/domain/repositories/goal_run_view.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/plan_goal_providers.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/messaging/detail_header.dart';
import 'package:cc_remote/widgets/plan_goal/goal_detail.dart';
import 'package:cc_remote/widgets/plan_goal/goal_list.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Live durable goals across the workspace or within one conversation.
/// [goalId] opens a full detail route; the list is not tied to a single space.
class SupervisedGoalsScreen extends ConsumerStatefulWidget {
  const SupervisedGoalsScreen({super.key, this.conversationId, this.goalId});

  final String? conversationId;
  final String? goalId;

  @override
  ConsumerState<SupervisedGoalsScreen> createState() =>
      _SupervisedGoalsScreenState();
}

class _SupervisedGoalsScreenState extends ConsumerState<SupervisedGoalsScreen> {
  PhoneGoalsForm? _form;
  String? _scope;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final workspace = ref.watch(activeWorkspaceIdProvider);
    final workspaceId = workspace.value;
    if (_scope != workspaceId) {
      _scope = workspaceId;
      _form = null;
    }
    final goalsAsync = workspaceId == null
        ? null
        : widget.conversationId == null
        ? ref.watch(phoneWorkspaceGoalsProvider(workspaceId))
        : ref.watch(
            phoneConversationGoalsProvider((
              workspaceId: workspaceId,
              conversationId: widget.conversationId!,
            )),
          );
    final writable = ref.watch(workspaceRoleProvider).value?.canWrite ?? false;
    return SafeArea(
      child: ColoredBox(
        color: t.canvas,
        child: Column(
          children: [
            if (widget.goalId != null)
              DetailHeader(title: l10n.mobileGoalsTitle),
            Expanded(
              child: workspace.hasError
                  ? CcEmptyState(
                      icon: AppIcons.triangleAlert,
                      message: l10n.mobileGoalsLoadFailed,
                      description: workspace.error.toString(),
                    )
                  : workspaceId == null ||
                        goalsAsync == null ||
                        goalsAsync.isLoading
                  ? const Center(child: CcSpinner(size: 24))
                  : goalsAsync.hasError
                  ? CcEmptyState(
                      icon: AppIcons.triangleAlert,
                      message: l10n.mobileGoalsLoadFailed,
                      description: goalsAsync.error.toString(),
                    )
                  : widget.goalId != null
                  ? _detail(context, goalsAsync.value ?? const [], workspaceId)
                  : PhoneGoalsList(
                      goals: goalsAsync.value ?? const [],
                      workspaceId: workspaceId,
                      conversationId: widget.conversationId,
                      writable: writable,
                      form: _form,
                      onForm: (form) =>
                          setState(() => _form = _form == form ? null : form),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(
    BuildContext context,
    List<GoalRunView> goals,
    String workspaceId,
  ) {
    final view = goals.where((v) => v.goal.id == widget.goalId).firstOrNull;
    if (view == null) {
      return CcEmptyState(
        icon: AppIcons.triangleAlert,
        message: AppLocalizations.of(context).mobileGoalMissing,
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PhoneGoalDetail(
          key: ValueKey('$workspaceId:${view.goal.id}'),
          view: view,
          workspaceId: workspaceId,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
