import 'dart:math' as math;

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/presentation/utils/conversation_display_name.dart';
import 'package:control_center/features/messaging/presentation/widgets/context_meter_chip.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_search_dialog.dart';
import 'package:control_center/features/messaging/providers/conversation_checkpoint_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/space_autonomy_provider.dart';
import 'package:control_center/features/messaging/providers/space_checker_provider.dart';
import 'package:control_center/features/messaging/providers/space_takeover_provider.dart';
import 'package:control_center/features/presence/presentation/widgets/whos_here_strip.dart';
import 'package:control_center/features/presence/providers/presence_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/agent_avatar.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Header bar displaying the open conversation (falling back to the space)
/// and the space's actions.
class SpaceHeader extends ConsumerWidget {
  /// Creates a new [SpaceHeader].
  const SpaceHeader({
    super.key,
    required this.space,
    required this.onManage,
    required this.onArchive,
    this.conversation,
  });

  /// The space to display.
  final Space space;

  /// Open conversation title, or the space name while it is still resolving.
  final Conversation? conversation;

  /// Callback to manage participants.
  final VoidCallback onManage;

  /// Callback to archive the space.
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final participantsAsync = ref.watch(spaceParticipantsProvider(space.id));
    final participants = participantsAsync.value ?? const [];
    // The wire never carries the "reverted" flag, so a session-scoped notifier
    // tracks whether this space has a revert the user can still undo (redo).
    final hasUndoableRevert = ref.watch(
      spaceHasUndoableRevertProvider(space.id),
    );
    final agents = participants.where((p) => !p.isUser).toList();
    final meteredAgentId = ref.watch(spaceMeteredAgentIdProvider(space.id));
    final l10n = AppLocalizations.of(context);

    final conversation = this.conversation;
    final title = conversation != null
        ? conversationDisplayName(conversation, l10n)
        : (space.name.isNotEmpty ? space.name : l10n.spaceLabel);
    final titleGenerating =
        conversation != null &&
        ref.watch(
          conversationTitleGeneratingProvider((
            spaceId: space.id,
            conversationId: conversation.id,
          )),
        );
    final titleStyle = CcTypography.body.copyWith(
      fontWeight: FontWeight.w600,
      color: tokens.textPrimary,
    );
    final subtitle = agents.isEmpty
        ? l10n.noAgents
        : l10n.agentCount(agents.length);

    final isPresenting =
        ref.watch(myPresenceProvider).spotlightSpaceId == space.id;
    final presentLabel = isPresenting
        ? l10n.stopPresenting
        : l10n.startPresenting;
    // Hidden while a take-over (by anyone) is already active — the
    // conversation-pane banner covers hand-back / status in that case.
    final takeoverActive =
        ref.watch(takeoverStatusProvider(space.id)).value != null;
    final visitorCount = WhosHereStrip.visitors(ref, space.id).length;

    // Visual order. [_HeaderAction.foldRank] decides which fold into the
    // overflow menu first when the pane is too narrow to show them all.
    final actions = [
      // Spotlight (present) this space to everyone else on the roster
      // (PRD 16 §5).
      _HeaderAction(
        icon: AppIcons.monitor,
        label: presentLabel,
        foldRank: 2,
        color: isPresenting ? tokens.accent : null,
        selected: isPresenting,
        onPressed: () => ref
            .read(myPresenceProvider.notifier)
            .setSpotlight(isPresenting ? null : space.id),
      ),
      // Take over this space's worktree (PRD 16 §8).
      if (!takeoverActive)
        _HeaderAction(
          icon: AppIcons.userCheck,
          label: l10n.takeoverTooltip,
          foldRank: 1,
          onPressed: () => _beginTakeover(context, ref),
        ),
      if (hasUndoableRevert)
        _HeaderAction(
          icon: AppIcons.rotateCw,
          label: l10n.undoRevert,
          foldRank: 3,
          onPressed: () => _undoRevert(context, ref),
        ),
      _HeaderAction(
        icon: AppIcons.search,
        label: l10n.searchInConversation,
        foldRank: 5,
        onPressed: () => showCcDialog<void>(
          context: context,
          builder: (_) => SpaceSearchDialog(spaceId: space.id),
        ),
      ),
      _HeaderAction(
        icon: AppIcons.users,
        label: l10n.manageParticipants,
        foldRank: 4,
        onPressed: onManage,
      ),
      _HeaderAction(
        icon: AppIcons.archive,
        label: l10n.archiveSpace,
        foldRank: 0,
        onPressed: onArchive,
      ),
    ];

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Everything but the title has a natural width, so the actions get
          // whatever is left once the leading glyph, a readable title floor,
          // the meter and the who's-here avatars are paid for. A narrow pane
          // (split editors, a docked terminal) folds the overflow into a
          // "More" menu instead of overflowing the fixed band.
          final meterWidth = meteredAgentId == null
              ? 0.0
              : _meterWidth + (agents.length > 1 ? _meterAgentWidth : 0);
          final visitorsWidth = visitorCount * _visitorWidth;
          // Past the point where even a zero-width title leaves no room for
          // the meter beside the "More" button, the meter yields: its
          // numbers are a glance, the actions are not.
          final showMeter =
              meterWidth > 0 &&
              constraints.maxWidth >=
                  _leadingWidth +
                      meterWidth +
                      visitorsWidth +
                      _HeaderAction.slotWidth;
          final reserved =
              _leadingWidth +
              _titleFloor +
              (showMeter ? meterWidth : 0) +
              visitorsWidth;
          final split = _HeaderAction.split(
            actions,
            budget: constraints.maxWidth - reserved,
          );

          return Row(
            children: [
              Icon(AppIcons.users, size: 20, color: tokens.textTertiary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // One line, always: the header is a fixed 56px band, so a
                    // long space name that wrapped pushed the subtitle past
                    // the bottom edge (a 2px RenderFlex overflow). Truncate
                    // and disclose the full name on hover instead of stealing
                    // a second line.
                    CcScrambleText(
                      title,
                      scrambling: titleGenerating,
                      style: titleStyle,
                      child: CcTruncatedText(title, style: titleStyle),
                    ),
                    Text(
                      subtitle,
                      style: CcTypography.caption.copyWith(
                        color: tokens.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Context-window telemetry. A space can hold several agents but
              // only ONE window fits in the header, so the meter follows
              // whichever agent last worked here (see
              // [spaceMeteredAgentIdProvider]) and names whose window it is
              // reading as soon as there is more than one.
              if (showMeter) ...[
                ContextMeterChip(
                  spaceId: space.id,
                  agentId: meteredAgentId!,
                  showAgent: agents.length > 1,
                ),
                const SizedBox(width: _meterGap),
              ],
              // Who else (human or agent) is here right now (PRD 16 §1–§3).
              // Renders nothing in solo mode or when nobody targets this
              // space.
              WhosHereStrip(spaceId: space.id),
              for (final action in split.inline) ...[
                const SizedBox(width: _actionGap),
                CcTooltip(
                  targetAnchor: Alignment.bottomCenter,
                  followerAnchor: Alignment.topCenter,
                  message: action.label,
                  child: CcIconButton(
                    icon: action.icon,
                    semanticLabel: action.label,
                    color: action.color,
                    onPressed: action.onPressed,
                  ),
                ),
              ],
              if (split.folded.isNotEmpty) ...[
                const SizedBox(width: _actionGap),
                _MoreActionsButton(actions: split.folded),
              ],
            ],
          );
        },
      ),
    );
  }

  // Header geometry the action budget is measured against. The meter and
  // visitor figures are each component's widest rendering, so a reservation
  // can only err toward folding one action too many, never overflowing.
  static const double _leadingWidth = 20 + 10;
  static const double _titleFloor = 96;
  // ContextMeterChip ("1000k / 1000k" in 11px mono + 12 wash + 8 end
  // padding) and the gap after it.
  static const double _meterWidth = 108 + _meterGap;
  static const double _meterGap = 8;
  // The attributing avatar (16) and its gap (6).
  static const double _meterAgentWidth = 22;
  // PresenceAvatarChip (22 + 2×1.5 padding + 2×1.5 follow ring) + 4 lead.
  static const double _visitorWidth = 32;
  static const double _actionGap = 4;

  /// Undoes the most-recent revert in this conversation (redo): the latest
  /// reverted batch reappears in the live message stream. The toast handle is
  /// captured before the await so it survives the async gap.
  Future<void> _undoRevert(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final toast = CcToastScope.maybeOf(context);
    final count = await ref
        .read(conversationCheckpointControllerProvider)
        .unrevert(space.id);
    toast?.show(
      count > 0 ? l10n.revertUndone : l10n.nothingToRevert,
      variant: count > 0 ? CcToastVariant.success : CcToastVariant.neutral,
    );
  }

  /// Begins the take-over, then opens the code-server editor tab on the same
  /// worktree — the natural take-over surface (PRD 16 §8). A failure (e.g.
  /// someone else just took over) surfaces via toast with the server's
  /// message rather than throwing into the widget tree.
  Future<void> _beginTakeover(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final toast = CcToastScope.maybeOf(context);
    try {
      await beginSpaceTakeover(ref.read(rpcClientProvider), space.id);
    } on RemoteRpcException catch (e) {
      toast?.show(
        l10n.takeoverFailed(e.message),
        variant: CcToastVariant.danger,
      );
      return;
    }
    ref.invalidate(takeoverStatusProvider(space.id));
    ref.read(codeServerTabRequestProvider(space.id).notifier).request();
  }
}

/// One header action, rendered inline as an icon button or folded into the
/// overflow menu when the pane is too narrow.
@immutable
class _HeaderAction {
  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.foldRank,
    required this.onPressed,
    this.color,
    this.selected = false,
  });

  final IconData icon;

  /// Tooltip, accessible name and menu row label.
  final String label;

  /// Lower ranks fold into the overflow menu first.
  final int foldRank;
  final VoidCallback onPressed;

  /// Active-state icon tint (inline only; the menu row uses [selected]).
  final Color? color;
  final bool selected;

  /// Inline icon button plus its leading gap.
  static const double slotWidth = 40 + SpaceHeader._actionGap;

  /// Splits [actions] into what fits [budget] inline and what folds into the
  /// overflow menu, keeping visual order on both sides. Once anything folds,
  /// the "More" button itself takes a slot.
  static ({List<_HeaderAction> inline, List<_HeaderAction> folded}) split(
    List<_HeaderAction> actions, {
    required double budget,
  }) {
    if (actions.length * slotWidth <= budget) {
      return (inline: actions, folded: const []);
    }
    final fit = math.max(0, (budget / slotWidth).floor() - 1);
    final byKeep = [...actions]
      ..sort((a, b) => b.foldRank.compareTo(a.foldRank));
    final kept = byKeep.take(fit).toSet();
    return (
      inline: [
        for (final a in actions)
          if (kept.contains(a)) a,
      ],
      folded: [
        for (final a in actions)
          if (!kept.contains(a)) a,
      ],
    );
  }
}

/// The "More" icon button holding the header actions that did not fit.
class _MoreActionsButton extends StatefulWidget {
  const _MoreActionsButton({required this.actions});

  final List<_HeaderAction> actions;

  @override
  State<_MoreActionsButton> createState() => _MoreActionsButtonState();
}

class _MoreActionsButtonState extends State<_MoreActionsButton> {
  final CcOverlayController _controller = CcOverlayController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // The trigger is a real button driving the controller, so the menu does
    // not wrap it in a second, competing tappable.
    return CcMenu(
      controller: _controller,
      toggleOnTargetTap: false,
      targetAnchor: AlignmentDirectional.bottomEnd,
      followerAnchor: AlignmentDirectional.topEnd,
      semanticLabel: l10n.moreLabel,
      items: [
        for (final a in widget.actions)
          CcMenuItem(
            label: a.label,
            icon: a.icon,
            selected: a.selected,
            onSelected: a.onPressed,
          ),
      ],
      target: CcTooltip(
        targetAnchor: Alignment.bottomCenter,
        followerAnchor: Alignment.topCenter,
        message: l10n.moreLabel,
        child: CcIconButton(
          icon: AppIcons.moreHorizontal,
          semanticLabel: l10n.moreLabel,
          onPressed: _controller.toggle,
        ),
      ),
    );
  }
}

/// Dialog for managing space participants.
class ManageSpaceDialog extends ConsumerStatefulWidget {
  /// Creates a new [ManageSpaceDialog].
  const ManageSpaceDialog({super.key, required this.spaceId});

  /// Space to manage.
  final String spaceId;

  @override
  ConsumerState<ManageSpaceDialog> createState() => _ManageSpaceDialogState();
}

class _ManageSpaceDialogState extends ConsumerState<ManageSpaceDialog> {
  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final participants =
        ref.watch(spaceParticipantsProvider(widget.spaceId)).value ?? const [];
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final agents = workspaceId != null
        ? ref.watch(workspaceAgentsProvider(workspaceId)).value ?? const []
        : ref.watch(agentsProvider).value ?? const [];
    final l10n = AppLocalizations.of(context);
    final existingIds = participants.map((p) => p.principalId).toSet();
    final spaceParticipants = participants.where((p) => !p.isUser).toList();
    final spaceAgentIds = spaceParticipants.map((p) => p.principalId).toSet();
    final spaceAgents = agents
        .where((a) => spaceAgentIds.contains(a.id))
        .toList();

    return CcDialog(
      title: l10n.manageParticipants,
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (spaceParticipants.isNotEmpty) ...[
              Text(
                l10n.currentParticipants,
                style: CcTypography.caption.copyWith(
                  color: tokens.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              ...spaceParticipants.map(
                (p) => _ParticipantRow(
                  spaceId: widget.spaceId,
                  participant: p,
                  onRemove: () => _removeAgent(p.principalId),
                ),
              ),
              const SizedBox(height: 24, child: Center(child: CcDivider())),
            ],
            Text(
              l10n.inviteAgent,
              style: CcTypography.caption.copyWith(color: tokens.textTertiary),
            ),
            const SizedBox(height: 8),
            _InviteSection(
              agents: agents,
              existingIds: existingIds,
              onInvite: _inviteAgent,
            ),
            const SizedBox(height: 24, child: Center(child: CcDivider())),
            _CheckerSection(spaceId: widget.spaceId, agents: spaceAgents),
          ],
        ),
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  Future<void> _removeAgent(String agentId) async {
    await ref
        .read(messagingServiceProvider)
        .removeParticipant(ref.requireWorkspaceId(), widget.spaceId, agentId);
  }

  Future<void> _inviteAgent(String agentId) async {
    await ref
        .read(messagingServiceProvider)
        .addAgentToSpace(ref.requireWorkspaceId(), widget.spaceId, agentId);
  }
}

class _ParticipantRow extends ConsumerWidget {
  const _ParticipantRow({
    required this.spaceId,
    required this.participant,
    required this.onRemove,
  });

  /// The space this participant belongs to — scopes the autonomy read/write.
  final String spaceId;
  final SpaceParticipant participant;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final agentAsync = ref.watch(agentDetailProvider(participant.principalId));
    final name = agentAsync.value?.name ?? '...';
    final title = agentAsync.value?.title ?? '';
    final l10n = AppLocalizations.of(context);
    final autonomy =
        ref.watch(spaceAutonomyProvider(spaceId)).value ??
        const <String, AutonomyLevel?>{};
    final currentLevel = autonomy[participant.principalId];
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final canSetAutonomy =
        workspaceId != null &&
        (ref.watch(myWorkspaceRoleProvider(workspaceId))?.isAdmin ?? false);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AgentAvatar(
                agentId: participant.principalId,
                name: name,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: CcTypography.body.copyWith(
                        color: tokens.textTertiary,
                      ),
                    ),
                    if (title.isNotEmpty)
                      Text(
                        title,
                        style: CcTypography.caption.copyWith(
                          color: tokens.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
              CcTooltip(
                message: l10n.remove,
                child: CcIconButton(
                  icon: AppIcons.x,
                  semanticLabel: l10n.remove,
                  onPressed: onRemove,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(
              top: 6,
              start: 34,
              end: 4,
            ),
            child: CcSelect<AutonomyLevel?>(
              label: l10n.autonomyDialLabel,
              // The dial decides whether this agent's risky effects are
              // pre-approved, so it carries the same admin floor as the
              // guardrail matrix it would otherwise neutralize (the server
              // enforces it; this keeps the control honest rather than
              // offering an action that will be refused).
              enabled: canSetAutonomy,
              options: [
                CcSelectOption(value: null, label: l10n.autonomyDefaultOption),
                CcSelectOption(
                  value: AutonomyLevel.proposeOnly,
                  label: l10n.autonomyProposeOnly,
                ),
                CcSelectOption(
                  value: AutonomyLevel.actWithApproval,
                  label: l10n.autonomyActWithApproval,
                ),
                CcSelectOption(
                  value: AutonomyLevel.actFreely,
                  label: l10n.autonomyActFreely,
                ),
              ],
              value: currentLevel,
              onChanged: (level) => setSpaceAutonomy(
                ref.read(rpcClientProvider),
                spaceId: spaceId,
                agentId: participant.principalId,
                level: level,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The space's checker-agent row (PRD 16 §13): a select over the space's
/// own agent participants (+ "None"), bound to `checker.get`/
/// `checker.setForSpace`.
class _CheckerSection extends ConsumerWidget {
  const _CheckerSection({required this.spaceId, required this.agents});

  final String spaceId;
  final List<Agent> agents;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentCheckerId = ref.watch(spaceCheckerProvider(spaceId)).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CcSelect<String?>(
          label: l10n.checkerLabel,
          options: [
            CcSelectOption(value: null, label: l10n.checkerNone),
            for (final a in agents) CcSelectOption(value: a.id, label: a.name),
          ],
          value: currentCheckerId,
          onChanged: (agentId) async {
            await setSpaceChecker(
              ref.read(rpcClientProvider),
              spaceId: spaceId,
              agentId: agentId,
            );
            ref.invalidate(spaceCheckerProvider(spaceId));
          },
        ),
        const SizedBox(height: 4),
        Text(
          l10n.checkerCaption,
          style: CcTypography.caption.copyWith(color: context.ds.textTertiary),
        ),
      ],
    );
  }
}

class _InviteSection extends StatefulWidget {
  const _InviteSection({
    required this.agents,
    required this.existingIds,
    required this.onInvite,
  });

  final List<Agent> agents;
  final Set<String> existingIds;
  final ValueChanged<String> onInvite;

  @override
  State<_InviteSection> createState() => _InviteSectionState();
}

class _InviteSectionState extends State<_InviteSection> {
  Agent? _selected;

  @override
  Widget build(BuildContext context) {
    final available = widget.agents
        .where((a) => !widget.existingIds.contains(a.id))
        .toList();
    final l10n = AppLocalizations.of(context);

    if (available.isEmpty) {
      return Text(
        l10n.allAgentsAlreadyInSpace,
        style: const TextStyle(fontSize: 12),
      );
    }

    return Column(
      children: [
        if (available.length <= 5)
          ...available.map(
            (a) => CcTile(
              leading: AgentAvatar(
                agentId: a.id,
                name: a.name,
                size: 22,
                showHoverCard: false,
              ),
              title: a.name,
              subtitle: a.title.isNotEmpty ? Text(a.title) : null,
              onTap: () {
                widget.onInvite(a.id);
                Navigator.of(context).pop();
              },
            ),
          )
        else ...[
          CcSelect<Agent>(
            value: _selected,
            options: available
                .map((a) => CcSelectOption<Agent>(value: a, label: a.name))
                .toList(),
            onChanged: (v) => setState(() => _selected = v),
            hintText: l10n.selectAnAgent,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: CcButton(
              onPressed: _selected == null
                  ? null
                  : () {
                      widget.onInvite(_selected!.id);
                      Navigator.of(context).pop();
                    },
              child: Text(l10n.invite),
            ),
          ),
        ],
      ],
    );
  }
}
