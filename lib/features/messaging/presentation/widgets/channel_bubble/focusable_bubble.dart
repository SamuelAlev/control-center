import 'dart:async';
import 'dart:math' as math;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/reaction_chips_row.dart';
import 'package:control_center/features/messaging/providers/channel_reactions_provider.dart';
import 'package:control_center/features/messaging/providers/conversation_checkpoint_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A bubble wrapper that shows a focus outline and a hover toolbar
/// (copy / permalink / revert / react / edit / delete).
class FocusableBubble extends ConsumerStatefulWidget {
  /// Creates a [FocusableBubble].
  const FocusableBubble({
    required this.child,
    super.key,
    this.messageId,
    this.channelId,
    this.alignRight = false,
    this.copyText,
    this.canRevert = false,
    this.onEdit,
    this.onDelete,
  });

  /// The wrapped child widget.
  final Widget child;

  /// Message ID for the permalink / revert / reaction actions.
  final String? messageId;

  /// Owning channel id — required for the "revert to here" action.
  final String? channelId;

  /// Whether this is a right-aligned (user) bubble.
  final bool alignRight;

  /// When non-empty, a copy-to-clipboard action is shown in the hover toolbar.
  final String? copyText;

  /// When true (and a [messageId] + [channelId] are present), a "revert to
  /// here" action is shown — reverting hides every message after this point and
  /// rolls the agent's worktree back to this turn.
  final bool canRevert;

  /// When non-null, an "edit" action is shown in the hover toolbar (user
  /// messages only).
  final VoidCallback? onEdit;

  /// When non-null, a "delete" action is shown in the hover toolbar (user
  /// messages only).
  final VoidCallback? onDelete;

  @override
  ConsumerState<FocusableBubble> createState() => _FocusableBubbleState();
}

/// Height of one rail entry: a 14px glyph in 4px padding. Fixed, so the rail's
/// total height is known without measuring it.
const double _railItemExtent = 22;

/// Horizontal gap between the message's edge and the icons. It is rendered as
/// padding INSIDE the rail's own hit region, not as empty space beside it, so
/// the cursor never crosses a dead zone on its way over.
const double _railGap = 6;

/// Gap kept between the pinned rail and the viewport's edges.
const double _railViewportInset = 8;

/// How long the rail outlives the pointer leaving the message.
///
/// The rail is a narrow strip BESIDE the message, so hiding it the instant the
/// message loses hover makes it unreachable: the cursor crosses pixels that
/// belong to neither on its way over and the icons vanish from under it. This
/// grace keeps them alive for that trip; entering the rail — or coming back onto
/// the message — cancels it and hovering a different message drops it at once
/// (see [_openRail]) so no stale rail is left hanging.
const Duration _railGrace = Duration(milliseconds: 180);

/// The one bubble currently showing its rail. Exactly one rail is visible at a
/// time: hovering another message hides this one immediately instead of letting
/// its [_railGrace] run out, which is what stopped a rail from lingering over
/// the message the reader had already moved past.
_FocusableBubbleState? _openRail;

class _FocusableBubbleState extends ConsumerState<FocusableBubble> {
  final FocusNode _focusNode = FocusNode();

  /// Links the overlay-hosted rail to this bubble's box.
  final LayerLink _link = LayerLink();

  /// Identifies the bubble's render box so the rail can measure it for pinning.
  final GlobalKey _targetKey = GlobalKey();

  final OverlayPortalController _portal = OverlayPortalController();

  bool _hoverBubble = false;

  /// Whether the pointer is on the rail itself. The rail lives in the app
  /// Overlay, a separate subtree, so leaving the bubble does not imply leaving
  /// the rail — this is what lets the cursor travel onto it.
  bool _hoverRail = false;

  /// Whether the reaction palette is open. Opening it moves the pointer into a
  /// further overlay, so hover alone would hide the very rail it is anchored to.
  bool _popoverOpen = false;

  /// Vertical offset of the rail from the bubble's top edge, so it stays inside
  /// the visible slice of a message taller than the viewport.
  ///
  /// A notifier, not a field behind `setState`: the pin is recomputed on every
  /// scroll tick and rebuilding this widget for it re-ran the whole message
  /// body (markdown, highlighted code, tool rows) per frame — the feed's scroll
  /// jank. Only the follower inside the overlay listens.
  final ValueNotifier<double> _railDy = ValueNotifier<double>(0);

  /// Number of actions currently in the rail, for the pinning clamp.
  int _railItems = 0;

  ScrollableState? _scrollable;
  bool _pinScheduled = false;

  /// Pending [_railGrace] hide, cancelled if the pointer lands on the rail.
  Timer? _hideTimer;

  bool get _showIcon => _hoverBubble || _hoverRail || _popoverOpen;

  /// Reveals or hides the overlay rail to match [_showIcon]. Never called from
  /// `build` — [OverlayPortalController] mutates the portal's element.
  ///
  /// Showing is immediate; hiding waits out [_railGrace] so the cursor can cross
  /// the gap between the message and the icons.
  void _syncPortal() {
    if (_showIcon) {
      _hideTimer?.cancel();
      _hideTimer = null;
      if (_portal.isShowing) {
        return;
      }
      final previous = _openRail;
      // A rail held open by its own reaction palette is not stale — the pointer
      // is inside that overlay on purpose. It closes itself when the palette does.
      if (previous != null && previous != this && !previous._popoverOpen) {
        previous._hideRail();
      }
      _openRail = this;
      _railDy.value = 0;
      _portal.show();
      _attachScroll();
      _schedulePin();
      return;
    }
    if (!_portal.isShowing || _hideTimer != null) {
      return;
    }
    _hideTimer = Timer(_railGrace, () {
      _hideTimer = null;
      if (!mounted || _showIcon) {
        return;
      }
      _hideRail();
    });
  }

  /// Drops the rail now, cancelling any pending grace.
  void _hideRail() {
    _hideTimer?.cancel();
    _hideTimer = null;
    if (_openRail == this) {
      _openRail = null;
    }
    if (!_portal.isShowing) {
      return;
    }
    _portal.hide();
    _detachScroll();
  }

  // Hover state deliberately does NOT go through `setState`: `build` reads none
  // of it (the rail is an overlay child driven by the portal controller, which
  // rebuilds only itself). Rebuilding the bubble on every hover enter/exit
  // re-ran the message body for each row the cursor passed over while scrolling.
  void _setHoverBubble(bool value) {
    if (_hoverBubble == value) {
      return;
    }
    _hoverBubble = value;
    _syncPortal();
  }

  void _setHoverRail(bool value) {
    if (_hoverRail == value) {
      return;
    }
    _hoverRail = value;
    _syncPortal();
  }

  void _attachScroll() {
    final next = Scrollable.maybeOf(context);
    if (next == _scrollable) {
      return;
    }
    _scrollable?.position.removeListener(_schedulePin);
    _scrollable = next;
    _scrollable?.position.addListener(_schedulePin);
  }

  void _detachScroll() {
    _scrollable?.position.removeListener(_schedulePin);
    _scrollable = null;
  }

  /// Recomputes the pinned offset after the current frame. Scroll listeners can
  /// fire mid-frame, where marking this subtree dirty would throw.
  void _schedulePin() {
    if (_pinScheduled || !mounted || !_portal.isShowing) {
      return;
    }
    _pinScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pinScheduled = false;
      _applyPin();
    });
  }

  /// Keeps the rail inside the visible slice of its own message while that
  /// message scrolls through the feed's viewport.
  ///
  /// An agent turn can be far taller than the viewport; a rail parked at the
  /// message's top edge would scroll out of reach exactly when the reader has
  /// scrolled down to the part they want to act on. It slides down to stay near
  /// the top of what is on screen and stops at the message's bottom so it never
  /// detaches from the message it belongs to.
  void _applyPin() {
    if (!mounted || !_portal.isShowing) {
      return;
    }
    final target = _targetKey.currentContext?.findRenderObject();
    final viewport = _scrollable?.context.findRenderObject();
    if (target is! RenderBox ||
        viewport is! RenderBox ||
        !target.hasSize ||
        !viewport.hasSize) {
      return;
    }
    final railHeight = _railItems * _railItemExtent;
    final slack = target.size.height - railHeight;
    if (slack <= 0) {
      _railDy.value = 0;
      return;
    }
    final targetTop = target.localToGlobal(Offset.zero).dy;
    final viewportTop = viewport.localToGlobal(Offset.zero).dy;
    final viewportBottom = viewportTop + viewport.size.height;
    // Never below the message's bottom and never past the viewport's own
    // bottom edge (which matters for the message the reader is scrolled into
    // from below).
    final maxDy = math.min(
      slack,
      viewportBottom - _railViewportInset - railHeight - targetTop,
    );
    final double wanted = (viewportTop + _railViewportInset - targetTop)
        .clamp(0.0, math.max(0.0, maxDy))
        .toDouble();
    // Sub-pixel churn would repaint every frame for no visible gain.
    if ((wanted - _railDy.value).abs() > 0.5) {
      _railDy.value = wanted;
    }
  }

  /// Builds a permalink to this message (`/workspaces/<ws>/channels/<c>?m=<id>`)
  /// and copies it to the clipboard, surfacing a confirmation toast.
  void _copyLink() {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null ||
        widget.channelId == null ||
        widget.messageId == null) {
      return;
    }
    final url = channelRoute(
      workspaceId,
      widget.channelId!,
      messageId: widget.messageId,
    );
    Clipboard.setData(ClipboardData(text: url));
    CcToastScope.maybeOf(context)?.show(
      AppLocalizations.of(context).linkCopied,
      variant: CcToastVariant.success,
    );
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    if (_openRail == this) {
      _openRail = null;
    }
    _detachScroll();
    _railDy.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Confirms, then reverts the conversation to just after this message: every
  /// later message is hidden (kept for an undo via the header's "undo revert"
  /// button) and the host rolls the agent's worktree back to this turn.
  Future<void> _confirmAndRevert() async {
    final l10n = AppLocalizations.of(context);
    final toast = CcToastScope.maybeOf(context);
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.revertToHere,
        content: Text(l10n.revertConfirmBody),
        actions: [
          CcButton(
            onPressed: () => Navigator.pop(ctx, false),
            variant: CcButtonVariant.secondary,
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.pop(ctx, true),
            variant: CcButtonVariant.destructive,
            child: Text(l10n.revert),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final count = await ref
        .read(conversationCheckpointControllerProvider)
        .revertTo(widget.channelId!, widget.messageId!);
    if (!mounted) {
      return;
    }
    toast?.show(
      count > 0 ? l10n.revertedToHere : l10n.nothingToRevert,
      variant: count > 0 ? CcToastVariant.success : CcToastVariant.neutral,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = resolveTokens(context);
    final showCopy =
        widget.copyText != null && widget.copyText!.trim().isNotEmpty;
    final showCopyLink = widget.messageId != null && widget.channelId != null;
    final showRevert =
        widget.canRevert &&
        widget.messageId != null &&
        widget.channelId != null;
    final showEdit = widget.onEdit != null;
    final showDelete = widget.onDelete != null;
    final showReactions = widget.messageId != null && widget.channelId != null;
    final showToolbar =
        showCopy ||
        showCopyLink ||
        showRevert ||
        showEdit ||
        showDelete ||
        showReactions;

    final actions = <Widget>[
      if (showCopy)
        _HoverIconButton(
          icon: AppIcons.copy,
          tokens: tokens,
          tooltip: AppLocalizations.of(context).copy,
          onTap: () => Clipboard.setData(ClipboardData(text: widget.copyText!)),
        ),
      if (showCopyLink)
        _HoverIconButton(
          icon: AppIcons.link,
          tokens: tokens,
          tooltip: AppLocalizations.of(context).copyLink,
          onTap: _copyLink,
        ),
      if (showReactions)
        _AddReactionButton(
          channelId: widget.channelId!,
          messageId: widget.messageId!,
          tokens: tokens,
          onOpenChanged: (open) {
            if (!mounted || _popoverOpen == open) {
              return;
            }
            _popoverOpen = open;
            _syncPortal();
          },
        ),
      if (showRevert)
        _HoverIconButton(
          icon: AppIcons.rotateCcw,
          tokens: tokens,
          tooltip: AppLocalizations.of(context).revertToHere,
          onTap: _confirmAndRevert,
        ),
      if (showEdit)
        _HoverIconButton(
          icon: AppIcons.pencil,
          tokens: tokens,
          tooltip: AppLocalizations.of(context).edit,
          onTap: widget.onEdit!,
        ),
      if (showDelete)
        _HoverIconButton(
          icon: AppIcons.trash2,
          tokens: tokens,
          tooltip: AppLocalizations.of(context).delete,
          onTap: widget.onDelete!,
        ),
    ];
    _railItems = actions.length;

    Widget bubble = FocusRing(
      focusNode: _focusNode,
      borderRadius: AppRadii.brMd,
      child: widget.child,
    );

    // The rail hangs in the pane's slack BESIDE the message — outside the
    // document column entirely — which is space no ancestor of this widget
    // owns. It therefore cannot be a `Positioned` at a negative offset: that
    // paints (with `Clip.none`) but is never hit-tested, because
    // `RenderBox.hitTest` rejects any position outside the box. That is exactly
    // why the icons used to vanish the instant the cursor reached for them.
    //
    // Hosting it in the app Overlay instead gives it a box of its own: it is
    // reachable, unclipped by the row, free to be taller than a short message,
    // and costs the message no width and no layout shift. A [LayerLink] keeps
    // it welded to the bubble's top-right corner as the feed scrolls.
    if (showToolbar) {
      bubble = CompositedTransformTarget(
        link: _link,
        child: KeyedSubtree(key: _targetKey, child: bubble),
      );
      bubble = OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (_) => _buildRail(tokens, actions),
        child: bubble,
      );
    }

    return MouseRegion(
      onEnter: (_) => _setHoverBubble(true),
      onExit: (_) => _setHoverBubble(false),
      child: Focus(
        focusNode: _focusNode,
        child: Column(
          crossAxisAlignment: widget.alignRight
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            bubble,
            if (showReactions)
              ReactionChipsRow(
                channelId: widget.channelId!,
                messageId: widget.messageId!,
                alignEnd: widget.alignRight,
              ),
          ],
        ),
      ),
    );
  }

  /// The overlay-hosted rail: a vertical strip of actions welded to the
  /// message's top-right corner, sitting in the slack beside the document
  /// column.
  ///
  /// It is anchored on the right for every message — agent turns and the
  /// reader's own right-aligned bubbles alike — so the actions are always in
  /// one predictable strip instead of switching sides with the speaker.
  Widget _buildRail(DesignSystemTokens tokens, List<Widget> actions) {
    // The `Align` is load-bearing, not cosmetic. An [OverlayPortal] lays its
    // overlay child out with the Overlay's own constraints — TIGHT, i.e. the
    // whole window — and [CompositedTransformFollower] is a proxy box that
    // passes them straight down. Unwrapped, this rail's `MouseRegion` measured
    // the full window anchored at the message's corner: opaque and on top of
    // everything, it swallowed hover and clicks for every message beside and
    // below its own (so a rail stayed lit while the reader scrolled past and
    // the rows underneath never lit up) and its `RepaintBoundary` became a
    // screen-sized layer. Aligning first hands the follower LOOSE constraints,
    // so the rail shrink-wraps to the icons it draws.
    return Align(
      alignment: Alignment.topLeft,
      child: ValueListenableBuilder<double>(
        valueListenable: _railDy,
        // The rail subtree is passed as `child` so re-pinning during a scroll
        // rebuilds the follower alone, never the icons (nor their hit regions).
        child: MouseRegion(
          onEnter: (_) => _setHoverRail(true),
          onExit: (_) => _setHoverRail(false),
          child: Padding(
            // The gap lives inside the hit region, so the last few pixels before
            // the icons already count as "on the rail".
            padding: const EdgeInsets.only(left: _railGap),
            child: RepaintBoundary(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: actions,
              ),
            ),
          ),
        ),
        builder: (context, dy, child) => CompositedTransformFollower(
          link: _link,
          targetAnchor: Alignment.topRight,
          followerAnchor: Alignment.topLeft,
          offset: Offset(0, dy),
          showWhenUnlinked: false,
          child: child,
        ),
      ),
    );
  }
}

class _HoverIconButton extends StatelessWidget {
  const _HoverIconButton({
    required this.icon,
    required this.onTap,
    required this.tokens,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final DesignSystemTokens tokens;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.brSm,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 14, color: tokens.fgTertiary),
        ),
      ),
    );
    final label = tooltip;
    if (label == null) {
      return button;
    }
    return CcTooltip(message: label, child: button);
  }
}

/// Hover-toolbar "add reaction" affordance: a small icon that opens a
/// [CcPopover] with the fixed emoji palette (PRD 16 §15). Tapping an emoji
/// toggles it via `reactions.toggle` and closes the popover.
class _AddReactionButton extends ConsumerStatefulWidget {
  const _AddReactionButton({
    required this.channelId,
    required this.messageId,
    required this.tokens,
    required this.onOpenChanged,
  });

  final String channelId;
  final String messageId;
  final DesignSystemTokens tokens;

  /// Reports the palette's open state so the hover rail can stay pinned while
  /// the pointer is inside the overlay (and therefore outside the rail).
  final ValueChanged<bool> onOpenChanged;

  @override
  ConsumerState<_AddReactionButton> createState() => _AddReactionButtonState();
}

class _AddReactionButtonState extends ConsumerState<_AddReactionButton> {
  final CcOverlayController _controller = CcOverlayController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onOverlayChanged);
  }

  void _onOverlayChanged() => widget.onOpenChanged(_controller.isOpen);

  @override
  void dispose() {
    _controller.removeListener(_onOverlayChanged);
    _controller.dispose();
    super.dispose();
  }

  void _pick(String emoji) {
    toggleChannelReaction(
      ref.read(rpcClientProvider),
      channelId: widget.channelId,
      messageId: widget.messageId,
      emoji: emoji,
    );
    _controller.hide();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcPopover(
      controller: _controller,
      semanticLabel: l10n.reactionAddTooltip,
      target: CcTooltip(
        message: l10n.reactionAddTooltip,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            AppIcons.smile,
            size: 14,
            color: widget.tokens.fgTertiary,
          ),
        ),
      ),
      overlayBuilder: (context, _) => Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final emoji in kReactionPalette)
              CcTappable(
                onPressed: () => _pick(emoji),
                semanticLabel: l10n.reactionToggleTooltip(emoji),
                builder: (context, states) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(emoji, style: const TextStyle(fontSize: 18)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
