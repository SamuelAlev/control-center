import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/bubble_shared.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/reaction_chips_row.dart';
import 'package:control_center/features/messaging/providers/conversation_checkpoint_providers.dart';
import 'package:control_center/features/messaging/providers/space_reactions_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/foundation.dart';
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
    this.spaceId,
    this.alignRight = false,
    this.copyText,
    this.canRevert = false,
    this.onEdit,
    this.onDelete,
    this.onStartThread,
  });

  /// The wrapped child widget.
  final Widget child;

  /// Message ID for the permalink / revert / reaction actions.
  final String? messageId;

  /// Owning space id — required for the "revert to here" action.
  final String? spaceId;

  /// Whether this is a right-aligned (user) bubble.
  final bool alignRight;

  /// When non-empty, a copy-to-clipboard action is shown in the hover toolbar.
  final String? copyText;

  /// When true (and a [messageId] + [spaceId] are present), a "revert to
  /// here" action is shown — reverting hides every message after this point and
  /// rolls the agent's worktree back to this turn.
  final bool canRevert;

  /// When non-null, an "edit" action is shown in the hover toolbar (user
  /// messages only).
  final VoidCallback? onEdit;

  /// When non-null, a "delete" action is shown in the hover toolbar (user
  /// messages only).
  final VoidCallback? onDelete;

  /// When non-null, a "start thread" action is shown in the hover toolbar
  /// (text messages only): opens a conversation anchored to this message.
  final VoidCallback? onStartThread;

  @override
  ConsumerState<FocusableBubble> createState() => _FocusableBubbleState();
}

/// Height of one rail entry: a 14px glyph in 4px padding. The rail is a single
/// row, so this is the strip's height — reserved whether or not it is showing.
const double _railItemExtent = 22;

/// Gap between the message and the rail beneath it.
const double _railTopGap = AppSpacing.xs;

class _FocusableBubbleState extends ConsumerState<FocusableBubble> {
  final FocusNode _focusNode = FocusNode();

  bool _hoverBubble = false;

  /// Whether the reaction palette is open. Opening it moves the pointer into an
  /// overlay — outside this widget's [MouseRegion] — so hover alone would hide
  /// the very rail the palette is anchored to.
  bool _popoverOpen = false;

  /// Whether the rail is currently revealed.
  ///
  /// A notifier, not a field behind `setState`: only the rail's opacity depends
  /// on it, and rebuilding this widget on every hover enter/exit re-ran the
  /// whole message body (markdown, highlighted code, tool rows) for each row the
  /// cursor passed over while scrolling — the feed's scroll jank.
  final ValueNotifier<bool> _revealed = ValueNotifier<bool>(false);

  void _sync() => _revealed.value = _hoverBubble || _popoverOpen;

  void _setHoverBubble(bool value) {
    if (_hoverBubble == value) {
      return;
    }
    _hoverBubble = value;
    _sync();
  }

  /// Builds a permalink to this message (`/workspaces/<ws>/spaces/<c>?m=<id>`)
  /// and copies it to the clipboard, surfacing a confirmation toast.
  void _copyLink() {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null ||
        widget.spaceId == null ||
        widget.messageId == null) {
      return;
    }
    final url = spaceRoute(
      workspaceId,
      widget.spaceId!,
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
    _revealed.dispose();
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
        .revertTo(widget.spaceId!, widget.messageId!);
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
    final showCopyLink = widget.messageId != null && widget.spaceId != null;
    final showRevert =
        widget.canRevert && widget.messageId != null && widget.spaceId != null;
    final showEdit = widget.onEdit != null;
    final showDelete = widget.onDelete != null;
    final showThread = widget.onStartThread != null;
    final showReactions = widget.messageId != null && widget.spaceId != null;

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
      if (showThread)
        _HoverIconButton(
          icon: AppIcons.gitBranch,
          tokens: tokens,
          tooltip: AppLocalizations.of(context).startThread,
          onTap: widget.onStartThread!,
        ),
      if (showReactions)
        _AddReactionButton(
          spaceId: widget.spaceId!,
          messageId: widget.messageId!,
          tokens: tokens,
          onOpenChanged: (open) {
            if (!mounted || _popoverOpen == open) {
              return;
            }
            _popoverOpen = open;
            _sync();
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
            FocusRing(
              focusNode: _focusNode,
              borderRadius: AppRadii.brMd,
              child: widget.child,
            ),
            if (showReactions)
              ReactionChipsRow(
                spaceId: widget.spaceId!,
                messageId: widget.messageId!,
                alignEnd: widget.alignRight,
              ),
            if (actions.isNotEmpty)
              _Rail(revealed: _revealed, actions: actions),
          ],
        ),
      ),
    );
  }
}

/// The action rail: one row of icons directly under the message.
///
/// Its height is reserved unconditionally — the strip occupies the same
/// [_railItemExtent] whether or not the pointer is on the message, so revealing
/// it moves nothing in the feed. That is the whole reason it is laid out here
/// rather than floated beside the message in the app Overlay, which is what it
/// used to be: an overlay costs no space, but it also has to be chased across
/// scroll ticks, kept alive while the cursor crosses the dead pixels between
/// the message and the icons, and de-duplicated against every other rail. In
/// flow, inside the message's own hover region, none of that exists.
class _Rail extends StatelessWidget {
  const _Rail({required this.revealed, required this.actions});

  /// Whether the icons are showing. Only this subtree listens, so a hover never
  /// rebuilds the message body.
  final ValueListenable<bool> revealed;

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: _railTopGap),
      child: SizedBox(
        height: _railItemExtent,
        child: ValueListenableBuilder<bool>(
          valueListenable: revealed,
          // Passed as `child` so a reveal rebuilds the opacity wrappers alone,
          // never the icons or their hit regions.
          child: RepaintBoundary(
            child: Row(mainAxisSize: MainAxisSize.min, children: actions),
          ),
          builder: (context, shown, child) => ExcludeSemantics(
            excluding: !shown,
            // A hidden rail must not be clickable and must not add a tab stop:
            // seven invisible buttons per message would otherwise put hundreds
            // of them between a keyboard user and the composer.
            child: ExcludeFocus(
              excluding: !shown,
              child: IgnorePointer(
                ignoring: !shown,
                child: AnimatedOpacity(
                  opacity: shown ? 1 : 0,
                  duration: CcMotion.resolve(context, CcMotion.fast),
                  curve: CcMotion.standard,
                  child: child,
                ),
              ),
            ),
          ),
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
    final button = CcTappable(
      onPressed: onTap,
      semanticLabel: tooltip,
      builder: (context, states) => Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 14,
          color:
              states.contains(WidgetState.hovered) ? tokens.fg : tokens.fgTertiary,
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
    required this.spaceId,
    required this.messageId,
    required this.tokens,
    required this.onOpenChanged,
  });

  final String spaceId;
  final String messageId;
  final DesignSystemTokens tokens;

  /// Reports the palette's open state so the rail stays revealed while the
  /// pointer is inside the overlay (and therefore off the message).
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
    toggleSpaceReaction(
      ref.read(rpcClientProvider),
      spaceId: widget.spaceId,
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
