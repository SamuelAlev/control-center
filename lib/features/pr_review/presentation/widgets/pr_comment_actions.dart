import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_edit_notifier.dart';
import 'package:control_center/features/pr_review/presentation/widgets/comment_action_cluster.dart';
import 'package:control_center/features/pr_review/presentation/widgets/comment_action_model.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_comment_field.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/pr_review/providers/send_comment_to_agent.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A comment plus the hover toolbar Linear's threads use.
///
/// Resolve is offered only for a thread the forge can resolve. Edit is
/// offered only to the author of a published comment. Delete is offered to
/// the author, to a writer or admin, and for an unpublished draft. Everyone
/// else does not see the row.
class PrCommentActions extends ConsumerStatefulWidget {
  /// Creates a [PrCommentActions].
  const PrCommentActions({
    super.key,
    required this.child,
    required this.prRef,
    required this.body,
    required this.authorLogin,
    this.commentId,
    this.reviewComment = false,
    this.published = true,
    this.path,
    this.startLine,
    this.endLine,
    this.thread,
    this.canResolve = false,
    this.resolved = false,
    this.resolveBusy = false,
    this.onResolve,
    this.onEdit,
    this.onDeleteLocal,
    this.onToggleReaction,
    this.toolbarTop = 4,
  });

  /// The comment chrome this toolbar floats over.
  final Widget child;

  /// The pull request the comment belongs to.
  final PrRef prRef;

  /// The comment body, used for the agent prompt and the markdown copy.
  final String body;

  /// The author's login. Empty when unknown.
  final String authorLogin;

  /// Forge id. Null for a draft that has not been posted.
  final int? commentId;

  /// True for an inline review comment, false for a conversation comment.
  ///
  /// The two are deleted on different forge routes and numbered independently.
  final bool reviewComment;

  /// False for a draft that exists only on this client.
  final bool published;

  /// File the comment is anchored to, when it is an inline thread.
  final String? path;

  /// First line of the anchor, when known.
  final int? startLine;

  /// Last line of the anchor, when known.
  final int? endLine;

  /// The whole thread, in order. Null for a comment that stands alone.
  final List<CommentExcerpt>? thread;

  /// Whether resolving would change anything on the forge.
  final bool canResolve;

  /// Whether the thread is resolved.
  final bool resolved;

  /// Whether a resolve write is in flight.
  final bool resolveBusy;

  /// Marks the thread resolved or reopened.
  final VoidCallback? onResolve;

  /// Opens an editor. Gated again on authorship.
  final VoidCallback? onEdit;

  /// Discards an unpublished draft. Published comments go through the forge.
  final VoidCallback? onDeleteLocal;

  /// Toggles a GitHub reaction. Null until the comment exists on the forge.
  final Future<void> Function(String content, {required bool add})?
  onToggleReaction;

  /// Distance from the top of the comment. Review cards clear their verdict chip.
  final double toolbarTop;

  @override
  ConsumerState<PrCommentActions> createState() => _PrCommentActionsState();
}

class _PrCommentActionsState extends ConsumerState<PrCommentActions> {
  bool _sending = false;

  String get _prompt => commentAgentPrompt(
    body: widget.body,
    author: widget.authorLogin,
    path: widget.path,
    startLine: widget.startLine,
    endLine: widget.endLine,
    thread: widget.thread,
  );

  bool get _inThread =>
      (widget.path != null && widget.path!.isNotEmpty) ||
      (widget.thread != null && widget.thread!.length > 1);

  void _copy(String text) {
    if (text.isEmpty) {
      return;
    }
    Clipboard.setData(ClipboardData(text: text));
    CcToastScope.of(context).show(
      AppLocalizations.of(context).copied,
      variant: CcToastVariant.success,
    );
  }

  Future<void> _send() async {
    if (_sending) {
      return;
    }
    setState(() => _sending = true);
    final l10n = AppLocalizations.of(context);
    try {
      await sendCommentToAgent(ref, prRef: widget.prRef, prompt: _prompt);
      if (!mounted) {
        return;
      }
      CcToastScope.of(
        context,
      ).show(l10n.commentSentToAgent, variant: CcToastVariant.success);
    } catch (_) {
      if (!mounted) {
        return;
      }
      CcToastScope.of(
        context,
      ).show(l10n.commentSendFailed, variant: CcToastVariant.danger);
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _delete() async {
    if (!widget.published) {
      widget.onDeleteLocal?.call();
      return;
    }
    final id = widget.commentId;
    if (id == null) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.commentDeleteTitle,
        content: Text(l10n.commentDeleteBody),
        actions: [
          CcButton(
            variant: CcButtonVariant.secondary,
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          CcButton(
            variant: CcButtonVariant.destructive,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.commentDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final error = widget.reviewComment
        ? await ref
              .read(prEditProvider(widget.prRef).notifier)
              .deleteReviewComment(commentId: id)
        : await ref
              .read(prEditProvider(widget.prRef).notifier)
              .deleteIssueComment(commentId: id);
    if (error != null && mounted) {
      CcToastScope.of(
        context,
      ).show(l10n.commentDeleteFailed, variant: CcToastVariant.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hidden = ref.watch(
      prEditProvider(widget.prRef).select(
        (s) => widget.reviewComment
            ? s.hiddenReviewCommentIds
            : s.hiddenIssueCommentIds,
      ),
    );
    final id = widget.commentId;
    if (id != null && hidden.contains(id)) {
      return const SizedBox.shrink();
    }

    final parts = widget.prRef.repoFullName.split('/');
    final owner = parts.isNotEmpty ? parts.first : '';
    final repo = parts.length > 1 ? parts[1] : '';
    // Same gate as write-access on the title: don't ask the forge who the
    // viewer is until the pull request itself has loaded. A miss is "cannot
    // delete", which the menu treats as hidden.
    final detailLoaded = ref.watch(prDetailProvider(widget.prRef)).hasValue;
    final permission = (!detailLoaded || owner.isEmpty || repo.isEmpty)
        ? null
        : ref
              .watch(repoPermissionProvider((owner: owner, repo: repo)))
              .asData
              ?.value;
    final viewer = ref.watch(githubUserProvider).asData?.value?.login;
    final isAuthor = commentIsAuthor(widget.authorLogin, viewer);
    final canDelete = canDeleteComment(
      isAuthor: isAuthor,
      published: widget.published,
      permission: permission,
    );
    final canEdit =
        widget.onEdit != null &&
        canEditComment(isAuthor: isAuthor, published: widget.published);
    final htmlUrl = ref.watch(prDetailProvider(widget.prRef)).value?.htmlUrl;
    final link = (id == null || htmlUrl == null)
        ? ''
        : commentPermalink(
            htmlUrl: htmlUrl,
            commentId: id,
            reviewComment: widget.reviewComment,
          );
    final markdown = commentAsMarkdown(
      body: widget.body,
      author: widget.authorLogin,
      path: widget.path,
      startLine: widget.startLine,
      endLine: widget.endLine,
      thread: widget.thread,
    );
    final showDelete =
        canDelete &&
        (widget.published ? id != null : widget.onDeleteLocal != null);

    return CommentActionsHost(
      toolbarTop: widget.toolbarTop,
      actions: (onPinned) => CommentActionCluster(
        onPinnedChanged: onPinned,
        onToggleReaction: widget.onToggleReaction,
        onResolve: widget.canResolve ? widget.onResolve : null,
        resolved: widget.resolved,
        resolveBusy: widget.resolveBusy,
        threadMenu: _inThread,
        onCopyLink: link.isEmpty ? null : () => _copy(link),
        onCopyMarkdown: markdown.isEmpty ? null : () => _copy(markdown),
        onCopyPrompt: _prompt.isEmpty ? null : () => _copy(_prompt),
        onSendToAgent: _prompt.isEmpty ? null : _send,
        sending: _sending,
        onEdit: canEdit ? widget.onEdit : null,
        onDelete: showDelete ? _delete : null,
      ),
      child: widget.child,
    );
  }
}

/// Swaps a comment body for the shared comment field, then writes it back.
///
/// The toolbar decides whether Edit is shown. This only owns the field.
class EditableCommentSlot extends StatefulWidget {
  /// Creates an [EditableCommentSlot].
  const EditableCommentSlot({
    super.key,
    required this.initialBody,
    required this.owner,
    required this.repo,
    required this.onSave,
    required this.builder,
  });

  /// The body shown, and the text the editor opens with.
  final String initialBody;

  /// Repo owner for mention completion inside the field.
  final String owner;

  /// Repo name for mention completion inside the field.
  final String repo;

  /// Persists the edited body. A non-null return is an error message.
  final Future<String?> Function(String body) onSave;

  /// Builds the comment. The editor widget is non-null while editing; the
  /// callback opens the field.
  final Widget Function(
    BuildContext context,
    Widget? editor,
    VoidCallback startEdit,
  )
  builder;

  @override
  State<EditableCommentSlot> createState() => _EditableCommentSlotState();
}

class _EditableCommentSlotState extends State<EditableCommentSlot> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  bool _editing = false;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _start() {
    _controller.text = widget.initialBody;
    setState(() => _editing = true);
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    final error = await widget.onSave(_controller.text);
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (error == null) {
      setState(() => _editing = false);
      return;
    }
    CcToastScope.of(context).show(
      AppLocalizations.of(context).saveFailed,
      variant: CcToastVariant.danger,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final editor = _editing
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PrCommentField(
                controller: _controller,
                focusNode: _focus,
                hintText: l10n.commentEdit,
                owner: widget.owner,
                repo: widget.repo,
                autofocus: true,
                minLines: 3,
                maxLines: 12,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CcButton(
                      variant: CcButtonVariant.secondary,
                      size: CcButtonSize.sm,
                      onPressed: _saving
                          ? null
                          : () => setState(() => _editing = false),
                      child: Text(l10n.cancel),
                    ),
                    const SizedBox(width: 8),
                    CcButton(
                      size: CcButtonSize.sm,
                      onPressed: _saving ? null : _save,
                      child: Text(l10n.save),
                    ),
                  ],
                ),
              ),
            ],
          )
        : null;
    return widget.builder(context, editor, _start);
  }
}
