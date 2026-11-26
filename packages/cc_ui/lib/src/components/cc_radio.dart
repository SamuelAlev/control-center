import 'package:cc_ui/src/components/cc_hit_target.dart';
import 'package:cc_ui/src/components/cc_roving_focus.dart';
import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:flutter/widgets.dart';

/// A flat 18px radio button for selecting one option of type [T] from a group.
///
/// Selected when [value] equals [groupValue]: the ring takes the accent color
/// and a filled accent dot is drawn via [CustomPaint]. Unselected shows a
/// hairline-bordered circle with a hover wash. Built on [CcTappable] for the
/// shared hover/press/focus treatment and keyboard activation, and announced
/// as a checked/unchecked radio in a mutually exclusive set. Outside a
/// [CcRadioGroup] the pointer target is 24px around the 18px circle where the
/// surrounding layout leaves room. Passing a null [onChanged] disables the
/// control.
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

  /// Optional external focus node. Inside a [CcRadioGroup] the group supplies
  /// one when this is null.
  final FocusNode? focusNode;

  /// Whether to autofocus on mount.
  final bool autofocus;

  static const double _size = 18;

  /// The pointer target of a radio standing on its own.
  static const double _target = 24;

  bool get _selected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final enabled = onChanged != null;
    final duration = CcMotion.resolveFade(context, CcMotion.fast);
    final group = _CcRadioGroupScope.maybeOf<T>(context);

    final Widget radio = CcTappable(
      // Keep the control focusable while selected (a selected radio is the
      // group's natural keyboard stop); tapping an already-selected radio is a
      // no-op rather than disabling the control.
      onPressed: enabled
          ? () {
              if (!_selected) onChanged!(value);
            }
          : null,
      focusNode: focusNode ?? group?.nodeFor(value),
      autofocus: autofocus,
      semanticLabel: semanticLabel,
      semanticButton: false,
      semanticChecked: _selected,
      semanticInMutuallyExclusiveGroup: true,
      canRequestFocus: enabled,
      borderRadius: const BorderRadius.all(Radius.circular(_size / 2)),
      // Clear of the circle, whose selected border is the ring's own accent:
      // around the 24px target on its own, 2px out inside a stacked group.
      focusRingOffset: group == null ? (_target - _size) / 2 : 2,
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
          final wash = pressed
              ? t.hoverStrong
              : hovered
              ? t.hover
              : null;
          fillColor = wash == null
              ? t.surface
              : Color.alphaBlend(wash, t.surface);
        }

        final dotColor = enabled ? t.accent : t.fgDisabled;

        return Opacity(
          opacity: enabled ? 1 : 0.6,
          child: AnimatedContainer(
            duration: duration,
            curve: CcMotion.standard,
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
    // Radios in a group sit edge to edge, so a larger target would take
    // presses meant for the neighbour.
    if (group != null) {
      return radio;
    }
    return CcHitTarget(minSize: const Size.square(_target), child: radio);
  }
}

/// A keyboard-navigable group of [CcRadio]s sharing one [groupValue].
///
/// The group is a single Tab stop: Tab lands on the selected radio (or the
/// first enabled one when nothing is selected) and the next Tab leaves the
/// group. `↑`/`↓` and `←`/`→` (mirrored under RTL) move focus and selection
/// together to the adjacent enabled radio, starting from the focused one and
/// wrapping at the ends; `Home`/`End` go to the first and last. Each child
/// [CcRadio] should be built with this group's [groupValue] and [onChanged];
/// the group gives each one a focus node unless it brings its own.
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
  /// When null, the moved-to radio's own [CcRadio.onChanged] is called.
  final ValueChanged<T>? onChanged;

  /// The radios in the group, in display/traversal order.
  final List<CcRadio<T>> children;

  @override
  State<CcRadioGroup<T>> createState() => _CcRadioGroupState<T>();
}

class _CcRadioGroupState<T> extends State<CcRadioGroup<T>> {
  final Map<T, FocusNode> _nodes = {};

  FocusNode _nodeFor(T value) =>
      _nodes.putIfAbsent(value, () => FocusNode(debugLabel: 'CcRadio $value'));

  FocusNode _nodeOf(CcRadio<T> radio) =>
      radio.focusNode ?? _nodeFor(radio.value);

  @override
  void didUpdateWidget(covariant CcRadioGroup<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final values = {for (final radio in widget.children) radio.value};
    final gone = [
      for (final entry in _nodes.entries)
        if (!values.contains(entry.key)) entry.key,
    ];
    if (gone.isEmpty) {
      return;
    }
    final removed = [for (final value in gone) _nodes.remove(value)!];
    // The removed radios still hold their nodes until the coming rebuild
    // drops them.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final node in removed) {
        node.dispose();
      }
    });
  }

  @override
  void dispose() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final children = widget.children;
    final focused = children.indexWhere((r) => _nodeOf(r).hasFocus);
    final target = ccRovingTarget(
      event: event,
      current: focused >= 0
          ? focused
          : children.indexWhere((r) => r.value == widget.groupValue),
      count: children.length,
      rtl: Directionality.of(context) == TextDirection.rtl,
      vertical: true,
      isEnabled: (index) => children[index].onChanged != null,
    );
    if (target == null) {
      return KeyEventResult.ignored;
    }
    final radio = children[target];
    _nodeOf(radio).requestFocus();
    if (radio.value != widget.groupValue) {
      (widget.onChanged ?? radio.onChanged)?.call(radio.value);
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final children = widget.children;
    bool enabled(CcRadio<T> radio) => radio.onChanged != null;
    final selected = children.indexWhere(
      (r) => r.value == widget.groupValue && enabled(r),
    );
    final stop = selected >= 0 ? selected : children.indexWhere(enabled);
    for (var i = 0; i < children.length; i++) {
      _nodeOf(children[i]).skipTraversal = i != stop;
    }
    return _CcRadioGroupScope<T>(
      nodeFor: _nodeFor,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}

/// Hands the radios of a [CcRadioGroup] the focus nodes the group moves
/// between.
class _CcRadioGroupScope<T> extends InheritedWidget {
  const _CcRadioGroupScope({required this.nodeFor, required super.child});

  final FocusNode Function(T value) nodeFor;

  static _CcRadioGroupScope<T>? maybeOf<T>(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_CcRadioGroupScope<T>>();

  @override
  bool updateShouldNotify(_CcRadioGroupScope<T> oldWidget) =>
      nodeFor != oldWidget.nodeFor;
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
