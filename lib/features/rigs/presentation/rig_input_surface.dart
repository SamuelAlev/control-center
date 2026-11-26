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
import 'package:control_center/features/rigs/presentation/rig_clipboard_permission_dialog.dart';
import 'package:control_center/features/rigs/presentation/rig_ios_key_translation.dart';
import 'package:control_center/features/rigs/presentation/rig_key_translation.dart';
import 'package:control_center/features/rigs/presentation/rig_keystroke_coalescer.dart';
import 'package:control_center/features/rigs/providers/rig_clipboard_permissions.dart';
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

part 'rig_input_clipboard.dart';
part 'rig_input_file_transfer.dart';
part 'rig_input_keyboard.dart';
part 'rig_input_pointer.dart';

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

/// Whether a clipboard bridge must be rebound after a rig widget update.
///
/// A network-policy restart replaces the live rig while preserving the tab and
/// its [RigInputSurface] state. Comparing only the server proxy leaves the
/// bridge signed for the closed rig id, so the next paste targets a machine
/// that no longer exists.
bool rigClipboardBridgeIdentityChanged({
  required String oldWorkspaceId,
  required String oldRigId,
  required String newWorkspaceId,
  required String newRigId,
}) => oldWorkspaceId != newWorkspaceId || oldRigId != newRigId;

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
    this.onRefused,
    this.onLaneForbidden,
    required this.child,
  });

  /// Told about a failed `rig.act`, so a refusal by kind (no write grant on
  /// the rig's space) turns the surface off instead of failing each event.
  final ValueChanged<Object>? onRefused;

  /// Told when a clipboard or file lane answers 403 (`drive` for a write).
  final void Function({required bool drive})? onLaneForbidden;

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
    if (rigClipboardBridgeIdentityChanged(
      oldWorkspaceId: oldWidget.workspaceId,
      oldRigId: oldWidget.rig.id,
      newWorkspaceId: widget.workspaceId,
      newRigId: widget.rig.id,
    )) {
      _bindClipboardBridge();
      _lastGuestPoint = null;
      _iosPointer = null;
      _iosGestureStart = null;
      _iosGestureStartedAt = null;
    }
  }

  /// Actions waiting to be sent, in input order.
  late final RigActionQueue _actions = RigActionQueue(
    send: (action) async {
      try {
        await _rigs.act(
          workspaceId: widget.workspaceId,
          rigId: widget.rig.id,
          action: action,
        );
      } on Object catch (e) {
        if (mounted) {
          widget.onRefused?.call(e);
        }
        rethrow;
      }
    },
  );

  bool _leftDown = false;
  int _downButtons = 0;
  int? _iosPointer;
  (int, int)? _iosGestureStart;
  DateTime? _iosGestureStartedAt;

  /// Built from the ambient proxy scope, which is where the signed URLs for
  /// the server's rig lanes come from. Null before the connection exists.
  RigTransferClient? _transferClient;
  RigClipboardBridge? _bridge;

  /// Guards against a second chord starting while one is in flight. A held
  /// ctrl+V repeats at the OS key-repeat rate, and each one is a round trip
  /// through the server into a guest.
  bool _clipboardBusy = false;

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

  /// When the last hover move went out, to rate-limit them.
  DateTime _lastHoverSent = DateTime.fromMillisecondsSinceEpoch(0);

  /// Where the pointer last was in guest pixels, for a drop with no position
  /// of its own (a paste of files).
  (int, int)? _lastGuestPoint;

  /// Rebinds clipboard transfers to the current workspace and live rig id.
  void _bindClipboardBridge() {
    final client = _transferClient;
    _bridge = client == null
        ? null
        : rigClipboardBridgeFor(
            client: client,
            workspaceId: widget.workspaceId,
            rigId: widget.rig.id,
          );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final proxy = MediaProxyScope.configOf(context);
    if (proxy == null || _transferClient?.proxy == proxy) {
      return;
    }
    _transferClient?.close();
    final client = rigTransferClientFor(context)
      ?..onForbidden = ({required bool drive}) {
        if (mounted) {
          widget.onLaneForbidden?.call(drive: drive);
        }
      };
    _transferClient = client;
    _bindClipboardBridge();
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

  /// Enqueues a non-text action, flushing buffered keystrokes ahead of it.
  ///
  /// The flush lives here rather than at each call site so ordering cannot be
  /// forgotten: text always reaches the guest before the click or key after it.
  void _enqueue(Map<String, dynamic> action, {bool coalesce = false}) {
    _keystrokes.flush();
    _enqueueRaw(action, coalesce: coalesce);
  }

  void _enqueueRaw(Map<String, dynamic> action, {bool coalesce = false}) =>
      _actions.add(action, coalesce: coalesce);

  /// Maps a canvas-local point through the same contained frame as the image.
  (int, int)? _toGuest(Offset local, Size canvas) {
    final guestWidth = widget.rig.displayWidth;
    final guestHeight = widget.rig.displayHeight;
    if (guestWidth == null || guestHeight == null) {
      return null;
    }
    return rigContainedGuestPoint(
      local: local,
      canvas: canvas,
      guestWidth: guestWidth,
      guestHeight: guestHeight,
    );
  }

  bool get _isComputer => widget.rig.surfaceKind == RigSurface.computer;

  /// Whether input goes out as `computer_use` verbs. An app window shares that
  /// vocabulary, but not the rest of [_isComputer]: it has no guest clipboard
  /// or drag selection, and its frames carry no cursor of their own.
  bool get _speaksComputerInput =>
      _isComputer || widget.rig.surfaceKind == RigSurface.window;

  bool get _isIos => widget.rig.surfaceKind == RigSurface.ios;

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
        // The keeper: a click on the rig toolbar around the canvas leaves the
        // keyboard with the machine.
        return CcFocusKeeper(
          child: TextInputSurface(
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
          ),
        );
      },
    );
  }
}
