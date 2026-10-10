import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_conversation_activity_row.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_conversations_accordion.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_height_reveal.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_hover_prefetch.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_row_adornments.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_sidebar_item.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/space_worktrees_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/gestures.dart' show kPrimaryButton, kTouchSlop;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Air above and below the title. The title row keeps both insets whether
/// or not its list is open, so opening does not resize the title block.
/// Kept tight so the space list reads as one list, not separate cards.
const double _kCardInset = AppSpacing.xs;

/// Air under the last conversation, closing the open card.
const double _kCardBottom = AppSpacing.sm;

/// One space in the global sidebar. The open space sits on a raised panel.
///
/// Reads its own selection from the route (see [watchRouteSpaceSelected]), so
/// opening a space rebuilds the card being left and the card being opened,
/// not the whole list.
class SpaceSidebarGroup extends ConsumerStatefulWidget
    implements CcFluidHoverTarget {
  /// Creates a [SpaceSidebarGroup].
  const SpaceSidebarGroup({super.key, required this.space});

  /// The space this group represents.
  final Space space;

  @override
  bool get fluidHoverEnabled => true;

  @override
  ConsumerState<SpaceSidebarGroup> createState() => _SpaceSidebarGroupState();
}

class _SpaceSidebarGroupState extends ConsumerState<SpaceSidebarGroup> {
  /// The card's press states, shared with its [CcTappable].
  ///
  /// Every row is also a drag source (see `SpaceFoldersList`), and the drag
  /// recognizer holds the gesture arena until the pointer moves or lifts, so
  /// the tap's own pressed state only arrived after `kPressTimeout`. The
  /// pointer itself sets it here on contact; the tap clears it as before, and
  /// so does a pointer that travels far enough to become a drag.
  final WidgetStatesController _states = WidgetStatesController();
  Offset? _downAt;

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (event.buttons != kPrimaryButton) {
      return;
    }
    _downAt = event.position;
    _states.update(WidgetState.pressed, true);
  }

  void _onPointerMove(PointerMoveEvent event) {
    final downAt = _downAt;
    if (downAt != null && (event.position - downAt).distance > kTouchSlop) {
      _releasePress();
    }
  }

  void _releasePress() {
    if (_downAt == null) {
      return;
    }
    _downAt = null;
    _states.update(WidgetState.pressed, false);
  }

  @override
  Widget build(BuildContext context) {
    final space = widget.space;
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final selected = watchRouteSpaceSelected(context, ref, space.id);
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
    // A press warms the list (see [SpaceHoverPrefetch]), so it is usually in
    // the cache by the time the route makes this card the open one.
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
    void open() => openSpaceFromSidebar(context, space.id);

    // Built once per data change, OUTSIDE the press builder: hover, press and
    // focus re-run only the wash and the menu-reveal scope around this
    // (identical) subtree, so the reveal, title and conversation rows are
    // skipped by the framework instead of rebuilt on every pointer change.
    final body = SpaceHeightReveal(
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
        // The air under the title stays on the row. Moving it onto the list
        // when the accordion opens would change the row's height in the same
        // frames the list is growing.
        cardInset: const EdgeInsets.only(top: _kCardInset, bottom: _kCardInset),
        interactive: false,
        onPress: open,
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
                      SpaceConversationActivityRow(
                        key: ValueKey(c.id),
                        conversation: c,
                        spaceId: space.id,
                      ),
                  ],
                ),
                const SizedBox(height: _kCardBottom),
              ],
            )
          : const SizedBox.shrink(),
    );

    // One press for the whole card. The title and the conversations are
    // content on that surface; the disclosure and the overflow menu stay
    // their own controls.
    final card = CcTappable(
      onPressed: open,
      borderRadius: AppRadii.brSm,
      semanticLabel: label,
      statesController: _states,
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
          // The title's overflow trigger is the only reader, so a hover
          // change rebuilds that trigger and nothing else in the card.
          child: SpaceMenuReveal(revealed: menu, child: body),
        );
      },
    );
    // Always in the tree: wrapping only unselected rows would remount the
    // card on selection and lose its reveal.
    return SpaceHoverPrefetch(
      workspaceId: selected ? null : workspaceId,
      spaceId: space.id,
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: (_) => _releasePress(),
        onPointerCancel: (_) => _releasePress(),
        child: card,
      ),
    );
  }
}
