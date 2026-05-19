import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// A labelled form field in the node config panel: the label, the control, and
/// an optional description under it.
///
/// Shared by the panel and the fields split out of it, so a control that moved
/// into its own file still reads as native beside the ones that did not.
class NodeFieldLabel extends StatelessWidget {
  /// Creates a [NodeFieldLabel].
  const NodeFieldLabel({
    super.key,
    required this.label,
    required this.child,
    this.description,
  });

  /// The field's name, shown above the control.
  final String label;

  /// The control itself.
  final Widget child;

  /// Optional explanation shown under the control.
  final String? description;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: ds.textPrimary, fontSize: 13)),
        const SizedBox(height: 6),
        child,
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: TextStyle(color: ds.textTertiary, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
