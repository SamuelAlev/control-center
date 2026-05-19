import 'package:cc_domain/features/governance/domain/entities/work_product.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_text_styles.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The revision chips for one artifact, plus a restore action while an older
/// revision is selected.
///
/// Shared by every artifact surface (the sidebar panel, the artifact tab) so
/// history is browsed the same way wherever the artifact is opened — the
/// alternative is two pickers that drift on which end of the list is the head.
class ArtifactRevisionPicker extends StatelessWidget {
  /// Creates an [ArtifactRevisionPicker].
  const ArtifactRevisionPicker({
    super.key,
    required this.revisions,
    required this.selected,
    required this.isHead,
    required this.onSelect,
    required this.onRestore,
    this.padding = const EdgeInsets.fromLTRB(12, 8, 8, 0),
  });

  /// The full history, oldest first (the last entry is the head).
  final List<WorkProductRevision> revisions;

  /// The revision number currently rendered.
  final int selected;

  /// Whether [selected] is the head revision (restore is pointless if so).
  final bool isHead;

  /// Called with the revision number the operator picked.
  final ValueChanged<int> onSelect;

  /// Called to re-publish the selected revision as a new head.
  final VoidCallback onRestore;

  /// Outer padding, so a dense sidebar card and a full tab can share the widget.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveDesignTokens(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Text(
            l10n.artifactRevisionPickerLabel,
            style: AppTextStyles.labelSmall(
              tokens,
            ).copyWith(color: tokens.textTertiary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final r in revisions)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: CcButton(
                        variant: r.revisionNumber == selected
                            ? CcButtonVariant.secondary
                            : CcButtonVariant.ghost,
                        size: CcButtonSize.sm,
                        onPressed: () => onSelect(r.revisionNumber),
                        child: Text('${r.revisionNumber}'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!isHead)
            CcButton(
              variant: CcButtonVariant.ghost,
              size: CcButtonSize.sm,
              icon: AppIcons.undo2,
              onPressed: onRestore,
              child: Text(l10n.artifactRestoreRevision),
            ),
        ],
      ),
    );
  }
}
