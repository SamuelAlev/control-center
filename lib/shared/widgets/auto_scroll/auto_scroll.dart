import 'dart:async';

import 'package:control_center/core/theme/app_shadows.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Browser-style middle-click auto-scroll for a single axis.
///
/// Vendored and trimmed from `auto_scrolling: ^0.4.0`. The upstream package
/// calls `setState(...)` from pointer callbacks and an `initState` post-frame
/// callback without `mounted` guards — when a large PR's diff subtree
/// re-mounts files while the user is mid-interaction, a [PointerUpEvent]
/// reaches a disposed `_AutoScrollMouseListenerState` and `setState` throws.
/// The crash then cascades through the layout pipeline (broken
/// `LayoutBuilder` intrinsics, `!_debugDuringDeviceUpdate` mouse-tracker
/// assertions, `RenderBox was not laid out` spam) and the app stops
/// rendering. Every call here checks `mounted` before mutating state.
///
/// The cursor/multi-axis features from the upstream package are not used in
/// this codebase and have been dropped. The browser-style click anchor
/// (chevron rosette painted at the click position) is built in. While
/// scroll is engaged we attach a global pointer route + a hardware-keyboard
/// handler so that any pointer-down anywhere on the app *or* an `Esc` press
/// disengages, even when those happen outside this widget's subtree —
/// matching browser behaviour.
class AutoScroll extends StatefulWidget {
  /// Creates an [AutoScroll] widget.
  const AutoScroll({
    super.key,
    required this.controller,
    this.scrollDirection = Axis.vertical,
    this.deadZoneRadius = 10,
    this.velocity = 0.2,
    this.scrollTick = 15,
    required this.child,
  });

  /// The [ScrollController] attached to the [Scrollable] widget. Must be the
  /// same controller that is attached to the [Scrollable] widget being
  /// auto-scrolled.
  final ScrollController controller;

  /// The direction of the scroll. Defaults to [Axis.vertical].
  final Axis scrollDirection;

  /// A radius around the cursor's start position inside which scrolling
  /// stays disengaged. Defaults to 10 logical pixels.
  final int deadZoneRadius;

  /// Scroll speed multiplier. Higher = faster. Defaults to 0.2.
  final double velocity;

  /// Time in milliseconds between scroll ticks. Defaults to 15ms.
  final int scrollTick;

  /// The wrapped scrollable.
  final Widget child;

  @override
  State<AutoScroll> createState() => _AutoScrollState();
}

class _AutoScrollState extends State<AutoScroll> {
  final GlobalKey _stackKey = GlobalKey();
  Timer? _scrollTimer;
  Offset? _startOffset;
  Offset? _cursorOffset;
  bool _canScroll = false;
  bool _globalAttached = false;

  /// Pointer ID of the press that engaged auto-scroll. The global pointer
  /// route fires for the *same* press that started us (the engage event is
  /// still being dispatched to `GestureBinding` after our local handler
  /// adds the route), so we must skip it once or we'd dismiss ourselves
  /// instantly. Cleared after the first match.
  int? _engagePointerId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final ctl = widget.controller;
      final canScroll =
          ctl.hasClients && ctl.position.maxScrollExtent > 0;
      if (canScroll != _canScroll) {
        setState(() => _canScroll = canScroll);
      }
    });
  }

  @override
  void dispose() {
    _detachGlobalListeners();
    _scrollTimer?.cancel();
    super.dispose();
  }

  void _startScrollTimer() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(
      Duration(milliseconds: widget.scrollTick),
      (timer) {
        final start = _startOffset;
        final cursor = _cursorOffset;
        if (start == null || cursor == null) {
          timer.cancel();
          return;
        }
        final delta = switch (widget.scrollDirection) {
          Axis.horizontal => start.dx - cursor.dx,
          Axis.vertical => start.dy - cursor.dy,
        };
        if (delta.abs() < widget.deadZoneRadius) {
          return;
        }
        final ctl = widget.controller;
        if (!ctl.hasClients) {
          return;
        }
        ctl.position.moveTo(ctl.position.pixels - delta * widget.velocity);
      },
    );
  }

  void _engage(PointerDownEvent event) {
    if (!mounted) {
      return;
    }
    setState(() {
      _startOffset = event.position;
      _cursorOffset = event.position;
    });
    _engagePointerId = event.pointer;
    _startScrollTimer();
    _attachGlobalListeners();
  }

  void _disengage() {
    _scrollTimer?.cancel();
    _detachGlobalListeners();
    _engagePointerId = null;
    if (!mounted) {
      return;
    }
    setState(() {
      _startOffset = null;
      _cursorOffset = null;
    });
  }

  void _attachGlobalListeners() {
    if (_globalAttached) {
      return;
    }
    _globalAttached = true;
    GestureBinding.instance.pointerRouter
        .addGlobalRoute(_handleGlobalPointer);
    HardwareKeyboard.instance.addHandler(_handleGlobalKey);
  }

  void _detachGlobalListeners() {
    if (!_globalAttached) {
      return;
    }
    _globalAttached = false;
    GestureBinding.instance.pointerRouter
        .removeGlobalRoute(_handleGlobalPointer);
    HardwareKeyboard.instance.removeHandler(_handleGlobalKey);
  }

  void _handleGlobalPointer(PointerEvent event) {
    if (event is! PointerDownEvent) {
      return;
    }
    if (event.pointer == _engagePointerId) {
      _engagePointerId = null;
      return;
    }
    if (_startOffset == null) {
      return;
    }
    _disengage();
  }

  bool _handleGlobalKey(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }
    if (event.logicalKey != LogicalKeyboardKey.escape) {
      return false;
    }
    if (_startOffset == null) {
      return false;
    }
    _disengage();
    return true;
  }

  bool _movedPastDeadZone(Offset eventPos) {
    final start = _startOffset;
    if (start == null) {
      return false;
    }
    return (eventPos - start).distance > widget.deadZoneRadius;
  }

  Offset? _anchorLocalOffset() {
    final start = _startOffset;
    if (start == null) {
      return null;
    }
    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return null;
    }
    return box.globalToLocal(start);
  }

  @override
  Widget build(BuildContext context) {
    final localAnchor = _anchorLocalOffset();
    return Stack(
      key: _stackKey,
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: MouseRegion(
            onHover: (event) {
              if (!_canScroll) {
                return;
              }
              if (_startOffset == null) {
                return;
              }
              if (!mounted) {
                return;
              }
              setState(() => _cursorOffset = event.position);
            },
            child: Listener(
              onPointerDown: (event) {
                if (!mounted) {
                  return;
                }
                if (_startOffset != null) {
                  // Already locked — any click (any button) dismisses.
                  // Clicks outside our subtree are handled by the global
                  // pointer route; this branch covers clicks inside.
                  _disengage();
                  return;
                }
                if (!_canScroll || event.buttons != kMiddleMouseButton) {
                  return;
                }
                _engage(event);
              },
              onPointerUp: (event) {
                if (!mounted) {
                  return;
                }
                if (_startOffset == null) {
                  return;
                }
                if (_movedPastDeadZone(event.position)) {
                  _disengage();
                }
              },
              onPointerMove: (event) {
                if (!mounted) {
                  return;
                }
                if (event.buttons != kMiddleMouseButton) {
                  return;
                }
                if (_startOffset == null) {
                  return;
                }
                setState(() => _cursorOffset = event.position);
              },
              child: widget.child,
            ),
          ),
        ),
        if (localAnchor != null)
          Positioned(
            left: localAnchor.dx,
            top: localAnchor.dy,
            child: const FractionalTranslation(
              translation: Offset(-0.5, -0.5),
              child: IgnorePointer(child: _AutoScrollAnchor()),
            ),
          ),
      ],
    );
  }
}

class _AutoScrollAnchor extends StatelessWidget {
  const _AutoScrollAnchor();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final tokens = context.designSystem;
    final bg = isDark ? const Color(0xFF2A2A2A) : (tokens?.panel ?? Colors.white);
    final border = isDark
        ? (tokens?.borderSecondary ?? const Color(0xFF555555))
        : (tokens?.borderSecondary ?? const Color(0xFFC4C4C4));
    final fg = isDark
        ? (tokens?.muted ?? const Color(0xFFCCCCCC))
        : (tokens?.muted ?? const Color(0xFF555555));
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(color: border, width: 1),
        boxShadow: AppShadows.soft,
      ),
      child: CustomPaint(painter: _AnchorRosettePainter(color: fg)),
    );
  }
}

class _AnchorRosettePainter extends CustomPainter {
  _AnchorRosettePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;

    canvas.drawCircle(centre, 1.4, fill);

    const double arm = 3.5;
    const double gap = 6.5;

    void chevron({required Offset tip, required Offset a, required Offset b}) {
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(b.dx, b.dy);
      canvas.drawPath(path, stroke);
    }

    chevron(
      tip: centre.translate(0, -gap - 2),
      a: centre.translate(-arm, -gap),
      b: centre.translate(arm, -gap),
    );
    chevron(
      tip: centre.translate(0, gap + 2),
      a: centre.translate(-arm, gap),
      b: centre.translate(arm, gap),
    );
    chevron(
      tip: centre.translate(-gap - 2, 0),
      a: centre.translate(-gap, -arm),
      b: centre.translate(-gap, arm),
    );
    chevron(
      tip: centre.translate(gap + 2, 0),
      a: centre.translate(gap, -arm),
      b: centre.translate(gap, arm),
    );
  }

  @override
  bool shouldRepaint(covariant _AnchorRosettePainter oldDelegate) =>
      oldDelegate.color != color;
}
