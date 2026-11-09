part of 'rig_input_surface.dart';

/// Pointer events translated into guest actions: press, hold, move, release
/// and wheel, in the order they happened.
extension _RigInputPointer on _RigInputSurfaceState {
  void _onPointerDown(PointerDownEvent event, Size canvas) {
    _focus.requestFocus();
    // Before the early returns below, not after: a press ends the run of
    // text even when the press itself lands in the letterbox and sends
    // nothing.
    _keystrokes.flush();
    if (_isIos) {
      if (_iosPointer != null || event.buttons != kPrimaryMouseButton) {
        return;
      }
      final point = _toGuest(event.localPosition, canvas);
      if (point == null) {
        return;
      }
      _iosPointer = event.pointer;
      _iosGestureStart = point;
      _iosGestureStartedAt = DateTime.now();
      return;
    }
    final point = _toGuest(event.localPosition, canvas);
    if (point == null) {
      return;
    }
    _downButtons = event.buttons;
    if (event.buttons == kPrimaryMouseButton) {
      // Raw press/release, not a synthesized click: the GUEST derives
      // single/double clicks and drags natively, exactly as it would from a
      // real mouse — the browser surface included, where press-hold-move is
      // what text selection IS.
      _enqueue({
        'action': 'mouse_move',
        'coordinate': [point.$1, point.$2],
      });
      _enqueue({'action': 'left_mouse_down'});
      _leftDown = true;
      // Issued now, while the guest cannot yet have started a drag of its
      // own — see [_dragBaseline].
      _captureDragBaseline();
    }
  }

  void _onPointerMove(PointerMoveEvent event, Size canvas) {
    if (_isIos) {
      return;
    }
    if (!_leftDown) {
      return;
    }
    final point = _toGuest(event.localPosition, canvas);
    if (point == null) {
      return;
    }
    _enqueue({
      'action': 'mouse_move',
      'coordinate': [point.$1, point.$2],
    }, coalesce: true);
  }

  /// Streams HOVER movement so the guest pointer tracks the local one.
  ///
  /// This is what dissolves the app/VM seam: menus highlight, links glow and
  /// the guest cursor follows before anything is clicked, the way a local
  /// desktop behaves. Throttled — the queue coalesces backlog, and the time
  /// gate keeps a fast wiggle from becoming an RPC per pixel.
  void _onPointerHover(PointerHoverEvent event, Size canvas) {
    if (_isIos) {
      return;
    }
    final now = DateTime.now();
    if (now.difference(_lastHoverSent).inMilliseconds < 25) {
      return;
    }
    final point = _toGuest(event.localPosition, canvas);
    if (point == null) {
      return;
    }
    _lastHoverSent = now;
    // Remembered for a paste of FILES, which has no position of its own: a
    // browser page's dropzone needs a point, and the last place the pointer
    // was is the only honest guess at where the user meant.
    _lastGuestPoint = point;
    _enqueue({
      'action': 'mouse_move',
      'coordinate': [point.$1, point.$2],
    }, coalesce: true);
  }

  /// The gesture arena took the pointer (a scrollable claimed it, the window
  /// lost focus mid-drag, the platform cancelled the sequence).
  ///
  /// Flutter delivers a CANCEL instead of an up, so without this the guest
  /// never sees `left_mouse_up`: its button stays down, `_leftDown` stays
  /// true, and every later move drags the guest with the button held until
  /// the user clicks again to break it. A cancelled press is still a press
  /// that must end.
  void _onPointerCancel(PointerCancelEvent event, Size canvas) {
    if (_isIos) {
      if (event.pointer == _iosPointer) {
        _iosPointer = null;
        _iosGestureStart = null;
        _iosGestureStartedAt = null;
      }
      return;
    }
    _keystrokes.flush();
    _downButtons = 0;
    if (!_leftDown) {
      return;
    }
    _leftDown = false;
    _enqueue({'action': 'left_mouse_up'});
  }

  void _onPointerUp(PointerUpEvent event, Size canvas) {
    _keystrokes.flush();
    if (_isIos) {
      if (event.pointer != _iosPointer) {
        return;
      }
      final from = _iosGestureStart;
      final startedAt = _iosGestureStartedAt;
      final to = _toGuest(event.localPosition, canvas);
      _iosPointer = null;
      _iosGestureStart = null;
      _iosGestureStartedAt = null;
      if (from == null || to == null) {
        return;
      }
      _enqueue(
        rigIosGestureAction(
          from: from,
          to: to,
          elapsed: startedAt == null
              ? const Duration(milliseconds: 300)
              : DateTime.now().difference(startedAt),
        ),
      );
      return;
    }
    final point = _toGuest(event.localPosition, canvas);
    final buttons = _downButtons;
    _downButtons = 0;
    if (_leftDown) {
      _leftDown = false;
      if (point != null) {
        _enqueue({
          'action': 'mouse_move',
          'coordinate': [point.$1, point.$2],
        });
      }
      _enqueue({'action': 'left_mouse_up'});
      return;
    }
    if (point == null) {
      return;
    }
    if (buttons & kSecondaryMouseButton != 0) {
      // The verb differs per surface, the intent does not: open the context
      // menu at that point.
      _enqueue(
        _speaksComputerInput
            ? {
                'action': 'right_click',
                'coordinate': [point.$1, point.$2],
              }
            : {
                'action': 'click',
                'coordinate': [point.$1, point.$2],
                'button': 'right',
              },
      );
    } else if (buttons & kMiddleMouseButton != 0) {
      _enqueue(
        _speaksComputerInput
            ? {
                'action': 'middle_click',
                'coordinate': [point.$1, point.$2],
              }
            : {
                'action': 'click',
                'coordinate': [point.$1, point.$2],
                'button': 'middle',
              },
      );
    }
  }

  void _onPointerSignal(PointerSignalEvent event, Size canvas) {
    if (_isIos) {
      return;
    }
    if (event is! PointerScrollEvent) {
      return;
    }
    final point = _toGuest(event.localPosition, canvas);
    if (point == null) {
      return;
    }
    if (_speaksComputerInput) {
      final dy = event.scrollDelta.dy;
      final dx = event.scrollDelta.dx;
      final vertical = dy.abs() >= dx.abs();
      final delta = vertical ? dy : dx;
      if (delta == 0) {
        return;
      }
      _enqueue({
        'action': 'scroll',
        'scroll_direction': vertical
            ? (delta > 0 ? 'down' : 'up')
            : (delta > 0 ? 'right' : 'left'),
        'scroll_amount': (delta.abs() / 40).ceil().clamp(1, 10),
        'coordinate': [point.$1, point.$2],
      }, coalesce: true);
    } else {
      _enqueue({
        'action': 'scroll',
        'dx': event.scrollDelta.dx.round(),
        'dy': event.scrollDelta.dy.round(),
      }, coalesce: true);
    }
  }
}
