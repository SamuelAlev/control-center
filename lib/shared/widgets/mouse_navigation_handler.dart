import 'dart:async';
import 'dart:math';

import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class NavigationHistoryState {
  const NavigationHistoryState({this.canGoBack = false, this.canGoForward = false});
  final bool canGoBack;
  final bool canGoForward;
}

class NavigationHistoryController extends Notifier<NavigationHistoryState> {
  VoidCallback? _onGoBack;
  VoidCallback? _onGoForward;

  @override
  NavigationHistoryState build() => const NavigationHistoryState();

  void goBack() => _onGoBack?.call();
  void goForward() => _onGoForward?.call();

  void update({
    required bool canBack,
    required bool canForward,
    VoidCallback? onGoBack,
    VoidCallback? onGoForward,
  }) {
    _onGoBack = onGoBack;
    _onGoForward = onGoForward;
    if (state.canGoBack != canBack || state.canGoForward != canForward) {
      Future.microtask(() {
        state = NavigationHistoryState(canGoBack: canBack, canGoForward: canForward);
      });
    }
  }
}

final navigationHistoryProvider =
    NotifierProvider<NavigationHistoryController, NavigationHistoryState>(
      NavigationHistoryController.new,
    );

class MouseNavigationHandler extends StatefulWidget {
  const MouseNavigationHandler({
    super.key,
    required this.child,
    this.historyController,
  });

  final Widget child;
  final NavigationHistoryController? historyController;

  @override
  State<MouseNavigationHandler> createState() => _MouseNavigationHandlerState();
}

class _MouseNavigationHandlerState extends State<MouseNavigationHandler> {
  final List<String> _backStack = [];
  final List<String> _forwardStack = [];
  String? _currentRoute;
  bool _navigating = false;

  bool _autoScrolling = false;
  Offset? _autoScrollOrigin;
  Offset? _currentMousePosition;
  ScrollableState? _autoScrollState;
  Timer? _autoScrollTimer;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _syncController();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  void _syncController() {
    widget.historyController?.update(
      canBack: _backStack.isNotEmpty,
      canForward: _forwardStack.isNotEmpty,
      onGoBack: _goBack,
      onGoForward: _goForward,
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location != _currentRoute && !_navigating) {
      if (_currentRoute != null) {
        _backStack.add(_currentRoute!);
      }
      _forwardStack.clear();
    }
    _currentRoute = location;
    _navigating = false;
    _syncController();

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_autoScrolling &&
        (event.buttons & kPrimaryMouseButton != 0 ||
            event.buttons & kSecondaryMouseButton != 0)) {
      _stopAutoScroll();
      return;
    }

    if (event.buttons & kBackMouseButton != 0) {
      _goBack();
    } else if (event.buttons & kForwardMouseButton != 0) {
      _goForward();
    } else if (event.buttons & kTertiaryButton != 0) {
      if (_autoScrolling) {
        _stopAutoScroll();
      } else {
        _startAutoScroll(event.position);
      }
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_autoScrolling) {
      _currentMousePosition = event.position;
    }
  }

  void _goBack() {
    if (!mounted) {
      return;
    }
    final router = GoRouter.of(context);
    if (_backStack.isNotEmpty) {
      _forwardStack.add(_currentRoute!);
      final target = _backStack.removeLast();
      _navigating = true;
      router.go(target);
    } else if (router.canPop()) {
      _navigating = true;
      router.pop();
    } else if (_currentRoute != dashboardRoute) {
      _navigating = true;
      router.go(dashboardRoute);
    }
  }

  void _goForward() {
    if (!mounted) {
      return;
    }
    if (_forwardStack.isNotEmpty) {
      final router = GoRouter.of(context);
      _backStack.add(_currentRoute!);
      final target = _forwardStack.removeLast();
      _navigating = true;
      router.go(target);
    }
  }

  void _startAutoScroll(Offset position) {
    final state = _findScrollableAtPosition(position, View.of(context).viewId);
    if (state == null) {
      return;
    }

    _autoScrolling = true;
    _autoScrollOrigin = position;
    _currentMousePosition = position;
    _autoScrollState = state;

    _showOverlay(position);
    _autoScrollTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _applyAutoScroll(),
    );
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _hideOverlay();
    if (mounted) {
      setState(() {
        _autoScrolling = false;
        _autoScrollOrigin = null;
        _currentMousePosition = null;
        _autoScrollState = null;
      });
    }
  }

  void _showOverlay(Offset position) {
    final tokens = context.designSystem;
    final entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              left: position.dx - 16,
              top: position.dy - 16,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (tokens?.fg ?? const Color(0xFF1F1F1F))
                      .withValues(alpha: 0.5),
                  border: Border.all(
                    color: tokens?.accent ?? Colors.white,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  LucideIcons.move,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    _overlayEntry = entry;
    Overlay.of(context).insert(entry);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _applyAutoScroll() {
    if (_autoScrollOrigin == null ||
        _currentMousePosition == null ||
        _autoScrollState == null ||
        !_autoScrollState!.mounted) {
      _stopAutoScroll();
      return;
    }

    final dx = _currentMousePosition!.dx - _autoScrollOrigin!.dx;
    final dy = _currentMousePosition!.dy - _autoScrollOrigin!.dy;
    final distance = sqrt(dx * dx + dy * dy);

    if (distance < 10) {
      return;
    }

    final speed = distance * 0.15;
    final position = _autoScrollState!.position;

    if (!_autoScrollState!.position.hasContentDimensions) {
      return;
    }

    final axis = _autoScrollState!.position.axis;
    final delta = axis == Axis.horizontal
        ? (dx / distance) * speed
        : (dy / distance) * speed;

    final target =
        (position.pixels + delta).clamp(position.minScrollExtent, position.maxScrollExtent);
    position.jumpTo(target);
  }

  ScrollableState? _findScrollableAtPosition(Offset position, int viewId) {
    final hitTestResult = HitTestResult();
    GestureBinding.instance.hitTestInView(hitTestResult, position, viewId);

    RenderBox? hitBox;
    for (final entry in hitTestResult.path.toList().reversed) {
      if (entry.target is RenderBox) {
        hitBox = entry.target as RenderBox;
        break;
      }
    }
    if (hitBox == null) {
      return null;
    }

    RenderObject? viewportRender;
    RenderObject? render = hitBox;
    while (render != null) {
      if (render is RenderAbstractViewport) {
        viewportRender = render;
        break;
      }
      render = render.parent;
    }
    if (viewportRender == null) {
      return null;
    }

    final rootContext = rootNavigatorKey.currentContext;
    if (rootContext == null) {
      return null;
    }

    Element? viewportElement;
    void search(Element element) {
      if (viewportElement != null) {
        return;
      }
      if (element is RenderObjectElement &&
          element.renderObject == viewportRender) {
        viewportElement = element;
        return;
      }
      element.visitChildren(search);
    }

    (rootContext as Element).visitChildren(search);
    if (viewportElement == null) {
      return null;
    }

    ScrollableState? result;
    viewportElement!.visitAncestorElements((element) {
      if (element.widget is Scrollable) {
        result = (element as StatefulElement).state as ScrollableState;
        return false;
      }
      return true;
    });
    return result;
  }
}
