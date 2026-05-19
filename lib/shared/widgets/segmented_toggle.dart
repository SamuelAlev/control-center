import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:flutter/material.dart';

/// A single option in a [SegmentedToggle].
typedef SegmentedOption<T> = ({T value, String label});

/// A connected segmented control: a bordered track holding adjoining segments,
/// the active one raised with a subtle fill and border. Mirrors the PR-list
/// sort toggle (Recent / Oldest / Largest) and is styled from the design-system
/// tokens so it reads correctly in both themes.
///
/// Use it for binary or small N-way mode toggles (e.g. Write / Preview).
class SegmentedToggle<T> extends StatelessWidget {
  /// Creates a [SegmentedToggle].
  const SegmentedToggle({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
  });

  /// The selectable segments, in display order.
  final List<SegmentedOption<T>> segments;

  /// The currently-selected segment value.
  final T value;

  /// Called with a segment's value when it is tapped.
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: t.bgSecondary,
        borderRadius: AppRadii.brMd,
        border: Border.all(color: t.borderSecondary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final s in segments)
            _Segment(
              label: s.label,
              selected: s.value == value,
              tokens: t,
              onTap: () => onChanged(s.value),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatefulWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.tokens,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final DesignSystemTokens tokens;
  final VoidCallback onTap;

  @override
  State<_Segment> createState() => _SegmentState();
}

class _SegmentState extends State<_Segment> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    final Color background;
    final Color border;
    if (widget.selected) {
      background = t.bgPrimary;
      border = t.borderSecondary;
    } else if (_hovered) {
      background = t.bgPrimaryHover;
      border = Colors.transparent;
    } else {
      background = Colors.transparent;
      border = Colors.transparent;
    }
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.selected ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppRadii.brSm,
            border: Border.all(color: border),
          ),
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: widget.selected ? t.textPrimary : t.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
