import 'package:cc_domain/features/pr_review/domain/entities/pr_label.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// A wrapping row of forge [PrLabel] chips.
class PrLabelWrap extends StatelessWidget {
  /// Creates a [PrLabelWrap].
  const PrLabelWrap({
    super.key,
    required this.labels,
    this.compact = false,
    this.spacing = 6,
    this.runSpacing = 6,
    this.onRemove,
    this.pendingNames = const {},
  });

  /// Labels to render, in forge order.
  final List<PrLabel> labels;

  /// Tighter chips for dense list rows and activity sentences.
  final bool compact;

  /// Gap between chips on one line.
  final double spacing;

  /// Gap between wrapped lines.
  final double runSpacing;

  /// When set, each chip shows a remove button. The argument is the name.
  final ValueChanged<String>? onRemove;

  /// Lowercased names whose add or remove is in flight.
  final Set<String> pendingNames;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = onRemove == null ? null : AppLocalizations.of(context);
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: [
        for (final label in labels)
          CcColorTag(
            label: label.name,
            color: label.color,
            tooltip: label.description.isEmpty ? null : label.description,
            compact: compact,
            onRemove: onRemove == null ? null : () => onRemove!(label.name),
            removing:
                onRemove != null &&
                pendingNames.contains(label.name.toLowerCase()),
            removeSemanticLabel: l10n?.removeLabel(label.name),
          ),
      ],
    );
  }
}
