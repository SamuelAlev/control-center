import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Asks why a finding is being dismissed.
///
/// The reason is not ceremony. It becomes the suppression fact that future
/// reviewers read and that the finalizer matches new findings against, so a
/// dismissal without one hides a row and teaches nothing — the pattern comes
/// back on the next pull request.
///
/// Returns the reason, or null when the person backed out. An empty string is
/// a deliberate answer ("no reason given") and still dismisses.
Future<String?> promptForDismissalReason(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController();
  try {
    return await showCcDialog<String>(
      context: context,
      builder: (dialogContext) => CcDialog(
        title: l10n.reviewFindingDismissTitle,
        onClose: () => Navigator.pop(dialogContext),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.reviewFindingDismissHint,
              style: CcTypography.bodySm.copyWith(
                color: context.designSystem?.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            CcTextField(
              controller: controller,
              autofocus: true,
              maxLines: 3,
              minLines: 2,
              hintText: l10n.reviewFindingDismissReasonHint,
              onSubmitted: (value) =>
                  Navigator.pop(dialogContext, value.trim()),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CcButton(
                  variant: CcButtonVariant.ghost,
                  size: CcButtonSize.sm,
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: AppSpacing.sm),
                CcButton(
                  size: CcButtonSize.sm,
                  onPressed: () =>
                      Navigator.pop(dialogContext, controller.text.trim()),
                  child: Text(l10n.reviewFindingDismiss),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  } finally {
    controller.dispose();
  }
}
