import 'dart:async';

import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show KeyDownEvent, LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Merge method options.
enum _MergeMethod { squash, merge, rebase }

/// Visual readiness state used to color the merge button.
enum _MergeReadiness {
  /// Required reviewers approved and no check is failing.
  ready,

  /// Reviews are OK but at least one check is still running.
  pending,

  /// A required reviewer hasn't approved or a check failed outright.
  blocked,
}

/// Button that opens the merge flyout with commit type selector and merge actions.
class MergeFlyoutButton extends ConsumerStatefulWidget {
  /// MergeFlyoutButton.
  const MergeFlyoutButton({
    super.key,
    required this.pr,
    required this.owner,
    required this.repo,
    required this.checks,
    required this.reviews,
  });

  /// Pull request to merge.
  final PullRequest pr;

  /// GitHub repository owner.
  final String owner;

  /// GitHub repository name.
  final String repo;

  /// Current check runs for the PR.
  final List<CheckRun> checks;

  /// Current review submissions for the PR.
  final List<PrReviewSubmission> reviews;

  @override
  ConsumerState<MergeFlyoutButton> createState() => _MergeFlyoutButtonState();
}

class _MergeFlyoutButtonState extends ConsumerState<MergeFlyoutButton> {
  final OverlayPortalController _popupCtrl = OverlayPortalController();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final _buttonKey = GlobalKey();
  bool _merging = false;
  Offset? _overlayOffset;
  _MergeMethod _method = _MergeMethod.squash;

  static const _overlayWidth = 520.0;

  @override
  void initState() {
    super.initState();
    _prefillFields();
  }

  @override
  void dispose() {
    if (_popupCtrl.isShowing) {
      _popupCtrl.hide();
    }
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _prefillFields() {
    switch (_method) {
      case _MergeMethod.squash:
        _titleCtrl.text = widget.pr.title;
        _descCtrl.text = widget.pr.body;
      case _MergeMethod.merge:
        _titleCtrl.text =
            'Merge pull request #${widget.pr.number} from ${widget.pr.headRef}';
        _descCtrl.text = widget.pr.title;
      case _MergeMethod.rebase:
        _titleCtrl.clear();
        _descCtrl.clear();
    }
  }

  bool get _allChecksPass {
    final checks = widget.checks;
    if (checks.isEmpty) {
      return true;
    }
    return checks.every(
      (c) =>
          c.isSuccess ||
          c.conclusion == CheckRunConclusion.skipped ||
          c.conclusion == CheckRunConclusion.neutral,
    );
  }

  /// A required check is explicitly failing (failure/timed-out/action-required).
  /// Pending or queued checks don't count as blocking — they count as pending.
  bool get _hasFailingCheck => widget.checks.any((c) => c.isFailing);

  /// At least one check is still queued or in-progress.
  bool get _hasPendingCheck =>
      widget.checks.any((c) => c.status != CheckRunStatus.completed);

  bool get _allReviewsApproved {
    final requested = widget.pr.requestedReviewers;
    if (requested.isEmpty) {
      return true;
    }
    final approvedLogins = <String>{};
    for (final r in widget.reviews) {
      if (r.state == PrReviewSubmissionState.approved &&
          r.author?.login != null) {
        approvedLogins.add(r.author!.login.toLowerCase());
      }
    }
    return requested.every(
      (r) => approvedLogins.contains(r.login.toLowerCase()),
    );
  }

  bool get _canCleanMerge => _allChecksPass && _allReviewsApproved;

  /// Readiness signal used to color the merge button:
  /// - `_MergeReadiness.blocked` when a requested reviewer hasn't approved or
  ///   a check is explicitly failing — merging would override branch
  ///   protection.
  /// - `_MergeReadiness.pending` when reviews are approved but at least one
  ///   check is still running.
  /// - `_MergeReadiness.ready` when everything required is green.
  _MergeReadiness get _readiness {
    if (!_allReviewsApproved || _hasFailingCheck) {
      return _MergeReadiness.blocked;
    }
    if (_hasPendingCheck) {
      return _MergeReadiness.pending;
    }
    return _MergeReadiness.ready;
  }

  String get _mergeMethodApiName {
    switch (_method) {
      case _MergeMethod.squash:
        return 'squash';
      case _MergeMethod.merge:
        return 'merge';
      case _MergeMethod.rebase:
        return 'rebase';
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
    setState(() {});
  }

  void _close() {
    _popupCtrl.hide();
  }

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

  Future<void> _merge() async {
    if (_merging) {
      return;
    }
    setState(() => _merging = true);

    final toaster = CcToastScope.of(context);
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(prReviewRepositoryProvider);

    try {
      await repo.mergePullRequest(
        prNumber: widget.pr.number,
        mergeMethod: _mergeMethodApiName,
        commitTitle: _method != _MergeMethod.rebase ? _titleCtrl.text : null,
        commitMessage: _method != _MergeMethod.rebase ? _descCtrl.text : null,
      );
      _close();
      toaster.show(l10n.pullRequestMerged, variant: CcToastVariant.success);
    } on Exception catch (e) {
      toaster.show(l10n.failedToMergePr('$e'), variant: CcToastVariant.danger);
    } finally {
      if (mounted) {
        setState(() => _merging = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.pr.canMerge) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);

    final variant = switch (_readiness) {
      _MergeReadiness.ready => CcButtonVariant.primary,
      _MergeReadiness.pending => CcButtonVariant.secondary,
      _MergeReadiness.blocked => CcButtonVariant.destructive,
    };

    return OverlayPortal(
      controller: _popupCtrl,
      overlayChildBuilder: _buildOverlay,
      child: CcButton(
        key: _buttonKey,
        onPressed: _toggle,
        size: CcButtonSize.sm,
        variant: variant,
        icon: AppIcons.gitMerge,
        child: Text(l10n.merge),
      ),
    );
  }

  Widget _buildOverlay(BuildContext overlayCtx) {
    final tokens = context.designSystem!;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final offset = _overlayOffset ?? Offset.zero;
    final showFields = _method != _MergeMethod.rebase;

    final warnings = <String>[];
    if (!_allChecksPass) {
      warnings.add(l10n.checksFailing);
    }
    if (!_allReviewsApproved) {
      warnings.add(l10n.reviewsPending);
    }

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
                elevation: 0,
                borderRadius: BorderRadius.circular(4),
                color: tokens.bgPrimary,
                child: Container(
                  width: _overlayWidth,
                  decoration: BoxDecoration(
                    color: tokens.bgPrimary,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: tokens.borderSecondary),
                    boxShadow: AppShadows.golden,
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      Text(
                        l10n.mergePullRequest,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: tokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Merge method selector
                      _buildMethodSelector(tokens, theme, l10n),
                      const SizedBox(height: 10),

                      // Commit title / description
                      if (showFields) ...[
                        _buildTextField(
                          controller: _titleCtrl,
                          hintText: l10n.commitTitle,
                          tokens: tokens,
                          theme: theme,
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _descCtrl,
                          hintText: l10n.commitDescription,
                          tokens: tokens,
                          theme: theme,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Warnings
                      if (warnings.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: tokens.bgWarningPrimary,
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: tokens.borderErrorSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: warnings
                                .map(
                                  (w) => Row(
                                    children: [
                                      Icon(
                                        AppIcons.alertTriangle,
                                        size: 14,
                                        color: tokens.fgWarningPrimary,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          w,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: tokens.textErrorPrimary,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ),

                      // Merge button
                      SizedBox(
                        width: double.infinity,
                        child: CcButton(
                          onPressed: _merging ? null : _merge,
                          fullWidth: true,
                          variant: _canCleanMerge
                              ? CcButtonVariant.primary
                              : CcButtonVariant.destructive,
                          child: _merging
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: tokens.textWhite,
                                  ),
                                )
                              : Text(
                                  _canCleanMerge
                                      ? l10n.mergePullRequest
                                      : l10n.forceMergePullRequest,
                                ),
                        ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required DesignSystemTokens tokens,
    required ThemeData theme,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: tokens.borderSecondary),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: theme.textTheme.bodyMedium?.copyWith(color: tokens.textPrimary),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: tokens.focusRing, width: 2),
          ),
          hintText: hintText,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: tokens.textPlaceholder,
          ),
        ),
      ),
    );
  }

  Widget _buildMethodSelector(
    DesignSystemTokens tokens,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: tokens.borderSecondary),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          _methodChip(
            label: l10n.squashAndMerge,
            method: _MergeMethod.squash,
            tokens: tokens,
            theme: theme,
          ),
          const SizedBox(width: 4),
          _methodChip(
            label: l10n.createMergeCommit,
            method: _MergeMethod.merge,
            tokens: tokens,
            theme: theme,
          ),
          const SizedBox(width: 4),
          _methodChip(
            label: l10n.rebaseAndMerge,
            method: _MergeMethod.rebase,
            tokens: tokens,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _methodChip({
    required String label,
    required _MergeMethod method,
    required DesignSystemTokens tokens,
    required ThemeData theme,
  }) {
    final selected = _method == method;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _method = method;
            _prefillFields();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? tokens.bgPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? tokens.textPrimary : tokens.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
