// RTL carve-out: panes and dividers are placed in physical viewport
// coordinates after [solveEditorWorkspaceLayout] mirrors horizontal splits.
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/editor_tab_group.dart';
import 'package:control_center/shared/editor/editor_workspace_layout.dart';
import 'package:flutter/widgets.dart';

/// A reusable VS Code-style editor grid: a tiling split-tree of tab groups with
/// drag-to-reorder, drag-to-split and drag-between-panes — the same surface the
/// messaging IDE and the PR detail page both render.
///
/// The engine is kind-agnostic: it renders [layout]'s tree and delegates every
/// tab body to [buildBody] and every feature-specific affordance (icons,
/// labels, the `[+]` menu, a sidebar toggle) to [chrome]. The host owns the
/// [layout] controller's lifecycle (create / dispose / persist) and any sidebar
/// composed around this widget.
///
/// Structural split changes (opening, closing or collapsing panes) animate
/// smoothly using a flat FLIP projection over [CcMotion.slow] /
/// [CcMotion.slowExit] while keeping every leaf's [EditorTabGroup] mounted
/// under its stable `ValueKey(leafId)`.
class EditorWorkspace extends StatefulWidget {
  /// Creates an [EditorWorkspace].
  const EditorWorkspace({
    super.key,
    required this.layout,
    required this.buildBody,
    required this.chrome,
    this.onResized,
  });

  /// The split-tree controller (owned/disposed by the host).
  final EditorLayoutController layout;

  /// Builds a tab's kept-alive body.
  final EditorBodyBuilder buildBody;

  /// Feature-specific chrome (icons / labels / `[+]` menu / sidebar toggle).
  final EditorChrome chrome;

  /// Called after a divider drag changes region weights, so the host can
  /// persist the new sizes. The weight mutation itself is already applied.
  final VoidCallback? onResized;

  @override
  State<EditorWorkspace> createState() => _EditorWorkspaceState();
}

typedef _EnteringPane = ({Size targetSize, Alignment alignment});
typedef _ExitingPane = ({String id, Rect from, Rect to, Border seamBorder});

class _EditorWorkspaceState extends State<EditorWorkspace>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this)
    ..addStatusListener(_onAnimStatus);

  Size? _lastSize;
  TextDirection? _lastDirection;
  Set<String> _knownLeafIds = {};
  Map<String, Rect> _settledRects = {};

  Map<String, Rect> _fromRects = {};
  Map<String, Rect> _toRects = {};
  Map<String, _EnteringPane> _entering = {};
  List<_ExitingPane> _exiting = const [];

  @override
  void initState() {
    super.initState();
    widget.layout.addListener(_onLayoutChanged);
  }

  @override
  void didUpdateWidget(EditorWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.layout, widget.layout)) {
      oldWidget.layout.removeListener(_onLayoutChanged);
      widget.layout.addListener(_onLayoutChanged);
      _anim.stop();
      _anim.value = 1;
      _knownLeafIds = {};
      _settledRects = {};
      _clearTransition();
    }
  }

  @override
  void dispose() {
    widget.layout.removeListener(_onLayoutChanged);
    _anim.dispose();
    super.dispose();
  }

  void _onAnimStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(_clearTransition);
    }
  }

  void _clearTransition() {
    _fromRects = {};
    _toRects = {};
    _entering = {};
    _exiting = const [];
  }

  bool _sameIdSet(Set<String> a, Iterable<String> b) {
    var count = 0;
    for (final id in b) {
      if (!a.contains(id)) {
        return false;
      }
      count++;
    }
    return count == a.length;
  }

  bool _rectsChanged(Map<String, Rect> prev, Map<String, Rect> next) {
    if (prev.length != next.length) {
      return true;
    }
    for (final entry in next.entries) {
      final before = prev[entry.key];
      if (before == null) {
        return true;
      }
      final after = entry.value;
      if ((before.left - after.left).abs() > 0.5 ||
          (before.top - after.top).abs() > 0.5 ||
          (before.width - after.width).abs() > 0.5 ||
          (before.height - after.height).abs() > 0.5) {
        return true;
      }
    }
    return false;
  }

  Map<String, Rect> _currentLeafRects() {
    if (!_anim.isAnimating || _toRects.isEmpty) {
      return _settledRects;
    }
    final t = CcMotion.emphasized.transform(_anim.value);
    final out = <String, Rect>{};
    for (final entry in _toRects.entries) {
      final from = _fromRects[entry.key] ?? entry.value;
      out[entry.key] = Rect.lerp(from, entry.value, t)!;
    }
    return out;
  }

  void _onLayoutChanged() {
    if (!mounted) {
      return;
    }
    final size = _lastSize;
    final direction = _lastDirection;
    if (size != null && direction != null && _knownLeafIds.isNotEmpty) {
      final next = solveEditorWorkspaceLayout(
        widget.layout.root,
        size,
        direction,
      );
      final currentRects = _currentLeafRects();
      final structureChanged =
          !_sameIdSet(_knownLeafIds, next.leafRects.keys) ||
          _rectsChanged(_settledRects, next.leafRects);

      if (structureChanged) {
        final tokens = context.designSystem ?? DesignSystemTokens.light();
        final fromRects = <String, Rect>{};
        final entering = <String, _EnteringPane>{};
        final exiting = <_ExitingPane>[];

        for (final id in next.leafOrder) {
          final existing = currentRects[id];
          if (existing != null) {
            fromRects[id] = existing;
          } else {
            final toRect = next.leafRects[id]!;
            final start = computeEnteringPaneStart(
              root: widget.layout.root,
              leafId: id,
              toRect: toRect,
              prevRects: currentRects,
              textDirection: direction,
              splitOrigin: widget.layout.lastSplitOrigin,
            );
            fromRects[id] = start.fromRect;
            entering[id] = (
              targetSize: toRect.size,
              alignment: start.alignment,
            );
          }
        }

        for (final entry in currentRects.entries) {
          if (!next.leafRects.containsKey(entry.key)) {
            final collapse = computeExitingPaneCollapse(
              fromRect: entry.value,
              prevRects: currentRects,
              nextRects: next.leafRects,
              hairlineColor: tokens.lineStrong,
            );
            exiting.add((
              id: entry.key,
              from: entry.value,
              to: collapse.toRect,
              seamBorder: collapse.seamBorder,
            ));
          }
        }

        _knownLeafIds = next.leafRects.keys.toSet();
        _settledRects = next.leafRects;

        final duration = CcMotion.resolveTravel(
          context,
          entering.isNotEmpty ? CcMotion.slow : CcMotion.slowExit,
        );
        if (duration == Duration.zero) {
          _anim.stop();
          _anim.value = 1;
          _clearTransition();
        } else {
          _fromRects = fromRects;
          _toRects = next.leafRects;
          _entering = entering;
          _exiting = exiting;
          _anim.duration = duration;
          _anim.forward(from: 0);
        }
      } else {
        _settledRects = next.leafRects;
      }
    }
    setState(() {});
  }

  void _snapTransition() {
    if (_anim.isAnimating) {
      _anim.stop();
      _anim.value = 1;
      setState(_clearTransition);
    }
  }

  void _onDividerDrag(EditorDividerPlacement divider, double delta) {
    final effectiveDelta = divider.isRtl ? -delta : delta;
    final changed = resizeEditorSplit(
      divider.splitNode,
      divider.dividerIndex,
      effectiveDelta,
      divider.splitExtent,
    );
    if (!changed) {
      return;
    }
    setState(() {});
    widget.onResized?.call();
  }

  void _syncViewport(Size size, TextDirection direction, EditorWorkspaceLayout target) {
    if (_lastSize == null || _knownLeafIds.isEmpty) {
      _lastSize = size;
      _lastDirection = direction;
      _knownLeafIds = target.leafRects.keys.toSet();
      _settledRects = target.leafRects;
      return;
    }
    if (size != _lastSize || direction != _lastDirection) {
      if (_anim.isAnimating &&
          direction == _lastDirection &&
          _lastSize!.width > 0 &&
          _lastSize!.height > 0) {
        final sx = size.width / _lastSize!.width;
        final sy = size.height / _lastSize!.height;
        Rect scaleRect(Rect r) =>
            Rect.fromLTWH(r.left * sx, r.top * sy, r.width * sx, r.height * sy);
        _fromRects = {
          for (final e in _fromRects.entries) e.key: scaleRect(e.value),
        };
        _toRects = target.leafRects;
        _entering = {
          for (final e in _entering.entries)
            if (target.leafRects.containsKey(e.key))
              e.key: (
                targetSize: target.leafRects[e.key]!.size,
                alignment: e.value.alignment,
              ),
        };
        _exiting = [
          for (final ex in _exiting)
            (
              id: ex.id,
              from: scaleRect(ex.from),
              to: scaleRect(ex.to),
              seamBorder: ex.seamBorder,
            ),
        ];
      } else if (_anim.isAnimating) {
        _anim.stop();
        _clearTransition();
      }
      _lastSize = size;
      _lastDirection = direction;
      _settledRects = target.leafRects;
    } else if (!_anim.isAnimating) {
      _settledRects = target.leafRects;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final direction = Directionality.of(context);
    final canCloseGroup = widget.layout.leafCount > 1;

    return ColoredBox(
      color: tokens.bgPrimary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(
            constraints.hasBoundedWidth ? constraints.maxWidth : 0,
            constraints.hasBoundedHeight ? constraints.maxHeight : 0,
          );
          final target = solveEditorWorkspaceLayout(
            widget.layout.root,
            size,
            direction,
          );
          _syncViewport(size, direction, target);

          return AnimatedBuilder(
            animation: _anim,
            builder: (context, _) {
              final isAnimating = _anim.isAnimating && _toRects.isNotEmpty;
              final eased = CcMotion.emphasized.transform(_anim.value);
              final leafRects = isAnimating
                  ? {
                      for (final id in target.leafOrder)
                        id: Rect.lerp(
                          _fromRects[id] ?? target.leafRects[id]!,
                          _toRects[id] ?? target.leafRects[id]!,
                          eased,
                        )!,
                    }
                  : target.leafRects;
              final dividers = isAnimating
                  ? computeAnimatedDividers(
                      widget.layout.root,
                      leafRects,
                      direction,
                    )
                  : target.dividers;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  if (isAnimating)
                    for (final ex in _exiting)
                      _buildExitingPlaceholder(
                        ex,
                        Rect.lerp(ex.from, ex.to, eased)!,
                        tokens.bgPrimary,
                      ),
                  for (final id in target.leafOrder)
                    _buildLeafPane(
                      id: id,
                      rect: leafRects[id]!,
                      target: target,
                      canCloseGroup: canCloseGroup,
                      isAnimating: isAnimating,
                    ),
                  for (final d in dividers)
                    Positioned(
                      key: ValueKey('divider:${d.id}'),
                      left: d.hitRect.left,
                      top: d.hitRect.top,
                      width: d.hitRect.width,
                      height: d.hitRect.height,
                      child: CcResizableDivider(
                        axis: d.axis,
                        thickness: 1,
                        hitSize: kEditorDividerHitSize,
                        color: tokens.lineStrong,
                        activeColor: tokens.fgBrandPrimary,
                        onDragStart: _snapTransition,
                        onDrag: (delta) => _onDividerDrag(d, delta),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildExitingPlaceholder(
    _ExitingPane ex,
    Rect rect,
    Color background,
  ) {
    return Positioned(
      key: ValueKey('exiting:${ex.id}'),
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: ExcludeFocus(
            child: ClipRect(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: background,
                  border: ex.seamBorder,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeafPane({
    required String id,
    required Rect rect,
    required EditorWorkspaceLayout target,
    required bool canCloseGroup,
    required bool isAnimating,
  }) {
    final entering = isAnimating ? _entering[id] : null;
    final leaf = target.leaves[id]!;
    return Positioned(
      key: ValueKey(id),
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: EditorPaneViewport(
        layoutSize: entering?.targetSize,
        alignment: entering?.alignment ?? Alignment.topLeft,
        child: EditorTabGroup(
          leafId: id,
          controller: leaf.controller,
          layout: widget.layout,
          buildBody: widget.buildBody,
          canCloseGroup: canCloseGroup,
          chrome: widget.chrome,
        ),
      ),
    );
  }
}
