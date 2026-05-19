import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

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
    // Use alpha-0 versions of the visible colors (not transparent-black) so
    // AnimatedContainer lerps only alpha, never RGB toward (0,0,0). Lerping
    // to Color(0x00000000) flashes dark gray for 1–2 frames.
    final Color background;
    final Color border;
    if (widget.selected) {
      background = t.bgPrimary;
      border = t.borderSecondary;
    } else if (_hovered) {
      background = t.bgPrimaryHover;
      border = t.borderSecondary.withValues(alpha: 0);
    } else {
      background = t.bgPrimaryHover.withValues(alpha: 0);
      border = t.borderSecondary.withValues(alpha: 0);
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
          // No explicit font family — Text merges this with the ambient
          // DefaultTextStyle, inheriting the app font.
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.selected ? t.textPrimary : t.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
