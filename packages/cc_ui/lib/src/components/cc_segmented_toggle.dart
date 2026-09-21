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
import 'package:flutter/services.dart';
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
/// One tab stop (roving tabindex): Tab → selected; arrows / Home / End move and
/// select; closed-loop wrap. [CcSegment.iconOnly] hides the label (tooltip +
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
  final FocusScopeNode _scopeNode = FocusScopeNode(
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );
  List<FocusNode> _segmentNodes = const [];

  @override
  void initState() {
    super.initState();
    _segmentNodes = _makeNodes(widget.segments.length);
  }

  @override
  void didUpdateWidget(covariant CcSegmentedToggle<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.segments.length != widget.segments.length) {
      for (final n in _segmentNodes) {
        n.dispose();
      }
      _segmentNodes = _makeNodes(widget.segments.length);
    }
  }

  @override
  void dispose() {
    for (final n in _segmentNodes) {
      n.dispose();
    }
    _scopeNode.dispose();
    super.dispose();
  }

  List<FocusNode> _makeNodes(int count) => [
    for (var i = 0; i < count; i++) FocusNode(debugLabel: 'CcSegment $i'),
  ];

  int get _selectedIndex =>
      widget.segments.indexWhere((s) => s.value == widget.value);

  void _select(int index) {
    final onChanged = widget.onChanged;
    if (onChanged == null || index < 0 || index >= widget.segments.length) {
      return;
    }
    final segment = widget.segments[index];
    if (segment.value != widget.value) {
      onChanged(segment.value);
    }
    // Roving tabindex: keep focus on the newly-selected segment after the
    // rebuild, so it stays the single tab stop.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && index < _segmentNodes.length) {
        _segmentNodes[index].requestFocus();
      }
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || widget.onChanged == null) {
      return KeyEventResult.ignored;
    }
    final count = widget.segments.length;
    if (count == 0) {
      return KeyEventResult.ignored;
    }
    // An unmatched value has no cursor to move from; start at the first
    // segment so the arrows still do something predictable.
    final current = _selectedIndex < 0 ? 0 : _selectedIndex;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowDown) {
      _select((current + 1) % count);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowUp) {
      _select((current - 1) % count);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.home) {
      _select(0);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.end) {
      _select(count - 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final disabled = widget.onChanged == null;
    final selectedIndex = _selectedIndex;
    final duration = CcMotion.resolveFade(context, CcMotion.moderate);
    final height = switch (widget.size) {
      CcSegmentedToggleSize.sm => 32.0,
      CcSegmentedToggleSize.md => 40.0,
    };
    // The tab stop is the selected segment; with nothing selected it is the
    // first one, so the control is never unreachable by keyboard.
    final tabStop = selectedIndex < 0 ? 0 : selectedIndex;
    final separator = disabled ? t.borderDisabled : t.borderSecondary;

    Widget buildSegment(int index) => _Segment<T>(
      segment: widget.segments[index],
      selected: index == selectedIndex,
      disabled: disabled,
      focusable: index == tabStop,
      focusNode: index < _segmentNodes.length ? _segmentNodes[index] : null,
      tokens: t,
      size: widget.size,
      duration: duration,
      fullWidth: widget.fullWidth,
      onPressed: disabled ? null : () => _select(index),
    );

    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: FocusScope(
        node: _scopeNode,
        child: Focus(
          canRequestFocus: false,
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
    required this.focusable,
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

  /// True on the roving tab stop — the only segment Tab can reach.
  final bool focusable;
  final FocusNode? focusNode;
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

    // MergeSemantics so "selected" lands on the same node as the button and its
    // label: as two nested nodes a screen reader announces the state apart from
    // the option it belongs to. A visible label is left to the child Text —
    // passing it to CcTappable as well would have it read twice. Icon-only
    // segments have no Text, so the name goes on CcTappable instead.
    final iconOnly = segment.iconOnly;
    Widget segmentButton = MergeSemantics(
      child: Semantics(
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: CcTappable(
          // The selected segment stays live rather than being disabled by a null
          // handler: a disabled segment cannot be tabbed to, and this is exactly
          // the one the roving tab stop belongs on. Re-picking it is a no-op,
          // handled upstream.
          onPressed: onPressed,
          focusNode: focusNode,
          canRequestFocus: focusable,
          borderRadius: AppRadii.brSm,
          focusRingColor: t.focusRing,
          semanticLabel: iconOnly ? segment.label : null,
          builder: (context, states) {
            final hovered = states.contains(WidgetState.hovered);
            final pressed = states.contains(WidgetState.pressed);
            final fluidActive = CcFluidHover.isItemActive(context);

            final Color background;
            final Color foreground;
            if (disabled) {
              // Keep the chosen segment readable when the control is inert —
              // "which one is on" is still information the user needs.
              background = selected
                  ? Color.alphaBlend(t.hoverStrong, t.bgDisabled)
                  : t.hover.withValues(alpha: 0);
              foreground = t.textDisabled;
            } else if (selected) {
              background = primary.bg;
              foreground = primary.fg;
            } else if (pressed) {
              background = t.hoverStrong;
              foreground = t.textSecondary;
            } else if (hovered) {
              background = fluidActive ? t.hover.withValues(alpha: 0) : t.hover;
              foreground = t.textSecondary;
            } else {
              background = t.hover.withValues(alpha: 0);
              foreground = t.textTertiary;
            }

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
            final borderColor = selected
                ? background
                : background.withValues(alpha: 0);

            return AnimatedContainer(
              duration: duration,
              curve: CcMotion.standard,
              padding: EdgeInsets.symmetric(horizontal: horizontal),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background,
                borderRadius: AppRadii.brSm,
                border: Border.all(color: borderColor),
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
                    if (label != null)
                      fullWidth ? Flexible(child: label) : label,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    if (iconOnly) {
      segmentButton = CcTooltip(message: segment.label, child: segmentButton);
    }
    return segmentButton;
  }
}
