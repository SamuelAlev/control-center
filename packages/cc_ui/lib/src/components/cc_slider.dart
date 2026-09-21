import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_fonts.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_shadows.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Flat horizontal slider (widgets-only; safe in off-Material overlays). Rest:
/// ink fill on tertiary track, panel thumb, mono value at start. Hover aims
/// (ghost thumb) without committing; accent only while aiming/dragging.
///
/// [divisions] snaps (and may paint dots); [stepLabels] names stops. Arrows
/// step one division (or 1% continuous); Home/End → [min]/[max]. Null
/// [onChanged] disables. Thumb tracks pointer (no motion animation).
class CcSlider extends StatefulWidget {
  /// Creates a [CcSlider].
  const CcSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.stepLabels,
    this.label,
    this.formatValue,
    this.showValue = true,
    this.showSteps,
    this.semanticLabel,
    this.semanticFormatter,
    this.focusNode,
    this.autofocus = false,
  }) : assert(min < max, 'CcSlider requires min < max'),
       assert(
         divisions == null || divisions > 0,
         'CcSlider divisions must be positive',
       ),
       assert(
         stepLabels == null || stepLabels.length >= 2,
         'CcSlider stepLabels needs at least two names',
       ),
       assert(
         stepLabels == null ||
             divisions == null ||
             divisions == stepLabels.length - 1,
         'CcSlider divisions must equal stepLabels.length - 1',
       );

  /// The current value, clamped into `[min, max]` for display.
  final double value;

  /// Called with the new value as the user drags, clicks, or presses a key.
  /// Null disables the slider. Hovering aims a future value and does **not**
  /// invoke this.
  final ValueChanged<double>? onChanged;

  /// Lower bound of the range.
  final double min;

  /// Upper bound of the range.
  final double max;

  /// When non-null the value snaps to this many equal steps across the range.
  /// Inferred from [stepLabels] when that is set and this is omitted.
  final int? divisions;

  /// Names for each stop, least → most, rendered under the track.
  ///
  /// Length must be `divisions + 1` (or at least 2 when [divisions] is
  /// omitted, in which case snapping uses `length - 1` steps). The matching
  /// name is also the default [formatValue], so the hover chip and start-edge
  /// reading speak the step rather than a number.
  final List<String>? stepLabels;

  /// Optional prefix shown with the value, e.g. `Volume` → `Volume: 70%`.
  final String? label;

  /// Formats [value] for the visible label and the hover preview chip.
  ///
  /// Defaults to the matching [stepLabels] entry when those are set, else a
  /// percent when the range is 0..1, otherwise a compact number. Assistive
  /// tech still uses [semanticFormatter] when given.
  final String Function(double value)? formatValue;

  /// Whether to show the value at the start edge. Defaults to true.
  final bool showValue;

  /// Whether to paint dots at each division. Defaults to true when
  /// [divisions] is set and there are at most [_maxAutoSteps] stops.
  final bool? showSteps;

  /// Accessibility label announced with the slider.
  final String? semanticLabel;

  /// Formats [value] for assistive tech. Defaults to [formatValue], then to
  /// a whole-percent reading of the position within the range.
  final String Function(double value)? semanticFormatter;

  /// Optional external focus node.
  final FocusNode? focusNode;

  /// Whether to autofocus on mount.
  final bool autofocus;

  /// Hit-test key for the track. Tests that aim a pointer at a specific
  /// fraction should target this, not the whole slider (the value label
  /// sits on the start side).
  static const Key trackKey = ValueKey<String>('cc_slider.track');

  /// Key for the committed/preview value label.
  static const Key valueKey = ValueKey<String>('cc_slider.value');

  /// Key for the hover preview chip.
  static const Key previewKey = ValueKey<String>('cc_slider.preview');

  /// Key for the named-step label row under the track.
  static const Key stepLabelsKey = ValueKey<String>('cc_slider.step_labels');

  static const double _trackHeight = 6;
  static const double _thumbSize = 14;
  static const double _ghostSize = 8;
  static const double _dotSize = 3;
  static const double _hitHeight = 32;
  static const int _maxAutoSteps = 12;

  @override
  State<CcSlider> createState() => _CcSliderState();
}

class _CcSliderState extends State<CcSlider> {
  bool _dragging = false;
  double? _hoverValue;

  bool get _enabled => widget.onChanged != null;

  double get _clamped => widget.value.clamp(widget.min, widget.max);

  /// [value] as a 0..1 position along the track.
  double get _fraction => (_clamped - widget.min) / (widget.max - widget.min);

  bool get _paintSteps {
    if (widget.showSteps != null) {
      return widget.showSteps!;
    }
    final divisions = _divisions;
    return divisions != null && divisions <= CcSlider._maxAutoSteps;
  }

  /// Effective stop count. Named labels imply evenly spaced stops even when
  /// [CcSlider.divisions] was left null.
  int? get _divisions =>
      widget.divisions ??
      (widget.stepLabels == null ? null : widget.stepLabels!.length - 1);

  /// Snaps [raw] to the nearest division stop when stepped.
  double _snap(double raw) {
    final bounded = raw.clamp(widget.min, widget.max);
    final divisions = _divisions;
    if (divisions == null) {
      return bounded;
    }
    final step = (widget.max - widget.min) / divisions;
    final steps = ((bounded - widget.min) / step).round();
    return (widget.min + steps * step).clamp(widget.min, widget.max);
  }

  /// Value at horizontal offset [dx] within a track of [width].
  double _valueForOffset(double dx, double width, {required bool isRtl}) {
    if (width <= 0) {
      return _clamped;
    }
    // The thumb centre travels only between the two half-thumb insets, so map
    // the pointer through that reduced span — otherwise the ends are
    // unreachable and the value lags the cursor.
    const inset = CcSlider._thumbSize / 2;
    final span = width - CcSlider._thumbSize;
    var fraction = span <= 0 ? 0.0 : ((dx - inset) / span).clamp(0.0, 1.0);
    if (isRtl) {
      fraction = 1.0 - fraction;
    }
    return _snap(widget.min + fraction * (widget.max - widget.min));
  }

  void _emit(double next) {
    if (!_enabled || next == _clamped) {
      return;
    }
    widget.onChanged!(next);
  }

  void _aimAt(double dx, double width, {required bool isRtl}) {
    if (!_enabled || _dragging) {
      return;
    }
    final next = _valueForOffset(dx, width, isRtl: isRtl);
    if (_hoverValue != next) {
      setState(() => _hoverValue = next);
    }
  }

  void _clearAim() {
    if (_hoverValue == null) {
      return;
    }
    setState(() => _hoverValue = null);
  }

  /// One keyboard step: a division when stepped, else 1% of the range.
  double get _step {
    final divisions = _divisions;
    final range = widget.max - widget.min;
    return divisions == null ? range / 100 : range / divisions;
  }

  void _nudge(double delta) {
    if (!_enabled) {
      return;
    }
    _emit(_snap(_clamped + delta));
  }

  String _display(double value) {
    final formatter = widget.formatValue;
    if (formatter != null) {
      return formatter(value);
    }
    final labels = widget.stepLabels;
    if (labels != null) {
      return labels[_stepIndex(value, labels.length)];
    }
    return _defaultSliderFormat(value, widget.min, widget.max);
  }

  /// Stop index for [value] across [count] named (or implied) steps.
  int _stepIndex(double value, int count) {
    if (count <= 1) {
      return 0;
    }
    final t = ((value - widget.min) / (widget.max - widget.min)).clamp(
      0.0,
      1.0,
    );
    return (t * (count - 1)).round();
  }

  String _visibleReading() {
    final aimed = _hoverValue;
    final value = aimed ?? _clamped;
    final formatted = _display(value);
    final prefix = widget.label;
    if (prefix == null || prefix.isEmpty) {
      return formatted;
    }
    return '$prefix: $formatted';
  }

  /// Formats [value] for assistive tech.
  String _announce([double? value]) {
    final v = value ?? _clamped;
    final formatter = widget.semanticFormatter;
    if (formatter != null) {
      return formatter(v);
    }
    if (widget.formatValue != null) {
      return widget.formatValue!(v);
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
    final t = context.ds;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final aimed = _hoverValue;
    final previewing = aimed != null && aimed != _clamped;

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
        // Arrow keys track the thumb's VISUAL motion (Material Slider parity):
        // under RTL the track is mirrored, so arrow-left increases the value.
        shortcuts: <ShortcutActivator, Intent>{
          const SingleActivator(LogicalKeyboardKey.arrowLeft): _AdjustIntent(
            forward: isRtl,
          ),
          const SingleActivator(LogicalKeyboardKey.arrowRight): _AdjustIntent(
            forward: !isRtl,
          ),
          const SingleActivator(LogicalKeyboardKey.home): const _ExtentIntent(
            toMax: false,
          ),
          const SingleActivator(LogicalKeyboardKey.end): const _ExtentIntent(
            toMax: true,
          ),
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
            return Row(
              children: [
                if (widget.showValue) ...[
                  _CcSliderValueLabel(
                    text: _visibleReading(),
                    reserve: _display(widget.min),
                    reserveMax: _display(widget.max),
                    prefix: widget.label,
                    previewing: previewing,
                    enabled: _enabled,
                    tokens: t,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth.isFinite
                          ? constraints.maxWidth
                          : 160.0;
                      final track = MouseRegion(
                        onEnter: _enabled
                            ? (e) => _aimAt(
                                e.localPosition.dx,
                                width,
                                isRtl: isRtl,
                              )
                            : null,
                        onHover: _enabled
                            ? (e) => _aimAt(
                                e.localPosition.dx,
                                width,
                                isRtl: isRtl,
                              )
                            : null,
                        onExit: _enabled ? (_) => _clearAim() : null,
                        child: GestureDetector(
                          key: CcSlider.trackKey,
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (d) => _emit(
                            _valueForOffset(
                              d.localPosition.dx,
                              width,
                              isRtl: isRtl,
                            ),
                          ),
                          onHorizontalDragStart: (d) {
                            setState(() {
                              _dragging = true;
                              _hoverValue = null;
                            });
                            _emit(
                              _valueForOffset(
                                d.localPosition.dx,
                                width,
                                isRtl: isRtl,
                              ),
                            );
                          },
                          onHorizontalDragUpdate: (d) => _emit(
                            _valueForOffset(
                              d.localPosition.dx,
                              width,
                              isRtl: isRtl,
                            ),
                          ),
                          onHorizontalDragEnd: (_) =>
                              setState(() => _dragging = false),
                          onHorizontalDragCancel: () =>
                              setState(() => _dragging = false),
                          child: _CcSliderTrack(
                            fraction: _fraction,
                            hoverFraction: aimed == null
                                ? null
                                : (aimed - widget.min) /
                                      (widget.max - widget.min),
                            hoverLabel: aimed == null ? null : _display(aimed),
                            stepCount: _paintSteps ? _divisions : null,
                            tokens: t,
                            enabled: _enabled,
                            active: _dragging || focused || aimed != null,
                            showFocusRing: focused,
                            isRtl: isRtl,
                            width: width,
                          ),
                        ),
                      );
                      final labels = widget.stepLabels;
                      if (labels == null) {
                        return track;
                      }
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          track,
                          _CcSliderStepLabels(
                            labels: labels,
                            selectedIndex: _stepIndex(_clamped, labels.length),
                            hoverIndex: aimed == null
                                ? null
                                : _stepIndex(aimed, labels.length),
                            enabled: _enabled,
                            tokens: t,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Committed value at rest; the aimed (future) value while hovering, painted
/// in tertiary so it reads as a preview until click.
class _CcSliderValueLabel extends StatelessWidget {
  const _CcSliderValueLabel({
    required this.text,
    required this.reserve,
    required this.reserveMax,
    required this.prefix,
    required this.previewing,
    required this.enabled,
    required this.tokens,
  });

  final String text;
  final String reserve;
  final String reserveMax;
  final String? prefix;
  final bool previewing;
  final bool enabled;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? tokens.textDisabled
        : (previewing ? tokens.textTertiary : tokens.textPrimary);
    final style = CcFonts.code(
      textStyle: CcTypography.monoNum.copyWith(color: color),
    );
    // Size to the longest of min/max/current so the track does not jump as
    // the reading changes. ~0.62em per mono numeral at this size.
    final chars = [
      text,
      _withPrefix(reserve),
      _withPrefix(reserveMax),
    ].map((s) => s.length).reduce((a, b) => a > b ? a : b);
    return ExcludeSemantics(
      child: AnimatedDefaultTextStyle(
        key: CcSlider.valueKey,
        duration: CcMotion.resolveFade(context, CcMotion.fast),
        curve: CcMotion.standard,
        style: style,
        child: SizedBox(
          width: chars * 8.0,
          child: Text(text, textAlign: TextAlign.end),
        ),
      ),
    );
  }

  String _withPrefix(String value) {
    final prefix = this.prefix;
    if (prefix == null || prefix.isEmpty) {
      return value;
    }
    return '$prefix: $value';
  }
}

/// Names under each stop. The committed step is ink + semibold; an aimed
/// (not yet committed) step is secondary; the rest stay tertiary.
class _CcSliderStepLabels extends StatelessWidget {
  const _CcSliderStepLabels({
    required this.labels,
    required this.selectedIndex,
    required this.hoverIndex,
    required this.enabled,
    required this.tokens,
  });

  final List<String> labels;
  final int selectedIndex;
  final int? hoverIndex;
  final bool enabled;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    final last = labels.length - 1;
    return ExcludeSemantics(
      child: Padding(
        key: CcSlider.stepLabelsKey,
        padding: const EdgeInsets.only(top: AppSpacing.xxs),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: Text(
                  labels[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: i == 0
                      ? TextAlign.start
                      : i == last
                      ? TextAlign.end
                      : TextAlign.center,
                  style: CcFonts.ui(
                    textStyle: CcTypography.caption.copyWith(
                      fontWeight: i == selectedIndex
                          ? CcTypography.semiboldWeight
                          : CcTypography.regularWeight,
                      color: !enabled
                          ? tokens.textDisabled
                          : i == selectedIndex
                          ? tokens.textPrimary
                          : (hoverIndex == i
                                ? tokens.textSecondary
                                : tokens.textTertiary),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Paints the track, fill, step dots, ghost, thumb and the hover chip.
class _CcSliderTrack extends StatelessWidget {
  const _CcSliderTrack({
    required this.fraction,
    required this.hoverFraction,
    required this.hoverLabel,
    required this.stepCount,
    required this.tokens,
    required this.enabled,
    required this.active,
    required this.showFocusRing,
    required this.isRtl,
    required this.width,
  });

  final double fraction;
  final double? hoverFraction;
  final String? hoverLabel;
  final int? stepCount;
  final DesignSystemTokens tokens;
  final bool enabled;
  final bool active;
  final bool showFocusRing;
  final bool isRtl;
  final double width;

  @override
  Widget build(BuildContext context) {
    final fill = !enabled
        ? tokens.bgDisabled
        : (active ? tokens.accent : tokens.textTertiary);
    final trackColor = enabled ? tokens.bgTertiary : tokens.bgDisabled;
    final ring = enabled ? fill : tokens.borderDisabled;
    final hover = hoverFraction;
    const thumb = CcSlider._thumbSize;
    final travel = (width - thumb).clamp(0.0, double.infinity);
    final hoverAlong = hover == null
        ? null
        : travel * (isRtl ? 1.0 - hover : hover);

    final alignmentX = hoverAlong == null
        ? 0.0
        : ((hoverAlong + thumb / 2) / width * 2 - 1).clamp(-1.0, 1.0);

    return SizedBox(
      width: width,
      height: CcSlider._hitHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size(width, CcSlider._hitHeight),
            painter: _CcSliderPainter(
              fraction: fraction,
              hoverFraction: hover,
              stepCount: stepCount,
              trackColor: trackColor,
              fillColor: fill,
              thumbFill: enabled ? tokens.bgPrimary : tokens.bgDisabled,
              thumbRing: ring,
              dotColor: tokens.idle,
              dotOnFillColor: tokens.bgPrimary.withValues(alpha: 0.7),
              ghostColor: tokens.idle,
              isRtl: isRtl,
            ),
          ),
          if (showFocusRing)
            Positioned(
              left: travel * (isRtl ? 1.0 - fraction : fraction) - 3,
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
          if (hoverAlong != null && hoverLabel != null)
            Positioned(
              left: 0,
              right: 0,
              top: -20,
              height: 20,
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment(alignmentX, 0.5),
                  child: _CcSliderPreviewChip(
                    label: hoverLabel!,
                    tokens: tokens,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Square chip above the aimed position — the future value.
class _CcSliderPreviewChip extends StatelessWidget {
  const _CcSliderPreviewChip({required this.label, required this.tokens});

  final String label;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: CcSlider.previewKey,
      decoration: BoxDecoration(
        color: tokens.bgPrimary,
        borderRadius: AppRadii.brXs,
        border: Border.all(color: tokens.borderPrimary),
        boxShadow: AppShadows.soft,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          label,
          style: CcFonts.code(
            textStyle: CcTypography.monoNum.copyWith(color: tokens.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Paints track, fill, dots, ghost and thumb. Fill grows from the START edge.
class _CcSliderPainter extends CustomPainter {
  _CcSliderPainter({
    required this.fraction,
    required this.hoverFraction,
    required this.stepCount,
    required this.trackColor,
    required this.fillColor,
    required this.thumbFill,
    required this.thumbRing,
    required this.dotColor,
    required this.dotOnFillColor,
    required this.ghostColor,
    required this.isRtl,
  });

  final double fraction;
  final double? hoverFraction;
  final int? stepCount;
  final Color trackColor;
  final Color fillColor;
  final Color thumbFill;
  final Color thumbRing;
  final Color dotColor;
  final Color dotOnFillColor;
  final Color ghostColor;
  final bool isRtl;

  @override
  void paint(Canvas canvas, Size size) {
    const thumb = CcSlider._thumbSize;
    const trackH = CcSlider._trackHeight;
    final travel = (size.width - thumb).clamp(0.0, double.infinity);
    final cy = size.height / 2;
    final trackTop = cy - trackH / 2;
    const radius = Radius.circular(trackH / 2);

    canvas.drawRRect(
      RRect.fromLTRBR(0, trackTop, size.width, trackTop + trackH, radius),
      Paint()..color = trackColor,
    );

    final fillWidth = travel * fraction + thumb / 2;
    if (fillWidth > 0) {
      final fillRect = isRtl
          ? RRect.fromLTRBR(
              size.width - fillWidth,
              trackTop,
              size.width,
              trackTop + trackH,
              radius,
            )
          : RRect.fromLTRBR(0, trackTop, fillWidth, trackTop + trackH, radius);
      canvas.drawRRect(fillRect, Paint()..color = fillColor);
    }

    final divisions = stepCount;
    if (divisions != null && divisions > 0) {
      final thumbX = thumb / 2 + travel * (isRtl ? 1.0 - fraction : fraction);
      for (var i = 0; i <= divisions; i++) {
        final f = i / divisions;
        final x = thumb / 2 + travel * (isRtl ? 1.0 - f : f);
        if ((x - thumbX).abs() < thumb / 2) {
          continue;
        }
        final onFill = isRtl ? f >= fraction : f <= fraction;
        canvas.drawCircle(
          Offset(x, cy),
          CcSlider._dotSize / 2,
          Paint()..color = onFill ? dotOnFillColor : dotColor,
        );
      }
    }

    final hover = hoverFraction;
    if (hover != null && (hover - fraction).abs() > 0.001) {
      final ghostX = thumb / 2 + travel * (isRtl ? 1.0 - hover : hover);
      canvas.drawCircle(
        Offset(ghostX, cy),
        CcSlider._ghostSize / 2,
        Paint()..color = ghostColor,
      );
    }

    final thumbX = thumb / 2 + travel * (isRtl ? 1.0 - fraction : fraction);
    canvas
      ..drawCircle(Offset(thumbX, cy), thumb / 2, Paint()..color = thumbFill)
      ..drawCircle(
        Offset(thumbX, cy),
        thumb / 2 - 1,
        Paint()
          ..color = thumbRing
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
  }

  @override
  bool shouldRepaint(_CcSliderPainter old) =>
      fraction != old.fraction ||
      hoverFraction != old.hoverFraction ||
      stepCount != old.stepCount ||
      trackColor != old.trackColor ||
      fillColor != old.fillColor ||
      thumbFill != old.thumbFill ||
      thumbRing != old.thumbRing ||
      dotColor != old.dotColor ||
      dotOnFillColor != old.dotOnFillColor ||
      ghostColor != old.ghostColor ||
      isRtl != old.isRtl;
}

/// Default visible reading: percent on a 0..1 range, else a compact number.
String _defaultSliderFormat(double value, double min, double max) {
  if (min == 0 && max == 1) {
    return '${((value - min) / (max - min) * 100).round()}%';
  }
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toStringAsFixed(1);
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
