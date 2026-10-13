import 'package:cc_domain/cc_domain.dart' show UndoClass;
import 'package:cc_domain/core/domain/entities/agent_shell_process.dart';
import 'package:cc_domain/features/todos/domain/entities/conversation_goal.dart';
import 'package:cc_domain/features/todos/domain/entities/todo_item.dart';
import 'package:cc_domain/features/todos/domain/value_objects/todo_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/undo/action_journal.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/agent_run_target.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/agents_section.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/goals_section.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/rigs_sections.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/terminals_section.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/plan_studio/providers/plan_studio_providers.dart';
import 'package:control_center/features/plan_studio/providers/space_plan_execution_provider.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_surfaces.dart';
import 'package:control_center/features/todos/providers/todo_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/collapsible_sidebar_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The "General" IDE-sidebar panel: a session dashboard showing the active
/// conversation's TODOS, AGENTS (live run tree), TERMINALS and
/// MACHINES (browser / computer rigs).
class GeneralPanel extends ConsumerWidget {
  /// Creates a [GeneralPanel].
  const GeneralPanel({
    super.key,
    required this.workspaceId,
    required this.focusedTabKey,
    required this.onOpenAgentRun,
    required this.onOpenAgentShell,
    required this.onFocusTerminal,
    required this.onKillTerminal,
    required this.onFocusRig,
    required this.onFocusBrowserTab,
    required this.onCloseBrowserTab,
  });

  /// The active workspace.
  final String workspaceId;

  /// The focused tab in the live editor layout, not the route's last tab.
  final String? focusedTabKey;

  /// Opens (or focuses) the tapped agent run — see [AgentRunTarget].
  final ValueChanged<AgentRunTarget> onOpenAgentRun;

  /// Opens (or focuses) a running agent command's read-only output.
  final ValueChanged<AgentShellProcess> onOpenAgentShell;

  /// Focuses (or opens) the terminal identified by its session id.
  final ValueChanged<String> onFocusTerminal;

  /// Ends the terminal identified by its session id (a TERMINALS row's
  /// hover trash), closing its tab when it has one.
  final ValueChanged<String> onKillTerminal;

  /// Focuses (or opens) the rig tab for the tapped machine — see
  /// [RigTabTarget].
  final ValueChanged<RigTabTarget> onFocusRig;

  /// Focuses the host web-browser tab a BROWSERS row was tapped for.
  final ValueChanged<String> onFocusBrowserTab;

  /// Closes the host web-browser tab its hover × was pressed on.
  final ValueChanged<String> onCloseBrowserTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final spaceId = ref.watch(selectedSpaceIdProvider);
    if (spaceId == null) {
      return CcEmptyState(
        icon: AppIcons.layoutDashboard,
        size: CcEmptyStateSize.sm,
        message: l10n.selectConversation,
      );
    }
    final tabKey = focusedTabKey;
    final conversationId = tabKey == MessagingTabKinds.chatSpaceTabKey(spaceId)
        ? ref.watch(standingConversationIdProvider(spaceId)).asData?.value
        : tabKey == null
        ? null
        : MessagingTabKinds.conversationIdFromChatTabKey(tabKey);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      children: [
        // Durable supervised goals (`/goal` + `/loop`) sit on top: they are
        // the standing orders every run below works toward.
        if (conversationId != null)
          GoalsSection(
            conversationId: conversationId,
            workspaceId: workspaceId,
          ),
        // An approved plan shows up as this conversation's GOAL (inside TODOS),
        // not as a surface of its own.
        _TodosSection(
          spaceId: spaceId,
          conversationId: conversationId,
          workspaceId: workspaceId,
        ),
        AgentsSection(
          spaceId: spaceId,
          workspaceId: workspaceId,
          onOpenAgentRun: onOpenAgentRun,
        ),
        TerminalsSection(
          spaceId: spaceId,
          workspaceId: workspaceId,
          onFocusTerminal: onFocusTerminal,
          onOpenAgentShell: onOpenAgentShell,
          onKillTerminal: onKillTerminal,
        ),
        // The machines this conversation can drive: browsers first (there can
        // be three, one per engine), then desktops. Rows focus the rig's tab.
        BrowsersSection(
          spaceId: spaceId,
          workspaceId: workspaceId,
          onFocusRig: onFocusRig,
          onFocusBrowserTab: onFocusBrowserTab,
          onCloseBrowserTab: onCloseBrowserTab,
        ),
        ComputersSection(
          spaceId: spaceId,
          workspaceId: workspaceId,
          onFocusRig: onFocusRig,
        ),
        PhonesSection(
          spaceId: spaceId,
          workspaceId: workspaceId,
          onFocusRig: onFocusRig,
        ),
      ],
    );
  }
}

/// The messaging IDE sidebar's collapsible section shell now lives in
/// [CollapsibleSidebarSection] (shared with the PR-detail Overview sidebar).

// TODOS

class _TodosSection extends ConsumerWidget {
  const _TodosSection({
    required this.spaceId,
    required this.conversationId,
    required this.workspaceId,
  });

  final String spaceId;
  final String? conversationId;
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final conversationId = this.conversationId;
    final todos = conversationId == null
        ? const <TodoItem>[]
        : ref.watch(conversationTodosProvider(conversationId)).asData?.value ??
              const <TodoItem>[];
    final goal = conversationId == null
        ? null
        : ref.watch(conversationGoalProvider(conversationId)).asData?.value;

    final listBody = todos.isEmpty
        ? SidebarEmptyRow(message: l10n.generalTodosEmpty)
        : ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: todos.length,
            onReorderItem: (oldIndex, newIndex) {
              final ids = todos.map((t) => t.id).toList();
              final moved = ids.removeAt(oldIndex);
              ids.insert(newIndex, moved);
              if (conversationId != null) {
                ref
                    .read(todoRepositoryProvider)
                    .reorder(workspaceId, conversationId, ids);
              }
            },
            itemBuilder: (context, index) {
              final todo = todos[index];
              return _TodoRow(
                key: ValueKey(todo.id),
                todo: todo,
                index: index,
                onToggle: () {
                  final previous = todo.status;
                  final next = switch (todo.status) {
                    TodoStatus.pending => TodoStatus.inProgress,
                    TodoStatus.inProgress => TodoStatus.completed,
                    TodoStatus.completed => TodoStatus.pending,
                  };
                  final repo = ref.read(todoRepositoryProvider);
                  if (conversationId == null) {
                    return;
                  }
                  repo.updateStatus(workspaceId, conversationId, todo.id, next);
                  // Reversible (PRD 19 §5): ⌘Z restores the prior status.
                  ref
                      .read(actionJournalProvider.notifier)
                      .record(
                        UndoableAction(
                          label: l10n.undoLabelTodoStatus,
                          undoClass: UndoClass.reversible,
                          undo: () => repo.updateStatus(
                            workspaceId,
                            conversationId,
                            todo.id,
                            previous,
                          ),
                          redo: () => repo.updateStatus(
                            workspaceId,
                            conversationId,
                            todo.id,
                            next,
                          ),
                        ),
                      );
                },
              );
            },
          );

    // An approved plan sets this conversation's goal, so when a plan is running
    // the goal row is where its progress and its stop button belong — no second
    // surface competing with the todos for the same job.
    final plan = ref.watch(
      spacePlanExecutionProvider((workspaceId: workspaceId, spaceId: spaceId)),
    );

    // When a goal is set (`/goal`, or an approved plan), the todos render nested
    // beneath a default-open goal accordion; otherwise the flat list sits at the
    // root.
    final body = goal == null
        ? listBody
        : _GoalAccordion(
            title: goal.title,
            progress: plan == null ? null : '${plan.settled}/${plan.total}',
            onCancelRun: plan != null && plan.isActive
                ? () => _cancelRun(ref, plan.orchestration.id)
                : null,
            onClear: () => _clearGoal(ref, l10n, goal),
            child: listBody,
          );

    return CollapsibleSidebarSection(
      icon: AppIcons.listTodo,
      label: l10n.generalSectionTodos,
      count: todos.isEmpty ? null : '${todos.length}',
      child: body,
    );
  }

  /// Stops the plan run this goal came from. Fire-and-forget with a toast on
  /// failure: the row reflects the cancelled orchestration on the next tick.
  Future<void> _cancelRun(WidgetRef ref, String orchestrationId) async {
    final context = ref.context;
    try {
      await ref.read(planStudioRepositoryProvider).cancel(orchestrationId);
    } on Object catch (e) {
      if (context.mounted) {
        CcToastScope.maybeOf(
          context,
        )?.show('$e', variant: CcToastVariant.danger);
      }
    }
  }

  /// Clears the conversation's goal (reversible via ⌘Z — undo re-sets the same
  /// title).
  void _clearGoal(WidgetRef ref, AppLocalizations l10n, ConversationGoal goal) {
    final conversationId = this.conversationId;
    if (conversationId == null) {
      return;
    }
    final repo = ref.read(todoRepositoryProvider);
    repo.clearGoal(workspaceId, conversationId);
    ref
        .read(actionJournalProvider.notifier)
        .record(
          UndoableAction(
            label: l10n.undoLabelGoalClear,
            undoClass: UndoClass.reversible,
            undo: () => repo.setGoal(workspaceId, conversationId, goal.title),
            redo: () => repo.clearGoal(workspaceId, conversationId),
          ),
        );
  }
}

/// A default-open accordion whose header is the conversation's `/goal` and
/// whose body is the todos working toward it.
///
/// When the goal came from an approved plan that is still executing, the header
/// also carries the run's progress and its stop button — the goal is the plan,
/// so its row is where "how far along" and "stop" live.
class _GoalAccordion extends StatefulWidget {
  const _GoalAccordion({
    required this.title,
    required this.onClear,
    required this.child,
    this.progress,
    this.onCancelRun,
  });

  final String title;

  /// `settled/total` for the plan behind this goal, or null when there is none.
  final String? progress;

  /// Stops the plan run; null when nothing is running.
  final VoidCallback? onCancelRun;

  final VoidCallback onClear;
  final Widget child;

  @override
  State<_GoalAccordion> createState() => _GoalAccordionState();
}

class _GoalAccordionState extends State<_GoalAccordion> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          expanded: _expanded,
          label: widget.title,
          button: true,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 6,
              ),
              child: Row(
                children: [
                  Icon(
                    _expanded ? AppIcons.chevronDown : AppIcons.chevronRight,
                    size: 14,
                    color: t.textTertiary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(AppIcons.target, size: 14, color: t.fgBrandPrimary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                      ),
                    ),
                  ),
                  // Plan progress: how many of the approved steps have settled.
                  if (widget.progress != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    SidebarSectionCountBadge(label: widget.progress!),
                  ],
                  if (widget.onCancelRun != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    CcTooltip(
                      message: l10n.planCancel,
                      child: CcTappable(
                        onPressed: widget.onCancelRun,
                        semanticLabel: l10n.planCancel,
                        builder: (context, states) => SizedBox(
                          width: 20,
                          height: 20,
                          child: Icon(
                            AppIcons.circleStop,
                            size: 14,
                            color: states.contains(WidgetState.hovered)
                                ? t.textPrimary
                                : t.textTertiary,
                          ),
                        ),
                      ),
                    ),
                  ],
                  CcTooltip(
                    message: l10n.goalClear,
                    child: CcTappable(
                      onPressed: widget.onClear,
                      semanticLabel: l10n.goalClear,
                      builder: (context, states) => SizedBox(
                        width: 20,
                        height: 20,
                        child: Icon(
                          AppIcons.x,
                          size: 14,
                          color: states.contains(WidgetState.hovered)
                              ? t.textPrimary
                              : t.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        CcCollapsible(
          expanded: _expanded,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: AppSpacing.md),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

class _TodoRow extends StatelessWidget {
  const _TodoRow({
    super.key,
    required this.todo,
    required this.index,
    required this.onToggle,
  });

  final TodoItem todo;
  final int index;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final completed = todo.status == TodoStatus.completed;
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: AppSpacing.sm,
          end: AppSpacing.sm,
          top: 5,
          bottom: 5,
        ),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Semantics(
                label: l10n.reorderTodo,
                child: Icon(
                  AppIcons.gripVertical,
                  size: 14,
                  color: t.textQuaternary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            _TodoStatusGlyph(status: todo.status),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                todo.content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: completed ? t.textTertiary : t.textPrimary,
                  decoration: completed ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A status glyph for a todo item — distinct shape per state (never colour
/// alone), with an accessible label.
class _TodoStatusGlyph extends StatelessWidget {
  const _TodoStatusGlyph({required this.status});

  final TodoStatus status;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final (icon, color, label) = switch (status) {
      TodoStatus.completed => (
        AppIcons.circleCheck,
        t.fgSuccessPrimary,
        l10n.todoStatusCompleted,
      ),
      TodoStatus.inProgress => (
        AppIcons.loaderCircle,
        t.fgBrandPrimary,
        l10n.todoStatusInProgress,
      ),
      TodoStatus.pending => (
        AppIcons.circle,
        t.textQuaternary,
        l10n.todoStatusPending,
      ),
    };
    return Semantics(
      label: label,
      child: Icon(icon, size: 14, color: color),
    );
  }
}
