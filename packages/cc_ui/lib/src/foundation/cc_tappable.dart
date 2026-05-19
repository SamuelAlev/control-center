import 'package:cc_ui/src/primitives/focus_ring.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Builds a tappable's visual given its current interaction [states].
typedef CcTappableStateBuilder = Widget Function(
  BuildContext context,
  Set<WidgetState> states,
);

/// The shared interaction primitive for cc_ui — a flat, ripple-free replacement
/// for Material's `InkWell`.
///
/// Composes pointer (tap/press + hover), keyboard (focus + Enter/Space
/// activation), and the keyboard-only [FocusRing] into a single
/// [WidgetStatesController], then hands the live state set to [builder] so a
/// component can paint its own hover/pressed/focused/disabled treatment. There
/// is no ink ripple — the design system is flat and reports state through color
/// washes instead.
class CcTappable extends StatefulWidget {
  /// Creates a [CcTappable].
  const CcTappable({
    super.key,
    required this.builder,
    this.onPressed,
    this.onLongPress,
    this.focusNode,
    this.autofocus = false,
    this.mouseCursor,
    this.borderRadius = const BorderRadius.all(Radius.circular(2)),
    this.focusRingColor,
    this.showFocusRing = true,
    this.semanticLabel,
    this.semanticButton = true,
    this.canRequestFocus = true,
    this.statesController,
    this.shortcuts,
  });

  /// Paints the child for the current interaction states.
  final CcTappableStateBuilder builder;

  /// Tap handler. When both this and [onLongPress] are null the tappable is
  /// disabled (and reports [WidgetState.disabled]).
  final VoidCallback? onPressed;

  /// Long-press handler.
  final VoidCallback? onLongPress;

  /// Optional external focus node.
  final FocusNode? focusNode;

  /// Whether to autofocus on mount.
  final bool autofocus;

  /// Cursor when enabled and hovered (defaults to a click cursor).
  final MouseCursor? mouseCursor;

  /// Corner radius for the focus ring (match the child's own radius).
  final BorderRadius borderRadius;

  /// Focus-ring color; defaults to the design system `focusRing` token.
  final Color? focusRingColor;

  /// Whether to draw the keyboard focus ring.
  final bool showFocusRing;

  /// Accessibility label.
  final String? semanticLabel;

  /// Whether to expose this as a semantic button.
  final bool semanticButton;

  /// Whether the tappable can take focus.
  final bool canRequestFocus;

  /// Optional external states controller (e.g. shared with a component).
  final WidgetStatesController? statesController;

  /// Extra keyboard shortcuts, merged over the default Enter/Space→activate map
  /// (same-activator entries override the defaults — e.g. to free Space).
  final Map<ShortcutActivator, Intent>? shortcuts;

  /// Whether the tappable is interactive.
  bool get enabled => onPressed != null || onLongPress != null;

  @override
  State<CcTappable> createState() => _CcTappableState();
}

class _CcTappableState extends State<CcTappable> {
  WidgetStatesController? _internalStates;
  FocusNode? _internalFocus;

  WidgetStatesController get _states =>
      widget.statesController ?? (_internalStates ??= WidgetStatesController());

  FocusNode get _focusNode => widget.focusNode ?? (_internalFocus ??= FocusNode());

  late final Map<Type, Action<Intent>> _actions = {
    ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
      _activate();
      return null;
    }),
  };

  static const Map<ShortcutActivator, Intent> _defaultShortcuts = {
    SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
  };

  @override
  void initState() {
    super.initState();
    _states.update(WidgetState.disabled, !widget.enabled);
  }

  @override
  void didUpdateWidget(CcTappable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _states.update(WidgetState.disabled, !widget.enabled);
  }

  @override
  void dispose() {
    _internalStates?.dispose();
    _internalFocus?.dispose();
    super.dispose();
  }

  void _activate() {
    if (!widget.enabled) {
      return;
    }
    widget.onPressed?.call();
  }

  void _setPressed(bool pressed) {
    if (widget.enabled) {
      _states.update(WidgetState.pressed, pressed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;

    Widget child = ListenableBuilder(
      listenable: _states,
      builder: (context, _) => widget.builder(context, _states.value),
    );

    child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? _activate : null,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      onLongPress: enabled ? widget.onLongPress : null,
      child: child,
    );

    // Focus + keyboard activation. Hover is handled by an explicit MouseRegion
    // (below) rather than FocusableActionDetector so the state is deterministic.
    child = Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      canRequestFocus: enabled && widget.canRequestFocus,
      onFocusChange: (focused) => _states.update(WidgetState.focused, focused),
      child: child,
    );
    child = Actions(actions: _actions, child: child);
    child = Shortcuts(
      shortcuts: widget.shortcuts == null
          ? _defaultShortcuts
          : {..._defaultShortcuts, ...widget.shortcuts!},
      child: child,
    );

    if (widget.showFocusRing) {
      child = FocusRing(
        focusNode: _focusNode,
        borderRadius: widget.borderRadius,
        color: widget.focusRingColor,
        enabled: enabled,
        child: child,
      );
    }

    child = MouseRegion(
      cursor: enabled
          ? (widget.mouseCursor ?? SystemMouseCursors.click)
          : SystemMouseCursors.basic,
      onEnter: enabled ? (_) => _states.update(WidgetState.hovered, true) : null,
      onExit: enabled ? (_) => _states.update(WidgetState.hovered, false) : null,
      child: child,
    );

    return Semantics(
      button: widget.semanticButton,
      enabled: enabled,
      label: widget.semanticLabel,
      container: true,
      child: child,
    );
  }
}
