import 'dart:convert';

import 'package:cc_domain/features/pr_review/domain/entities/pr_inline_thread.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_comment_field.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_inline_comments/suggestion_renderer.dart';
import 'package:control_center/features/pr_review/presentation/widgets/reaction_bar.dart';
import 'package:control_center/features/pr_review/providers/pr_inline_comments_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/pr_review/providers/reaction_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/relative_time.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Height of the one-line collapsed summary row, excluding the card's margin.
/// Exported so the diff can reserve a realistic gap before the block is first
/// measured (an over-estimate makes the code jump as it settles).
const double kCollapsedThreadHeight = 34;

/// Pr inline thread block.
class PrInlineThreadBlock extends ConsumerStatefulWidget {
  /// PrInlineThreadBlock({.
  const PrInlineThreadBlock({
    super.key,
    required this.thread,
    required this.controller,
    this.collapsed = false,
    this.focused = false,
    this.resolveBusy = false,
    this.canResolve = true,
    this.embedded = false,
    this.onToggleCollapsed,
    this.onSetResolved,
  });

  /// PrInlineThread.
  final PrInlineThread thread;

  /// In-memory controller for draft inline review threads.
  final PrInlineCommentsController controller;

  /// Whether to render the one-line summary instead of the full conversation.
  final bool collapsed;

  /// Whether this is the focused conversation (matches the active highlight).
  final bool focused;

  /// Whether a resolve write is in flight (the toggle shows a spinner).
  final bool resolveBusy;

  /// Whether resolving would actually change anything.
  ///
  /// False for a forge-owned conversation on a forge with no resolvable
  /// threads: the button would be a press that silently did nothing, which
  /// reads as "settled" to the one person who cannot see the pull request.
  /// Collapsing still works — that is local by definition.
  final bool canResolve;

  /// Whether a host already draws the frame around this thread.
  ///
  /// In the diff a thread floats over the code and needs its own card. In the
  /// conversation timeline it sits inside one that already carries the file
  /// header, and a second border inside the first just reads as noise.
  final bool embedded;

  /// Flips [collapsed]. Null falls back to the host's own default (no chevron).
  final VoidCallback? onToggleCollapsed;

  /// Marks the conversation resolved / reopened. Null falls back to the
  /// controller's local-only toggle.
  final ValueChanged<bool>? onSetResolved;

  @override
  ConsumerState<PrInlineThreadBlock> createState() =>
      _PrInlineThreadBlockState();
}

class _PrInlineThreadBlockState extends ConsumerState<PrInlineThreadBlock> {
  final _replyCtrl = TextEditingController();
  final _replyFocus = FocusNode();
  bool _replying = false;
  bool _sending = false;
  String? _editingEntryId;

  @override
  void dispose() {
    _replyCtrl.dispose();
    _replyFocus.dispose();
    super.dispose();
  }

  /// Posts the reply, then clears the box.
  ///
  /// Goes through [PrInlineCommentsController.replyTo] rather than `reply`:
  /// `reply` looks the thread up in the controller's own state, so replying to
  /// a forge-side conversation — every comment the diff shows from GitHub —
  /// found nothing and returned, silently. And the text is held until the post
  /// lands: clearing optimistically and then failing destroys something a
  /// person wrote with nothing left to retry from.
  Future<void> _sendReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.controller.replyTo(widget.thread, text);
      if (!mounted) {
        return;
      }
      _replyCtrl.clear();
      setState(() {
        _replying = false;
        _sending = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _sending = false);
      CcToastScope.of(context).show(
        AppLocalizations.of(context).failedToPostReply('$e'),
        variant: CcToastVariant.danger,
      );
    }
  }

  void _setResolved(bool value) {
    final handler = widget.onSetResolved;
    if (handler != null) {
      handler(value);
      return;
    }
    widget.controller.toggleResolved(widget.thread.id);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final thread = widget.thread;
    final prRepo = ref.watch(prRepoRowProvider(widget.controller.pr));
    if (widget.collapsed) {
      return _CollapsedThreadRow(
        thread: thread,
        focused: widget.focused,
        embedded: widget.embedded,
        onExpand: widget.onToggleCollapsed,
      );
    }
    final borderColor = widget.focused ? tokens.accent : tokens.borderSecondary;
    return Container(
      margin: widget.embedded
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: widget.embedded
          ? BoxDecoration(color: tokens.bgPrimary)
          : BoxDecoration(
              color: tokens.bgPrimary,
              borderRadius: AppRadii.brMd,
              border: Border.all(color: borderColor),
              boxShadow: AppShadows.soft,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 0),
            child: Row(
              children: [
                if (widget.onToggleCollapsed != null) ...[
                  CcIconButton(
                    onPressed: widget.onToggleCollapsed,
                    icon: AppIcons.chevronDown,
                    tooltip: AppLocalizations.of(context).collapseComment,
                  ),
                  const SizedBox(width: 2),
                ],
                Text(
                  thread.entries.length == 1
                      ? '1 comment'
                      : '${thread.entries.length} comments',
                  style: CcTypography.caption.copyWith(
                    color: tokens.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // A multi-line comment names its range, the way the forge
                // does. The highlight already covers those rows; saying which
                // ones removes any doubt about what the card is attached to.
                if (thread.isMultiLine) ...[
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(
                      context,
                    ).commentOnLinesRange(thread.line, thread.lineEnd),
                    style: CcTypography.caption.copyWith(
                      color: tokens.textTertiary,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                if (thread.resolved) ...[
                  CcBadge(
                    label: AppLocalizations.of(context).resolved,
                    variant: CcBadgeVariant.success,
                    icon: AppIcons.checkCircle2,
                  ),
                  const SizedBox(width: 8),
                ],
                _SyncBadge(
                  state: thread.syncState,
                  error: thread.syncError,
                  onRetry: thread.syncState == PrInlineSyncState.error
                      ? () => widget.controller.retryPost(thread.id)
                      : null,
                ),
                const Spacer(),
                if (widget.resolveBusy)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CcSpinner(size: 14),
                    ),
                  )
                else if (widget.canResolve)
                  CcIconButton(
                    onPressed: () => _setResolved(!thread.resolved),
                    icon: thread.resolved
                        ? AppIcons.rotateCcw
                        : AppIcons.checkCircle2,
                    tooltip: thread.resolved
                        ? AppLocalizations.of(context).reopen
                        : AppLocalizations.of(context).resolve,
                  ),
              ],
            ),
          ),
          for (var i = 0; i < thread.entries.length; i++) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: _InlineEntryTile(
                entry: thread.entries[i],
                prRef: widget.controller.pr,
                originalCode: thread.originalCode,
                filePath: thread.filePath,
                originalStartLine: thread.line,
                isEditing: _editingEntryId == thread.entries[i].id,
                onToggleReaction: thread.entries[i].serverCommentId == null
                    ? null
                    : (content, {required add}) => toggleReaction(
                        ref,
                        ReactionTarget.reviewComment,
                        commentId: thread.entries[i].serverCommentId!,
                        pr: widget.controller.pr,
                        content: content,
                        add: add,
                      ),
                onEditStart: thread.isSuggestion && i == 0
                    ? () =>
                          setState(() => _editingEntryId = thread.entries[i].id)
                    : null,
                onEditSubmit: thread.isSuggestion && i == 0
                    ? (newBody) {
                        widget.controller.updateEntry(
                          threadId: thread.id,
                          entryId: thread.entries[i].id,
                          newBody: newBody,
                        );
                        setState(() => _editingEntryId = null);
                      }
                    : null,
                onEditCancel: thread.isSuggestion && i == 0
                    ? () => setState(() => _editingEntryId = null)
                    : null,
              ),
            ),
            if (i != thread.entries.length - 1) const CcDivider(),
          ],
          if (thread.isSuggestion && !thread.resolved) ...[
            const CcDivider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Row(
                children: [
                  CcButton(
                    onPressed: () =>
                        widget.controller.acceptSuggestion(thread.id),
                    icon: AppIcons.checkCheck,
                    child: Text(AppLocalizations.of(context).acceptAndResolve),
                  ),
                  const SizedBox(width: 8),
                  CcButton(
                    onPressed: () => widget.controller.dismissThread(thread.id),
                    variant: CcButtonVariant.secondary,
                    icon: AppIcons.archive,
                    child: Text(AppLocalizations.of(context).dismiss),
                  ),
                ],
              ),
            ),
          ],
          // A queued comment is not a thread yet — it becomes one when the
          // review is submitted. Offering a reply here would write text the
          // batch submit has nowhere to put, so it waits.
          if (thread.isPendingReview) ...[
            const CcDivider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Text(
                AppLocalizations.of(context).queuedCommentHint,
                style: CcTypography.caption.copyWith(
                  color: tokens.textTertiary,
                ),
              ),
            ),
          ] else ...[
            const CcDivider(),
            if (_replying)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                // The same rich field the diff composer and the review body
                // use — a reply is a comment, so it gets emoji, GIFs,
                // formatting and a preview rather than a bare line of text.
                child: SelectionContainer.disabled(
                  child: PrCommentField(
                    controller: _replyCtrl,
                    focusNode: _replyFocus,
                    hintText: AppLocalizations.of(context).replyEllipsis,
                    owner: prRepo?.remoteOwner ?? '',
                    repo: prRepo?.remoteName ?? '',
                    autofocus: true,
                    minLines: 2,
                    maxLines: 8,
                    onSubmitted: (_) => _sendReply(),
                    footer: (context) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _sending
                            ? const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 9),
                                child: SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CcSpinner(size: 14),
                                ),
                              )
                            : _SendButton(onPressed: _sendReply),
                      ),
                    ),
                  ),
                ),
              )
            else
              InkWell(
                onTap: () {
                  setState(() => _replying = true);
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _replyFocus.requestFocus(),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Row(
                    children: [
                      Icon(
                        AppIcons.messageSquare,
                        size: 14,
                        color: tokens.textTertiary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context).replyEllipsis,
                        style: CcTypography.caption.copyWith(
                          color: tokens.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// The one-line stand-in for a collapsed conversation.
///
/// A collapsed thread must stay VISIBLE — the whole point of collapsing is to
/// read the code with the discussion still marked, and a resolved conversation
/// that disappears entirely is one nobody finds again. So it keeps the author,
/// a one-line preview, the reply count and its state, in a row the height of a
/// couple of code lines, and the whole row expands it.
class _CollapsedThreadRow extends StatefulWidget {
  const _CollapsedThreadRow({
    required this.thread,
    required this.focused,
    required this.embedded,
    required this.onExpand,
  });

  final PrInlineThread thread;
  final bool focused;
  final bool embedded;
  final VoidCallback? onExpand;

  @override
  State<_CollapsedThreadRow> createState() => _CollapsedThreadRowState();
}

class _CollapsedThreadRowState extends State<_CollapsedThreadRow> {
  bool _hovered = false;

  /// The comment's first meaningful line, with markdown noise and a
  /// ```suggestion fence flattened to a label — a preview that is three
  /// backticks tells the reader nothing.
  String _preview(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final body = widget.thread.entries.isEmpty
        ? ''
        : widget.thread.entries.first.body;
    for (final raw in const LineSplitter().convert(body)) {
      final line = raw.trim();
      if (line.isEmpty) {
        continue;
      }
      if (line.startsWith('```suggestion')) {
        return l10n.suggestedChange;
      }
      if (line.startsWith('```')) {
        continue;
      }
      return line;
    }
    return l10n.emptyComment;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final thread = widget.thread;
    final author = thread.entries.isEmpty ? null : thread.entries.first;
    final replies = thread.entries.length - 1;
    final preview = _preview(context);
    return Semantics(
      button: true,
      label: l10n.expandComment,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onExpand,
          child: Container(
            height: kCollapsedThreadHeight,
            margin: widget.embedded
                ? EdgeInsets.zero
                : const EdgeInsets.fromLTRB(12, 6, 12, 8),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: _hovered ? tokens.bgPrimaryHover : tokens.bgPrimary,
              borderRadius: AppRadii.brMd,
              border: widget.embedded
                  ? null
                  : Border.all(
                      color: widget.focused
                          ? tokens.accent
                          : tokens.borderSecondary,
                    ),
            ),
            child: Row(
              children: [
                Icon(
                  AppIcons.chevronRight,
                  size: 14,
                  color: tokens.textTertiary,
                ),
                const SizedBox(width: 6),
                GitHubUserAvatar(
                  login: author?.author ?? '?',
                  avatarUrl: author?.authorAvatarUrl,
                  size: 18,
                  showHoverCard: false,
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    author?.author ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: tokens.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.caption.copyWith(
                      color: tokens.textTertiary,
                    ),
                  ),
                ),
                if (replies > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    l10n.repliesCountLabel(replies),
                    style: CcTypography.caption.copyWith(
                      color: tokens.textTertiary,
                    ),
                  ),
                ],
                if (thread.resolved) ...[
                  const SizedBox(width: 8),
                  CcBadge(
                    label: l10n.resolved,
                    variant: CcBadgeVariant.success,
                    icon: AppIcons.checkCircle2,
                  ),
                ],
                if (thread.isPendingReview) ...[
                  const SizedBox(width: 8),
                  CcBadge(
                    label: l10n.pendingReview,
                    variant: CcBadgeVariant.warning,
                    icon: AppIcons.cloudOff,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineEntryTile extends StatelessWidget {
  const _InlineEntryTile({
    required this.entry,
    required this.prRef,
    required this.originalCode,
    this.filePath,
    this.originalStartLine,
    this.isEditing = false,
    this.onToggleReaction,
    this.onEditStart,
    this.onEditSubmit,
    this.onEditCancel,
  });

  final PrInlineEntry entry;

  /// The PR's identity key — its repo resolves markdown `#N` references.
  final PrRef prRef;
  final String originalCode;
  final String? filePath;
  final int? originalStartLine;
  final bool isEditing;

  /// Reaction toggle for a synced review comment; null while the entry is a
  /// local draft (GitHub reactions only attach to posted comments).
  final Future<void> Function(String content, {required bool add})?
  onToggleReaction;
  final VoidCallback? onEditStart;
  final void Function(String newBody)? onEditSubmit;
  final VoidCallback? onEditCancel;

  static final RegExp _suggestionFence = RegExp(
    r'```suggestion\s*\n([\s\S]*?)\n?```',
    multiLine: true,
  );
  bool get _isSuggestionEntry => _suggestionFence.hasMatch(entry.body);

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GitHubUserAvatar(
          login: entry.author,
          avatarUrl: entry.authorAvatarUrl,
          size: 24,
          showHoverCard: false,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    entry.author,
                    style: CcTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AppTimestamp(
                    dateTime: entry.createdAt,
                    child: Text(
                      formatRelativeTime(context, entry.createdAt),
                      style: CcTypography.caption.copyWith(
                        color: tokens.textTertiary,
                      ),
                    ),
                  ),
                  if (_isSuggestionEntry && onEditStart != null) ...[
                    const SizedBox(width: 4),
                    CcIconButton(
                      onPressed: () {
                        if (isEditing) {
                          onEditCancel?.call();
                        } else {
                          onEditStart?.call();
                        }
                      },
                      icon: isEditing ? AppIcons.x : AppIcons.pencil,
                      tooltip: isEditing
                          ? AppLocalizations.of(context).cancelEdit
                          : AppLocalizations.of(context).editSuggestion,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              if (isEditing && onEditSubmit != null)
                _SuggestionEditor(
                  initialCode: _extractSuggestedCode(),
                  onSubmit: onEditSubmit!,
                  onCancel: onEditCancel ?? () {},
                )
              else
                SuggestionAwareMarkdown(
                  prRef: prRef,
                  body: entry.body,
                  originalCode: originalCode,
                  filePath: filePath,
                  originalStartLine: originalStartLine,
                ),
              if (onToggleReaction != null) ...[
                const SizedBox(height: 6),
                ReactionBar(
                  reactions: entry.reactions,
                  onToggle: onToggleReaction!,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _extractSuggestedCode() {
    final match = _suggestionFence.firstMatch(entry.body);
    return match?.group(1)?.trim() ?? '';
  }
}

class _SuggestionEditor extends ConsumerStatefulWidget {
  const _SuggestionEditor({
    required this.initialCode,
    required this.onSubmit,
    required this.onCancel,
  });
  final String initialCode;
  final ValueChanged<String> onSubmit;
  final VoidCallback onCancel;
  @override
  ConsumerState<_SuggestionEditor> createState() => _SuggestionEditorState();
}

class _SuggestionEditorState extends ConsumerState<_SuggestionEditor> {
  late final _ctrl = TextEditingController(text: widget.initialCode);
  final _focus = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final replacement = _ctrl.text;
    if (replacement.trim().isEmpty) {
      widget.onCancel();
      return;
    }
    widget.onSubmit('```suggestion\n$replacement\n```');
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      decoration: BoxDecoration(
        color: tokens.bgPrimary,
        borderRadius: AppRadii.brMd,
        border: Border.all(color: tokens.borderSecondary),
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelectionContainer.disabled(
            child: CcTextField(
              controller: _ctrl,
              focusNode: _focus,
              autofocus: true,
              maxLines: null,
              minLines: 2,
              textStyle: AppFonts.codeStyleDynamic(
                ref.watch(codeFontFamilyProvider),
                fontSize: 12,
                height: 1.55,
                color: tokens.textPrimary,
              ),
              onChanged: (_) => setState(() {}),
              hintText: AppLocalizations.of(context).editSuggestedCodeHint,
              chromeless: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CcButton(
                variant: CcButtonVariant.secondary,
                onPressed: widget.onCancel,
                child: Text(AppLocalizations.of(context).cancel),
              ),
              const SizedBox(width: 8),
              _SendButton(onPressed: _submit),
            ],
          ),
        ],
      ),
    );
  }
}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge({
    required this.state,
    required this.error,
    required this.onRetry,
  });
  final PrInlineSyncState state;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final (label, color, icon) = switch (state) {
      PrInlineSyncState.local => (
        AppLocalizations.of(context).draftLabel,
        tokens.textTertiary,
        AppIcons.cloudOff,
      ),
      PrInlineSyncState.pendingReview => (
        AppLocalizations.of(context).pendingReview,
        const Color(0xFFBF8700),
        AppIcons.cloudOff,
      ),
      PrInlineSyncState.pending => (
        AppLocalizations.of(context).postingEllipsis,
        tokens.textTertiary,
        AppIcons.loader,
      ),
      PrInlineSyncState.synced => (
        AppLocalizations.of(context).synced,
        const Color(0xFF2DA44E),
        AppIcons.cloud,
      ),
      PrInlineSyncState.error => (
        AppLocalizations.of(context).failed,
        const Color(0xFFCF222E),
        AppIcons.alertCircle,
      ),
    };
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: CcTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
    if (onRetry == null) {
      return CcTooltip(message: error ?? label, child: pill);
    }

    return CcTooltip(
      message: error ?? AppLocalizations.of(context).clickToRetry,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: onRetry, child: pill),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return CcIconButton(
      icon: AppIcons.arrowUp,
      variant: CcButtonVariant.accent,
      size: CcButtonSize.sm,
      tooltip: AppLocalizations.of(context).send,
      onPressed: onPressed,
    );
  }
}
