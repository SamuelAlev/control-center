import 'package:cc_domain/features/pr_review/domain/entities/pr_label.dart';
import 'package:cc_ui/cc_ui.dart';
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
  });

  /// Labels to render, in forge order.
  final List<PrLabel> labels;

  /// Tighter chips for dense list rows and activity sentences.
  final bool compact;

  /// Gap between chips on one line.
  final double spacing;

  /// Gap between wrapped lines.
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) {
      return const SizedBox.shrink();
    }
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
          ),
      ],
    );
  }
}
