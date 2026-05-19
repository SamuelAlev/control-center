// Human input for a rig: pointer + keyboard, forwarded as rig.act.
//
// The server is the chokepoint — every event lands in `rig_action_log`
// attributed to this user, and the take-over lock is enforced there, not
// here. This widget's job is only translation: canvas coordinates into guest
// pixels, Flutter key events into the names the action layer speaks, and a
// strict ordering so a click cannot overtake the move that positions it.
// Both drivable surfaces get the same raw stream — hover moves, press/hold/
// release, wheel, coalesced typing — because press-hold-move is what text
// selection IS, in a browser page exactly as on a desktop.
library;

import 'dart:async';

import 'package:cc_data/cc_data.dart' show RemoteRigRepository, RigView;
import 'package:cc_domain/features/rigs/domain/value_objects/rig_clipboard.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/infrastructure/clipboard/host_clipboard.dart';
import 'package:control_center/core/keybindings/text_input_surface.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/rigs/presentation/rig_action_queue.dart';
import 'package:control_center/features/rigs/presentation/rig_key_translation.dart';
import 'package:control_center/features/rigs/presentation/rig_keystroke_coalescer.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/features/rigs/providers/rig_transfer_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

/// The three things a clipboard chord can mean.
enum RigClipboardChord {
  /// Copy the guest's selection out to this host.
  copy,

  /// Cut it out to this host.
  cut,

  /// Paste this host's clipboard into the guest.
  paste,
}

/// The clipboard chord [event] is, or null when it is not one.
///
/// Reads the HOST's convention, not the guest's: Cmd on macOS, Ctrl
/// elsewhere. That distinction is the whole reason this is a function.
///
/// On macOS it is unambiguous — `super+c` means nothing to an XFCE desktop or
/// a Chromium page, so intercepting Cmd+C costs nothing and Ctrl+C still
/// reaches a guest terminal as the SIGINT it is.
///
/// On Windows and Linux the host chord and the guest chord are the SAME
/// keystroke, and Ctrl+C in a guest terminal is an interrupt rather than a
/// copy. The handler deals with that by forwarding the chord to the guest
/// unchanged and only writing the host clipboard when the guest's actually
/// changed — so an interrupt stays an interrupt and does not overwrite what
/// the user had copied.
RigClipboardChord? rigClipboardChordFor(KeyEvent event) {
  final keyboard = HardwareKeyboard.instance;
  final usesMeta =
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.iOS;
  final held = usesMeta ? keyboard.isMetaPressed : keyboard.isControlPressed;
  if (!held || keyboard.isAltPressed) {
    return null;
  }
  // On macOS the modifier must be META and nothing else: ctrl+cmd+C is a
  // different chord and forwarding it as a plain copy would be wrong.
  if (usesMeta && keyboard.isControlPressed) {
    return null;
  }
  final key = event.logicalKey;
  if (key == LogicalKeyboardKey.keyC) {
    return RigClipboardChord.copy;
  }
  if (key == LogicalKeyboardKey.keyX) {
    return RigClipboardChord.cut;
  }
  if (key == LogicalKeyboardKey.keyV) {
    return RigClipboardChord.paste;
  }
  return null;
}

/// Captures pointer and keyboard input over a rig's live canvas and forwards
/// it to the guest.
///
/// Layout-transparent: it draws nothing and sizes to [child], which must be
/// the canvas the frames are painted into with `BoxFit.contain` — the
/// letterbox math here mirrors that fit to map taps into guest pixels.
class RigInputSurface extends ConsumerStatefulWidget {
  /// Creates a [RigInputSurface].
  const RigInputSurface({
    super.key,
    required this.workspaceId,
    required this.rig,
    required this.enabled,
    this.active = true,
    required this.child,
  });

  /// The owning workspace.
  final String workspaceId;

  /// The rig being driven.
  final RigView rig;

  /// Whether input is captured at all. False renders [child] untouched — an
  /// agent-driven rig is watch-only and every pointer event falls through to
  /// the app (tab switching, scrolling the page) instead of into the VM.
  final bool enabled;

  /// Whether this canvas is the tab on screen. Becoming active grabs the
  /// keyboard: a machine the user switched to should be the sole recipient of
  /// input without needing a click first.
  final bool active;

  /// The frame canvas.
  final Widget child;

  @override
  ConsumerState<RigInputSurface> createState() => _RigInputSurfaceState();
}

class _RigInputSurfaceState extends ConsumerState<RigInputSurface> {
  final FocusNode _focus = FocusNode(debugLabel: 'rig-input');

  /// Whether the pointer is over the canvas. While it is, the machine owns
  /// the keyboard — hover-to-type, the way a remote desktop behaves — and
  /// the surface re-asserts focus if anything in the app steals it.
  bool _pointerInside = false;

  /// Read once, not per action: [RigActionQueue] keeps draining through
  /// [dispose], and `ref` is unusable by then.
  late final RemoteRigRepository _rigs;

  /// Batches printable characters into one `type` action each.
  late final KeystrokeCoalescer _keystrokes = KeystrokeCoalescer(
    onFlush: (text) => _enqueueRaw({'action': 'type', 'text': text}),
  );

  @override
  void initState() {
    super.initState();
    // Resolved while the element is definitely alive.
    _rigs = ref.read(rigRepositoryProvider);
    if (widget.enabled && widget.active) {
      // The machine on screen owns the keyboard from the first frame — no
      // click required.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.enabled && widget.active) {
          _focus.requestFocus();
        }
      });
    }
  }

  @override
  void didUpdateWidget(RigInputSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled &&
        widget.active &&
        !(oldWidget.active && oldWidget.enabled)) {
      _focus.requestFocus();
    }
    // Losing capture (control handed back, the tab hidden) ends the run being
    // typed: holding it would deliver it later, out of order with whatever
    // happened in between.
    if (!widget.enabled || !widget.active) {
      _keystrokes.flush();
    }
  }

  /// Actions waiting to be sent, in input order.
  late final RigActionQueue _actions = RigActionQueue(
    send: (action) => _rigs.act(
      workspaceId: widget.workspaceId,
      rigId: widget.rig.id,
      action: action,
    ),
  );

  bool _leftDown = false;
  int _downButtons = 0;

  // ── The clipboard and file bridge ───────────────────────────────────────

  /// Built from the ambient proxy scope, which is where the signed URLs for
  /// the server's rig lanes come from. Null before the connection exists.
  RigTransferClient? _transferClient;
  RigClipboardBridge? _bridge;

  /// Guards against a second chord starting while one is in flight. A held
  /// ctrl+V repeats at the OS key-repeat rate, and each one is a round trip
  /// through the server into a guest.
  bool _clipboardBusy = false;

  /// Where the pointer last was in guest pixels, for a drop with no position
  /// of its own (a paste of files).
  (int, int)? _lastGuestPoint;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final proxy = MediaProxyScope.configOf(context);
    if (proxy == null || _transferClient?.proxy == proxy) {
      return;
    }
    _transferClient?.close();
    final client = rigTransferClientFor(context);
    _transferClient = client;
    _bridge = client == null
        ? null
        : rigClipboardBridgeFor(
            client: client,
            workspaceId: widget.workspaceId,
            rigId: widget.rig.id,
          );
  }

  @override
  void dispose() {
    // Flush BEFORE tearing down: the last word typed is already the user's
    // input, and the queue deliberately outlives this widget so it reaches
    // the machine.
    _keystrokes.dispose();
    _transferClient?.close();
    _focus.dispose();
    super.dispose();
  }

  /// Shows [outcome] to the user, quietly when there was nothing to carry.
  void _report(RigClipboardOutcome outcome) {
    if (!mounted || outcome.wasEmpty) {
      // A copy with nothing selected is a no-op, and a toast for it is noise
      // in a surface where people press ctrl+C constantly.
      return;
    }
    CcToastScope.of(context).show(
      outcome.summary,
      variant: outcome.ok ? CcToastVariant.neutral : CcToastVariant.danger,
    );
  }

  /// Runs a clipboard chord: forward it to the guest, then move the content.
  Future<void> _runClipboardChord(RigClipboardChord chord) async {
    final bridge = _bridge;
    if (bridge == null || _clipboardBusy) {
      return;
    }
    _clipboardBusy = true;
    try {
      if (chord == RigClipboardChord.paste) {
        await _pasteIntoGuest(bridge);
      } else {
        await _copyFromGuest(bridge, cut: chord == RigClipboardChord.cut);
      }
    } on Object catch (e) {
      AppLog.d('rig-input', 'clipboard chord ${chord.name} failed: $e');
    } finally {
      _clipboardBusy = false;
    }
  }

  /// Tells the guest to copy, then carries what it copied to this host.
  Future<void> _copyFromGuest(
    RigClipboardBridge bridge, {
    required bool cut,
  }) async {
    final letter = cut ? 'x' : 'c';
    // In the GUEST's vocabulary, always ctrl — a Linux desktop and a Chromium
    // page both copy with ctrl, whatever the host's own convention is.
    _enqueue(
      _isComputer
          ? {'action': 'key', 'text': 'ctrl+$letter'}
          : {
              'action': 'key',
              'key': letter,
              'modifiers': ['ctrl'],
            },
    );
    // Awaited, not assumed: reading before the chord has reached the guest
    // reads the PREVIOUS clipboard, and writing that to the host is silent
    // data loss for whatever the user actually had.
    await _actions.drain();
    // The guest's own applications need a moment to service the chord and
    // take ownership of the selection. Short enough to feel instant, long
    // enough that a normal application has answered.
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) {
      return;
    }
    // `pullToHost` refuses to carry content the guest was already holding —
    // which is what a ctrl+C that meant "interrupt" looks like on Windows and
    // Linux, where the crossing chord is the guest's own.
    _report(await bridge.pullToHost());
  }

  /// Puts this host's clipboard into the guest and tells it to paste.
  Future<void> _pasteIntoGuest(RigClipboardBridge bridge) async {
    final snapshot = await bridge.readHost();
    if (!mounted) {
      return;
    }
    if (snapshot.isEmpty) {
      return;
    }
    // Files are a COPY, not a clipboard write: they have to exist inside the
    // guest before anything there can open them.
    if (snapshot.files.isNotEmpty) {
      await _deliverFiles(bridge, snapshot.files, point: _lastGuestPoint);
      return;
    }
    final pushed = await bridge.pushToGuest(snapshot);
    if (!mounted) {
      return;
    }
    if (pushed.ok) {
      _enqueue(
        _isComputer
            ? {'action': 'key', 'text': 'ctrl+v'}
            : {
                'action': 'key',
                'key': 'v',
                'modifiers': ['ctrl'],
              },
      );
      return;
    }
    // The guest's clipboard could not be written — on the browser surface
    // that is a page served over plain http, which browsers give no
    // clipboard at all. Text can still be INSERTED at the caret, which is
    // what a paste does anyway; an image cannot, so say so.
    final text = snapshot.text;
    if (!_isComputer && text != null && text.isNotEmpty) {
      _enqueue({'action': 'type', 'text': text});
      return;
    }
    _report(pushed);
  }

  /// Copies [files] into the guest, offered at [point] when there is one.
  Future<void> _deliverFiles(
    RigClipboardBridge bridge,
    List<HostFile> files, {
    (int, int)? point,
  }) async {
    if (files.isEmpty) {
      return;
    }
    if (mounted) {
      final l10n = AppLocalizations.of(context);
      CcToastScope.of(context).show(
        files.length == 1
            ? l10n.rigDropSendingOne(files.single.name)
            : l10n.rigDropSendingMany(files.length),
      );
    }
    final result = await bridge.dropFiles(files, x: point?.$1, y: point?.$2);
    if (!mounted) {
      return;
    }
    CcToastScope.of(context).show(
      result.summary,
      variant: result.isError ? CcToastVariant.danger : CcToastVariant.neutral,
    );
  }

  // ── Sending ─────────────────────────────────────────────────────────────

  /// Enqueues a non-text action, flushing buffered keystrokes ahead of it.
  ///
  /// The flush lives HERE rather than at each call site so ordering cannot be
  /// forgotten by a later one: text the user typed always reaches the guest
  /// before the click, key or scroll that followed it.
  void _enqueue(Map<String, dynamic> action, {bool coalesce = false}) {
    _keystrokes.flush();
    _enqueueRaw(action, coalesce: coalesce);
  }

  void _enqueueRaw(Map<String, dynamic> action, {bool coalesce = false}) =>
      _actions.add(action, coalesce: coalesce);

  // ── Coordinate mapping ──────────────────────────────────────────────────

  /// Maps a canvas-local position to guest pixels, or null when it falls in
  /// the letterbox or the guest's display size is not known yet.
  (int, int)? _toGuest(Offset local, Size canvas) {
    final gw = widget.rig.displayWidth;
    final gh = widget.rig.displayHeight;
    if (gw == null || gh == null || gw <= 0 || gh <= 0) {
      return null;
    }
    final scale = _min(canvas.width / gw, canvas.height / gh);
    if (scale <= 0) {
      return null;
    }
    final ox = (canvas.width - gw * scale) / 2;
    final oy = (canvas.height - gh * scale) / 2;
    final x = (local.dx - ox) / scale;
    final y = (local.dy - oy) / scale;
    if (x < 0 || y < 0 || x >= gw || y >= gh) {
      return null;
    }
    return (x.round().clamp(0, gw - 1), y.round().clamp(0, gh - 1));
  }

  static double _min(double a, double b) => a < b ? a : b;

  bool get _isComputer => widget.rig.surfaceKind != RigSurface.browser;

  // ── Pointer ─────────────────────────────────────────────────────────────

  void _onPointerDown(PointerDownEvent event, Size canvas) {
    _focus.requestFocus();
    // Before the early returns below, not after: a press ends the run of
    // text even when the press itself lands in the letterbox and sends
    // nothing.
    _keystrokes.flush();
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

  DateTime _lastHoverSent = DateTime.fromMillisecondsSinceEpoch(0);

  void _onPointerMove(PointerMoveEvent event, Size canvas) {
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
        _isComputer
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
        _isComputer
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
    if (event is! PointerScrollEvent) {
      return;
    }
    final point = _toGuest(event.localPosition, canvas);
    if (point == null) {
      return;
    }
    if (_isComputer) {
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

  // ── Keyboard ────────────────────────────────────────────────────────────

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) {
      // Presses are sent as full chords on the way down; a release on its
      // own has nothing to add. Swallowed so it cannot leak into the app.
      return KeyEventResult.handled;
    }
    if (kRigBareModifiers.contains(event.logicalKey)) {
      return KeyEventResult.handled; // Rides along in the chord.
    }
    // Clipboard chords are intercepted BEFORE the generic key path, because
    // the generic path would forward Cmd+C to a Linux guest as `super+c`,
    // which means nothing anywhere. See [rigClipboardChordFor] for how the
    // ambiguous (Windows/Linux) case stays honest.
    final clipboard = rigClipboardChordFor(event);
    if (clipboard != null) {
      _keystrokes.flush();
      unawaited(_runClipboardChord(clipboard));
      return KeyEventResult.handled;
    }
    final pressed = HardwareKeyboard.instance;
    final ctrl = pressed.isControlPressed;
    final alt = pressed.isAltPressed;
    final meta = pressed.isMetaPressed;
    final shift = pressed.isShiftPressed;

    final character = event.character;
    if (_isComputer) {
      if (character != null &&
          character.isNotEmpty &&
          !ctrl &&
          !alt &&
          !meta &&
          !kRigControlCharacters.contains(character)) {
        // Buffered, not sent: a word becomes one `type` action. Anything
        // that is not a printable character flushes it first (see
        // [_enqueue]), so ordering survives.
        _keystrokes.add(character);
        return KeyEventResult.handled;
      }
      final name = rigX11NameFor(event.logicalKey);
      if (name == null) {
        return KeyEventResult.handled;
      }
      final combo = [
        if (ctrl) 'ctrl',
        if (alt) 'alt',
        if (meta) 'super',
        // Shift only matters for named keys — a shifted character already
        // arrived uppercase through the character branch above.
        if (shift) 'shift',
        name,
      ].join('+');
      _enqueue({'action': 'key', 'text': combo});
      return KeyEventResult.handled;
    }

    // Browser: printable characters are batched into ONE `type` action, the
    // same as the computer surface — a word per round trip instead of a JSON
    // RPC per letter, and an audit entry whose redaction covers a run of
    // text rather than hashing one character at a time (a one-character hash
    // over a ~100-symbol alphabet is brute-forced instantly, so per-character
    // "redaction" protected nothing).
    if (character != null &&
        character.isNotEmpty &&
        !ctrl &&
        !alt &&
        !meta &&
        !kRigControlCharacters.contains(character)) {
      _keystrokes.add(character);
      return KeyEventResult.handled;
    }
    final modifiers = [
      if (ctrl) 'ctrl',
      if (alt) 'alt',
      if (meta) 'meta',
      if (shift) 'shift',
    ];
    final cdpName = rigCdpNameFor(event.logicalKey);
    if (cdpName != null) {
      // Named keys carry their modifiers: shift+ArrowLeft extends the
      // selection, ctrl+Enter submits the form.
      _enqueue({
        'action': 'key',
        'key': cdpName,
        if (modifiers.isNotEmpty) 'modifiers': modifiers,
      });
      return KeyEventResult.handled;
    }
    // A printable key with a real modifier held is a chord (ctrl+c copies).
    // Bare characters never reach here — the branch above took them.
    if (ctrl || alt || meta) {
      // The KEY CHARACTER first, the label only as a fallback. `keyLabel` is
      // the physical key's name, which on a non-Latin layout is a word ("КА")
      // rather than a character — so a `length == 1` test dropped every
      // modifier chord on those layouts with no feedback at all, and the
      // machine simply did not respond to ctrl+C.
      final candidate = (character != null && character.isNotEmpty)
          ? character
          : event.logicalKey.keyLabel;
      if (candidate.length == 1) {
        _enqueue({
          'action': 'key',
          'key': candidate.toLowerCase(),
          'modifiers': modifiers,
        });
      } else {
        // Still nothing usable: say so once rather than swallowing the press.
        // A chord that silently does nothing is indistinguishable from a
        // frozen guest.
        AppLog.d(
          'rig-input',
          'Dropped a modifier chord with no CDP name: '
              '${event.logicalKey.debugName ?? candidate} '
              '(modifiers: ${modifiers.join("+")})',
        );
      }
    }
    return KeyEventResult.handled;
  }

  // ── Files across the canvas edge ────────────────────────────────────────

  /// Wraps [child] so files can be dragged INTO the machine and out of it.
  ///
  /// Both halves live here because both need the letterbox maths that maps a
  /// canvas point to a guest pixel — a drop delivered at (0, 0) hits the
  /// wrong element on every page there has ever been.
  Widget _wrapWithFileTransfer({required Size canvas, required Widget child}) {
    // ── OUT ──────────────────────────────────────────────────────────────
    //
    // Nothing tells a host that a drag STARTED inside a guest: there is no
    // event for it, and the frame stream is pixels. What there IS, while an X
    // application drags something, is that application OWNING the
    // `XdndSelection` — so the drag payload can be asked for, and only then.
    //
    // Hence the shape: the OS's own drag gesture over this canvas asks the
    // guest what it is dragging, and returns null (no drag starts, nothing
    // visible happens) when the answer is "nothing", which is the answer
    // almost every time. The provider polls for a moment because the guest is
    // necessarily BEHIND: the press and the first moves have to reach it and
    // its application has to decide a drag began, all of which happens after
    // this host has already recognised one.
    //
    // The `Listener` underneath is not in the gesture arena, so guest input
    // keeps flowing while this waits — a drag inside the guest that is not
    // going anywhere near the edge behaves exactly as it did before.
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

    // ── IN ───────────────────────────────────────────────────────────────
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

  /// The drag payload the guest was already holding when this press began.
  ///
  /// The reason drag-out needs a baseline at all: X11 has no "the drag is
  /// over" step. An application that dragged something keeps owning
  /// `XdndSelection` afterwards, sometimes for the rest of its life — so
  /// asking "is a drag in flight?" answers YES long after one finished, and
  /// without this every later press over the canvas would hijack itself into
  /// re-dragging the last file out. Comparing against what was there BEFORE
  /// the press turns that into "did a new drag start?", which is the actual
  /// question.
  String? _dragBaseline;

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
      _isComputer
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
            _isComputer
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

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      if (_focus.hasFocus) {
        _focus.unfocus();
      }
      return widget.child;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvas = Size(constraints.maxWidth, constraints.maxHeight);
        // TextInputSurface is load-bearing, not decoration: it tells the
        // keybinding dispatcher this focus IS typing. Without it every
        // `!textInputFocus` app binding stays active over the canvas and
        // macOS's unmatched-key silencer consumes printable keys before
        // anything else sees them — a machine you cannot type into.
        return TextInputSurface(
          child: _wrapWithFileTransfer(
            canvas: canvas,
            child: Focus(
              focusNode: _focus,
              onKeyEvent: _onKey,
              onFocusChange: (has) {
                // The run of text ends when the keyboard goes elsewhere.
                if (!has) {
                  _keystrokes.flush();
                }
                // Losing focus while the pointer is still over the canvas is
                // never what the user meant — something else in the app
                // grabbed it (a rebuilt composer, a pane-activation handler).
                // Take it back: within the canvas the machine is the sole
                // recipient of input. Leaving the canvas is the release.
                if (!has && _pointerInside && widget.enabled) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _pointerInside && widget.enabled) {
                      _focus.requestFocus();
                    }
                  });
                }
              },
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (e) => _onPointerDown(e, canvas),
                onPointerMove: (e) => _onPointerMove(e, canvas),
                onPointerHover: (e) => _onPointerHover(e, canvas),
                onPointerUp: (e) => _onPointerUp(e, canvas),
                onPointerCancel: (e) => _onPointerCancel(e, canvas),
                onPointerSignal: (e) => _onPointerSignal(e, canvas),
                child: MouseRegion(
                  // Hover-to-type: entering the canvas hands the machine the
                  // keyboard, leaving hands it back — no click required, the
                  // way a remote desktop behaves.
                  onEnter: (_) {
                    _pointerInside = true;
                    if (widget.enabled) {
                      _focus.requestFocus();
                    }
                  },
                  onExit: (_) {
                    _pointerInside = false;
                    // Leaving the canvas hands the keyboard back, so whatever
                    // was typed goes now rather than 200 ms into whatever the
                    // user does next.
                    _keystrokes.flush();
                    if (_focus.hasFocus) {
                      _focus.unfocus();
                    }
                  },
                  // The GUEST's rendered cursor is the cursor: hover streaming
                  // keeps it under the local pointer (the tablet is absolute,
                  // so there is no drift), and hiding the local one is what
                  // makes the two machines read as one screen instead of two
                  // arrows chasing each other. The browser surface renders no
                  // cursor of its own, so there the local pointer stays.
                  cursor: _isComputer
                      ? SystemMouseCursors.none
                      : SystemMouseCursors.basic,
                  // Nothing around the canvas: the whole surface IS the
                  // machine (the guest's own cursor is the pointer), so an
                  // accent ring announcing focus would sit on top of the
                  // illusion the hover-to-type behavior is building.
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
