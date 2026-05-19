import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/plan_document.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/plan_tab.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:control_center/features/plan_studio/providers/plan_studio_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Plan ids whose studio tab was already auto-opened this app session.
///
/// Ephemeral UI de-duplication only — the open tab is the durable state.
/// Without it, leaving and re-entering the conversation inside the freshness
/// window would re-open a tab the operator may have deliberately closed.
final Set<String> _autoOpenedPlanIds = <String>{};

/// Clears the auto-open ledger. Tests only — each case needs a clean session.
@visibleForTesting
void resetAutoOpenedPlanTabs() => _autoOpenedPlanIds.clear();

/// Renders a submitted plan's whole lifecycle as one compact row in the feed.
///
/// The message metadata carries only the plan id; the bubble watches the
/// `PlanDocument` row, so `proposed → approved → rejected → superseded`
/// re-renders live with zero feed churn (the same shape
/// `OrchestrationProposalBubble` uses).
///
/// This is what makes a plan visible where it was authored. `submit_plan` used
/// to persist silently, so the only way to find a plan was to navigate to Plan
/// Studio and notice a new card — and the user's first signal that anything had
/// gone wrong was having to ask "you didn't write the plan?".
///
/// The row is deliberately thin: the graph, the estimate and the node inspector
/// live in Plan Studio, which opens as an editor **tab** beside the conversation
/// (see [openPlanStudio]). A plan that lands while the operator is watching this
/// conversation opens its tab on arrival — there is nothing to go hunt for.
class PlanBubble extends ConsumerWidget {
  /// Creates a [PlanBubble].
  const PlanBubble({super.key, required this.message});

  /// The plan channel message.
  final ChannelMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = resolveTokens(context);
    final l10n = AppLocalizations.of(context);
    final planId = message.metadata?['planId'] as String?;
    final workspaceId = ref.watch(activeWorkspaceIdProvider);

    if (planId == null || workspaceId == null) {
      return const SizedBox.shrink();
    }

    final async = ref.watch(planDocumentProvider(planId));

    // `Container`, not `DecoratedBox`: a decoration paints behind the child, so
    // any opaque full-bleed child (a tinted header, a filled footer) covers the
    // 1px side border. `Container` insets the child by the border's dimensions,
    // which keeps the card's edge intact whatever it holds.
    Widget shell(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.bgPrimary,
          borderRadius: AppRadii.brMd,
          border: Border.all(color: tokens.borderSecondary),
        ),
        child: ClipRRect(borderRadius: AppRadii.brMd, child: child),
      ),
    );

    Widget unavailable() => Padding(
      padding: const EdgeInsets.all(14),
      child: Text(
        l10n.planUnavailable,
        style: CcTypography.caption.copyWith(color: tokens.textTertiary),
      ),
    );

    return shell(
      async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CcSpinner()),
        ),
        error: (e, _) => unavailable(),
        data: (plan) => plan == null
            ? unavailable()
            : _Row(
                plan: plan,
                workspaceId: workspaceId,
                submittedAt: message.createdAt,
              ),
      ),
    );
  }
}

class _Row extends ConsumerStatefulWidget {
  const _Row({
    required this.plan,
    required this.workspaceId,
    required this.submittedAt,
  });

  final PlanDocument plan;
  final String workspaceId;

  /// When the plan message was posted — decides whether the plan is *arriving*
  /// (auto-open its tab) or is history being scrolled past (don't).
  final DateTime submittedAt;

  @override
  ConsumerState<_Row> createState() => _RowState();
}

class _RowState extends ConsumerState<_Row> {
  /// A plan is treated as "just produced" within this window of its message's
  /// timestamp. Long enough to cover the round trip from `submit_plan` to the
  /// feed, short enough that scrolling back to a plan from earlier in the
  /// session never re-opens it.
  static const Duration _freshWindow = Duration(seconds: 30);

  /// Below this width the actions move under the summary instead of beside it.
  static const double _wideRowWidth = 440;

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _maybeAutoOpen();
  }

  /// Opens Plan Studio for a plan that just landed in the conversation the
  /// operator is looking at. Deferred to the first frame: this runs during the
  /// feed's build, and the host layout must not have its tab tree mutated
  /// mid-build.
  void _maybeAutoOpen() {
    final plan = widget.plan;
    if (plan.status != PlanDocumentStatus.proposed) {
      return;
    }
    if (DateTime.now().difference(widget.submittedAt) > _freshWindow) {
      return;
    }
    if (!_autoOpenedPlanIds.add(plan.id)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _open();
      }
    });
  }

  void _open() => openPlanStudio(
    context,
    workspaceId: widget.workspaceId,
    kind: PlanTabKind.document,
    id: widget.plan.id,
    title: widget.plan.goal,
  );

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final tokens = resolveTokens(context);
    final l10n = AppLocalizations.of(context);
    final (label, icon) = _statusVisuals(plan.status, l10n);

    // Goal + one metadata line: status, step count, revision. Everything else
    // about the plan — graph, estimate, per-node inspector — is one click away
    // in the studio tab.
    // The status glyph rides the "open" action rather than sitting in a leading
    // gutter, so the goal starts at the card's text edge. Status is still
    // carried by shape as well as color — the glyph moved, it did not go away —
    // and `label` states it in words on the metadata line.
    final summary = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                plan.goal,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: CcTypography.body.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                  height: bodyLineHeight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                [
                  label,
                  l10n.planStepCount(plan.graph.nodes.length),
                  if (plan.revision > 1) l10n.planRevisionLabel(plan.revision),
                ].join('  ·  '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CcTypography.caption.copyWith(
                  color: tokens.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final actions = [
      CcButton(
        variant: CcButtonVariant.ghost,
        size: CcButtonSize.sm,
        icon: icon,
        onPressed: _open,
        child: Text(l10n.planOpenInStudio),
      ),
      if (plan.status == PlanDocumentStatus.proposed)
        CcButton(
          size: CcButtonSize.sm,
          loading: _busy,
          icon: AppIcons.check,
          onPressed: _busy ? null : _approve,
          child: Text(l10n.planApproveAndRun),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 10,
      ),
      // One line when the pane is wide enough for the actions to sit beside the
      // summary; the actions drop below it on a narrow (split) pane rather than
      // squeezing the goal to nothing or overflowing.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final actionsRow = Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment: WrapAlignment.end,
            children: actions,
          );
          if (constraints.maxWidth >= _wideRowWidth) {
            return Row(
              children: [
                Expanded(child: summary),
                const SizedBox(width: 8),
                actionsRow,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [summary, const SizedBox(height: 8), actionsRow],
          );
        },
      ),
    );
  }

  /// Status label + icon. Never color alone: the glyph on the open action and
  /// the word on the metadata line both carry the state.
  (String, IconData) _statusVisuals(
    PlanDocumentStatus status,
    AppLocalizations l10n,
  ) => switch (status) {
    PlanDocumentStatus.draft => (l10n.planStatusDraft, AppIcons.pencil),
    PlanDocumentStatus.proposed => (
      l10n.planStatusProposed,
      AppIcons.squarePen,
    ),
    PlanDocumentStatus.approved => (
      l10n.planStatusApproved,
      AppIcons.circleCheck,
    ),
    PlanDocumentStatus.rejected => (l10n.planStatusRejected, AppIcons.circleX),
    PlanDocumentStatus.superseded => (
      l10n.planStatusSuperseded,
      AppIcons.rotateCcw,
    ),
  };

  Future<void> _approve() async {
    setState(() => _busy = true);
    try {
      await ref.read(planStudioRepositoryProvider).approvePlan(widget.plan.id);
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.maybeOf(
          context,
        )?.show('$e', variant: CcToastVariant.danger);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}
