import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/features/agents/domain/value_objects/agent_live_state.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/presentation/widgets/agent_status.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/agents/providers/conversation_run_tree_provider.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/agent_run_target.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/paused_runs_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/collapsible_sidebar_section.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// The AGENTS section of the messaging IDE's General panel: the conversation's
/// live run tree, one row per agent with its spawned subagent runs nested
/// beneath.
///
/// Extracted from `general_panel.dart` so the panel stays readable and this
/// section — the entry point into a run's activity — can be tested on its own.
class AgentsSection extends ConsumerWidget {
  /// Creates an [AgentsSection].
  const AgentsSection({
    super.key,
    required this.spaceId,
    required this.workspaceId,
    required this.onOpenAgentRun,
  });

  /// The conversation whose run tree is rendered.
  final String spaceId;

  /// The active workspace.
  final String workspaceId;

  /// Opens (or focuses) the tapped run — see [AgentRunTarget].
  final ValueChanged<AgentRunTarget> onOpenAgentRun;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final treeAsync = ref.watch(
      spaceRunTreeProvider((workspaceId: workspaceId, spaceId: spaceId)),
    );
    final roots = treeAsync.asData?.value ?? const <RunTreeNode>[];
    final agents =
        ref.watch(workspaceAgentsProvider(workspaceId)).asData?.value ??
        const <Agent>[];
    final agentsById = {for (final a in agents) a.id: a};
    final pausedRunIds = ref.watch(pausedRunsProvider);

    // Flatten for a live "done/total" count. Every node here has a row (the tree
    // holds exactly what is rendered), so the count can no longer overstate what
    // is on screen.
    var total = 0;
    var settled = 0;
    void countNode(RunTreeNode n) {
      total++;
      if (n.status != AgentLiveState.running) {
        settled++;
      }
      n.children.forEach(countNode);
    }

    roots.forEach(countNode);

    // Resolve an agent-group node's row label to the agent's display name
    // (falling back to the id the provider left in `label`).
    String nameFor(RunTreeNode node) {
      final agent = agentsById[node.agentId];
      if (agent != null && agent.name.trim().isNotEmpty) {
        return agent.name;
      }
      if (agent != null && agent.title.trim().isNotEmpty) {
        return agent.title;
      }
      return node.label;
    }

    // A subagent row's label: its own summary, then a synthesized fallback. The
    // fallback is localized HERE rather than in the provider, which has no
    // BuildContext — and it never shows a raw id, which is what previously made a
    // summary-less run read as the agent nested under itself.
    final timeFormat = DateFormat.Hm(
      Localizations.localeOf(context).toString(),
    );
    String labelFor(RunTreeNode node) {
      if (node.label.isNotEmpty) {
        return node.label;
      }
      final startedAt = node.startedAt;
      final time = startedAt == null
          ? ''
          : timeFormat.format(startedAt.toLocal());
      if (node.retryAttempt > 0) {
        return l10n.agentRunRetryLabel(node.retryAttempt, time);
      }
      return l10n.agentRunStarting(time);
    }

    final rows = <Widget>[];

    // Renders the whole tree, not a fixed two levels. An agent row is always
    // depth 0 and its subagents depth 1, but a subagent may itself have spawned
    // another level, so the walk has to recurse. Anything not walked here would
    // still be counted by `countNode` above, which is how ten running subagents
    // once showed up in the header total with no row to open.
    //
    // `ancestorLines` carries, for each level above this row, whether that
    // ancestor still has siblings below — so the guide line for that level keeps
    // descending past this row instead of leaving a gap in the rail.
    void emit(
      RunTreeNode node, {
      required int depth,
      required bool isLastChild,
      required List<bool> ancestorLines,
    }) {
      final isRoot = depth == 0;
      final label = isRoot ? nameFor(node) : labelFor(node);
      // A running/blocked agent can be paused at its next turn boundary.
      final canPause =
          isRoot &&
          (node.status == AgentLiveState.running ||
              node.status == AgentLiveState.blocked);
      final paused = isRoot && pausedRunIds.contains(node.runId);
      rows.add(
        _AgentRow(
          node: node,
          displayLabel: label,
          depth: depth,
          isLastChild: isLastChild,
          ancestorLines: ancestorLines,
          // Truthful at every level now that the whole tree renders: a row with
          // children always has them on screen beneath it, so the head of its
          // guide line can never dangle into nothing.
          hasChildren: node.children.isNotEmpty,
          paused: paused,
          onPauseToggle: canPause
              ? () => _togglePause(ref, context, node.runId, paused)
              : null,
          onTap: () => onOpenAgentRun((
            agentId: node.agentId,
            runId: node.runId,
            label: label,
            isSubAgent: !isRoot,
          )),
          // A top-level run's activity IS the conversation, so tapping opens
          // chat and the menu offers the raw timeline; every nested row is the
          // mirror of that — tapping opens the timeline, the menu jumps back to
          // the conversation. Either way it stays off an already-crowded 200px row.
          onSecondaryMenu: (position) => _showRowMenu(
            context,
            position,
            label: isRoot ? l10n.openAgentActivity : l10n.focusConversation,
            icon: isRoot ? AppIcons.activity : AppIcons.messageSquareText,
            onSelected: () => onOpenAgentRun((
              agentId: node.agentId,
              runId: node.runId,
              label: label,
              isSubAgent: isRoot,
            )),
          ),
        ),
      );
      for (var i = 0; i < node.children.length; i++) {
        emit(
          node.children[i],
          depth: depth + 1,
          isLastChild: i == node.children.length - 1,
          // The row's own level contributes a rail to its children only while
          // this row still has siblings coming; the root level never does.
          ancestorLines: isRoot
              ? const <bool>[]
              : [...ancestorLines, !isLastChild],
        );
      }
    }

    for (final root in roots) {
      emit(root, depth: 0, isLastChild: true, ancestorLines: const <bool>[]);
    }

    return CollapsibleSidebarSection(
      icon: AppIcons.sparkles,
      label: l10n.generalSectionAgents,
      count: total == 0 ? null : '$settled/$total',
      child: roots.isEmpty
          ? SidebarEmptyRow(message: l10n.generalAgentsEmpty)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rows,
            ),
    );
  }

  /// A one-item context menu for an agent row — the reverse jump between the
  /// conversation and a run's raw timeline.
  void _showRowMenu(
    BuildContext context,
    Offset position, {
    required String label,
    required IconData icon,
    required VoidCallback onSelected,
  }) {
    showCcMenuAt(
      context: context,
      position: position,
      items: [CcMenuItem(label: label, icon: icon, onSelected: onSelected)],
    );
  }

  /// Pauses or resumes the agent's run at a turn boundary. Optimistically flips
  /// the row's affordance; a non-pausable run (external CLI / already finished)
  /// surfaces a toast and leaves the row un-paused.
  Future<void> _togglePause(
    WidgetRef ref,
    BuildContext context,
    String runId,
    bool paused,
  ) async {
    final port = ref.read(messagingServiceProvider);
    final notifier = ref.read(pausedRunsProvider.notifier);
    final toast = CcToastScope.of(context);
    final cannotPauseMessage = AppLocalizations.of(context).agentCannotPause;
    if (paused) {
      notifier.markResumed(runId);
      await port.resumeRun(runId);
      return;
    }
    final accepted = await port.pauseRun(runId);
    if (accepted) {
      notifier.markPaused(runId);
    } else {
      toast.show(cannotPauseMessage, variant: CcToastVariant.neutral);
    }
  }
}

class _AgentRow extends StatelessWidget {
  const _AgentRow({
    required this.node,
    required this.displayLabel,
    required this.depth,
    required this.isLastChild,
    required this.ancestorLines,
    required this.hasChildren,
    required this.paused,
    required this.onPauseToggle,
    required this.onTap,
    this.onSecondaryMenu,
  });

  final RunTreeNode node;

  /// The row label to render (the resolved agent name for a parent/agent row,
  /// or the subagent's task label for a child row).
  final String displayLabel;
  final int depth;
  final bool isLastChild;

  /// One flag per level *above* this row's own connector, in outermost-first
  /// order: true when that ancestor still has siblings below, so its guide line
  /// must keep descending through this row. Empty for a root and for a root's
  /// direct children (there is no level between them and their connector).
  final List<bool> ancestorLines;

  /// Whether rows are rendered beneath this one. When true the row paints the
  /// head of the guide line, descending from its own status dot to its bottom
  /// edge — where the first child's connector bleeds up to meet it.
  final bool hasChildren;

  /// Whether this agent's run is currently paused (drives the pause/resume
  /// affordance). Only meaningful for parent rows.
  final bool paused;

  /// Pauses/resumes the agent's run; null when the run can't be paused (idle,
  /// finished) or for a subagent row.
  final VoidCallback? onPauseToggle;
  final VoidCallback onTap;

  /// Opens the row's context menu at the pointer (right-click / long-press).
  final ValueChanged<Offset>? onSecondaryMenu;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final visual = AgentStatusVisual.resolve(node.status, t, l10n);
    final isParent = depth == 0;
    // A child row's own connector supplies its own level of indent and each
    // level above it is supplied by an `_AncestorRail` of the same width — which
    // both indents the row and continues that ancestor's guide line through it.
    const leftPad = _rowInset;
    // Distance from the row's left edge to its status dot's center: the inset,
    // one width per ancestor level, the connector this row draws for itself
    // (children only), then the dot's own radius. The guide line has to descend
    // from exactly here.
    final dotCenterX =
        leftPad +
        ancestorLines.length * _treeIndent +
        (isParent ? 0 : _treeIndent) +
        _dotRadius;

    // GestureDetector wraps (rather than replaces) CcTappable because the
    // cc_ui primitive covers tap/long-press/keyboard but not right-click.
    return GestureDetector(
      onSecondaryTapDown: onSecondaryMenu == null
          ? null
          : (details) => onSecondaryMenu!(details.globalPosition),
      child: CcTappable(
        onPressed: onTap,
        onLongPress: onSecondaryMenu == null
            ? null
            : () => onSecondaryMenu!(_rowCenter(context)),
        semanticLabel: '$displayLabel, ${visual.label}',
        borderRadius: AppRadii.brSm,
        // A flat hover wash instead of an ink ripple — the design system reports
        // state through color, not motion.
        builder: (context, states) => ColoredBox(
          color: states.contains(WidgetState.hovered)
              ? t.bgSecondaryHover
              : const Color(0x00000000),
          // The head of the guide line, painted across the row's *full* box
          // (padding included) so it can run from the dot down to the row's
          // bottom edge, which is exactly where the first child's connector
          // bleeds up to. Without it the rail began a row-padding below the
          // dot and read as floating rather than descending from this agent.
          child: CustomPaint(
            painter: hasChildren
                ? _TrunkHeadPainter(
                    color: _guideColor(t),
                    dotCenterX: dotCenterX,
                  )
                : null,
            child: Padding(
              padding: const EdgeInsets.only(
                left: leftPad,
                right: AppSpacing.sm,
                top: _rowPadY,
                bottom: _rowPadY,
              ),
              child: Row(
                children: [
                  for (final descending in ancestorLines)
                    _AncestorRail(descending: descending),
                  if (!isParent) _TreeConnector(isLast: isLastChild),
                  AgentStatusDot(visual: visual, size: _dotRadius * 2),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      displayLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isParent
                            ? FontWeight.w600
                            : CcTypography.regularWeight,
                        color: isParent ? t.textPrimary : t.textSecondary,
                      ),
                    ),
                  ),
                  if (!isParent && node.turnCount > 0) ...[
                    const SizedBox(width: AppSpacing.xs),
                    _TurnBadge(count: node.turnCount),
                  ],
                  if (isParent && onPauseToggle != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    _PauseButton(paused: paused, onTap: onPauseToggle!),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The row's own center in global coordinates — the anchor for a long-press
/// menu, which (unlike a right-click) carries no pointer position.
Offset _rowCenter(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) {
    return Offset.zero;
  }
  return box.localToGlobal(box.size.center(Offset.zero));
}

/// A small pause/resume toggle for a running agent row.
class _PauseButton extends StatelessWidget {
  const _PauseButton({required this.paused, required this.onTap});

  final bool paused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return CcTappable(
      onPressed: onTap,
      borderRadius: AppRadii.brSm,
      semanticLabel: paused ? l10n.resumeAgent : l10n.pauseAgent,
      builder: (context, states) => Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(
          paused ? AppIcons.play : AppIcons.pause,
          size: 14,
          color: states.contains(WidgetState.hovered)
              ? t.textPrimary
              : t.textSecondary,
        ),
      ),
    );
  }
}

/// Left inset of every row in the tree, [AppSpacing.sm] wider than the section
/// header's so a top-level agent's status dot lands on the header chevron's
/// center rather than sitting a notch left of the whole panel's left rail.
const double _rowInset = AppSpacing.md;

/// Horizontal indent one tree level costs — also the [_TreeConnector]'s width,
/// so `_guideInset` lands on the parent row's dot center at every depth. Tight
/// on purpose: a subagent is a detail of its parent, not a peer and at 20 the
/// children drifted far enough right to read as their own column.
const double _treeIndent = 12;

/// Radius of a row's status dot. The guide line descends from it and is
/// centered on it, so the two have to agree.
const double _dotRadius = 4;

/// Vertical padding above and below a row's content.
const double _rowPadY = 5;

/// Where the guide line sits inside the connector. A row's status dot center is
/// `_rowInset + _dotRadius` from the row's left edge and a child's connector
/// starts at its parent's left edge, so one dot-radius puts the vertical stroke
/// directly under the parent's dot.
const double _guideInset = _dotRadius;

/// Vertical bleed past the connector box, into the row's padding, so the guide
/// reads as one continuous line down a run of siblings instead of dashes.
const double _guideBleed = _rowPadY;

/// The tree guide's stroke. Not a border token: `borderSecondary` is gray800 in
/// dark mode, which on the gray950 panel is ~1.1:1 — the guide simply
/// disappeared and the next step up (`borderPrimary`, gray700) is barely
/// better at ~1.2:1. `fgDisabled` resolves in both themes but reads hot at
/// 4.5:1 in dark, so it is dialled back with alpha rather than swapped for a
/// flatter token — that lands between the palette's steps and keeps the line
/// sitting on whatever the row's background currently is, hover wash included.
Color _guideColor(DesignSystemTokens t) => t.fgDisabled.withValues(alpha: 0.7);

/// The head of the guide line, painted by a row that has children: a stroke
/// from the bottom of its own status dot to its bottom edge, where the first
/// child's [_TreeConnector] bleeds up to meet it. Painted over the row's full
/// box (padding included) so "bottom edge" means exactly that.
class _TrunkHeadPainter extends CustomPainter {
  _TrunkHeadPainter({required this.color, required this.dotCenterX});

  final Color color;

  /// Horizontal center of this row's status dot, from the row's left edge.
  final double dotCenterX;

  @override
  void paint(Canvas canvas, Size size) {
    // The row's padding is symmetric, so its content — and therefore the
    // vertically-centered status dot — sits on the box's own center line.
    canvas.drawLine(
      Offset(dotCenterX, size.height / 2 + _dotRadius),
      Offset(dotCenterX, size.height),
      Paint()
        ..color = color
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_TrunkHeadPainter old) =>
      old.color != color || old.dotCenterX != dotCenterX;
}

/// One ancestor level's slice of indent to the left of a nested row.
///
/// Draws that ancestor's `│` when it still has siblings below and nothing when
/// it was the last — without this, a third level indents correctly but its
/// ancestor's rail vanishes behind it and the tree reads as broken.
class _AncestorRail extends StatelessWidget {
  const _AncestorRail({required this.descending});

  /// Whether the ancestor at this level still has siblings below.
  final bool descending;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return SizedBox(
      width: _treeIndent,
      height: 20,
      child: descending
          ? CustomPaint(painter: _AncestorRailPainter(color: _guideColor(t)))
          : null,
    );
  }
}

class _AncestorRailPainter extends CustomPainter {
  _AncestorRailPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Full height plus the same bleed the connector uses, so the rail reads as
    // one continuous line rather than a dash per row.
    canvas.drawLine(
      const Offset(_guideInset, -_guideBleed),
      Offset(_guideInset, size.height + _guideBleed),
      Paint()
        ..color = color
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_AncestorRailPainter old) => old.color != color;
}

/// A `├`/`└` tree connector drawn to the left of a child row.
class _TreeConnector extends StatelessWidget {
  const _TreeConnector({required this.isLast});

  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return SizedBox(
      width: _treeIndent,
      height: 20,
      child: CustomPaint(
        painter: _TreeConnectorPainter(color: _guideColor(t), isLast: isLast),
      ),
    );
  }
}

class _TreeConnectorPainter extends CustomPainter {
  _TreeConnectorPainter({required this.color, required this.isLast});

  final Color color;
  final bool isLast;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final midY = size.height / 2;
    // Vertical stroke: bleeds up into the row's padding to meet the row above,
    // and continues past the bottom unless this is the last sibling (`└`).
    canvas.drawLine(
      const Offset(_guideInset, -_guideBleed),
      Offset(_guideInset, isLast ? midY : size.height + _guideBleed),
      paint,
    );
    // Horizontal elbow into the row, stopping short of the status dot.
    canvas.drawLine(
      Offset(_guideInset, midY),
      Offset(size.width - AppSpacing.xxs, midY),
      paint,
    );
  }

  @override
  bool shouldRepaint(_TreeConnectorPainter old) =>
      old.color != color || old.isLast != isLast;
}

/// A `+N` badge tinted with the accent, matching the reference's turn counts.
class _TurnBadge extends StatelessWidget {
  const _TurnBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: t.accentSoft,
        borderRadius: AppRadii.brSm,
      ),
      child: Text(
        '+$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: t.fgBrandPrimary,
        ),
      ),
    );
  }
}
