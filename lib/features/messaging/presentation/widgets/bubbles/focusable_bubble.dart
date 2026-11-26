import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/bubble_icon_button.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/bubble_shared.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/reaction_chips_row.dart';
import 'package:control_center/features/messaging/providers/conversation_checkpoint_providers.dart';
import 'package:control_center/features/messaging/providers/space_reactions_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'focusable_bubble_rail.dart';
part 'focusable_bubble_reaction.dart';

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
    this.groupHover,
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

  /// Hover over the rest of the message, when the message is laid out as
  /// several feed rows (a long agent turn) and this bubble wraps only its last
  /// one: the rail reveals while any of those rows is hovered.
  final ValueListenable<bool>? groupHover;

  @override
  ConsumerState<FocusableBubble> createState() => _FocusableBubbleState();
}

/// Height of one rail entry: a 14px glyph in 4px padding. The rail is a single
/// row, so this is the strip's height — reserved whether or not it is showing.
const double _railItemExtent = 22;

/// Gap between the message and the rail beneath it.
const double _railTopGap = AppSpacing.xs;

class _FocusableBubbleState extends ConsumerState<FocusableBubble>
    with _RailReveal {
  final FocusNode _focusNode = FocusNode();

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

  @override
  void _sync() => _revealed.value =
      _hoverBubble ||
      _focusWithin ||
      _popoverOpen ||
      (widget.groupHover?.value ?? false);

  @override
  void initState() {
    super.initState();
    widget.groupHover?.addListener(_sync);
  }

  @override
  void didUpdateWidget(covariant FocusableBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupHover != widget.groupHover) {
      oldWidget.groupHover?.removeListener(_sync);
      widget.groupHover?.addListener(_sync);
      _sync();
    }
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
    widget.groupHover?.removeListener(_sync);
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
        BubbleIconButton(
          icon: AppIcons.copy,
          tokens: tokens,
          tooltip: AppLocalizations.of(context).copy,
          onTap: () => Clipboard.setData(ClipboardData(text: widget.copyText!)),
        ),
      if (showCopyLink)
        BubbleIconButton(
          icon: AppIcons.link,
          tokens: tokens,
          tooltip: AppLocalizations.of(context).copyLink,
          onTap: _copyLink,
        ),
      if (showThread)
        BubbleIconButton(
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
        BubbleIconButton(
          icon: AppIcons.rotateCcw,
          tokens: tokens,
          tooltip: AppLocalizations.of(context).revertToHere,
          onTap: _confirmAndRevert,
        ),
      if (showEdit)
        BubbleIconButton(
          icon: AppIcons.pencil,
          tokens: tokens,
          tooltip: AppLocalizations.of(context).edit,
          onTap: widget.onEdit!,
        ),
      if (showDelete)
        BubbleIconButton(
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
        onFocusChange: _onFocusChange,
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
