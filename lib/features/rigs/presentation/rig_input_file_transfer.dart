part of 'rig_input_surface.dart';

/// Files dragged into the machine and out of it.
extension _RigInputFileTransfer on _RigInputSurfaceState {
  /// Wraps [child] so files can be dragged INTO the machine and out of it.
  ///
  /// Both halves live here because both need the letterbox maths that maps a
  /// canvas point to a guest pixel — a drop delivered at (0, 0) hits the
  /// wrong element on every page there has ever been.
  Widget _wrapWithFileTransfer({required Size canvas, required Widget child}) {
    if (_isIos) {
      return child;
    }
    // What there IS, while an X application drags something, is that application OWNING the
    // `XdndSelection` — so the drag payload can be asked for, and only then.
    // Hence the shape: the OS's own drag gesture over this canvas asks the guest what it is
    // dragging, and returns null (no drag starts, nothing visible happens) when the answer is
    // "nothing", which is the answer almost every time.
    final draggable = DragItemWidget(
      allowedOperations: () => const [DropOperation.copy],
      dragItemProvider: _dragOutItem,
      child: DraggableWidget(
        // Only when this user is actually driving. An agent-driven rig is
        // watch-only, and a drag gesture over it belongs to the app (scroll,
        // tab switch), not to a machine nobody has taken control of.
        isLocationDraggable: (_) => widget.enabled && widget.active,
        child: child,
      ),
    );

    return DropRegion(
      formats: Formats.standardFormats,
      hitTestBehavior: HitTestBehavior.opaque,
      // Copy, never move: a drop into a VM must not invite the source
      // application to delete the original.
      onDropOver: (event) =>
          widget.enabled ? DropOperation.copy : DropOperation.none,
      onPerformDrop: (event) => _acceptDrop(event, canvas),
      child: draggable,
    );
  }

  /// Notes what the guest is holding, so [_dragOutItem] can tell a NEW drag
  /// from a stale selection. Fire-and-forget: it must not delay the press.
  void _captureDragBaseline() {
    final bridge = _bridge;
    if (bridge == null || !widget.enabled || !_isComputer) {
      // Only the desktop surface has a drag selection to read — see
      // [_dragOutItem].
      return;
    }
    _dragBaseline = null;
    unawaited(
      bridge.peekDragPayload().then((payload) {
        // Dropped if the drag already started: a baseline captured after the
        // fact would BE the new payload, and comparing it against itself
        // refuses the drag. Late is worse than absent here.
        _dragBaseline ??= payload == null
            ? ''
            : RigClipboardBridge.fingerprintOf(payload);
      }, onError: (_) {}),
    );
  }

  /// Builds the drag item for a drag that started over this canvas, or null
  /// when the guest is not dragging anything new.
  ///
  /// Desktop only. A browser rig is deliberately excluded: headless Chromium
  /// has no drag selection to read, and the nearest available signal — the
  /// page's current text selection — is not evidence of a drag at all. Acting
  /// on it would hijack every click-drag over a page that happened to have
  /// something selected. Copying out of a browser rig is what ctrl+C is for.
  Future<DragItem?> _dragOutItem(DragItemRequest request) async {
    final bridge = _bridge;
    if (bridge == null || !widget.enabled || !_isComputer) {
      return null;
    }
    // Poll briefly. The host recognises a drag after a few pixels of
    // movement; the guest has to receive those moves and its application has
    // to start its own drag, which is at least one round trip later. Giving
    // up immediately would mean drag-out never worked; waiting long would
    // stall every ordinary drag inside the guest, so this is short and the
    // failure is silent.
    RigClipboardData? payload;
    for (var attempt = 0; attempt < 4; attempt++) {
      final seen = await bridge.peekDragPayload();
      // A payload identical to the pre-press baseline is the stale selection
      // of a drag that already finished, not this one.
      if (seen != null &&
          RigClipboardBridge.fingerprintOf(seen) != _dragBaseline) {
        payload = seen;
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    if (payload == null) {
      return null;
    }
    final item = DragItem();
    if (payload.files.isNotEmpty) {
      final staged = await bridge.stageForDrag(payload);
      if (staged != null) {
        item
          ..add(Formats.fileUri(staged.uri))
          ..add(Formats.plainText(staged.name));
        // The guest is still mid-drag with its button held. Whatever happens
        // on this side, it must not ALSO drop inside the guest when the
        // button comes back up — that would put the file in two places, one
        // of which nobody asked for.
        unawaited(_cancelGuestDrag());
        return item;
      }
    }
    final text = payload.text;
    if (text != null && text.isNotEmpty) {
      item.add(Formats.plainText(text));
      unawaited(_cancelGuestDrag());
      return item;
    }
    return null;
  }

  /// Ends the guest's own drag once the host has taken the payload.
  ///
  /// Escape then a button release, in that order: Escape is what every X
  /// toolkit reads as "abandon this drag", and the release afterwards makes
  /// sure the guest is not left believing a button is still down — a stuck
  /// button turns every later pointer move into a drag.
  Future<void> _cancelGuestDrag() async {
    _leftDown = false;
    _enqueue(
      _speaksComputerInput
          ? {'action': 'key', 'text': 'Escape'}
          : {'action': 'key', 'key': 'Escape'},
    );
    _enqueue({'action': 'left_mouse_up'});
  }

  /// Takes a file drop from the OS and sends it into the machine.
  Future<void> _acceptDrop(PerformDropEvent event, Size canvas) async {
    final bridge = _bridge;
    if (bridge == null || !widget.enabled) {
      return;
    }
    final readers = [
      for (final item in event.session.items)
        if (item.dataReader != null) item.dataReader!,
    ];
    final snapshot = await snapshotFromReader(readers);
    if (!mounted) {
      return;
    }
    if (snapshot.files.isEmpty) {
      // Text or an image dragged in, not a file. It is still a paste, and
      // pasting it is what the user meant — the alternative is a drop that
      // silently does nothing.
      if (!snapshot.isEmpty) {
        final pushed = await bridge.pushToGuest(snapshot);
        if (pushed.ok) {
          _enqueue(
            _speaksComputerInput
                ? {'action': 'key', 'text': 'ctrl+v'}
                : {
                    'action': 'key',
                    'key': 'v',
                    'modifiers': ['ctrl'],
                  },
          );
        } else {
          _report(pushed);
        }
      }
      return;
    }
    await _deliverFiles(
      bridge,
      snapshot.files,
      point: _toGuest(event.position.local, canvas) ?? _lastGuestPoint,
    );
  }
}
