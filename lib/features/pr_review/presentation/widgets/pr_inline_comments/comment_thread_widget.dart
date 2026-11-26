import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/features/pr_review/domain/entities/pr_inline_thread.dart';
import 'package:cc_syntax/syntax_languages.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/text_draft_provider.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_edit_notifier.dart';
import 'package:control_center/features/pr_review/presentation/utils/syntax_highlighter.dart';
import 'package:control_center/features/pr_review/presentation/widgets/comment_action_model.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_comment_actions.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_comment_field.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_inline_comments/suggestion_blocks.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_inline_comments/suggestion_renderer.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_sign_in_notice.dart';
import 'package:control_center/features/pr_review/presentation/widgets/reaction_bar.dart';
import 'package:control_center/features/pr_review/providers/pr_comment_draft_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_inline_comments_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/pr_review/providers/reaction_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/syntax/grammar_registry.dart';
import 'package:control_center/shared/utils/relative_time.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:control_center/shared/widgets/focus_on_mount.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter/widgets.dart';
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

class _PrInlineThreadBlockState extends ConsumerState<PrInlineThreadBlock>
    with SingleTickerProviderStateMixin {
  // Runs alongside the body's own height animation (same tokens, same
  // snapping rules) to move what the header and the card's edge show.
  late final AnimationController _open = AnimationController(
    vsync: this,
    value: widget.collapsed ? 0 : 1,
    duration: CcMotion.moderate,
    reverseDuration: CcMotion.moderateExit,
  );
  late final CurvedAnimation _openCurve = CurvedAnimation(
    parent: _open,
    curve: CcMotion.standard,
  );
  late final CurvedAnimation _bodyFade = CurvedAnimation(
    parent: _open,
    curve: const Interval(0.3, 1),
  );
  final _authorKey = GlobalKey();
  double _previewDx = 0;
  late TextEditingController _replyCtrl;
  final _replyFocus = FocusNode();
  bool _replying = false;
  bool _sending = false;
  String? _editingEntryId;

  TextDraftKey get _replyKey => (
    workspaceId: widget.controller.pr.workspaceId,
    surface: 'pr-thread-reply',
    destination: (
      widget.controller.pr.repoFullName,
      widget.controller.pr.number,
      widget.thread.id,
    ),
  );

  TextDraftKey _editKey(PrInlineEntry entry) => (
    workspaceId: widget.controller.pr.workspaceId,
    surface: 'pr-thread-edit',
    destination: (
      widget.controller.pr.repoFullName,
      widget.controller.pr.number,
      widget.thread.id,
      entry.id,
    ),
  );

  @override
  void initState() {
    super.initState();
    _replyCtrl = ref.read(prCommentDraftControllerProvider(_replyKey));
    _replying = _replyCtrl.text.isNotEmpty;
  }

  @override
  void didUpdateWidget(PrInlineThreadBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller.pr != widget.controller.pr ||
        oldWidget.thread.id != widget.thread.id) {
      _replyCtrl = ref.read(prCommentDraftControllerProvider(_replyKey));
      _replying = _replyCtrl.text.isNotEmpty;
      _sending = false;
    }
    if (oldWidget.collapsed != widget.collapsed) {
      _runToggle();
    }
  }

  void _runToggle() {
    final target = widget.collapsed ? 0.0 : 1.0;
    // A keyboard toggle snaps, and so does reduced motion: the body does the
    // same, and reports the change with its own short fade.
    if (FocusModality.instance.lastInputWasKeyboard ||
        CcMotion.reduced(context)) {
      _open.value = target;
      return;
    }
    // The comment's text starts at the card's left edge, back past the
    // name, the avatar and the caret; that is where the preview heads as it
    // leaves.
    final author = _authorKey.currentContext?.findRenderObject();
    if (author is RenderBox && author.hasSize) {
      final shift = author.size.width + 50;
      _previewDx = Directionality.of(context) == TextDirection.rtl
          ? shift
          : -shift;
    }
    if (widget.collapsed) {
      _open.reverse();
    } else {
      _open.forward();
    }
  }

  @override
  void dispose() {
    _bodyFade.dispose();
    _openCurve.dispose();
    _open.dispose();
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
    final draftCtrl = _replyCtrl;
    final originalText = draftCtrl.text;
    final text = originalText.trim();
    if (text.isEmpty || _sending) {
      return;
    }
    final controller = widget.controller;
    final thread = widget.thread;
    setState(() => _sending = true);
    try {
      await controller.replyTo(thread, text);
      if (draftCtrl.text == originalText) {
        draftCtrl.clear();
      }
      if (!mounted || !identical(_replyCtrl, draftCtrl)) {
        return;
      }
      setState(() {
        _replying = draftCtrl.text.isNotEmpty;
        _sending = false;
      });
    } catch (e) {
      if (!mounted || !identical(_replyCtrl, draftCtrl)) {
        return;
      }
      setState(() => _sending = false);
      showPrError(
        context,
        ref,
        e,
        (l) => l.failedToPostReply('$e'),
        prRef: widget.controller.pr,
      );
    }
  }

  /// Where an edit of [entry] is written. An unsent comment is rewritten
  /// here; a posted one on the forge. Null while a post is in flight: that
  /// request carries the old body, and the comment has no forge id yet.
  Future<String?> Function(String body)? _saveEntry(
    PrInlineThread thread,
    PrInlineEntry entry,
  ) {
    if (thread.isUnsent) {
      return (body) async {
        widget.controller.updateEntry(
          threadId: thread.id,
          entryId: entry.id,
          newBody: body.trim(),
        );
        return null;
      };
    }
    final commentId = entry.serverCommentId;
    if (commentId == null) {
      return null;
    }
    return (body) => ref
        .read(prEditProvider(widget.controller.pr).notifier)
        .saveReviewComment(commentId: commentId, body: body.trim());
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
    final hidden = ref.watch(
      prEditProvider(
        widget.controller.pr,
      ).select((s) => s.hiddenReviewCommentIds),
    );
    final edited = ref.watch(
      prEditProvider(
        widget.controller.pr,
      ).select((s) => s.optimisticReviewComments),
    );
    final visible = [
      for (final entry in thread.entries)
        if (entry.serverCommentId == null ||
            !hidden.contains(entry.serverCommentId))
          switch (edited[entry.serverCommentId]) {
            final body? => entry.copyWith(body: body),
            null => entry,
          },
    ];
    if (thread.entries.isNotEmpty && visible.isEmpty) {
      return const SizedBox.shrink();
    }
    final toggle = widget.onToggleCollapsed;
    final first = visible.isEmpty ? null : visible.first;
    final firstIsSuggestion =
        thread.isSuggestion &&
        first != null &&
        first.id == thread.entries.first.id;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          Padding(
            // Every comment's text starts on the card's own left edge, the
            // one the caret and the reply row sit on.
            padding: EdgeInsets.fromLTRB(14, i == 0 ? 8 : 10, 14, 12),
            child: _entryTile(
              thread,
              visible,
              i,
              suggestionEditable: firstIsSuggestion && i == 0,
            ),
          ),
          if (i != visible.length - 1) const CcDivider(),
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
              style: CcTypography.caption.copyWith(color: tokens.textTertiary),
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
                      alignment: AlignmentDirectional.centerEnd,
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
            // A real button: the reply stub was a bare gesture, so a
            // keyboard user had no way to start a reply.
            CcTappable(
              onPressed: () {
                setState(() => _replying = true);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _replying) {
                    _replyFocus.requestFocus();
                  }
                });
              },
              semanticLabel: AppLocalizations.of(context).replyEllipsis,
              builder: (context, states) => ExcludeSemantics(
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
            ),
        ],
      ],
    );
    final borderColor = widget.focused ? tokens.accent : tokens.borderSecondary;
    // One card for both states. The header row never changes shape: opening
    // only grows the card downward, so the caret, the avatar and the name
    // stay under the pointer that clicked them.
    return AnimatedBuilder(
      animation: _openCurve,
      child: CcCollapsible(expanded: !widget.collapsed, child: body),
      builder: (context, body) {
        final open = _openCurve.value;
        return Container(
          margin: widget.embedded
              ? EdgeInsets.zero
              : const EdgeInsets.fromLTRB(12, 6, 12, 8),
          decoration: widget.embedded
              ? BoxDecoration(color: tokens.bgPrimary)
              : BoxDecoration(
                  color: tokens.bgPrimary,
                  border: Border.all(color: borderColor),
                  boxShadow: BoxShadow.lerpList(null, AppShadows.soft, open),
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _ThreadHeader(
                thread: thread,
                first: first,
                replies: visible.length - 1,
                open: open,
                collapsed: widget.collapsed,
                onToggle: toggle,
                authorKey: _authorKey,
                previewDx: _previewDx,
                actions: [
                  if (!thread.isPendingReview)
                    _SyncBadge(
                      state: thread.syncState,
                      error: thread.syncError,
                      onRetry: thread.syncState == PrInlineSyncState.error
                          ? () => widget.controller.retryPost(thread.id)
                          : null,
                    ),
                  if (firstIsSuggestion &&
                      parseSuggestionBlocks(first.body).isNotEmpty)
                    _suggestionPencil(thread, first),
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
              ?body,
            ],
          ),
        );
      },
    );
  }

  /// The session-owned text of a whole-comment edit of [entry], or null when
  /// the comment cannot be edited (its post is still in flight).
  TextEditingController? _editDraft(
    PrInlineThread thread,
    PrInlineEntry entry,
  ) => thread.isUnsent || entry.serverCommentId != null
      ? ref.read(prCommentDraftControllerProvider(_editKey(entry)))
      : null;

  /// Opens the code-only editor of a suggestion. It lives in the header, next
  /// to the author it belongs to, and steps aside while the whole comment is
  /// being edited: one editor replaces the other.
  Widget _suggestionPencil(PrInlineThread thread, PrInlineEntry entry) {
    final editing = _editingEntryId == entry.id;
    final pencil = CcIconButton(
      onPressed: () =>
          setState(() => _editingEntryId = editing ? null : entry.id),
      icon: editing ? AppIcons.x : AppIcons.pencil,
      tooltip: editing
          ? AppLocalizations.of(context).cancelEdit
          : AppLocalizations.of(context).editSuggestion,
    );
    final draft = _editDraft(thread, entry);
    if (draft == null) {
      return pencil;
    }
    return ListenableBuilder(
      listenable: draft,
      builder: (context, _) =>
          draft.text.isEmpty ? pencil : const SizedBox.shrink(),
    );
  }

  Widget _entryTile(
    PrInlineThread thread,
    List<PrInlineEntry> visible,
    int i, {
    required bool suggestionEditable,
  }) {
    final entry = visible[i];
    final tile = _InlineEntryTile(
      entry: entry,
      prRef: widget.controller.pr,
      // The header row already names the first comment's author.
      showAuthor: i != 0,
      originalCode: thread.originalCode,
      filePath: thread.filePath,
      // A file-level thread has no lines; the actions name the file.
      originalStartLine: thread.isFileLevel ? null : thread.line,
      lineEnd: thread.isFileLevel ? null : thread.lineEnd,
      canResolve: widget.canResolve,
      resolved: thread.resolved,
      resolveBusy: widget.resolveBusy,
      onResolve: () => _setResolved(!thread.resolved),
      thread: [
        for (final entry in visible) (author: entry.author, body: entry.body),
      ],
      onDeleteLocal: entry.serverCommentId == null
          ? () => widget.controller.dismissThread(thread.id)
          : null,
      editDraft: _editDraft(thread, entry),
      onSaveDraft: _saveEntry(thread, entry),
      isEditing: _editingEntryId == entry.id,
      onToggleReaction: entry.serverCommentId == null
          ? null
          : (content, {required add}) => toggleReaction(
              ref,
              ReactionTarget.reviewComment,
              commentId: entry.serverCommentId!,
              pr: widget.controller.pr,
              content: content,
              add: add,
            ),
      onEditSubmit: suggestionEditable
          ? (newBody) {
              widget.controller.updateEntry(
                threadId: thread.id,
                entryId: entry.id,
                newBody: newBody,
              );
              setState(() => _editingEntryId = null);
            }
          : null,
      onEditCancel: suggestionEditable
          ? () => setState(() => _editingEntryId = null)
          : null,
    );
    // The first comment's text is what the collapsed preview becomes, so it
    // arrives as the preview leaves.
    return i == 0 ? FadeTransition(opacity: _bodyFade, child: tile) : tile;
  }
}

/// A collapsed conversation's one line: the comment's first meaningful line,
/// with a ```suggestion fence flattened to a label — a preview that is three
/// backticks tells the reader nothing. `more` says the comment goes on past
/// that line, so the row can mark that it is not the whole text.
({String text, bool more}) _threadPreview(AppLocalizations l10n, String body) {
  String? preview;
  for (final raw in const LineSplitter().convert(body)) {
    final line = raw.trim();
    if (line.isEmpty) {
      continue;
    }
    if (preview != null) {
      return (text: preview, more: true);
    }
    if (line.startsWith('```suggestion')) {
      return (text: l10n.suggestedChange, more: false);
    }
    if (line.startsWith('```')) {
      continue;
    }
    preview = line;
  }
  return (text: preview ?? l10n.emptyComment, more: false);
}

/// The row a conversation keeps in both states: caret, avatar, author, then
/// the reply count and its state at the far edge.
///
/// A collapsed thread must stay VISIBLE — the whole point of collapsing is to
/// read the code with the discussion still marked, and a resolved conversation
/// that disappears entirely is one nobody finds again. So the row is the same
/// one the open card starts with, and only the slot after the name changes:
/// collapsed it holds a one-line preview, open it holds the timestamp while
/// the preview travels down to where the full comment begins.
class _ThreadHeader extends StatelessWidget {
  const _ThreadHeader({
    required this.thread,
    required this.first,
    required this.replies,
    required this.open,
    required this.collapsed,
    required this.onToggle,
    required this.authorKey,
    required this.previewDx,
    required this.actions,
  });

  final PrInlineThread thread;

  /// The comment that opens the conversation; null for an empty thread.
  final PrInlineEntry? first;
  final int replies;

  /// 0 collapsed, 1 open, in between while the card animates.
  final double open;
  final bool collapsed;

  /// Null for a thread its host never collapses: no caret, nothing to press.
  final VoidCallback? onToggle;
  final GlobalKey authorKey;

  /// Horizontal distance from the preview to the start of the comment text.
  final double previewDx;

  /// Controls that only an open conversation offers.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final first = this.first;
    final preview = _threadPreview(l10n, first?.body ?? '');
    final meta = CcTypography.caption.copyWith(color: tokens.textTertiary);
    Widget row(Set<WidgetState> states) => Container(
      height: kCollapsedThreadHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      color: states.contains(WidgetState.hovered)
          ? tokens.bgPrimaryHover
          : null,
      child: Row(
        children: [
          if (onToggle != null) ...[
            Transform.rotate(
              angle: (rtl ? -1 : 1) * open * 1.5707963267948966,
              child: Icon(
                AppIcons.chevronRight,
                size: 14,
                color: tokens.textTertiary,
              ),
            ),
            const SizedBox(width: 6),
          ],
          // The author's name follows; skip the avatar's initial.
          ExcludeSemantics(
            child: GitHubUserAvatar(
              login: first?.author ?? '?',
              avatarUrl: first?.authorAvatarUrl,
              size: 18,
              showHoverCard: false,
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              first?.author ?? '',
              key: authorKey,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CcTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                if (open > 0 && first != null)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Opacity(
                      opacity: open,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppTimestamp(
                            dateTime: first.createdAt,
                            child: Text(
                              formatRelativeTime(context, first.createdAt),
                              style: meta,
                            ),
                          ),
                          // A multi-line comment names its range, the way
                          // the forge does. The highlight already covers
                          // those rows; saying which ones removes any doubt
                          // about what the card is attached to.
                          if (thread.isMultiLine) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                l10n.commentOnLinesRange(
                                  thread.line,
                                  thread.lineEnd,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: meta,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                // The preview leaves toward the line the full comment starts
                // on, fading out as that text fades in beneath the row.
                if (open < 1)
                  IgnorePointer(
                    child: Transform.translate(
                      offset: Offset(previewDx * open, 32 * open),
                      child: Opacity(
                        opacity: (1 - open / 0.6).clamp(0, 1),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            // The mark for "there is more below" is the one
                            // a clipped line already ends with.
                            preview.more ? '${preview.text} …' : preview.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: meta,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (open > 0)
            Opacity(
              opacity: open,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final action in actions) ...[
                    const SizedBox(width: 8),
                    action,
                  ],
                ],
              ),
            ),
          if (replies > 0) ...[
            const SizedBox(width: 8),
            Text(l10n.repliesCountLabel(replies), style: meta),
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
    );
    if (onToggle == null) {
      return row(const {});
    }
    // A focusable disclosure in both states. Collapsed it reads as one line:
    // "Expand comment, collapsed, alice, <preview>, 2 replies, Resolved".
    // Open, the row's own buttons stay separate stops.
    final tappable = Semantics(
      expanded: !collapsed,
      child: CcTappable(
        onPressed: onToggle,
        semanticLabel: collapsed ? l10n.expandComment : l10n.collapseComment,
        builder: (context, states) => row(states),
      ),
    );
    return collapsed ? MergeSemantics(child: tappable) : tappable;
  }
}

class _InlineEntryTile extends StatelessWidget {
  const _InlineEntryTile({
    required this.entry,
    required this.prRef,
    required this.originalCode,
    this.filePath,
    this.originalStartLine,
    this.lineEnd,
    this.canResolve = false,
    this.resolved = false,
    this.resolveBusy = false,
    this.onResolve,
    this.thread = const [],
    this.onDeleteLocal,
    this.editDraft,
    this.onSaveDraft,
    this.isEditing = false,
    this.showAuthor = true,
    this.onToggleReaction,
    this.onEditSubmit,
    this.onEditCancel,
  });

  final PrInlineEntry entry;

  /// The PR's identity key — its repo resolves markdown `#N` references.
  final PrRef prRef;
  final String originalCode;
  final String? filePath;
  final int? originalStartLine;
  final int? lineEnd;
  final bool canResolve;
  final bool resolved;
  final bool resolveBusy;
  final VoidCallback? onResolve;
  final List<CommentExcerpt> thread;
  final VoidCallback? onDeleteLocal;

  /// Holds an in-progress edit across a scroll.
  final TextEditingController? editDraft;

  /// Rewrites the comment: locally while unsent, on the forge once posted.
  /// Null hides Edit, for a comment whose post is in flight (that request
  /// already carries its old body). The toolbar still limits a posted
  /// comment's Edit to its author.
  final Future<String?> Function(String body)? onSaveDraft;
  final bool isEditing;

  /// Whether the tile names its author. False for the comment that opens a
  /// conversation: the thread's header row already carries its author.
  final bool showAuthor;

  /// Reaction toggle for a synced review comment; null while the entry is a
  /// local draft (GitHub reactions only attach to posted comments).
  final Future<void> Function(String content, {required bool add})?
  onToggleReaction;
  final void Function(String newBody)? onEditSubmit;
  final VoidCallback? onEditCancel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final published = entry.serverCommentId != null;
    final repoParts = prRef.repoFullName.split('/');
    return EditableCommentSlot(
      key: ValueKey(entry.id),
      initialBody: entry.body,
      owner: repoParts.first,
      repo: repoParts.length > 1 ? repoParts[1] : '',
      controller: editDraft,
      onSave: onSaveDraft ?? (_) async => null,
      builder: (context, editor, startEdit) => PrCommentActions(
        prRef: prRef,
        body: entry.body,
        authorLogin: entry.author,
        commentId: entry.serverCommentId,
        reviewComment: true,
        published: published,
        path: filePath,
        startLine: originalStartLine,
        endLine: lineEnd,
        thread: thread,
        canResolve: canResolve,
        resolved: resolved,
        resolveBusy: resolveBusy,
        onResolve: onResolve,
        // Always the whole text, prose included. The pencil stays the way to
        // change only a suggestion's code, so one editor replaces the other.
        onEdit: onSaveDraft == null
            ? null
            : () {
                onEditCancel?.call();
                startEdit();
              },
        onDeleteLocal: onDeleteLocal,
        onToggleReaction: onToggleReaction,
        child: _entryContent(context, tokens, editor),
      ),
    );
  }

  Widget _entryContent(
    BuildContext context,
    DesignSystemTokens tokens,
    Widget? editor,
  ) {
    final content = <Widget>[
      if (editor != null)
        SelectionContainer.disabled(child: editor)
      else if (isEditing && onEditSubmit != null)
        _SuggestionEditor(
          initialBody: entry.body,
          filePath: filePath,
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
      if (onToggleReaction != null && entry.reactions.isNotEmpty) ...[
        const SizedBox(height: 6),
        ReactionBar(
          reactions: entry.reactions,
          showAdder: false,
          onToggle: onToggleReaction!,
        ),
      ],
    ];
    if (!showAuthor) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: content,
      );
    }
    // A reply repeats the header row's shape, with its text on the same
    // left edge as every other comment in the conversation.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            GitHubUserAvatar(
              login: entry.author,
              avatarUrl: entry.authorAvatarUrl,
              size: 18,
              showHoverCard: false,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                entry.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CcTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            AppTimestamp(
              dateTime: entry.createdAt,
              child: Text(
                formatRelativeTime(context, entry.createdAt),
                style: CcTypography.caption.copyWith(
                  color: tokens.textTertiary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...content,
      ],
    );
  }
}

class _SuggestionEditor extends ConsumerStatefulWidget {
  const _SuggestionEditor({
    required this.initialBody,
    required this.onSubmit,
    required this.onCancel,
    this.filePath,
  });
  final String initialBody;
  final String? filePath;
  final ValueChanged<String> onSubmit;
  final VoidCallback onCancel;
  @override
  ConsumerState<_SuggestionEditor> createState() => _SuggestionEditorState();
}

class _SuggestionEditorState extends ConsumerState<_SuggestionEditor> {
  late final List<DiffSyntaxTextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  final Set<String> _warmed = <String>{};
  bool _dark = false;

  String? get _language {
    final path = widget.filePath;
    return path == null ? null : shikiLangForPath(path);
  }

  @override
  void initState() {
    super.initState();
    final blocks = parseSuggestionBlocks(widget.initialBody);
    final replacements = blocks.isEmpty
        ? const <String>['']
        : [for (final block in blocks) block.code];
    _controllers = [
      for (final replacement in replacements)
        DiffSyntaxTextEditingController(
          text: replacement,
          languageId: _language,
        ),
    ];
    _focusNodes = [for (var i = 0; i < replacements.length; i++) FocusNode()];
    _warmGrammar();
  }

  void _warmGrammar() {
    final language = _language;
    if (language == null || !_warmed.add(language)) {
      return;
    }
    unawaited(
      ensureLanguageAvailable(language).then((available) {
        if (!available || !mounted) {
          return;
        }
        setState(() {
          for (final controller in _controllers) {
            controller.refreshHighlighting();
          }
        });
      }),
    );
  }

  void _addSuggestion() {
    final controller = DiffSyntaxTextEditingController(
      languageId: _language,
      dark: _dark,
    );
    final focus = FocusNode();
    setState(() {
      _controllers.add(controller);
      _focusNodes.add(focus);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        focus.requestFocus();
      }
    });
  }

  void _removeSuggestion(int index) {
    if (_controllers.length == 1) {
      return;
    }
    final controller = _controllers.removeAt(index);
    final focus = _focusNodes.removeAt(index);
    controller.dispose();
    focus.dispose();
    setState(() {});
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focus in _focusNodes) {
      focus.dispose();
    }
    super.dispose();
  }

  void _submit() {
    widget.onSubmit(
      replaceSuggestionBlocks(widget.initialBody, [
        for (final controller in _controllers) controller.text,
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    _dark = context.ccTheme?.isDark ?? false;
    for (final controller in _controllers) {
      controller.configure(languageId: _language, dark: _dark);
    }
    final codeStyle = AppFonts.codeStyleDynamic(
      ref.watch(codeFontFamilyProvider),
      fontSize: 12,
      height: 1.55,
      color: tokens.textPrimary,
    );
    final editor = Container(
      decoration: BoxDecoration(
        color: tokens.bgPrimary,
        border: Border.all(color: tokens.borderSecondary),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 6, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _controllers.length; i++) ...[
            if (i > 0) const CcDivider(),
            SelectionContainer.disabled(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CcTextField(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      maxLines: null,
                      minLines: 2,
                      textStyle: codeStyle,
                      hintText: l10n.editSuggestedCodeHint,
                      chromeless: true,
                    ),
                  ),
                  if (_controllers.length > 1)
                    CcIconButton(
                      onPressed: () => _removeSuggestion(i),
                      icon: AppIcons.x,
                      variant: CcButtonVariant.ghost,
                      size: CcButtonSize.sm,
                      tooltip: l10n.remove,
                    ),
                ],
              ),
            ),
          ],
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: CcButton(
              onPressed: _addSuggestion,
              variant: CcButtonVariant.ghost,
              size: CcButtonSize.sm,
              child: Text(l10n.addASuggestion),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CcButton(
                variant: CcButtonVariant.secondary,
                onPressed: widget.onCancel,
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: 8),
              _SendButton(onPressed: _submit),
            ],
          ),
        ],
      ),
    );
    // The pencil that opened this becomes the close button in place and keeps
    // focus, so the first block asks for focus itself; Send or Cancel hand it
    // back to the pencil.
    return FocusOnMount(
      focusNode: _focusNodes.first,
      builder: (_, _) => editor,
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
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12)),
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

    final retryLabel = error ?? AppLocalizations.of(context).clickToRetry;
    return CcTooltip(
      message: retryLabel,
      // Focusable, so a failed post can be retried from the keyboard.
      child: CcTappable(
        onPressed: onRetry,
        semanticLabel: '$label, $retryLabel',
        builder: (context, states) => ExcludeSemantics(child: pill),
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
