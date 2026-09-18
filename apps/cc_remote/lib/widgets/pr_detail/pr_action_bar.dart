import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/pr_row.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// Bottom bar with comment field, approve/request/comment/merge buttons.
class PrActionBar extends StatelessWidget {
  const PrActionBar({
    super.key,
    required this.pr,
    required this.acting,
    required this.error,
    required this.notice,
    required this.commentController,
    required this.onSubmitReview,
    required this.onMerge,
  });

  final PullRequest pr;
  final bool acting;
  final String? error;
  final String? notice;
  final TextEditingController commentController;
  final void Function(String event, String success) onSubmitReview;
  final VoidCallback? onMerge;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final canAct = pr.isOpen && !acting;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.topbar,
        border: Border(top: BorderSide(color: t.borderSoft)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (error != null) ...[
              _Notice(text: error!, danger: true),
              const SizedBox(height: 8),
            ] else if (notice != null) ...[
              _Notice(text: notice!, danger: false),
              const SizedBox(height: 8),
            ],
            if (pr.isOpen) ...[
              CcTextArea(
                controller: commentController,
                minLines: 1,
                maxLines: 4,
                hintText: l10n.reviewCommentHint,
                enabled: !acting,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CcButton(
                      variant: CcButtonVariant.secondary,
                      size: CcButtonSize.sm,
                      icon: AppIcons.messageSquare,
                      onPressed: canAct
                          ? () => onSubmitReview('COMMENT', l10n.commentPosted)
                          : null,
                      child: Text(l10n.comment),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CcButton(
                      variant: CcButtonVariant.secondary,
                      size: CcButtonSize.sm,
                      icon: AppIcons.circleX,
                      onPressed: canAct
                          ? () => onSubmitReview(
                              'REQUEST_CHANGES',
                              l10n.changesRequested,
                            )
                          : null,
                      child: Text(l10n.request),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CcButton(
                      size: CcButtonSize.sm,
                      icon: AppIcons.check,
                      loading: acting,
                      onPressed: canAct
                          ? () => onSubmitReview('APPROVE', l10n.approved)
                          : null,
                      child: Text(l10n.approve),
                    ),
                  ),
                ],
              ),
              if (pr.canMerge) ...[
                const SizedBox(height: 8),
                CcButton(
                  fullWidth: true,
                  variant: CcButtonVariant.secondary,
                  size: CcButtonSize.sm,
                  icon: AppIcons.gitMerge,
                  onPressed: canAct ? onMerge : null,
                  child: Text(l10n.squashAndMerge),
                ),
              ],
            ] else
              Text(
                l10n.noActionsAvailable(prLifecycleLabel(l10n, pr)),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: t.textTertiary),
              ),
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.danger});

  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: danger ? t.dangerSoft : t.successSoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(
              danger ? AppIcons.triangleAlert : AppIcons.circleCheck,
              size: 14,
              color: danger ? t.textErrorPrimary : t.textSuccessPrimary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: t.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
