import 'package:cc_domain/cc_domain.dart' show UndoClass;
import 'package:cc_domain/core/domain/entities/review_space_association.dart'
    show ReviewSpaceAssociation;
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/todos/domain/entities/conversation_goal.dart';
import 'package:cc_domain/features/todos/domain/entities/todo_item.dart';
import 'package:cc_domain/features/todos/domain/value_objects/todo_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/undo/action_journal.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/agent_run_target.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/agents_section.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/goals_section.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/rigs_sections.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/plan_studio/providers/plan_studio_providers.dart';
import 'package:control_center/features/plan_studio/providers/space_plan_execution_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_space_provider.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_surfaces.dart';
import 'package:control_center/features/sandboxing/providers/terminal_sessions_provider.dart';
import 'package:control_center/features/todos/providers/todo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/collapsible_sidebar_section.dart';
import 'package:control_center/shared/widgets/pr_title_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The "General" IDE-sidebar panel: a session dashboard showing the active
/// conversation's PULL REQUESTS (the linked PR, when there is one), TODOS,
/// AGENTS (live run tree), TERMINALS and MACHINES (browser / computer rigs).
class GeneralPanel extends ConsumerWidget {
  /// Creates a [GeneralPanel].
  const GeneralPanel({
    super.key,
    required this.workspaceId,
    required this.onOpenAgentRun,
    required this.onFocusTerminal,
    required this.onFocusRig,
    required this.onFocusBrowserTab,
    required this.onCloseBrowserTab,
  });

  /// The active workspace.
  final String workspaceId;

  /// Opens (or focuses) the tapped agent run — see [AgentRunTarget].
  final ValueChanged<AgentRunTarget> onOpenAgentRun;

  /// Focuses (or opens) the terminal identified by its session id.
  final ValueChanged<String> onFocusTerminal;

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
        message: l10n.selectConversation,
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      children: [
        // Durable supervised goals (`/goal` + `/loop`) sit on top: they are
        // the standing orders every run below works toward.
        GoalsSection(spaceId: spaceId, workspaceId: workspaceId),
        // The conversation's linked pull request, when there is one.
        _PullRequestsSection(spaceId: spaceId),
        // An approved plan shows up as this conversation's GOAL (inside TODOS),
        // not as a surface of its own.
        _TodosSection(spaceId: spaceId, workspaceId: workspaceId),
        AgentsSection(
          spaceId: spaceId,
          workspaceId: workspaceId,
          onOpenAgentRun: onOpenAgentRun,
        ),
        _TerminalsSection(spaceId: spaceId, onFocusTerminal: onFocusTerminal),
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

// ---------------------------------------------------------------------------
// PULL REQUESTS
// ---------------------------------------------------------------------------

/// The pull requests this conversation is about, from either direction.
///
/// A PR reaches a conversation two ways and only one of them writes a row.
/// [spacePrDetailProvider] resolves the [ReviewSpaceAssociation] for the space
/// (prNumber + repoFullName) and fetches the [PullRequest] — that is the PR
/// WORKBENCH direction, where the space was minted for a PR opened off the PR
/// list. The other direction is a conversation that AUTHORED a pull request:
/// it commits on `conv/<id>` in its own worktree, and pushing that branch and
/// opening a PR records nothing, so this section stayed empty for the case the
/// operator is most likely to look for it in. [spaceBranchPullRequestsProvider]
/// covers it by matching the worktree branch to an open PR's head, which works
/// however the PR was opened (compose screen, `gh`, the web UI, an agent).
///
/// The association wins on a tie: it is an explicit link, and one PR must not
/// render twice when both directions resolve it. While the lookups are in
/// flight, or when the conversation has no PR at all, the section renders
/// nothing — the PULL REQUESTS label only appears once there is a card under it.
class _PullRequestsSection extends ConsumerWidget {
  const _PullRequestsSection({required this.spaceId});

  final String spaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linked = ref.watch(spacePrDetailProvider(spaceId)).asData?.value;
    final authored =
        ref.watch(spaceBranchPullRequestsProvider(spaceId)).value ?? const [];

    // Keyed by `owner/repo#number` — a space can own a worktree per repo, so
    // this legitimately holds more than one PR.
    final prs = <String, PullRequest>{};
    if (linked != null) {
      prs['${linked.repoFullName}#${linked.number}'] = linked;
    }
    for (final match in authored) {
      prs.putIfAbsent(
        '${match.pr.repoFullName}#${match.pr.number}',
        () => match.pr,
      );
    }
    if (prs.isEmpty) {
      return const SizedBox.shrink();
    }
    return CollapsibleSidebarSection(
      icon: AppIcons.gitPullRequest,
      label: AppLocalizations.of(context).pullRequests,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final pr in prs.values) _ConversationPrCard(pr: pr)],
      ),
    );
  }
}

/// Compact card for the single PR linked to the conversation.
class _ConversationPrCard extends ConsumerWidget {
  const _ConversationPrCard({required this.pr});

  final PullRequest pr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final workspaceId = ref.watch(activeWorkspaceIdProvider);

    return CcTappable(
      onPressed: workspaceId == null
          ? null
          : () => context.push(
              pullRequestDetailRoute(workspaceId, pr.repoFullName, pr.number),
            ),
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return Container(
          margin: const EdgeInsets.fromLTRB(8, 2, 8, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hovered ? t.hover : t.bgPrimary,
            borderRadius: AppRadii.brMd,
            border: Border.all(color: t.borderSecondary),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_stateIcon(pr), size: 18, color: _stateColor(pr, t)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PrTitleText(
                      pr.title,
                      leading: [TextSpan(text: '#${pr.number}  ')],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${pr.repoFullName}  ·  ${pr.baseRef} ← ${pr.headRef}',
                      style: TextStyle(fontSize: 11, color: t.textTertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _stateIcon(PullRequest pr) {
    if (pr.isDraft) {
      return AppIcons.gitPullRequestDraft;
    }
    if (pr.state == PrState.closed) {
      return AppIcons.gitPullRequestClosed;
    }
    return AppIcons.gitPullRequest;
  }

  Color _stateColor(PullRequest pr, DesignSystemTokens t) {
    if (pr.state == PrState.closed) {
      return t.textErrorPrimary;
    }
    if (pr.isDraft) {
      return t.textTertiary;
    }
    return t.textSuccessPrimary;
  }
}

// ---------------------------------------------------------------------------
// TODOS
// ---------------------------------------------------------------------------

class _TodosSection extends ConsumerWidget {
  const _TodosSection({required this.spaceId, required this.workspaceId});

  final String spaceId;
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final todosAsync = ref.watch(conversationTodosProvider(spaceId));
    final todos = todosAsync.asData?.value ?? const <TodoItem>[];
    final goal = ref.watch(conversationGoalProvider(spaceId)).asData?.value;

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
              ref
                  .read(todoRepositoryProvider)
                  .reorder(workspaceId, spaceId, ids);
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
                  repo.updateStatus(workspaceId, spaceId, todo.id, next);
                  // Reversible (PRD 19 §5): ⌘Z restores the prior status.
                  ref
                      .read(actionJournalProvider.notifier)
                      .record(
                        UndoableAction(
                          label: l10n.undoLabelTodoStatus,
                          undoClass: UndoClass.reversible,
                          undo: () => repo.updateStatus(
                            workspaceId,
                            spaceId,
                            todo.id,
                            previous,
                          ),
                          redo: () => repo.updateStatus(
                            workspaceId,
                            spaceId,
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
    final repo = ref.read(todoRepositoryProvider);
    repo.clearGoal(workspaceId, spaceId);
    ref
        .read(actionJournalProvider.notifier)
        .record(
          UndoableAction(
            label: l10n.undoLabelGoalClear,
            undoClass: UndoClass.reversible,
            undo: () => repo.setGoal(workspaceId, spaceId, goal.title),
            redo: () => repo.clearGoal(workspaceId, spaceId),
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
                            color:
                                states.contains(WidgetState.hovered)
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
                          color:
                              states.contains(WidgetState.hovered)
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
        AnimatedSize(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.md),
                  child: widget.child,
                )
              : const SizedBox(width: double.infinity),
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
        padding: const EdgeInsets.only(
          left: AppSpacing.sm,
          right: AppSpacing.sm,
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

// ---------------------------------------------------------------------------
// TERMINALS
// ---------------------------------------------------------------------------

class _TerminalsSection extends ConsumerWidget {
  const _TerminalsSection({
    required this.spaceId,
    required this.onFocusTerminal,
  });

  final String spaceId;
  final ValueChanged<String> onFocusTerminal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final sessions = ref.watch(spaceTerminalsProvider(spaceId));
    return CollapsibleSidebarSection(
      icon: AppIcons.terminal,
      label: l10n.generalSectionTerminals,
      count: sessions.isEmpty ? null : '${sessions.length}/${sessions.length}',
      child: sessions.isEmpty
          ? SidebarEmptyRow(message: l10n.generalTerminalsEmpty)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < sessions.length; i++)
                  _TerminalRow(
                    mirror: sessions[i],
                    onTap: () => onFocusTerminal(sessions[i].sessionId),
                    color: t.fgSuccessPrimary,
                  ),
              ],
            ),
    );
  }
}

class _TerminalRow extends StatelessWidget {
  const _TerminalRow({
    required this.mirror,
    required this.onTap,
    required this.color,
  });

  final TerminalMirror mirror;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    // Prefer the shell's live title (OSC / foreground process); fall back to
    // the bound agent id, then the generic section label.
    final name = mirror.title.isNotEmpty
        ? mirror.title
        : (mirror.session.agentId.isEmpty
              ? l10n.terminal
              : mirror.session.agentId);
    return InkWell(
      onTap: onTap,
      child: Semantics(
        button: true,
        label: l10n.focusTerminal,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 5,
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: t.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
