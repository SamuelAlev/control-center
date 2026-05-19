import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A flat 18px radio button for selecting one option of type [T] from a group.
///
/// Selected when [value] equals [groupValue]: the ring takes the accent color
/// and a filled accent dot is drawn via [CustomPaint]. Unselected shows a
/// hairline-bordered circle with a hover wash. Built on [CcTappable] for the
/// shared hover/press/focus treatment and keyboard activation. Passing a null
/// [onChanged] disables the control.
class CcRadio<T> extends StatelessWidget {
  /// Creates a [CcRadio].
  const CcRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  });

  /// The value this radio represents.
  final T value;

  /// The currently selected value in the group. Selected when it equals
  /// [value].
  final T? groupValue;

  /// Called with [value] when this radio is tapped while unselected. Null
  /// disables the radio.
  final ValueChanged<T>? onChanged;

  /// Optional accessibility label.
  final String? semanticLabel;

  /// Optional external focus node.
  final FocusNode? focusNode;

  /// Whether to autofocus on mount.
  final bool autofocus;

  static const double _size = 18;

  bool get _selected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final enabled = onChanged != null;
    final duration = CcMotion.resolve(context, CcMotion.fast);

    return CcTappable(
      // Keep the control focusable while selected (a selected radio is the
      // group's natural keyboard stop); tapping an already-selected radio is a
      // no-op rather than disabling the control.
      onPressed: enabled
          ? () {
              if (!_selected) onChanged!(value);
            }
          : null,
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: semanticLabel,
      canRequestFocus: enabled,
      borderRadius: const BorderRadius.all(Radius.circular(_size / 2)),
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final pressed = states.contains(WidgetState.pressed);

        Color fillColor;
        Color borderColor;
        if (_selected) {
          borderColor = enabled ? t.accent : t.borderDisabled;
          fillColor = t.surface;
        } else {
          borderColor = enabled ? t.borderPrimary : t.borderDisabled;
          fillColor = pressed
              ? t.hoverStrong
              : hovered
              ? t.hover
              : t.surface;
        }

        final dotColor = enabled ? t.accent : t.fgDisabled;

        return Opacity(
          opacity: enabled ? 1 : 0.6,
          child: Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              color: fillColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor),
            ),
            child: AnimatedOpacity(
              opacity: _selected ? 1 : 0,
              duration: duration,
              curve: CcMotion.standard,
              child: CustomPaint(
                painter: _DotPainter(color: dotColor),
                size: const Size(_size, _size),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A keyboard-navigable group of [CcRadio]s sharing one [groupValue].
///
/// Wraps [children] in a focus scope so `Tab` enters the group and `↑`/`↓`/
/// `←`/`→` move the selection to the adjacent enabled radio (calling
/// [onChanged]), matching the WAI-ARIA radiogroup keyboard model. Each child
/// [CcRadio] should be built with this group's [groupValue] and [onChanged].
/// The selected radio stays focusable (see [CcRadio]).
class CcRadioGroup<T> extends StatefulWidget {
  /// Creates a [CcRadioGroup] over [children], which should be [CcRadio]s
  /// sharing this group's [groupValue] and [onChanged].
  const CcRadioGroup({
    super.key,
    required this.groupValue,
    required this.onChanged,
    required this.children,
  });

  /// The currently selected value in the group (selected when a child's value
  /// equals it).
  final T? groupValue;

  /// Called with the newly-selected value when an arrow key moves selection.
  final ValueChanged<T>? onChanged;

  /// The radios in the group, in display/traversal order.
  final List<CcRadio<T>> children;

  @override
  State<CcRadioGroup<T>> createState() => _CcRadioGroupState<T>();
}

class _CcRadioGroupState<T> extends State<CcRadioGroup<T>> {
  final FocusScopeNode _scope = FocusScopeNode(
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final children = widget.children;
    if (children.isEmpty) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final isNext =
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowRight;
    final isPrev =
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowLeft;
    if (!isNext && !isPrev) {
      return KeyEventResult.ignored;
    }
    // Walk from the currently-selected radio to the next enabled, different one.
    final current = children.indexWhere((r) => r.value == widget.groupValue);
    var idx = current < 0 ? (isNext ? -1 : 0) : current;
    for (var step = 0; step < children.length; step++) {
      idx = isNext
          ? (idx + 1) % children.length
          : (idx - 1 + children.length) % children.length;
      final radio = children[idx];
      if (radio.onChanged != null && radio.value != widget.groupValue) {
        widget.onChanged?.call(radio.value);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: _scope,
      child: Focus(
        canRequestFocus: false,
        onKeyEvent: _onKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: widget.children,
        ),
      ),
    );
  }
}

class _DotPainter extends CustomPainter {
  const _DotPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.width * 0.28, paint);
  }

  @override
  bool shouldRepaint(_DotPainter oldDelegate) => oldDelegate.color != color;
}
