import 'package:cc_domain/features/pr_review/domain/entities/pr_label.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/hover_focus_reveal.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
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

  /// When set, each chip reveals a remove control. The argument is the name.
  final ValueChanged<String>? onRemove;

  /// Lowercased names whose add or remove is in flight.
  final Set<String> pendingNames;

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
          onRemove == null
              ? CcColorTag(
                  label: label.name,
                  color: label.color,
                  tooltip: label.description.isEmpty ? null : label.description,
                  compact: compact,
                )
              : _RemovableLabelChip(
                  label: label,
                  compact: compact,
                  pending: pendingNames.contains(label.name.toLowerCase()),
                  onRemove: () => onRemove!(label.name),
                ),
      ],
    );
  }
}

class _RemovableLabelChip extends StatefulWidget {
  const _RemovableLabelChip({
    required this.label,
    required this.compact,
    required this.pending,
    required this.onRemove,
  });

  final PrLabel label;
  final bool compact;
  final bool pending;
  final VoidCallback onRemove;

  @override
  State<_RemovableLabelChip> createState() => _RemovableLabelChipState();
}

class _RemovableLabelChipState extends State<_RemovableLabelChip> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // The remove button stays mounted (transparent at rest) so Tab and screen
    // readers reach it, not only the mouse.
    return HoverFocusReveal(
      builder: (context, revealed) => CcColorTag(
        label: widget.label.name,
        color: widget.label.color,
        tooltip: widget.label.description.isEmpty
            ? null
            : widget.label.description,
        compact: widget.compact,
        trailing: SizedBox(
          width: 14,
          height: 14,
          child: widget.pending
              ? const Center(child: CcSpinner(size: 10))
              : HoverFocusReveal.fade(
                  revealed: revealed,
                  child: CcTappable(
                    onPressed: widget.onRemove,
                    semanticLabel: l10n.removeLabel(widget.label.name),
                    borderRadius: AppRadii.brSm,
                    builder: (context, states) =>
                        const Icon(AppIcons.x, size: 12),
                  ),
                ),
        ),
      ),
    );
  }
}
