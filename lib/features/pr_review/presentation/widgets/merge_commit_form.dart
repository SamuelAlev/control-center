import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// How a pull request is merged.
enum PrMergeMethod {
  /// Squash the branch into one commit.
  squash,

  /// A merge commit.
  merge,

  /// Replay the commits onto the base.
  rebase,
}

/// The commit-message form inside the merge flyout.
class MergeCommitForm extends StatelessWidget {
  /// Creates a [MergeCommitForm].
  const MergeCommitForm({
    super.key,
    required this.method,
    required this.onMethodChanged,
    required this.titleController,
    required this.descriptionController,
    required this.warnings,
    required this.merging,
    required this.overrideMerge,
    required this.onMerge,
  });

  /// The selected merge method.
  final PrMergeMethod method;

  /// Called when the operator picks another method.
  final ValueChanged<PrMergeMethod> onMethodChanged;

  /// Squash or merge commit title.
  final TextEditingController titleController;

  /// Squash or merge commit body.
  final TextEditingController descriptionController;

  /// Reasons the merge is not clean, already worded for display.
  final List<String> warnings;

  /// A merge request is in flight.
  final bool merging;

  /// The confirm button overrides the forge and is labeled as a force merge.
  final bool overrideMerge;

  /// Starts the merge.
  final VoidCallback onMerge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem!;
    final showFields = method != PrMergeMethod.rebase;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.mergePullRequest,
          style: CcTypography.body.copyWith(
            fontWeight: FontWeight.w700,
            color: tokens.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        CcSegmentedToggle<PrMergeMethod>(
          fullWidth: true,
          semanticLabel: l10n.mergeMethod,
          value: method,
          onChanged: onMethodChanged,
          segments: [
            CcSegment(value: PrMergeMethod.squash, label: l10n.squashAndMerge),
            CcSegment(
              value: PrMergeMethod.merge,
              label: l10n.createMergeCommit,
            ),
            CcSegment(value: PrMergeMethod.rebase, label: l10n.rebaseAndMerge),
          ],
        ),
        const SizedBox(height: 10),
        if (showFields) ...[
          _field(
            controller: titleController,
            hintText: l10n.commitTitle,
            tokens: tokens,
          ),
          const SizedBox(height: 8),
          _field(
            controller: descriptionController,
            hintText: l10n.commitDescription,
            tokens: tokens,
            maxLines: 4,
          ),
          const SizedBox(height: 12),
        ],
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
              children: [
                for (final warning in warnings)
                  Row(
                    children: [
                      Icon(
                        AppIcons.alertTriangle,
                        size: 14,
                        color: tokens.fgWarningPrimary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          warning,
                          style: CcTypography.caption
                              .copyWith(color: tokens.textTertiary)
                              .copyWith(color: tokens.textErrorPrimary),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: CcButton(
            onPressed: merging ? null : onMerge,
            fullWidth: true,
            variant: overrideMerge
                ? CcButtonVariant.destructive
                : CcButtonVariant.primary,
            child: merging
                ? CcSpinner(size: 16, color: tokens.textWhite)
                : Text(
                    overrideMerge
                        ? l10n.forceMergePullRequest
                        : l10n.mergePullRequest,
                  ),
          ),
        ),
      ],
    );
  }
}

Widget _field({
  required TextEditingController controller,
  required String hintText,
  required DesignSystemTokens tokens,
  int maxLines = 1,
}) {
  return Container(
    decoration: BoxDecoration(
      color: tokens.bgSecondary,
      borderRadius: BorderRadius.circular(2),
      border: Border.all(color: tokens.borderSecondary),
    ),
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
    child: CcTextField(
      controller: controller,
      maxLines: maxLines,
      textStyle: CcTypography.body.copyWith(color: tokens.textPrimary),
      hintText: hintText,
      chromeless: true,
    ),
  );
}
