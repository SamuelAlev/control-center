import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/evaluate_pr_merge_readiness.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/merge_commit_form.dart';
import 'package:control_center/features/pr_review/presentation/widgets/merge_conflicts_panel.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show KeyDownEvent, LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Readiness is NOT computed here. `evaluatePrMergeReadiness` in cc_domain owns
// it, because the server needs the same answer to decide whether to raise a
// "ready to merge" notification — and a button that says ready while the bell
// stays quiet (or the reverse) is worse than either alone.

/// Button that opens the merge flyout with commit type selector and merge actions.
class MergeFlyoutButton extends ConsumerStatefulWidget {
  /// MergeFlyoutButton.
  const MergeFlyoutButton({
    super.key,
    required this.pr,
    required this.prRef,
    required this.owner,
    required this.repo,
    required this.checks,
    required this.reviews,
  });

  /// Pull request to merge.
  final PullRequest pr;

  /// The PR's identity key (repo coords + number).
  final PrRef prRef;

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
  PrMergeMethod _method = PrMergeMethod.squash;

  /// GitHub refused a merge of THIS head because it conflicts. The forge's
  /// `mergeable_state` can lag (it is computed asynchronously and the page
  /// may hold a stale copy), and the refusal is the fresher word — without
  /// it the flyout would keep offering a merge that just failed.
  bool _rejectedForConflicts = false;

  // The method labels share one full-width track. 520px clips
  // "Create a merge commit" at the control's body size.
  static const _mergeFormWidth = 576.0;

  // A file list and one button; the merge form's width would leave it
  // mostly empty.
  static const _conflictsWidth = 440.0;

  double get _overlayWidth => _hasConflicts ? _conflictsWidth : _mergeFormWidth;

  /// Whether the branch conflicts with its base, by the forge's state or by
  /// a merge it just refused.
  bool get _hasConflicts =>
      _rejectedForConflicts ||
      widget.pr.mergeableState == PrMergeableState.dirty;

  @override
  void didUpdateWidget(covariant MergeFlyoutButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A push is a new head: the refusal was about the old one.
    if (oldWidget.pr.headSha != widget.pr.headSha) {
      _rejectedForConflicts = false;
    }
  }

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
      case PrMergeMethod.squash:
        _titleCtrl.text = widget.pr.title;
        _descCtrl.text = widget.pr.body;
      case PrMergeMethod.merge:
        _titleCtrl.text =
            'Merge pull request #${widget.pr.number} from ${widget.pr.headRef}';
        _descCtrl.text = widget.pr.title;
      case PrMergeMethod.rebase:
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

  /// The approving reviewers among the reviews this widget was handed.
  Iterable<String> get _approvedLogins => [
    for (final r in widget.reviews)
      if (r.state == PrReviewSubmissionState.approved &&
          r.author?.login != null)
        r.author!.login,
  ];

  /// Whether the review requirement is satisfied.
  ///
  /// Read independently of [_readiness] for the warning list: a PR the forge
  /// calls `clean` can still have a requested reviewer who has not looked, and
  /// saying so is useful even though merging is allowed.
  bool get _reviewsSatisfied => prReviewsSatisfied(
    reviewDecision: widget.pr.reviewDecision,
    requestedReviewerLogins: widget.pr.requestedReviewers.map((r) => r.login),
    requestedTeamSlugs: widget.pr.requestedTeamSlugs,
    approvedLogins: _approvedLogins,
  );

  /// Merging from here would override the forge, so the confirm button turns
  /// destructive and says "force merge". A `pending` PR is NOT an override:
  /// GitHub itself allows that merge, the run just isn't all-green yet.
  bool get _isOverrideMerge => _readiness == PrMergeReadiness.blocked;

  /// The check list this widget holds, collapsed to the rolled-up status the
  /// shared heuristic takes. Failing wins over pending — one red required check
  /// blocks regardless of what else is still running.
  PrChecksStatus get _checksStatus {
    if (widget.checks.any((c) => c.isFailing)) {
      return PrChecksStatus.failing;
    }
    if (widget.checks.any((c) => c.status != CheckRunStatus.completed)) {
      return PrChecksStatus.pending;
    }
    return widget.checks.isEmpty ? PrChecksStatus.none : PrChecksStatus.passing;
  }

  /// Readiness signal used to colour the merge button.
  ///
  /// Computed by [evaluatePrMergeReadiness] — the same function the server's
  /// open-PR poller uses to decide whether to raise a "ready to merge"
  /// notification, so the two cannot disagree.
  ///
  /// The draft case never arises here (the button is hidden on drafts) but the
  /// shared function checks it anyway, because the poller sees drafts.
  PrMergeReadiness get _readiness => evaluatePrMergeReadiness(
    isDraft: widget.pr.isDraft,
    mergeableState: widget.pr.mergeableState,
    reviewDecision: widget.pr.reviewDecision,
    checksStatus: _checksStatus,
    requestedReviewerLogins: widget.pr.requestedReviewers.map((r) => r.login),
    requestedTeamSlugs: widget.pr.requestedTeamSlugs,
    approvedLogins: _approvedLogins,
  ).readiness;

  String get _mergeMethodApiName {
    switch (_method) {
      case PrMergeMethod.squash:
        return 'squash';
      case PrMergeMethod.merge:
        return 'merge';
      case PrMergeMethod.rebase:
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
    final repository = ref.read(prRepositoryProvider(widget.prRef));
    if (repository == null) {
      setState(() => _merging = false);
      return;
    }

    try {
      await repository.mergePullRequest(
        prNumber: widget.prRef.number,
        mergeMethod: _mergeMethodApiName,
        commitTitle: _method != PrMergeMethod.rebase ? _titleCtrl.text : null,
        commitMessage: _method != PrMergeMethod.rebase ? _descCtrl.text : null,
      );
      _close();
      toaster.show(l10n.pullRequestMerged, variant: CcToastVariant.success);
    } on RemoteRpcException catch (e) {
      // The forge's own reason ("Pull Request has merge conflicts"), not a
      // generic failure. A conflict also turns the flyout into the conflicts
      // view, which is where the fix lives.
      if (e.code == RpcErrorCodes.prNotMergeable &&
          e.data is Map &&
          (e.data! as Map)['has_conflicts'] == true &&
          mounted) {
        setState(() {
          _rejectedForConflicts = true;
          _computeOverlayOffset();
        });
      }
      toaster.show(
        l10n.failedToMergePr(e.message),
        variant: CcToastVariant.danger,
      );
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

    final conflicts = _hasConflicts;
    // A conflict is not an override the operator can force: GitHub refuses
    // the merge outright. Secondary rather than red, because what the button
    // opens is a list and a fix, not a dangerous act; the label and the
    // warning glyph carry the state.
    final variant = conflicts
        ? CcButtonVariant.secondary
        : switch (_readiness) {
            PrMergeReadiness.ready => CcButtonVariant.primary,
            PrMergeReadiness.pending => CcButtonVariant.secondary,
            PrMergeReadiness.blocked => CcButtonVariant.destructive,
          };

    return OverlayPortal(
      controller: _popupCtrl,
      overlayChildBuilder: _buildOverlay,
      child: CcButton(
        key: _buttonKey,
        onPressed: _toggle,
        size: CcButtonSize.sm,
        variant: variant,
        icon: conflicts ? AppIcons.alertTriangle : AppIcons.gitMerge,
        child: Text(conflicts ? l10n.mergeConflictsButton : l10n.merge),
      ),
    );
  }

  Widget _buildOverlay(BuildContext overlayCtx) {
    final tokens = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final offset = _overlayOffset ?? Offset.zero;

    // What the forge alone knows first (a conflict or a protection rule is
    // invisible in a check list), then what the local signals still add.
    final warnings = <String>[];
    switch (widget.pr.mergeableState) {
      case PrMergeableState.dirty:
        warnings.add(l10n.mergeConflictsWithBase);
      case PrMergeableState.behind:
        warnings.add(l10n.branchOutOfDateWithBase);
      case PrMergeableState.blocked:
        warnings.add(l10n.mergeBlockedByBranchProtection);
      case PrMergeableState.clean:
      case PrMergeableState.hasHooks:
      case PrMergeableState.unstable:
      case PrMergeableState.unknown:
      case PrMergeableState.unrecognized:
        break;
    }
    if (!_allChecksPass) {
      warnings.add(l10n.checksFailing);
    }
    if (!_reviewsSatisfied) {
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
                  child: _hasConflicts
                      ? MergeConflictsPanel(
                          pr: widget.pr,
                          prRef: widget.prRef,
                          onFixStarted: _close,
                        )
                      : MergeCommitForm(
                          method: _method,
                          onMethodChanged: (method) {
                            setState(() {
                              _method = method;
                              _prefillFields();
                            });
                          },
                          titleController: _titleCtrl,
                          descriptionController: _descCtrl,
                          warnings: warnings,
                          merging: _merging,
                          overrideMerge: _isOverrideMerge,
                          onMerge: _merge,
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
