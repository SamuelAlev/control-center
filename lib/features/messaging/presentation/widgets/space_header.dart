import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/messaging/presentation/utils/conversation_display_name.dart';
import 'package:control_center/features/messaging/presentation/widgets/context_meter_chip.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_header_actions.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_search_dialog.dart';
import 'package:control_center/features/messaging/providers/conversation_checkpoint_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/space_takeover_provider.dart';
import 'package:control_center/features/presence/presentation/widgets/whos_here_strip.dart';
import 'package:control_center/features/presence/providers/presence_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
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

    // Visual order. [SpaceHeaderAction.foldRank] decides which fold into the
    // overflow menu first when the pane is too narrow to show them all.
    final actions = [
      // Spotlight (present) this space to everyone else on the roster
      // (PRD 16 §5).
      SpaceHeaderAction(
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
        SpaceHeaderAction(
          icon: AppIcons.userCheck,
          label: l10n.takeoverTooltip,
          foldRank: 1,
          onPressed: () => _beginTakeover(context, ref),
        ),
      if (hasUndoableRevert)
        SpaceHeaderAction(
          icon: AppIcons.rotateCw,
          label: l10n.undoRevert,
          foldRank: 3,
          onPressed: () => _undoRevert(context, ref),
        ),
      SpaceHeaderAction(
        icon: AppIcons.search,
        label: l10n.searchInConversation,
        foldRank: 5,
        onPressed: () => showCcDialog<void>(
          context: context,
          builder: (_) => SpaceSearchDialog(spaceId: space.id),
        ),
      ),
      SpaceHeaderAction(
        icon: AppIcons.users,
        label: l10n.manageParticipants,
        foldRank: 4,
        onPressed: onManage,
      ),
      SpaceHeaderAction(
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
                      SpaceHeaderAction.slotWidth;
          final reserved =
              _leadingWidth +
              _titleFloor +
              (showMeter ? meterWidth : 0) +
              visitorsWidth;
          final split = SpaceHeaderAction.split(
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
                const SizedBox(width: SpaceHeaderAction.gap),
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
                const SizedBox(width: SpaceHeaderAction.gap),
                SpaceHeaderMoreButton(actions: split.folded),
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
