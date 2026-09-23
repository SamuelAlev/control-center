import 'dart:async';

import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/utils/conversation_display_name.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_conversations_accordion.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_height_reveal.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_sidebar_item.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/space_worktrees_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/relative_time.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Air above the title and below the last row. Painted by the space row's
/// own fill, so a press recolors the card inset with the title instead of
/// leaving a band of panel color above and below it.
const double _kCardInset = AppSpacing.sm;

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
    // The parent hover item is this whole group, so a pointer on a
    // conversation would otherwise mark the space row hovered too.
    final row = CcFluidHover.consumeTappable(
      SpaceSidebarItem(
        space: space,
        selected: selected,
        quietSelection: selected,
        subtitle: branch,
        absentLeading: const SpaceStatusMark(),
        runningShownOnConversations: childCarriesRunning,
        unreadShownOnConversations:
            listed &&
            active.any(
              (c) => ref.watch(
                conversationUnreadProvider((
                  spaceId: space.id,
                  conversationId: c.id,
                )),
              ),
            ),
        // The air under the title stays on the row. Moving it onto the list
        // when the accordion opens would change the row's height in the
        // same frames the list is growing.
        cardInset: const EdgeInsets.only(top: _kCardInset, bottom: _kCardInset),
        onPress: onOpenSpace,
      ),
    );
    // Every space keeps a reveal, including the closed ones. The open card
    // grows and the card being left shrinks in the same gesture; a reveal
    // that mounts already open has nothing to animate from.
    final showThreads = selected && listed;
    return SpaceHeightReveal(
      open: showThreads,
      selected: selected,
      fillColor: t.bgTertiary,
      header: row,
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
                        // A conversation row is part of the space, not its
                        // own destination.
                        onPress: onOpenSpace,
                      ),
                  ],
                ),
                const SizedBox(height: _kCardInset),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}

class _ConversationActivity extends ConsumerStatefulWidget {
  const _ConversationActivity({
    super.key,
    required this.conversation,
    required this.spaceId,
    required this.runningSince,
    required this.onPress,
  });

  final Conversation conversation;
  final String spaceId;

  /// When set, the caption is the time since this run started.
  final DateTime? runningSince;
  final VoidCallback onPress;

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
      onPress: widget.onPress,
    );
  }
}
