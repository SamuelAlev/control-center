import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/text_draft_provider.dart';
import 'package:control_center/di/providers.dart' show githubUserProvider;
import 'package:control_center/features/pr_review/presentation/utils/pr_image_attachment.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_comment_field.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_sign_in_notice.dart';
import 'package:control_center/features/pr_review/providers/pr_comment_draft_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart'
    show currentUserLoginForPrProvider;
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Top-level conversation comment composer rendered beneath the PR Overview
/// activity timeline.
///
/// Rests as a compact Linear-style `"Leave a comment…"` trigger aligned to the
/// timeline's 24px gutter; tapping it expands into the full Write/Preview
/// [PrCommentField] backed by a session-persisted draft controller.
class PrConversationComposer extends ConsumerStatefulWidget {
  /// Creates a [PrConversationComposer].
  const PrConversationComposer({
    super.key,
    required this.pr,
    required this.prRef,
  });

  /// The pull request being commented on.
  final PullRequest pr;

  /// The PR's identity key (repo coords + number) for PR-keyed providers.
  final PrRef prRef;

  @override
  ConsumerState<PrConversationComposer> createState() =>
      _PrConversationComposerState();
}

class _PrConversationComposerState
    extends ConsumerState<PrConversationComposer> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'pr-conversation-field');
  final FocusNode _triggerFocus = FocusNode(
    debugLabel: 'pr-conversation-trigger',
  );
  late TextEditingController _ctrl;
  bool _expanded = false;
  bool _sending = false;

  TextDraftKey get _draftKey => (
    workspaceId: widget.prRef.workspaceId,
    surface: 'pr-conversation-comment',
    destination: (widget.prRef.repoFullName, widget.prRef.number),
  );

  @override
  void initState() {
    super.initState();
    _ctrl = ref.read(prCommentDraftControllerProvider(_draftKey));
    _expanded = _ctrl.text.isNotEmpty;
  }

  @override
  void didUpdateWidget(PrConversationComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prRef != widget.prRef) {
      _ctrl = ref.read(prCommentDraftControllerProvider(_draftKey));
      _expanded = _ctrl.text.isNotEmpty;
      _sending = false;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _triggerFocus.dispose();
    super.dispose();
  }

  bool get _hasFocusInside =>
      FocusManager.instance.primaryFocus?.context?.findAncestorStateOfType<
          _PrConversationComposerState>() ==
      this;

  void _expand() {
    setState(() => _expanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _expanded) {
        // The expanded editor is much taller than the trigger it replaces, so
        // bring its Cancel/Comment row into view. Done before focusing, and
        // without animation: the field's own caret reveal on focus would
        // otherwise interrupt the scroll and stop at the first line.
        unawaited(
          Scrollable.ensureVisible(
            context,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          ),
        );
        _focusNode.requestFocus();
      }
    });
  }

  void _collapse() {
    final hadFocus = _hasFocusInside;
    setState(() => _expanded = false);
    if (!hadFocus) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_expanded) {
        _triggerFocus.requestFocus();
      }
    });
  }

  Future<void> _cancel() async {
    if (_sending) {
      return;
    }
    if (_ctrl.text.trim().isEmpty) {
      _ctrl.clear();
      _collapse();
      return;
    }
    final l10n = AppLocalizations.of(context);
    final discard = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.discardChangesConfirm,
        content: const SizedBox.shrink(),
        actions: [
          CcButton(
            onPressed: () => Navigator.pop(ctx, false),
            variant: CcButtonVariant.ghost,
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.pop(ctx, true),
            variant: CcButtonVariant.destructive,
            child: Text(l10n.discard),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      _ctrl.clear();
      _collapse();
    }
  }

  Future<void> _submit() async {
    if (_sending) {
      return;
    }
    final draftCtrl = _ctrl;
    final originalText = draftCtrl.text;
    final text = originalText.trim();
    if (text.isEmpty) {
      return;
    }
    final prRef = widget.prRef;
    final repo = ref.read(prRepositoryProvider(prRef));
    if (repo == null) {
      return;
    }
    setState(() => _sending = true);
    try {
      await repo.postIssueComment(prNumber: prRef.number, body: text);
      if (draftCtrl.text == originalText) {
        draftCtrl.clear();
      }
      if (!mounted) {
        return;
      }
      ref
        ..invalidate(prIssueCommentsProvider(prRef))
        ..invalidate(prTimelineEventsProvider(prRef))
        ..invalidate(prDetailProvider(prRef));
      if (!identical(_ctrl, draftCtrl)) {
        return;
      }
      final hadFocus = _hasFocusInside;
      final stayExpanded = draftCtrl.text.isNotEmpty;
      setState(() {
        _sending = false;
        _expanded = stayExpanded;
      });
      if (!stayExpanded && hadFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_expanded) {
            _triggerFocus.requestFocus();
          }
        });
      }
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      if (identical(_ctrl, draftCtrl)) {
        setState(() => _sending = false);
      }
      showPrError(
        context,
        ref,
        e,
        (l) => l.failedToPostComment('$e'),
        prRef: prRef,
      );
    }
  }

  (String owner, String repo) _resolveCoords() {
    final repoRow = ref.watch(prRepoRowProvider(widget.prRef));
    if (repoRow != null &&
        repoRow.remoteOwner.isNotEmpty &&
        repoRow.remoteName.isNotEmpty) {
      return (repoRow.remoteOwner, repoRow.remoteName);
    }
    final parts = widget.pr.repoFullName.split('/');
    return (parts.isNotEmpty ? parts[0] : '', parts.length > 1 ? parts[1] : '');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: _ViewerAvatar(prRef: widget.prRef),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _expanded ? _buildExpanded(context) : _buildCollapsed(context),
        ),
      ],
    );
  }

  Widget _buildCollapsed(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return CcTappable(
      focusNode: _triggerFocus,
      semanticLabel: l10n.leaveACommentEllipsis,
      borderRadius: BorderRadius.circular(2),
      onPressed: _expand,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: hovered ? t.bgPrimaryHover : t.panel,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: hovered ? t.borderPrimary : t.borderSecondary,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.leaveACommentEllipsis,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CcTypography.bodySm.copyWith(color: t.textPlaceholder),
                ),
              ),
              const SizedBox(width: 8),
              ExcludeSemantics(
                child: Icon(
                  AppIcons.messageSquare,
                  size: 14,
                  color: hovered ? t.textSecondary : t.textTertiary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpanded(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (owner, repoName) = _resolveCoords();
    final repoRow = ref.watch(prRepoRowProvider(widget.prRef));
    final repoClient = ref.watch(prRepositoryProvider(widget.prRef));
    final hasRepo = repoClient != null;
    final canUploadImages =
        hasRepo &&
        owner.isNotEmpty &&
        repoName.isNotEmpty &&
        ref.watch(prRepoWriteAccessProvider(widget.prRef)) &&
        (repoRow?.forge ?? widget.prRef.forge) != ForgeHost.bitbucket;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _submit,
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _submit,
        const SingleActivator(LogicalKeyboardKey.escape): _cancel,
      },
      child: SelectionContainer.disabled(
        child: PrCommentField(
          controller: _ctrl,
          focusNode: _focusNode,
          hintText: l10n.leaveACommentEllipsis,
          owner: owner,
          repo: repoName,
          autofocus: false,
          minLines: 4,
          maxLines: 12,
          onAttachImage: canUploadImages
              ? () => attachPrImagesToController(
                  context: context,
                  controller: _ctrl,
                  repo: ref.read(prRepositoryProvider(widget.prRef)),
                  owner: owner,
                  repoName: repoName,
                )
              : null,
          footer: (context) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Spacer(),
                CcButton(
                  onPressed: _sending ? null : _cancel,
                  variant: CcButtonVariant.secondary,
                  size: CcButtonSize.sm,
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _ctrl,
                  builder: (context, value, _) => CcButton(
                    variant: CcButtonVariant.primary,
                    size: CcButtonSize.sm,
                    loading: _sending,
                    onPressed: hasRepo && !_sending && value.text.trim().isNotEmpty
                        ? _submit
                        : null,
                    child: Text(l10n.comment),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewerAvatar extends ConsumerWidget {
  const _ViewerAvatar({required this.prRef});

  final PrRef prRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final login = ref.watch(currentUserLoginForPrProvider(prRef));
    if (login.isEmpty) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: t.bgSecondary,
          shape: BoxShape.circle,
          border: Border.all(color: t.borderSecondary),
        ),
        child: ExcludeSemantics(
          child: Icon(AppIcons.messageSquare, size: 13, color: t.fgTertiary),
        ),
      );
    }
    final ghUser = ref.watch(githubUserProvider).value;
    final avatarUrl =
        ghUser != null && ghUser.login.toLowerCase() == login ? ghUser.avatarUrl : '';
    return ExcludeSemantics(
      child: GitHubUserAvatar(
        login: login,
        avatarUrl: avatarUrl,
        size: 24,
        showHoverCard: false,
      ),
    );
  }
}
