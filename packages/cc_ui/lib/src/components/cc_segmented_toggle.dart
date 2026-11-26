import 'dart:math' as math;

import 'package:cc_ui/src/components/cc_roving_focus.dart';
import 'package:cc_ui/src/components/cc_tooltip.dart';
import 'package:cc_ui/src/foundation/cc_component_tokens.dart';
import 'package:cc_ui/src/foundation/cc_fluid_hover.dart';
import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// A single option in a [CcSegmentedToggle].
@immutable
class CcSegment<T> {
  /// Creates a [CcSegment].
  const CcSegment({
    required this.value,
    required this.label,
    this.icon,
    this.iconOnly = false,
  }) : assert(!iconOnly || icon != null, 'CcSegment.iconOnly requires an icon');

  /// The value reported through [CcSegmentedToggle.onChanged] when picked.
  final T value;

  /// The segment's name. Drawn as the visible label unless [iconOnly] is set,
  /// in which case it is the tooltip and the semantic name. The caller
  /// localizes it.
  final String label;

  /// Optional leading icon (an [IconData] from the bundled icon font —
  /// declare app glyphs via `tool/gen_icon_seams.py`; see `CcIcons`).
  final IconData? icon;

  /// When true, only [icon] is drawn; [label] remains the tooltip and the
  /// accessible name. Use for compact layout switches (grid / list).
  final bool iconOnly;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CcSegment<T> &&
          other.value == value &&
          other.label == label &&
          other.icon == icon &&
          other.iconOnly == iconOnly;

  @override
  int get hashCode => Object.hash(value, label, icon, iconOnly);
}

/// Height/padding scale for a [CcSegmentedToggle] — the shared control ramp.
enum CcSegmentedToggleSize {
  /// Small — 32px tall, [CcTypography.bodySm]. The dense toolbar default.
  sm,

  /// Medium — 40px tall, [CcTypography.body]. Matches field and [CcButton]
  /// height, so a toggle standing beside a [CcTextField] lines up.
  md,
}

/// Connected segmented control: one bordered track, adjoining segments, exactly
/// one selected. Prefer [CcSelect] when options no longer fit one row; [CcTabs]
/// when the choice navigates rather than filters.
///
/// Selected segment uses [CcButtonTokens.primary] (fill over the track hairline,
/// not inset). Unselected: [DesignSystemTokens.textTertiary] + hover wash.
/// Selection must stay filled-vs-empty (not color alone); `Semantics.selected`
/// in a mutually exclusive group.
///
/// One tab stop (roving tabindex): Tab → selected, the next Tab leaves the
/// control; `←`/`→` (mirrored under RTL) and Home / End move and select,
/// wrapping at the ends; `↑`/`↓` are left to directional focus. [CcSegment.iconOnly] hides the label (tooltip +
/// a11y name). Null [onChanged] disables the control but keeps the selected fill.
class CcSegmentedToggle<T> extends StatefulWidget {
  /// Creates a [CcSegmentedToggle].
  const CcSegmentedToggle({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.size = CcSegmentedToggleSize.sm,
    this.fullWidth = false,
    this.semanticLabel,
  });

  /// The selectable segments, in display order.
  final List<CcSegment<T>> segments;

  /// The currently-selected segment value. A value matching no segment simply
  /// leaves the track unselected.
  final T value;

  /// Called with a segment's value when it is picked (pointer or keyboard).
  /// When null the control is disabled.
  final ValueChanged<T>? onChanged;

  /// The height/padding scale.
  final CcSegmentedToggleSize size;

  /// When true the segments share the width equally and the track fills its
  /// horizontal constraints; otherwise each segment hugs its label.
  final bool fullWidth;

  /// Accessibility label for the group (e.g. "Editor mode").
  final String? semanticLabel;

  @override
  State<CcSegmentedToggle<T>> createState() => _CcSegmentedToggleState<T>();
}

class _CcSegmentedToggleState<T> extends State<CcSegmentedToggle<T>> {
  late final CcRovingFocusNodes _segmentNodes = CcRovingFocusNodes(
    'CcSegment',
    widget.segments.length,
  );

  @override
  void didUpdateWidget(covariant CcSegmentedToggle<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _segmentNodes.sync(widget.segments.length);
  }

  @override
  void dispose() {
    _segmentNodes.dispose();
    super.dispose();
  }

  int get _selectedIndex =>
      widget.segments.indexWhere((s) => s.value == widget.value);

  void _select(int index) {
    final segment = widget.segments[index];
    if (segment.value != widget.value) {
      widget.onChanged?.call(segment.value);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (widget.onChanged == null) {
      return KeyEventResult.ignored;
    }
    final target = ccRovingTarget(
      event: event,
      current: _segmentNodes.focusedIndex ?? _selectedIndex,
      count: widget.segments.length,
      rtl: Directionality.of(context) == TextDirection.rtl,
    );
    if (target == null) {
      return KeyEventResult.ignored;
    }
    _segmentNodes[target].requestFocus();
    _select(target);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final disabled = widget.onChanged == null;
    final selectedIndex = _selectedIndex;
    final duration = CcMotion.resolveFade(context, CcMotion.moderate);
    final baseHeight = switch (widget.size) {
      CcSegmentedToggleSize.sm => 32.0,
      CcSegmentedToggleSize.md => 40.0,
    };
    final textStyle = widget.size == CcSegmentedToggleSize.sm
        ? CcTypography.bodySm
        : CcTypography.body;
    // The track keeps its exact height at the default text size and grows
    // with a larger one, so an enlarged label is never cut off.
    final fontSize = textStyle.fontSize!;
    final lineHeight = fontSize * textStyle.height!;
    final scaledLine =
        MediaQuery.textScalerOf(context).scale(fontSize) * textStyle.height!;
    final height = math.max(baseHeight, scaledLine + baseHeight - lineHeight);
    // The tab stop is the selected segment; with nothing selected it is the
    // first one, so the control is never unreachable by keyboard.
    _segmentNodes.setStop(selectedIndex < 0 ? 0 : selectedIndex);
    final separator = disabled ? t.borderDisabled : t.borderSecondary;

    Widget buildSegment(int index) => _Segment<T>(
      segment: widget.segments[index],
      selected: index == selectedIndex,
      disabled: disabled,
      focusNode: _segmentNodes[index],
      tokens: t,
      size: widget.size,
      duration: duration,
      fullWidth: widget.fullWidth,
      onPressed: disabled ? null : () => _select(index),
    );

    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: Container(
          height: height,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: disabled ? t.bgDisabled : t.surface,
            borderRadius: AppRadii.brSm,
          ),
          // Hairline is painted *behind* the segments (CustomPaint.painter,
          // not a BoxDecoration border). A Container border would inset the
          // children and leave a lighter ring around the choice — 1px on
          // top and bottom, so the selected cell felt 2px taller than the
          // fill. The selected fill (and its matching-color border) covers
          // that stroke instead.
          child: CustomPaint(
            painter: _TrackHairlinePainter(
              color: disabled ? t.borderDisabled : t.borderPrimary,
            ),
            child: CcFluidHover(
              axis: CcFluidHoverAxis.x,
              itemCount: widget.segments.length,
              isItemDisabled: (_) => disabled,
              itemBuilder: (context, index) => buildSegment(index),
              layoutBuilder: (context, items) {
                final cells = <Widget>[];
                for (var i = 0; i < items.length; i++) {
                  if (i > 0) {
                    cells.add(
                      _Separator(
                        // The fill's own edge separates a selected segment.
                        visible: selectedIndex != i && selectedIndex != i - 1,
                        color: separator,
                        duration: duration,
                      ),
                    );
                  }
                  cells.add(
                    widget.fullWidth ? Expanded(child: items[i]) : items[i],
                  );
                }
                return Row(
                  mainAxisSize: widget.fullWidth
                      ? MainAxisSize.max
                      : MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: cells,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// 1px track hairline, painted behind the segments so a selected fill covers it.
class _TrackHairlinePainter extends CustomPainter {
  const _TrackHairlinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    // Inset by 0.5 so the 1px stroke sits on the pixel grid, not straddling
    // the outer edge.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
        const Radius.circular(AppRadii.sm),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_TrackHairlinePainter old) => old.color != color;
}

/// The hairline parting two adjoining segments. It fades rather than
/// disappears so the track does not flicker as the selection moves.
class _Separator extends StatelessWidget {
  const _Separator({
    required this.visible,
    required this.color,
    required this.duration,
  });

  final bool visible;
  final Color color;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      curve: CcMotion.standard,
      width: 1,
      // Alpha-0 of the visible color (never transparent-black) so the lerp
      // touches only alpha and cannot flash a dark gray mid-transition.
      color: visible ? color : color.withValues(alpha: 0),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.segment,
    required this.selected,
    required this.disabled,
    required this.focusNode,
    required this.tokens,
    required this.size,
    required this.duration,
    required this.fullWidth,
    required this.onPressed,
  });

  final CcSegment<T> segment;
  final bool selected;
  final bool disabled;
  final FocusNode focusNode;
  final DesignSystemTokens tokens;
  final CcSegmentedToggleSize size;
  final Duration duration;
  final bool fullWidth;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final primary = CcButtonTokens.primary(t);
    final horizontal = size == CcSegmentedToggleSize.sm
        ? AppSpacing.md
        : AppSpacing.lg;
    final iconSize = size == CcSegmentedToggleSize.sm ? 14.0 : 16.0;
    final baseStyle = size == CcSegmentedToggleSize.sm
        ? CcTypography.bodySm
        : CcTypography.body;

    // A visible label is left to the child Text, which merges into the
    // tappable's node; passing it to CcTappable as well would have it read
    // twice. Icon-only segments have no Text, so the name goes on CcTappable.
    final iconOnly = segment.iconOnly;
    Widget segmentButton = CcTappable(
      // The selected segment stays live rather than being disabled by a null
      // handler: a disabled segment cannot be tabbed to, and this is exactly
      // the one the roving tab stop belongs on. Re-picking it is a no-op,
      // handled upstream.
      onPressed: onPressed,
      focusNode: focusNode,
      borderRadius: AppRadii.brSm,
      // The selected fill is the ink/brand colour the ring would vanish
      // into, and the track clips a ring drawn outside it, so on that
      // segment the ring takes the fill's own label colour.
      focusRingColor: selected && !disabled ? primary.fg : t.focusRing,
      semanticLabel: iconOnly ? segment.label : null,
      semanticSelected: selected,
      semanticInMutuallyExclusiveGroup: true,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final pressed = states.contains(WidgetState.pressed);
        final fluidActive = CcFluidHover.isItemActive(context);

        // Two layers, never one lerped color. The hover wash is `fg` at a
        // few percent and the selected fill is an opaque brand color; a
        // single animated color between them runs through their straight
        // RGB midpoint, which in dark mode (white-based wash) flashes a
        // pale grey on both segments at every change. Each layer instead
        // fades only its own alpha.
        final Color fill;
        final Color wash;
        final Color foreground;
        if (disabled) {
          // Keep the chosen segment readable when the control is inert —
          // "which one is on" is still information the user needs.
          fill = Color.alphaBlend(t.hoverStrong, t.bgDisabled);
          wash = t.hover.withValues(alpha: 0);
          foreground = t.textDisabled;
        } else {
          fill = primary.bg;
          wash = pressed
              ? t.hoverStrong
              : hovered && !fluidActive
              ? t.hover
              : t.hover.withValues(alpha: 0);
          foreground = selected
              ? primary.fg
              : hovered || pressed
              ? t.textSecondary
              : t.textTertiary;
        }
        final shownFill = selected ? fill : fill.withValues(alpha: 0);

        final Widget? label = iconOnly
            ? null
            : Text(
                segment.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: baseStyle.copyWith(
                  color: foreground,
                  fontWeight: CcTypography.mediumWeight,
                ),
              );

        // 1px border on every segment keeps label height stable. Selected
        // uses the fill color so the edge matches the item; transparent
        // on the rest so the track hairline still shows. Top+bottom is
        // 2px, which is what keeps the selected cell from feeling taller
        // than the unselected ones after the fill covers the track.
        return TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: wash),
          duration: duration,
          curve: CcMotion.standard,
          builder: (context, washColor, fillLayer) => DecoratedBox(
            decoration: BoxDecoration(
              color: washColor,
              borderRadius: AppRadii.brSm,
            ),
            child: fillLayer,
          ),
          child: AnimatedContainer(
            duration: duration,
            curve: CcMotion.standard,
            padding: EdgeInsets.symmetric(horizontal: horizontal),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: shownFill,
              borderRadius: AppRadii.brSm,
              border: Border.all(color: shownFill),
            ),
            child: SelectionContainer.disabled(
              child: Row(
                mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (segment.icon != null) ...[
                    Icon(segment.icon, size: iconSize, color: foreground),
                    if (label != null) const SizedBox(width: AppSpacing.xs),
                  ],
                  if (label != null) fullWidth ? Flexible(child: label) : label,
                ],
              ),
            ),
          ),
        );
      },
    );
    if (iconOnly) {
      segmentButton = CcTooltip(message: segment.label, child: segmentButton);
    }
    return segmentButton;
  }
}
