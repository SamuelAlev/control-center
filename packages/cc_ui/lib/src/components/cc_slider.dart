import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A flat horizontal slider for a continuous or stepped value.
///
/// A pill-capped track ([DesignSystemTokens.bgTertiary]) whose leading portion
/// fills with the accent color up to [value], with a circular thumb riding the
/// boundary. Per DESIGN.md the thumb is a panel-filled disc closed by a 2px
/// accent ring — depth comes from the border, never a shadow.
///
/// Purist replacement for Material's `Slider`: built on
/// `package:flutter/widgets.dart` only, so it needs no `Material` ancestor and
/// works inside off-Material overlays (`showCcDialog`, toasts, sub-windows)
/// where Material's slider throws.
///
/// Pass [divisions] to snap to evenly spaced stops. Drag, click-to-position,
/// and the keyboard all work: arrow keys step by one division (or 1% of the
/// range when continuous), Home/End jump to [min]/[max]. A null [onChanged]
/// disables the control. The thumb position is not animated — it tracks the
/// pointer exactly, so there is nothing to suppress under reduced motion.
class CcSlider extends StatefulWidget {
  /// Creates a [CcSlider].
  const CcSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.semanticLabel,
    this.semanticFormatter,
    this.focusNode,
    this.autofocus = false,
  }) : assert(min < max, 'CcSlider requires min < max'),
       assert(
         divisions == null || divisions > 0,
         'CcSlider divisions must be positive',
       );

  /// The current value, clamped into `[min, max]` for display.
  final double value;

  /// Called with the new value as the user drags, clicks, or presses a key.
  /// Null disables the slider.
  final ValueChanged<double>? onChanged;

  /// Lower bound of the range.
  final double min;

  /// Upper bound of the range.
  final double max;

  /// When non-null the value snaps to this many equal steps across the range.
  final int? divisions;

  /// Accessibility label announced with the slider.
  final String? semanticLabel;

  /// Formats [value] for assistive tech. Defaults to a whole-percent reading of
  /// the position within the range.
  final String Function(double value)? semanticFormatter;

  /// Optional external focus node.
  final FocusNode? focusNode;

  /// Whether to autofocus on mount.
  final bool autofocus;

  static const double _trackHeight = 4;
  static const double _thumbSize = 16;
  static const double _hitHeight = 24;

  @override
  State<CcSlider> createState() => _CcSliderState();
}

class _CcSliderState extends State<CcSlider> {
  bool _dragging = false;

  bool get _enabled => widget.onChanged != null;

  double get _clamped => widget.value.clamp(widget.min, widget.max);

  /// [value] as a 0..1 position along the track.
  double get _fraction => (_clamped - widget.min) / (widget.max - widget.min);

  /// Snaps [raw] to the nearest division stop when [CcSlider.divisions] is set.
  double _snap(double raw) {
    final bounded = raw.clamp(widget.min, widget.max);
    final divisions = widget.divisions;
    if (divisions == null) {
      return bounded;
    }
    final step = (widget.max - widget.min) / divisions;
    final steps = ((bounded - widget.min) / step).round();
    return (widget.min + steps * step).clamp(widget.min, widget.max);
  }

  /// Reports the value at horizontal offset [dx] within a track of [width].
  void _emitForOffset(double dx, double width) {
    if (!_enabled || width <= 0) {
      return;
    }
    // The thumb centre travels only between the two half-thumb insets, so map
    // the pointer through that reduced span — otherwise the ends are
    // unreachable and the value lags the cursor.
    const inset = CcSlider._thumbSize / 2;
    final span = width - CcSlider._thumbSize;
    final fraction = span <= 0 ? 0.0 : ((dx - inset) / span).clamp(0.0, 1.0);
    final raw = widget.min + fraction * (widget.max - widget.min);
    final next = _snap(raw);
    if (next != _clamped) {
      widget.onChanged!(next);
    }
  }

  /// One keyboard step: a division when stepped, else 1% of the range.
  double get _step {
    final divisions = widget.divisions;
    final range = widget.max - widget.min;
    return divisions == null ? range / 100 : range / divisions;
  }

  void _nudge(double delta) {
    if (!_enabled) {
      return;
    }
    final next = _snap(_clamped + delta);
    if (next != _clamped) {
      widget.onChanged!(next);
    }
  }

  /// Formats [value] for assistive tech.
  String _announce([double? value]) {
    final v = value ?? _clamped;
    final formatter = widget.semanticFormatter;
    if (formatter != null) {
      return formatter(v);
    }
    final fraction = (v - widget.min) / (widget.max - widget.min);
    return '${(fraction * 100).round()}%';
  }

  /// The reading one step above the current value (clamped at [CcSlider.max]).
  String _announceIncreased() => _announce(_snap(_clamped + _step));

  /// The reading one step below the current value (clamped at [CcSlider.min]).
  String _announceDecreased() => _announce(_snap(_clamped - _step));

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();

    return Semantics(
      slider: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      value: _announce(),
      // Flutter asserts that an increase/decrease action carries BOTH `value`
      // and the matching increased/decreased reading, or neither.
      increasedValue: _enabled ? _announceIncreased() : null,
      decreasedValue: _enabled ? _announceDecreased() : null,
      onIncrease: _enabled ? () => _nudge(_step) : null,
      onDecrease: _enabled ? () => _nudge(-_step) : null,
      child: FocusableActionDetector(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        enabled: _enabled,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.arrowLeft): _AdjustIntent(
            forward: false,
          ),
          SingleActivator(LogicalKeyboardKey.arrowRight): _AdjustIntent(
            forward: true,
          ),
          SingleActivator(LogicalKeyboardKey.home): _ExtentIntent(toMax: false),
          SingleActivator(LogicalKeyboardKey.end): _ExtentIntent(toMax: true),
        },
        actions: <Type, Action<Intent>>{
          _AdjustIntent: CallbackAction<_AdjustIntent>(
            onInvoke: (intent) {
              _nudge(intent.forward ? _step : -_step);
              return null;
            },
          ),
          _ExtentIntent: CallbackAction<_ExtentIntent>(
            onInvoke: (intent) {
              if (_enabled) {
                widget.onChanged!(intent.toMax ? widget.max : widget.min);
              }
              return null;
            },
          ),
        },
        mouseCursor: _enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: Builder(
          builder: (context) {
            final focused = Focus.of(context).hasPrimaryFocus;
            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : 160.0;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => _emitForOffset(d.localPosition.dx, width),
                  onHorizontalDragStart: (d) {
                    setState(() => _dragging = true);
                    _emitForOffset(d.localPosition.dx, width);
                  },
                  onHorizontalDragUpdate: (d) =>
                      _emitForOffset(d.localPosition.dx, width),
                  onHorizontalDragEnd: (_) => setState(() => _dragging = false),
                  onHorizontalDragCancel: () =>
                      setState(() => _dragging = false),
                  child: SizedBox(
                    width: width,
                    height: CcSlider._hitHeight,
                    child: _CcSliderTrack(
                      fraction: _fraction,
                      tokens: t,
                      enabled: _enabled,
                      active: _dragging || focused,
                      showFocusRing: focused,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Paints the track, the filled portion, and the thumb.
class _CcSliderTrack extends StatelessWidget {
  const _CcSliderTrack({
    required this.fraction,
    required this.tokens,
    required this.enabled,
    required this.active,
    required this.showFocusRing,
  });

  final double fraction;
  final DesignSystemTokens tokens;
  final bool enabled;
  final bool active;
  final bool showFocusRing;

  @override
  Widget build(BuildContext context) {
    final fill = enabled
        ? (active ? tokens.accentHover : tokens.accent)
        : tokens.bgDisabled;
    final trackColor = enabled ? tokens.bgTertiary : tokens.bgDisabled;
    final ring = enabled ? fill : tokens.borderDisabled;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const thumb = CcSlider._thumbSize;
        final travel = (width - thumb).clamp(0.0, double.infinity);
        final thumbLeft = travel * fraction;
        return Stack(
          children: [
            // Track — vertically centred, pill-capped.
            Positioned(
              left: 0,
              right: 0,
              top: (CcSlider._hitHeight - CcSlider._trackHeight) / 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: trackColor,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(CcSlider._trackHeight / 2),
                  ),
                ),
                child: const SizedBox(height: CcSlider._trackHeight),
              ),
            ),
            // Filled portion, up to the thumb centre.
            Positioned(
              left: 0,
              width: thumbLeft + thumb / 2,
              top: (CcSlider._hitHeight - CcSlider._trackHeight) / 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(CcSlider._trackHeight / 2),
                  ),
                ),
                child: const SizedBox(height: CcSlider._trackHeight),
              ),
            ),
            Positioned(
              left: thumbLeft,
              top: (CcSlider._hitHeight - thumb) / 2,
              child: Container(
                width: thumb,
                height: thumb,
                decoration: BoxDecoration(
                  color: enabled ? tokens.bgPrimary : tokens.bgDisabled,
                  shape: BoxShape.circle,
                  border: Border.all(color: ring, width: 2),
                ),
              ),
            ),
            if (showFocusRing)
              Positioned(
                left: thumbLeft - 3,
                top: (CcSlider._hitHeight - thumb) / 2 - 3,
                child: Container(
                  width: thumb + 6,
                  height: thumb + 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: tokens.focusRing, width: 2),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Steps the value by one increment in either direction.
class _AdjustIntent extends Intent {
  const _AdjustIntent({required this.forward});

  final bool forward;
}

/// Jumps the value to one end of the range.
class _ExtentIntent extends Intent {
  const _ExtentIntent({required this.toMax});

  final bool toMax;
}
