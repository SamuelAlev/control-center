import 'package:cc_ui/src/foundation/cc_fluid_hover.dart';
import 'package:cc_ui/src/foundation/cc_focus_keeper.dart';
import 'package:cc_ui/src/primitives/focus_ring.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Builds a tappable's visual given its current interaction [states].
typedef CcTappableStateBuilder =
    Widget Function(BuildContext context, Set<WidgetState> states);

/// The shared interaction primitive for cc_ui — a flat, ripple-free replacement
/// for Material's `InkWell`.
///
/// Composes pointer (tap/press + hover), keyboard (focus + Enter/Space
/// activation) and the keyboard-only [FocusRing] into a single
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
    this.borderRadius = BorderRadius.zero,
    this.focusRingColor,
    this.focusRingOffset = 0,
    this.showFocusRing = true,
    this.semanticLabel,
    this.semanticButton = true,
    this.canRequestFocus = true,
    this.requestFocusOnTap = true,
    this.focusableWhenDisabled = false,
    this.statesController,
    this.shortcuts,
    this.semanticSelected,
    this.semanticChecked,
    this.semanticMixed,
    this.semanticToggled,
    this.semanticExpanded,
    this.semanticInMutuallyExclusiveGroup,
    this.semanticValue,
    this.semanticHint,
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

  /// Gap between the child and the focus ring. Zero paints the ring on the
  /// child's outer edge; a positive value paints it outside with that much
  /// clear space (CSS `outline-offset` style).
  final double focusRingOffset;

  /// Whether to draw the keyboard focus ring.
  final bool showFocusRing;

  /// Accessibility label.
  final String? semanticLabel;

  /// Whether to expose this as a semantic button.
  final bool semanticButton;

  /// Whether the tappable can take focus.
  final bool canRequestFocus;

  /// Whether a click or tap moves keyboard focus here, so the next Tab starts
  /// from the control the person just used. Focus stays put while it sits in
  /// a text input or under a [CcFocusKeeper]. Has no effect when
  /// [canRequestFocus] is false.
  final bool requestFocusOnTap;

  /// Whether the tappable stays a focus target while it has no handler. A
  /// control that is briefly busy (a button showing its loading state) sets
  /// this so focus is not thrown off it; activation is still refused.
  final bool focusableWhenDisabled;

  /// Selected state for assistive technology (a tab, a nav row, a chip).
  final bool? semanticSelected;

  /// Checked state for assistive technology (a checkbox, a radio).
  final bool? semanticChecked;

  /// Mixed (indeterminate) state for assistive technology. Mutually exclusive
  /// with a true [semanticChecked].
  final bool? semanticMixed;

  /// On/off state for assistive technology (a switch).
  final bool? semanticToggled;

  /// Expanded state for assistive technology (a disclosure header, a trigger
  /// that owns a popup).
  final bool? semanticExpanded;

  /// Whether this is one of a set where only one can be chosen (a radio, a
  /// segment).
  final bool? semanticInMutuallyExclusiveGroup;

  /// Current value for assistive technology (a dropdown's selection).
  final String? semanticValue;

  /// Extra description for assistive technology.
  final String? semanticHint;

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

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocus ??= FocusNode());

  /// The controller [_resolve] currently listens to.
  WidgetStatesController? _listenedStates;

  /// The enclosing [CcFluidHover] group's pointer-inside flag, when an item
  /// scope is above this tappable.
  ValueListenable<bool>? _fluidPointer;

  /// Whether the enclosing group owns this tappable's hover (see
  /// [CcFluidHover.controlsTappable]), and whether it picked this item.
  bool _fluidControlled = false;
  bool _fluidActive = false;

  /// The states [CcTappable.builder] last painted, and the signal that they
  /// changed. The builder re-runs only when this resolved set changes: a raw
  /// hover change the group overrides, or the pointer crossing into a group
  /// while this row is not the one it picks, repaints nothing.
  Set<WidgetState> _visible = const <WidgetState>{};
  final _StatesChanged _visibleChanged = _StatesChanged();

  late final Map<Type, Action<Intent>> _actions = {
    ActivateIntent: _ActivateAction(this),
  };

  // A held key activates once, not on every repeat.
  static const Map<ShortcutActivator, Intent> _defaultShortcuts = {
    SingleActivator(LogicalKeyboardKey.enter, includeRepeats: false):
        ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.numpadEnter, includeRepeats: false):
        ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.space, includeRepeats: false):
        ActivateIntent(),
  };

  @override
  void initState() {
    super.initState();
    _bindStates();
    _states.update(WidgetState.disabled, !widget.enabled);
  }

  @override
  void didUpdateWidget(CcTappable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _bindStates();
    _states.update(WidgetState.disabled, !widget.enabled);
  }

  @override
  void dispose() {
    _listenedStates?.removeListener(_resolve);
    _fluidPointer?.removeListener(_resolve);
    _visibleChanged.dispose();
    _internalStates?.dispose();
    _internalFocus?.dispose();
    super.dispose();
  }

  void _bindStates() {
    final next = _states;
    if (identical(next, _listenedStates)) {
      return;
    }
    _listenedStates?.removeListener(_resolve);
    _listenedStates = next..addListener(_resolve);
  }

  void _bindFluidPointer(ValueListenable<bool>? next) {
    if (identical(next, _fluidPointer)) {
      return;
    }
    _fluidPointer?.removeListener(_resolve);
    _fluidPointer = next?..addListener(_resolve);
  }

  /// Inside a fluid group with the pointer in it, hover is the group's pick,
  /// not this row's own [MouseRegion]: the nearest row washes even while the
  /// pointer sits in a gap.
  Set<WidgetState> _compute() {
    final states = Set<WidgetState>.of(_states.value);
    if (_fluidControlled && (_fluidPointer?.value ?? false)) {
      states.remove(WidgetState.hovered);
      if (_fluidActive) {
        states.add(WidgetState.hovered);
      }
    }
    return states;
  }

  void _resolve() {
    final next = _compute();
    if (setEquals(next, _visible)) {
      return;
    }
    _visible = next;
    _visibleChanged.notify();
  }

  void _activate() {
    if (!widget.enabled) {
      return;
    }
    widget.onPressed?.call();
  }

  /// The defaults with [extra] laid over them. An entry of [extra] replaces
  /// the default bound to the same key, whatever its repeat setting.
  static Map<ShortcutActivator, Intent> _mergedShortcuts(
    Map<ShortcutActivator, Intent>? extra,
  ) {
    if (extra == null) {
      return _defaultShortcuts;
    }
    final overridden = <LogicalKeyboardKey>{
      for (final activator in extra.keys)
        if (activator is SingleActivator) activator.trigger,
    };
    return {
      for (final entry in _defaultShortcuts.entries)
        if (!overridden.contains((entry.key as SingleActivator).trigger))
          entry.key: entry.value,
      ...extra,
    };
  }

  /// A held activation key activates once. The repeats are consumed here so
  /// they reach neither this tappable's shortcuts nor the app-level ones that
  /// map the same keys to [ActivateIntent].
  KeyEventResult _swallowActivationRepeat(FocusNode node, KeyEvent event) {
    if (event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final activates =
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space;
    return activates ? KeyEventResult.handled : KeyEventResult.ignored;
  }

  /// A pointer activation: take focus first, so Tab continues from here and
  /// a surface this opens can hand focus back when it closes.
  void _handleTap() {
    if (widget.requestFocusOnTap &&
        widget.canRequestFocus &&
        !_focusNode.hasPrimaryFocus &&
        !CcFocusKeeper.holds(FocusManager.instance.primaryFocus)) {
      _focusNode.requestFocus();
    }
    _activate();
  }

  void _setPressed(bool pressed) {
    if (widget.enabled) {
      _states.update(WidgetState.pressed, pressed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    final focusable =
        widget.canRequestFocus && (enabled || widget.focusableWhenDisabled);
    final fluidControlled = CcFluidHover.controlsTappable(context);
    // Both read the item scope, which notifies only when THIS item's active
    // state changes — the pointer entering or leaving the group arrives
    // through the listenable instead, so it does not rebuild every row.
    _fluidControlled = fluidControlled;
    _fluidActive = CcFluidHover.isItemActive(context);
    _bindFluidPointer(CcFluidHover.pointerInsideOf(context));
    _visible = _compute();
    Widget child = ListenableBuilder(
      listenable: _visibleChanged,
      builder: (context, _) => widget.builder(context, _visible),
    );

    child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? _handleTap : null,
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
      canRequestFocus: focusable,
      onKeyEvent: _swallowActivationRepeat,
      onFocusChange: (focused) => _states.update(WidgetState.focused, focused),
      child: child,
    );
    child = Actions(actions: _actions, child: child);
    child = Shortcuts(
      shortcuts: _mergedShortcuts(widget.shortcuts),
      child: child,
    );

    if (widget.showFocusRing) {
      child = FocusRing(
        focusNode: _focusNode,
        borderRadius: widget.borderRadius,
        color: widget.focusRingColor,
        offset: widget.focusRingOffset,
        enabled: focusable,
        child: child,
      );
    }

    child = MouseRegion(
      cursor: enabled
          ? (widget.mouseCursor ?? SystemMouseCursors.click)
          : SystemMouseCursors.basic,
      onEnter: enabled
          ? (_) => _states.update(WidgetState.hovered, true)
          : null,
      onExit: enabled
          ? (_) => _states.update(WidgetState.hovered, false)
          : null,
      child: child,
    );

    if (fluidControlled) {
      child = CcFluidHover.consumeTappable(child);
    }

    return Semantics(
      button: widget.semanticButton,
      enabled: enabled,
      label: widget.semanticLabel,
      value: widget.semanticValue,
      hint: widget.semanticHint,
      selected: widget.semanticSelected,
      checked: widget.semanticChecked,
      mixed: widget.semanticMixed,
      toggled: widget.semanticToggled,
      expanded: widget.semanticExpanded,
      inMutuallyExclusiveGroup: widget.semanticInMutuallyExclusiveGroup,
      container: true,
      child: child,
    );
  }
}

/// Enter/Space on the tappable. Claims the key only while the tappable can
/// act, or is busy and holding focus on purpose; a plainly disabled one lets
/// the key go on to whoever else wants it.
class _ActivateAction extends Action<ActivateIntent> {
  _ActivateAction(this._state);

  final _CcTappableState _state;

  @override
  bool isEnabled(ActivateIntent intent) =>
      _state.widget.enabled || _state.widget.focusableWhenDisabled;

  @override
  Object? invoke(ActivateIntent intent) {
    _state._activate();
    return null;
  }
}

/// Lets the tappable signal its resolved states changed.
class _StatesChanged extends ChangeNotifier {
  void notify() => notifyListeners();
}
