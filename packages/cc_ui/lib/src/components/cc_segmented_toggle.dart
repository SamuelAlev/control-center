import 'package:cc_ui/src/foundation/cc_component_tokens.dart';
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
  const CcSegment({required this.value, required this.label, this.icon});

  /// The value reported through [CcSegmentedToggle.onChanged] when picked.
  final T value;

  /// The segment's visible text. The caller localizes it.
  final String label;

  /// Optional leading icon (an [IconData] from the bundled icon font —
  /// declare app glyphs via `tool/gen_icon_seams.py`; see `CcIcons`).
  final IconData? icon;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CcSegment<T> &&
          other.value == value &&
          other.label == label &&
          other.icon == icon;

  @override
  int get hashCode => Object.hash(value, label, icon);
}

/// Height/padding scale for a [CcSegmentedToggle] — the shared control ramp.
enum CcSegmentedToggleSize {
  /// Small — 32px tall, [CcTypography.bodySm]. The dense toolbar default.
  sm,

  /// Medium — 40px tall, [CcTypography.body]. Matches field and [CcButton]
  /// height, so a toggle standing beside a [CcTextField] lines up.
  md,
}

/// A connected segmented control — one bordered track holding adjoining
/// segments, exactly one of which is selected.
///
/// The cc_ui replacement for Material's `SegmentedButton` / `ToggleButtons`.
/// Use it for a small N-way mode switch whose options are all worth showing
/// (Write / Preview, Diff / Preview, All / Done / Processing); reach for
/// `CcSelect` once the list stops fitting on one row, and for `CcTabs` when the
/// choice navigates rather than filters.
///
/// **Anatomy.** A square (`AppRadii.brSm`) track fills with
/// [DesignSystemTokens.surface] under a 1px [DesignSystemTokens.borderPrimary]
/// hairline; the segments sit flush inside it, parted by hairline separators
/// that fade out on both sides of the selection. The selected segment takes the
/// primary-button treatment — ink [DesignSystemTokens.fg] in light, a
/// brand-tinted dark ink in dark, labelled in [DesignSystemTokens.accentOn]
/// (resolved through [CcButtonTokens.primary], so it cannot drift from the
/// button) — per DESIGN.md: *"selected tabs/segments use a dark fill with white
/// text, matching the primary-button logic"*. Unselected segments are
/// [DesignSystemTokens.textTertiary] on nothing, taking a
/// [DesignSystemTokens.hover] wash on hover. Selection therefore survives
/// grayscale and color-blind viewing as a filled-vs-empty cell, never as color
/// alone, and is announced through `Semantics.selected` in a mutually exclusive
/// group.
///
/// **Keyboard.** The track is one tab stop (roving tabindex, the WAI-ARIA radio
/// group pattern): Tab lands on the *selected* segment, then `←`/`→` (and
/// `↑`/`↓`, `Home`/`End`) move through the options, selecting each as it is
/// focused. Wrapping is closed-loop.
///
/// Passing a null [onChanged] disables the whole control: it mutes to the
/// disabled tokens and drops out of the focus order, while the selected segment
/// keeps a distinct fill so the current value still reads.
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
    final duration = CcMotion.resolve(context, CcMotion.fast);
    final height = switch (widget.size) {
      CcSegmentedToggleSize.sm => 32.0,
      CcSegmentedToggleSize.md => 40.0,
    };
    // The tab stop is the selected segment; with nothing selected it is the
    // first one, so the control is never unreachable by keyboard.
    final tabStop = selectedIndex < 0 ? 0 : selectedIndex;
    final separator = disabled ? t.borderDisabled : t.borderSecondary;

    final cells = <Widget>[];
    for (var i = 0; i < widget.segments.length; i++) {
      if (i > 0) {
        cells.add(
          _Separator(
            // A separator touching the filled segment would cut into it; the
            // fill's own edge is the division there.
            visible: selectedIndex != i && selectedIndex != i - 1,
            color: separator,
            duration: duration,
          ),
        );
      }
      final cell = _Segment<T>(
        segment: widget.segments[i],
        selected: i == selectedIndex,
        disabled: disabled,
        focusable: i == tabStop,
        focusNode: i < _segmentNodes.length ? _segmentNodes[i] : null,
        tokens: t,
        size: widget.size,
        duration: duration,
        fullWidth: widget.fullWidth,
        onPressed: disabled ? null : () => _select(i),
      );
      cells.add(widget.fullWidth ? Expanded(child: cell) : cell);
    }

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
            decoration: BoxDecoration(
              color: disabled ? t.bgDisabled : t.surface,
              borderRadius: AppRadii.brSm,
              border: Border.all(
                color: disabled ? t.borderDisabled : t.borderPrimary,
              ),
            ),
            child: Row(
              mainAxisSize: widget.fullWidth
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: cells,
            ),
          ),
        ),
      ),
    );
  }
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
    // the option it belongs to. The label is left to the child Text — passing it
    // to CcTappable as well would have it read twice.
    return MergeSemantics(
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
          builder: (context, states) {
            final hovered = states.contains(WidgetState.hovered);
            final pressed = states.contains(WidgetState.pressed);

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
              background = t.hover;
              foreground = t.textSecondary;
            } else {
              background = t.hover.withValues(alpha: 0);
              foreground = t.textTertiary;
            }

            final label = Text(
              segment.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: baseStyle.copyWith(
                color: foreground,
                fontWeight: CcTypography.mediumWeight,
              ),
            );

            return AnimatedContainer(
              duration: duration,
              curve: CcMotion.standard,
              padding: EdgeInsets.symmetric(horizontal: horizontal),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background,
                borderRadius: AppRadii.brSm,
              ),
              child: SelectionContainer.disabled(
                child: Row(
                  mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (segment.icon != null) ...[
                      Icon(segment.icon, size: iconSize, color: foreground),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    fullWidth ? Flexible(child: label) : label,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
