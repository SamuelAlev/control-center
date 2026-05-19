import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/features/pr_review/domain/entities/pr_inline_thread.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_comment_field.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_inline_comments_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_emoji/flutter_emoji.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Button that opens the approve/review overlay.
class ReviewOverlayButton extends ConsumerStatefulWidget {
  /// ReviewOverlayButton({.
  const ReviewOverlayButton({
    super.key,
    required this.pr,
    required this.prRef,
    required this.owner,
    required this.repo,
  });

  /// PullRequest.
  final PullRequest pr;

  /// The PR's identity key (repo coords + number) for PR-keyed providers.
  final PrRef prRef;

  /// GitHub repository owner.
  final String owner;

  /// GitHub repository name.
  final String repo;

  @override
  ConsumerState<ReviewOverlayButton> createState() =>
      _ReviewOverlayButtonState();
}

class _ReviewOverlayButtonState extends ConsumerState<ReviewOverlayButton> {
  final OverlayPortalController _popupCtrl = OverlayPortalController();
  final TextEditingController _commentCtrl = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  final _buttonKey = GlobalKey();
  Timer? _draftTimer;
  bool _draftLoaded = false;
  bool _saving = false;
  Offset? _overlayOffset;

  /// Resolved per call, not captured in `initState`: the repository is bound
  /// to the PR's own repo via its key, and the binding must follow the key if
  /// the widget is reused across a PR→PR hop.
  PrReviewRepository? get _repo => ref.read(prRepositoryProvider(widget.prRef));

  @override
  void initState() {
    super.initState();
    _commentCtrl.addListener(_onCommentChanged);
  }

  @override
  void dispose() {
    if (_popupCtrl.isShowing) {
      _popupCtrl.hide();
    }
    unawaited(_saveDraft());
    _draftTimer?.cancel();
    _commentCtrl.removeListener(_onCommentChanged);
    _commentCtrl.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  void _onCommentChanged() {
    _autoReplaceShortcodes();
    _scheduleDraftSave();
  }

  void _autoReplaceShortcodes() {
    final text = _commentCtrl.text;
    final pattern = RegExp(r':([a-zA-Z0-9_+-]+):');
    final match = pattern.firstMatch(text);
    if (match == null) {
      return;
    }

    final name = match.group(1)!;
    final parser = EmojiParser();
    if (!parser.hasName(name)) {
      return;
    }

    final emojiChar = parser.get(name).code;
    final start = match.start;
    final end = match.end;
    _commentCtrl.removeListener(_onCommentChanged);
    _commentCtrl.text =
        text.substring(0, start) + emojiChar + text.substring(end);
    _commentCtrl.selection = TextSelection.collapsed(
      offset: start + emojiChar.length,
    );
    _commentCtrl.addListener(_onCommentChanged);
  }

  void _scheduleDraftSave() {
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 800), _saveDraft);
  }

  Future<void> _saveDraft() async {
    if (_saving) {
      return;
    }

    final text = _commentCtrl.text;
    if (text.isEmpty) {
      return;
    }

    if (widget.owner.isEmpty || widget.repo.isEmpty) {
      return;
    }

    final repo = _repo;
    if (repo == null) {
      return;
    }
    try {
      _saving = true;
      await repo.upsertDraft(widget.prRef.number, text);
    } finally {
      _saving = false;
    }
  }

  Future<void> _clearDraft() async {
    if (widget.owner.isEmpty || widget.repo.isEmpty) {
      return;
    }

    final repo = _repo;
    if (repo != null) {
      await repo.clearDraft(widget.prRef.number);
    }
  }

  Future<void> _loadDraft() async {
    if (_draftLoaded) {
      return;
    }

    if (widget.owner.isEmpty || widget.repo.isEmpty) {
      return;
    }

    final repo = _repo;
    if (repo == null) {
      return;
    }
    final draft = await repo.getDraft(widget.prRef.number);
    if (draft != null && draft.isNotEmpty) {
      _commentCtrl.text = draft;
      _draftLoaded = true;
    }
  }

  void _toggle() {
    if (_popupCtrl.isShowing) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    _computeOverlayOffset();
    _popupCtrl.show();
    _loadDraft();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _commentFocus.requestFocus();
    });
    setState(() {});
  }

  /// Closes the panel. [saveDraft] is false when the body is being SUBMITTED:
  /// saving and clearing the draft are both fire-and-forget, so a save on the
  /// way out can land after the post-submit clear and resurrect a body the
  /// reviewer already sent.
  void _close({bool saveDraft = true}) {
    _draftTimer?.cancel();
    if (saveDraft) {
      unawaited(_saveDraft());
    }
    _popupCtrl.hide();
  }

  /// Wide enough for the three verdicts to sit on ONE row without any of them
  /// ellipsizing in a translated locale — and, as a bonus, for the composer's
  /// formatting toolbar to fit beside the Write/Preview tabs instead of
  /// wrapping onto a second line.
  static const _overlayWidth = 660.0;

  void _computeOverlayOffset() {
    final ctx = _buttonKey.currentContext;
    final box = ctx?.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) {
      return;
    }

    final buttonBottomRight = box.localToGlobal(
      Offset(box.size.width, box.size.height),
      ancestor: overlay,
    );
    final left = (buttonBottomRight.dx - _overlayWidth).clamp(
      0.0,
      (overlay.size.width - _overlayWidth).clamp(0.0, double.infinity),
    );
    final top = buttonBottomRight.dy + 8;
    _overlayOffset = Offset(left, top);
  }

  PrInlineCommentsController get _inlineComments =>
      ref.read(prInlineCommentsControllerProvider(widget.prRef).notifier);

  /// Comments the reviewer queued in the diff, waiting to go out with a
  /// verdict.
  List<PrInlineThread> get _pending => _inlineComments.pendingReviewThreads;

  /// Submits the verdict together with every queued inline comment, so the
  /// author gets ONE review rather than a verdict plus N drive-by comments.
  ///
  /// The optimistic verdict is set first and rolled back on failure; the queued
  /// comments are never dropped by a failure (the controller keeps them and
  /// marks them errored), so a rejected submit can simply be retried.
  Future<void> _submit(
    String event,
    PrReviewSubmissionState? optimistic,
    String Function(AppLocalizations) successMessage,
  ) async {
    final toaster = CcToastScope.of(context);
    final l10n = AppLocalizations.of(context);
    final comment = _commentCtrl.text.trim();
    final ctl = _inlineComments;
    final queued = ctl.pendingReviewThreads.length;
    // GitHub rejects a comment-only review with neither a body nor comments.
    if (event == 'COMMENT' && comment.isEmpty && queued == 0) {
      toaster.show(l10n.reviewNeedsABody, variant: CcToastVariant.warning);
      return;
    }
    if (optimistic != null) {
      ref
          .read(prOptimisticReviewStateProvider.notifier)
          .set(widget.prRef, optimistic);
    }
    _close(saveDraft: false);
    try {
      if (ctl.canPost) {
        await ctl.submitPendingReview(
          event: event,
          body: comment.isEmpty ? null : comment,
        );
      } else {
        final repo = _repo;
        if (repo == null) {
          return;
        }
        await repo.submitReview(
          prNumber: widget.prRef.number,
          event: event,
          body: comment.isEmpty ? null : comment,
        );
      }
      unawaited(_clearDraft());
      if (mounted) {
        _commentCtrl.clear();
        _refreshAfterSubmit(postedComments: queued > 0);
      }
      toaster.show(successMessage(l10n), variant: CcToastVariant.success);
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      if (optimistic != null) {
        ref
            .read(prOptimisticReviewStateProvider.notifier)
            .set(widget.prRef, null);
      }
      toaster.show(
        l10n.failedToSubmitReview('$e'),
        variant: CcToastVariant.danger,
      );
    }
  }

  /// Re-subscribes the surfaces a submitted review changes.
  ///
  /// The server already busts its own cache and signals every open watch
  /// stream, so this is not what fetches the new data — it is what guarantees
  /// the new data is *emitted*. A live stream dedupes on the payload
  /// fingerprint it last sent, so a re-validation that races the forge's
  /// read-after-write lag and comes back with the pre-review payload emits
  /// nothing at all, leaving the reviewer rail on its old state until the
  /// operator presses refresh. Invalidating re-subscribes with a clean
  /// fingerprint, which is the same thing that makes the refresh button work.
  /// Mirrors `PrEditNotifier._refreshReviewers`.
  void _refreshAfterSubmit({required bool postedComments}) {
    final pr = widget.prRef;
    ref
      ..invalidate(prReviewersProvider(pr))
      ..invalidate(prDetailProvider(pr))
      ..invalidate(prReviewsProvider(pr))
      ..invalidate(prTimelineEventsProvider(pr));
    if (postedComments) {
      ref.invalidate(prReviewCommentsProvider(pr));
    }
  }

  Future<void> _approve() => _submit(
    'APPROVE',
    PrReviewSubmissionState.approved,
    (l10n) => l10n.pullRequestApproved,
  );

  Future<void> _requestChanges() => _submit(
    'REQUEST_CHANGES',
    PrReviewSubmissionState.changesRequested,
    (l10n) => l10n.changesRequested,
  );

  Future<void> _comment() =>
      _submit('COMMENT', null, (l10n) => l10n.reviewSubmitted);

  void _insertAtCursor(String text) {
    final ctrl = _commentCtrl;
    final selection = ctrl.selection;
    final old = ctrl.text;
    if (selection.isValid && selection.start >= 0) {
      final start = selection.start;
      final end = selection.end;
      ctrl.text = old.substring(0, start) + text + old.substring(end);
      ctrl.selection = TextSelection.collapsed(offset: start + text.length);
    } else {
      ctrl.text = old + text;
      ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
    }
  }

  Future<void> _attachFile() async {
    final owner = widget.owner;
    final repo = widget.repo;
    if (owner.isEmpty || repo.isEmpty) {
      CcToastScope.of(context).show(
        AppLocalizations.of(context).noActiveWorkspaceGithub,
        variant: CcToastVariant.danger,
      );
      return;
    }
    final files = await openFiles(
      acceptedTypeGroups: [
        XTypeGroup(
          label: AppLocalizations.of(context).images,
          extensions: ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'],
        ),
      ],
    );
    for (final file in files) {
      try {
        final bytes = await file.readAsBytes();
        final base64 = base64Encode(bytes);
        final uniqueId = DateTime.now().millisecondsSinceEpoch;
        final path = '.github/pr-assets/${uniqueId}_${file.name}';
        final repo = _repo;
        if (repo == null) {
          return;
        }
        final url = await repo.uploadContent(
          path,
          base64,
          'Upload image for PR review',
        );
        _insertAtCursor('![${file.name}]($url)\n');
      } on Exception catch (e) {
        if (!mounted) {
          return;
        }

        CcToastScope.of(context).show(
          AppLocalizations.of(context).failedToUpload(file.name, '$e'),
          variant: CcToastVariant.danger,
        );
      }
    }
  }

  PrReviewSubmissionState? get _myReviewState {
    final pr = widget.prRef;
    final optimistic = ref.read(prOptimisticReviewStateProvider)[pr];
    if (optimistic != null) {
      final reviews = ref.read(prReviewsProvider(pr)).asData?.value;
      if (reviews != null) {
        final myLogin = ref.read(currentUserLoginForPrProvider(pr));
        if (myLogin.isNotEmpty) {
          for (final r in reviews.reversed) {
            if (r.author?.login.toLowerCase() == myLogin) {
              if (r.state == optimistic) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    ref
                        .read(prOptimisticReviewStateProvider.notifier)
                        .set(pr, null);
                  }
                });
              }
              break;
            }
          }
        }
      }
      return optimistic;
    }

    final reviews = ref.read(prReviewsProvider(pr)).asData?.value;
    if (reviews == null || reviews.isEmpty) {
      return null;
    }
    final myLogin = ref.read(currentUserLoginForPrProvider(pr));
    if (myLogin.isEmpty) {
      return null;
    }
    for (final r in reviews.reversed) {
      if (r.author?.login.toLowerCase() == myLogin) {
        return r.state;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(prOptimisticReviewStateProvider);
    // Watch (not read) the inline-comment state so the queued count on the
    // button tracks the diff live — a review being drafted a few files away
    // must be visible from here, or the reviewer forgets it and never submits.
    ref.watch(prInlineCommentsControllerProvider(widget.prRef));
    final pendingCount = _pending.length;
    final myState = _myReviewState;
    final isApproved = myState == PrReviewSubmissionState.approved;
    final isChangesRequested =
        myState == PrReviewSubmissionState.changesRequested;

    final baseLabel = switch (myState) {
      PrReviewSubmissionState.approved => AppLocalizations.of(context).approved,
      PrReviewSubmissionState.changesRequested => AppLocalizations.of(
        context,
      ).requestedChanges,
      _ => AppLocalizations.of(context).review,
    };
    final label = pendingCount > 0 ? '$baseLabel ($pendingCount)' : baseLabel;

    final icon = switch (myState) {
      PrReviewSubmissionState.approved => AppIcons.checkCircle2,
      PrReviewSubmissionState.changesRequested => AppIcons.xCircle,
      _ => AppIcons.checkCircle,
    };

    return OverlayPortal(
      controller: _popupCtrl,
      overlayChildBuilder: _buildOverlay,
      child: CcButton(
        key: _buttonKey,
        onPressed: _toggle,
        size: CcButtonSize.sm,
        variant: isChangesRequested
            ? CcButtonVariant.destructive
            : pendingCount > 0
            ? CcButtonVariant.primary
            : isApproved
            ? CcButtonVariant.secondary
            : CcButtonVariant.primary,
        icon: icon,
        child: Text(label),
      ),
    );
  }

  Widget _buildOverlay(BuildContext overlayCtx) {
    final tokens = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final offset = _overlayOffset ?? Offset.zero;
    final pending = _pending;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _close,
          ),
        ),
        Positioned(
          left: offset.dx,
          top: offset.dy,
          width: _overlayWidth,
          child: Focus(
            canRequestFocus: false,
            onKeyEvent: (_, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.escape) {
                _close();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: RepaintBoundary(
              child: Material(
                elevation: 8,
                borderRadius: AppRadii.brLg,
                color: tokens.bgPrimary,
                child: Container(
                  width: _overlayWidth,
                  decoration: BoxDecoration(
                    borderRadius: AppRadii.brLg,
                    border: Border.all(color: tokens.borderSecondary),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.finishYourReview,
                        style: CcTypography.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: tokens.textPrimary,
                        ),
                      ),
                      // The queued comments are the review. Naming them here —
                      // with the file:line of each — is what turns "submit"
                      // from a leap of faith into a read-back of what goes out.
                      if (pending.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _PendingCommentsSummary(
                          threads: pending,
                          onDiscard: () {
                            _inlineComments.discardPendingReview();
                            setState(() {});
                          },
                        ),
                      ],
                      const SizedBox(height: 10),
                      // The same rich field the diff composer and thread
                      // replies use. Emoji, GIFs, image upload, formatting and
                      // the preview used to live here and only here, inlined —
                      // which is why a comment written on the diff had none of
                      // them. Image upload stays host-supplied: it needs repo
                      // write access, which only this surface has.
                      PrCommentField(
                        controller: _commentCtrl,
                        focusNode: _commentFocus,
                        hintText: l10n.reviewCommentHint,
                        owner: widget.owner,
                        repo: widget.repo,
                        minLines: 5,
                        maxLines: 10,
                        onAttachImage: _attachFile,
                      ),
                      const SizedBox(height: 14),
                      const CcDivider(),
                      const SizedBox(height: 12),
                      // One row, read left to right in ascending commitment:
                      // the negative verdict, the no-verdict option, then the
                      // one that ships it. Approve sits last because that is
                      // where a confirming action lives in every other dialog
                      // in the app, and carries the PRIMARY variant rather than
                      // green: green would sign it as a status, and this is a
                      // button, not a badge. Request-changes keeps the solid
                      // red — nothing is destroyed here, but the design
                      // system's destructive variant is the red a negative
                      // verdict needs. "Comment" stays neutral on purpose: it
                      // is the no-verdict option, so tinting it would imply a
                      // third position.
                      // `Expanded` and not `fullWidth`: the three share the
                      // width equally, and full-width flushes a label left,
                      // which reads as three ragged buttons in a row of equals.
                      Row(
                        children: [
                          Expanded(
                            child: CcButton(
                              onPressed: _requestChanges,
                              variant: CcButtonVariant.destructive,
                              child: Text(
                                // Ellipsize rather than overflow: this label is
                                // one of the longest strings in the app once
                                // translated.
                                l10n.requestChanges,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CcButton(
                              onPressed: _comment,
                              variant: CcButtonVariant.secondary,
                              child: Text(
                                l10n.commentVerdict,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CcButton(
                              onPressed: _approve,
                              variant: CcButtonVariant.primary,
                              child: Text(
                                l10n.approve,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Lists the inline comments queued for this review, with a way to throw the
/// whole batch away.
///
/// Deliberately shows the anchor (`path:line`) rather than the body: the
/// question at submit time is "did I mean to send these five", and the file and
/// line answer it faster than a wall of prose would.
class _PendingCommentsSummary extends StatelessWidget {
  const _PendingCommentsSummary({
    required this.threads,
    required this.onDiscard,
  });

  final List<PrInlineThread> threads;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    // Root-overlay context: a CcTheme ancestor is not guaranteed here, so this
    // resolves defensively rather than asserting one into existence.
    final tokens =
        context.designSystem ??
        (Theme.of(context).brightness == Brightness.dark
            ? DesignSystemTokens.dark()
            : DesignSystemTokens.light());
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        borderRadius: AppRadii.brMd,
        border: Border.all(color: tokens.borderSecondary),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                AppIcons.messageSquare,
                size: 13,
                color: tokens.textTertiary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.pendingCommentsCount(threads.length),
                  style: CcTypography.caption.copyWith(
                    color: tokens.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              CcButton(
                onPressed: onDiscard,
                variant: CcButtonVariant.ghost,
                size: CcButtonSize.sm,
                child: Text(l10n.discard),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final t in threads.take(6))
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                t.isMultiLine
                    ? '${t.filePath}:${t.line}-${t.lineEnd}'
                    : '${t.filePath}:${t.lineEnd}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CcTypography.caption.copyWith(
                  color: tokens.textTertiary,
                ),
              ),
            ),
          if (threads.length > 6)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                l10n.andNMore(threads.length - 6),
                style: CcTypography.caption.copyWith(
                  color: tokens.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
