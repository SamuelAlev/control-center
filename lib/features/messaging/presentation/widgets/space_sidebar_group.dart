import 'dart:async';

import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/utils/conversation_display_name.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_conversations_accordion.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_height_reveal.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_hover_prefetch.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_sidebar_item.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/space_worktrees_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/relative_time.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Air above and below the title. The title row keeps both insets whether
/// or not its list is open, so opening does not resize the title block.
/// Kept tight so the space list reads as one list, not separate cards.
const double _kCardInset = AppSpacing.xs;

/// Air under the last conversation, closing the open card.
const double _kCardBottom = AppSpacing.sm;

/// One space in the global sidebar. The open space sits on a raised panel.
class SpaceSidebarGroup extends ConsumerWidget implements CcFluidHoverTarget {
  /// Creates a [SpaceSidebarGroup].
  const SpaceSidebarGroup({
    super.key,
    required this.space,
    required this.routeSpaceId,
    required this.onOpenSpace,
  });

  /// The space this group represents.
  final Space space;

  /// Space id from the URL, when the route is a space.
  final String? routeSpaceId;

  /// Opens the space itself.
  final VoidCallback onOpenSpace;

  @override
  bool get fluidHoverEnabled => true;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final selected = space.id == routeSpaceId;
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final branch = workspaceId == null
        ? null
        : ref
              .watch(
                spaceSidebarBranchProvider((
                  workspaceId: workspaceId,
                  spaceId: space.id,
                )),
              )
              .value;
    // Conversations, the count, and the accordion belong to the open space.
    // An inactive row is only the space itself, so it does not subscribe.
    final conversations = selected
        ? ref.watch(spaceConversationsProvider(space.id)).value ??
              const <Conversation>[]
        : const <Conversation>[];
    final active = conversations
        .where((c) => !c.isArchived)
        .toList(growable: false);
    final listed = active.length > 1;
    final busyIds = listed
        ? ref.watch(spaceBusyConversationIdsProvider(space.id))
        : const <String>{};
    final childCarriesRunning =
        listed && active.any((c) => busyIds.contains(c.id));
    final startedAt = listed
        ? ref.watch(spaceRunStartedAtProvider(space.id))
        : const <String, DateTime>{};
    final unreadOnChild =
        listed &&
        active.any(
          (c) => ref.watch(
            conversationUnreadProvider((
              spaceId: space.id,
              conversationId: c.id,
            )),
          ),
        );
    // Every space keeps a reveal, including the closed ones. The open card
    // grows and the card being left shrinks in the same gesture; a reveal
    // that mounts already open has nothing to animate from.
    final showThreads = selected && listed;
    final label = space.name.isNotEmpty ? space.name : l10n.spaceLabel;
    // One press for the whole card. The title and the conversations are
    // content on that surface; the disclosure and the overflow menu stay
    // their own controls.
    final card = CcTappable(
      onPressed: onOpenSpace,
      borderRadius: AppRadii.brSm,
      semanticLabel: label,
      builder: (context, states) {
        final pressed = states.contains(WidgetState.pressed);
        final hovered = states.contains(WidgetState.hovered);
        final menu =
            hovered ||
            (states.contains(WidgetState.focused) &&
                FocusModality.instance.isKeyboard);
        // The travelling wash already covers this card. A second hover fill
        // here would stack on it. Press still belongs to this surface.
        final wash = pressed
            ? t.hoverStrong
            : (hovered && !CcFluidHover.isItemActive(context))
            ? t.hover
            : const Color(0x00000000);
        return DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(color: wash, borderRadius: AppRadii.brSm),
          child: SpaceHeightReveal(
            open: showThreads,
            selected: selected,
            fillColor: t.bgTertiary,
            header: SpaceSidebarItem(
              space: space,
              selected: selected,
              quietSelection: selected,
              subtitle: branch,
              absentLeading: const SpaceStatusMark(),
              runningShownOnConversations: childCarriesRunning,
              unreadShownOnConversations: unreadOnChild,
              // The air under the title stays on the row. Moving it onto
              // the list when the accordion opens would change the row's
              // height in the same frames the list is growing.
              cardInset: const EdgeInsets.only(
                top: _kCardInset,
                bottom: _kCardInset,
              ),
              interactive: false,
              menuRevealed: menu,
              onPress: onOpenSpace,
            ),
            child: showThreads
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SpaceConversationsAccordion(
                        label: l10n.conversationCount(active.length),
                        children: [
                          for (final c in active)
                            _ConversationActivity(
                              key: ValueKey(c.id),
                              conversation: c,
                              spaceId: space.id,
                              runningSince: startedAt[c.id],
                            ),
                        ],
                      ),
                      const SizedBox(height: _kCardBottom),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        );
      },
    );
    // Always in the tree: wrapping only unselected rows would remount the
    // card on selection and lose its reveal.
    return SpaceHoverPrefetch(
      workspaceId: selected ? null : workspaceId,
      spaceId: space.id,
      child: card,
    );
  }
}

class _ConversationActivity extends ConsumerStatefulWidget {
  const _ConversationActivity({
    super.key,
    required this.conversation,
    required this.spaceId,
    required this.runningSince,
  });

  final Conversation conversation;
  final String spaceId;

  /// When set, the caption is the time since this run started.
  final DateTime? runningSince;

  @override
  ConsumerState<_ConversationActivity> createState() =>
      _ConversationActivityState();
}

class _ConversationActivityState extends ConsumerState<_ConversationActivity> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Coarse enough to keep a list of conversations cheap, fine enough that
    // a minute or hour boundary shows up while the row is on screen.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversation = widget.conversation;
    final running = widget.runningSince != null;
    final unread = ref.watch(
      conversationUnreadProvider((
        spaceId: widget.spaceId,
        conversationId: conversation.id,
      )),
    );
    final l10n = AppLocalizations.of(context);
    // No selected fill and no overflow: rename and archive live on the tab.
    // The leading mark is the only status: hollow when idle, spinning while
    // a run is in progress, filled accent when messages are unseen.
    return SpaceRow(
      indent: kSpaceSidebarMarkSlot + kSpaceSidebarMarkGap,
      markSlot: kConversationMarkSlot,
      markGap: kConversationMarkGap,
      labelFontSize: kConversationLabelFontSize,
      extent: kConversationRowExtent,
      leading: conversationActivityMark(running: running, unread: unread),
      label: conversationDisplayName(conversation, l10n),
      trailingLabel: formatCompactAge(
        context,
        widget.runningSince ?? conversation.updatedAt,
      ),
      selected: false,
      status: running ? SpaceStatus.running : SpaceStatus.idle,
      // The leading mark is the unread signal, so the trailing dot stays off.
      unread: false,
      leadingHandlesRunning: true,
    );
  }
}
