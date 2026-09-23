import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/reaction_bar.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Hover toolbar for one comment: react, copy link when the comment has a
/// permalink, resolve when this is a thread, and the overflow menu. Null
/// callbacks are omitted, so a top-level comment does not grow a resolve
/// action and a comment you cannot delete does not offer it.
class CommentActionCluster extends StatefulWidget {
  /// Creates a [CommentActionCluster].
  const CommentActionCluster({
    super.key,
    this.onToggleReaction,
    this.onResolve,
    this.resolved = false,
    this.resolveBusy = false,
    this.onCopyLink,
    this.onCopyMarkdown,
    this.threadMenu = false,
    this.onCopyPrompt,
    this.onSendToAgent,
    this.sending = false,
    this.onEdit,
    this.onDelete,
    this.onPinnedChanged,
  });

  /// Toggles a GitHub reaction. Null hides React (a draft has nothing to
  /// react to on the forge yet).
  final Future<void> Function(String content, {required bool add})?
  onToggleReaction;

  /// Resolves or reopens the thread. Null when this comment is not in one,
  /// or the forge cannot resolve threads.
  final VoidCallback? onResolve;

  /// Whether the thread is currently resolved.
  final bool resolved;

  /// Whether a resolve write is in flight.
  final bool resolveBusy;

  /// Copies a permalink. Null when the comment has no forge url yet.
  final VoidCallback? onCopyLink;

  /// Copies the comment (or the whole thread) as Markdown.
  final VoidCallback? onCopyMarkdown;

  /// Whether the copy rows name the thread. A lone conversation comment
  /// copies itself; a diff thread copies the discussion.
  final bool threadMenu;

  /// Copies the prompt [onSendToAgent] would send.
  final VoidCallback? onCopyPrompt;

  /// Sends the comment to an agent. Null hides the row.
  final VoidCallback? onSendToAgent;

  /// Whether a send is in flight.
  final bool sending;

  /// Opens the editor. Null when the viewer cannot edit.
  final VoidCallback? onEdit;

  /// Deletes the comment. Null when the viewer cannot delete.
  final VoidCallback? onDelete;

  /// Fired when a popover or the menu is holding the toolbar open.
  final ValueChanged<bool>? onPinnedChanged;

  @override
  State<CommentActionCluster> createState() => _CommentActionClusterState();
}

class _CommentActionClusterState extends State<CommentActionCluster> {
  final CcOverlayController _reactions = CcOverlayController();
  bool _menuOpen = false;

  @override
  void initState() {
    super.initState();
    _reactions.addListener(_pin);
  }

  @override
  void dispose() {
    _reactions.removeListener(_pin);
    _reactions.dispose();
    super.dispose();
  }

  void _pin() {
    widget.onPinnedChanged?.call(_reactions.isOpen || _menuOpen);
  }

  void _openMenu() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }
    final origin = box.localToGlobal(Offset(0, box.size.height));
    setState(() => _menuOpen = true);
    _pin();
    final l10n = AppLocalizations.of(context);
    showCcMenuAt(
      context: context,
      position: origin,
      items: _menuItems(l10n),
      onDismissed: () {
        if (mounted) {
          setState(() => _menuOpen = false);
        }
        _pin();
      },
    );
  }

  List<CcMenuItem> _menuItems(AppLocalizations l10n) {
    final items = <CcMenuItem>[
      if (widget.onResolve != null)
        CcMenuItem(
          label: widget.resolved
              ? l10n.commentReopenThread
              : l10n.commentResolveThread,
          icon: widget.resolved ? AppIcons.rotateCcw : AppIcons.check,
          enabled: !widget.resolveBusy,
          onSelected: widget.onResolve!,
        ),
      if (widget.onCopyMarkdown != null)
        CcMenuItem(
          label: widget.threadMenu
              ? l10n.commentCopyThreadMarkdown
              : l10n.commentCopyMarkdown,
          icon: AppIcons.copy,
          onSelected: widget.onCopyMarkdown!,
        ),
      if (widget.onCopyPrompt != null)
        CcMenuItem(
          label: widget.threadMenu
              ? l10n.commentCopyThreadPrompt
              : l10n.commentCopyPrompt,
          icon: AppIcons.copy,
          onSelected: widget.onCopyPrompt!,
        ),
      if (widget.onSendToAgent != null)
        CcMenuItem(
          label: l10n.commentSendToAgent,
          icon: AppIcons.bot,
          enabled: !widget.sending,
          onSelected: widget.onSendToAgent!,
        ),
      if (widget.onEdit != null || widget.onDelete != null)
        const CcMenuItem.divider(),
      if (widget.onEdit != null)
        CcMenuItem(
          label: l10n.commentEdit,
          icon: AppIcons.pencil,
          onSelected: widget.onEdit!,
        ),
      if (widget.onDelete != null)
        CcMenuItem(
          label: l10n.commentDelete,
          icon: AppIcons.trash2,
          destructive: true,
          onSelected: widget.onDelete!,
        ),
    ];
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final hasReaction = widget.onToggleReaction != null;
    final hasLink = widget.onCopyLink != null;
    return Container(
      decoration: BoxDecoration(
        color: tokens.bgPrimary,
        border: Border.all(color: tokens.borderSecondary),
        borderRadius: AppRadii.brSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasReaction)
            CcPopover(
              controller: _reactions,
              toggleOnTargetTap: false,
              overlayBuilder: (context, _) => GitHubReactionPalette(
                onSelected: (content) {
                  _reactions.hide();
                  widget.onToggleReaction!(content, add: true);
                },
              ),
              target: CcIconButton(
                onPressed: _reactions.toggle,
                icon: AppIcons.smile,
                size: CcButtonSize.sm,
                tooltip: l10n.commentReact,
              ),
            ),
          if (hasLink) ...[
            if (hasReaction) _hairline(tokens),
            CcIconButton(
              onPressed: widget.onCopyLink,
              icon: AppIcons.link,
              size: CcButtonSize.sm,
              tooltip: l10n.commentCopyLink,
            ),
          ],
          if (widget.onResolve != null) ...[
            if (hasReaction || hasLink) _hairline(tokens),
            if (widget.resolveBusy)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CcSpinner(size: 14),
                ),
              )
            else
              CcIconButton(
                onPressed: widget.onResolve,
                icon: widget.resolved ? AppIcons.rotateCcw : AppIcons.check,
                size: CcButtonSize.sm,
                tooltip: widget.resolved
                    ? l10n.commentReopenThread
                    : l10n.commentResolveThread,
              ),
          ],
          _hairline(tokens),
          CcIconButton(
            onPressed: widget.sending ? null : _openMenu,
            icon: AppIcons.moreHorizontal,
            size: CcButtonSize.sm,
            tooltip: l10n.commentActions,
          ),
        ],
      ),
    );
  }

  Widget _hairline(DesignSystemTokens tokens) {
    return Container(width: 1, height: 16, color: tokens.borderSecondary);
  }
}

/// Reveals [actions] at the top end of [child] while the pointer is over the
/// comment, a toolbar popover is open, or keyboard focus is inside the toolbar.
///
/// Touch platforms keep the toolbar visible: there is no hover to discover it.
class CommentActionsHost extends StatefulWidget {
  /// Creates a [CommentActionsHost].
  const CommentActionsHost({
    super.key,
    required this.actions,
    required this.child,
    this.toolbarTop = 4,
  });

  /// The toolbar. The callback stays true while a menu or the reaction
  /// palette is open, so the toolbar does not vanish when the pointer leaves.
  final Widget Function(ValueChanged<bool> onPinnedChanged) actions;

  /// The comment body the toolbar floats over.
  final Widget child;

  /// Distance from the top of [child]. Review cards pass a larger value so
  /// the toolbar clears the verdict chip in the header.
  final double toolbarTop;

  @override
  State<CommentActionsHost> createState() => _CommentActionsHostState();
}

class _CommentActionsHostState extends State<CommentActionsHost> {
  final FocusScopeNode _scope = FocusScopeNode(debugLabel: 'comment-actions');
  final FocusNode _entry = FocusNode(debugLabel: 'comment-actions-entry');
  bool _hover = false;
  bool _keyboard = false;
  bool _pinned = false;

  @override
  void initState() {
    super.initState();
    _scope.addListener(_syncKeyboard);
    _entry.addListener(_syncKeyboard);
  }

  @override
  void dispose() {
    _scope.removeListener(_syncKeyboard);
    _entry.removeListener(_syncKeyboard);
    _scope.dispose();
    _entry.dispose();
    super.dispose();
  }

  void _syncKeyboard() {
    final inside = _scope.focusedChild != null || _entry.hasFocus;
    if (inside == _keyboard || !mounted) {
      if (!inside) {
        // Focus moved from the entry stub to a toolbar button a frame later.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          final still = _scope.focusedChild != null || _entry.hasFocus;
          if (still != _keyboard) {
            setState(() => _keyboard = still);
          }
        });
      }
      return;
    }
    setState(() => _keyboard = inside);
  }

  bool get _touch => switch (defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.android => true,
    _ => false,
  };

  @override
  Widget build(BuildContext context) {
    final show = _touch || _hover || _keyboard || _pinned;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          // One tab stop per comment. Focusing it reveals the toolbar; the
          // buttons themselves stay out of the tab order until then, so a
          // long timeline is not a run of invisible stops.
          PositionedDirectional(
            top: widget.toolbarTop,
            end: 4,
            child: Focus(
              focusNode: _entry,
              child: Semantics(
                button: true,
                label: AppLocalizations.of(context).commentActions,
                child: const SizedBox(width: 1, height: 1),
              ),
            ),
          ),
          PositionedDirectional(
            top: widget.toolbarTop,
            end: 4,
            child: IgnorePointer(
              ignoring: !show,
              child: AnimatedOpacity(
                opacity: show ? 1 : 0,
                duration: CcMotion.resolve(context, CcMotion.fast),
                curve: CcMotion.standard,
                child: Focus(
                  canRequestFocus: show,
                  skipTraversal: !show,
                  descendantsAreFocusable: show,
                  child: FocusScope(
                    node: _scope,
                    child: widget.actions((pinned) {
                      if (!mounted || pinned == _pinned) {
                        return;
                      }
                      setState(() => _pinned = pinned);
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
