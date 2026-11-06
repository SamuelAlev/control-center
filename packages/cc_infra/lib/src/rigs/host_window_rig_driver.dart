import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/features/rigs/domain/ports/host_window_port.dart';
import 'package:cc_domain/features/rigs/domain/ports/rig_port.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/computer_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action_result.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_clipboard.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_file_transfer.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/window_action.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/rigs/qemu_keymap.dart';
import 'package:cc_infra/src/rigs/rig_drivers.dart';

/// Drives the windows of a desktop app running on the host.
///
/// Host-managed like the iOS driver, with less underneath: there is no session
/// to own, because the app is someone else's process. Disposing this ends the
/// viewers and leaves the app running.
///
/// Coordinates are window pixels from the top-left corner, in the units the
/// platform reports window bounds in, and [display] is that size. Screenshots
/// are scaled to the agent ceiling, so like the desktop surface an action's
/// coordinates are window pixels and not screenshot pixels.
///
/// Ownership is enforced by [HostWindowPort] on every call. The checks here
/// only produce a better sentence first.
class HostWindowRigDriver implements RigDriver {
  /// Creates a driver over [scope].
  HostWindowRigDriver({
    required this._port,
    required this._scope,
    this.inputMode = HostWindowInputMode.background,
    this._onDisplayChanged,
  });

  final HostWindowPort _port;
  final void Function(RigDisplaySize display)? _onDisplayChanged;

  /// How input reaches the window.
  final HostWindowInputMode inputMode;

  HostWindowScope _scope;

  /// The processes this driver may reach.
  HostWindowScope get scope => _scope;

  /// Replaces the process set, as when an app is relaunched. The selection is
  /// dropped: window ids do not survive a process.
  set scope(HostWindowScope next) {
    if (next == _scope) {
      return;
    }
    _scope = next;
    _selectedId = null;
    _explicitSelection = false;
    _lastPointer = null;
    _heldButton = null;
  }

  int? _selectedId;

  /// Whether a caller chose the window. An automatic pick moves on when its
  /// window closes; a chosen window closing is the caller's to hear about.
  bool _explicitSelection = false;

  RigDisplaySize _display = RigDisplaySize.defaultDesktop;
  (int, int)? _lastPointer;
  RigMouseButton? _heldButton;

  Future<void> _commandTail = Future<void>.value();
  bool _disposed = false;
  final Set<StreamController<List<int>>> _lanes = {};

  @override
  RigDisplaySize get display => _display;

  /// Concatenated PNGs: the native captures PNG on all three platforms.
  @override
  RigStreamCodec get watchCodec => RigStreamCodec.mpng;

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _commandTail.then((_) {
      if (_disposed) {
        throw StateError('The window rig driver is closed.');
      }
      return operation();
    });
    _commandTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  /// Reads the window size now, for a rig that is opening.
  Future<RigDisplaySize?> refreshDisplay() async {
    try {
      await _currentWindow();
      return _display;
    } on HostWindowException {
      // The app may not have mapped a window yet. The first action tells.
      return null;
    }
  }

  /// The window actions apply to, refreshing [display] from its real bounds.
  Future<HostWindow> _currentWindow() async {
    final windows = await _port.listWindows(_scope);
    final selected = _selectedId;
    if (selected != null) {
      for (final window in windows) {
        if (window.id == selected) {
          _noteSize(window);
          return window;
        }
      }
      if (_explicitSelection) {
        throw const HostWindowException(
          HostWindowFailure.notFound,
          'The selected window has closed. Use list_windows and select_window '
          'to pick another.',
        );
      }
    }
    if (windows.isEmpty) {
      throw const HostWindowException(
        HostWindowFailure.notFound,
        'This app has no open window. It may still be starting, or it has '
        'closed them all.',
      );
    }
    final chosen = windows.firstWhere(
      (window) => window.isOnScreen,
      orElse: () => windows.first,
    );
    _selectedId = chosen.id;
    _explicitSelection = false;
    _noteSize(chosen);
    return chosen;
  }

  void _noteSize(HostWindow window) {
    final next = RigDisplaySize(
      window.width < 2 ? 2 : window.width,
      window.height < 2 ? 2 : window.height,
    );
    if (next != _display) {
      _display = next;
      _onDisplayChanged?.call(next);
    }
  }

  void _requirePoint(HostWindow window, int x, int y) {
    if (x < 0 || y < 0 || x >= window.width || y >= window.height) {
      throw HostWindowException(
        HostWindowFailure.outOfBounds,
        '($x, $y) is outside the ${window.width}x${window.height} window. '
        'Coordinates are window pixels, not screenshot or screen pixels.',
      );
    }
  }

  /// The point to act on: the given one, else where the pointer last was.
  (int, int) _pointOr(int? x, int? y) {
    if (x != null && y != null) {
      return (x, y);
    }
    final last = _lastPointer;
    if (last == null) {
      throw const HostWindowException(
        HostWindowFailure.invalid,
        'The pointer has not been placed in this window yet. Give a '
        'coordinate.',
      );
    }
    return last;
  }

  Future<void> _send(HostWindow window, HostWindowInput input) =>
      _port.sendInput(_scope, window.id, input, mode: inputMode);

  Future<void> _pointer(
    HostWindow window,
    HostWindowPointerPhase phase,
    int x,
    int y, {
    RigMouseButton button = RigMouseButton.left,
    int clickCount = 1,
    Set<HostWindowModifier> modifiers = const {},
  }) async {
    _requirePoint(window, x, y);
    await _send(
      window,
      HostWindowPointerInput(
        phase: phase,
        x: x,
        y: y,
        button: button,
        clickCount: clickCount,
        modifiers: modifiers,
      ),
    );
    _lastPointer = (x, y);
  }

  @override
  Future<RigActionResult> perform(RigAction action) {
    if (action is! ComputerAction && action is! WindowAction) {
      return Future.value(
        RigActionResult.error(
          'A ${action.surface.wire} action cannot be sent to an app window '
          'rig.',
        ),
      );
    }
    return _serialize(() async {
      try {
        return switch (action) {
          final WindowAction a => await _performWindow(a),
          final ComputerAction a => await _performComputer(a),
          _ => RigActionResult.error('Unknown action "${action.verb}".'),
        };
      } on HostWindowException catch (e) {
        return _failure(action.verb, e);
      } on Object catch (e) {
        return rigDriverFailure(action.verb, e);
      }
    });
  }

  Future<RigActionResult> _performWindow(WindowAction action) async {
    switch (action) {
      case WindowList():
        final windows = await _port.listWindows(_scope);
        if (windows.isEmpty) {
          return RigActionResult.ok('This app has no open window.');
        }
        return RigActionResult.ok(
          wrapUntrustedRigContent(
            [for (final window in windows) _describe(window)].join('\n'),
            source: 'app window titles',
          ),
        );

      case WindowSelect(:final windowId):
        final windows = await _port.listWindows(_scope);
        final match = windows.where((window) => window.id == windowId);
        if (match.isEmpty) {
          return RigActionResult.error(
            'Window $windowId is not one of this app\'s windows. Use '
            'list_windows.',
          );
        }
        _selectedId = windowId;
        _explicitSelection = true;
        _lastPointer = null;
        _noteSize(match.first);
        return RigActionResult.ok(
          'Selected window $windowId '
          '(${match.first.width}x${match.first.height}).',
        );

      case WindowReadUi():
        final window = await _currentWindow();
        final tree = await _port.readUi(_scope, window.id);
        return RigActionResult.ok(
          wrapUntrustedRigContent(
            summarizeHostWindowTree(tree),
            source: 'app accessibility tree',
          ),
        );
    }
  }

  String _describe(HostWindow window) {
    final where = window.isOnScreen ? 'on screen' : 'not on screen';
    final selected = window.id == _selectedId ? ' selected' : '';
    return 'window_id=${window.id} ${window.width}x${window.height} '
        '$where$selected title=${jsonEncode(window.title)}';
  }

  Future<RigActionResult> _performComputer(ComputerAction action) async {
    switch (action) {
      case ComputerScreenshot():
        return await _captureForAgentUnlocked();

      case ComputerCursorPosition():
        final at = _lastPointer;
        return RigActionResult.ok(
          at == null
              ? 'The pointer has not been placed in this window yet.'
              : 'The pointer was last sent to (${at.$1}, ${at.$2}) in window '
                    'pixels. That is the last position injected, not a '
                    'reading: background input does not move the real cursor.',
        );

      case ComputerMouseMove(:final x, :final y):
        final window = await _currentWindow();
        final held = _heldButton;
        await _pointer(
          window,
          held == null
              ? HostWindowPointerPhase.move
              : HostWindowPointerPhase.drag,
          x,
          y,
          button: held ?? RigMouseButton.left,
        );
        return RigActionResult.ok('Moved the pointer to ($x, $y).');

      case ComputerClick(
        :final button,
        :final clicks,
        :final x,
        :final y,
        :final modifiers,
      ):
        final held = _modifiers(modifiers);
        final window = await _currentWindow();
        final (px, py) = _pointOr(x, y);
        await _pointer(window, HostWindowPointerPhase.move, px, py);
        for (var click = 1; click <= clicks; click++) {
          await _pointer(
            window,
            HostWindowPointerPhase.down,
            px,
            py,
            button: button,
            clickCount: click,
            modifiers: held,
          );
          await _pointer(
            window,
            HostWindowPointerPhase.up,
            px,
            py,
            button: button,
            clickCount: click,
            modifiers: held,
          );
        }
        return RigActionResult.ok('${action.summary}.');

      case ComputerButtonHold(:final button, :final pressed):
        final window = await _currentWindow();
        final (px, py) = _pointOr(null, null);
        await _pointer(
          window,
          pressed ? HostWindowPointerPhase.down : HostWindowPointerPhase.up,
          px,
          py,
          button: button,
        );
        _heldButton = pressed ? button : null;
        return RigActionResult.ok('${action.summary}.');

      case ComputerDrag(:final fromX, :final fromY, :final toX, :final toY):
        final window = await _currentWindow();
        final (startX, startY) = _pointOr(fromX, fromY);
        _requirePoint(window, toX, toY);
        await _pointer(window, HostWindowPointerPhase.move, startX, startY);
        await _pointer(window, HostWindowPointerPhase.down, startX, startY);
        try {
          // Intermediate points, because a single jump reads as a teleport to
          // most drag handlers and the drag never starts.
          const steps = 8;
          for (var i = 1; i <= steps; i++) {
            await _pointer(
              window,
              HostWindowPointerPhase.drag,
              startX + ((toX - startX) * i / steps).round(),
              startY + ((toY - startY) * i / steps).round(),
            );
            await Future<void>.delayed(const Duration(milliseconds: 16));
          }
        } finally {
          // A failed step must not leave the app holding a button down.
          await _pointer(
            window,
            HostWindowPointerPhase.up,
            _lastPointer?.$1 ?? startX,
            _lastPointer?.$2 ?? startY,
          );
        }
        return RigActionResult.ok('${action.summary}.');

      case ComputerScroll(:final direction, :final amount, :final x, :final y):
        final window = await _currentWindow();
        final (px, py) = x != null && y != null
            ? (x, y)
            : _lastPointer ?? (window.width ~/ 2, window.height ~/ 2);
        _requirePoint(window, px, py);
        await _send(
          window,
          HostWindowScrollInput(
            x: px,
            y: py,
            dx: switch (direction) {
              RigScrollDirection.left => amount,
              RigScrollDirection.right => -amount,
              _ => 0,
            },
            dy: switch (direction) {
              RigScrollDirection.up => amount,
              RigScrollDirection.down => -amount,
              _ => 0,
            },
          ),
        );
        _lastPointer = (px, py);
        return RigActionResult.ok('${action.summary}.');

      case ComputerKey(:final combo, :final hold):
        final chord = _chordFor(combo);
        if (chord == null) {
          return RigActionResult.error(
            'Unknown key combination "$combo". Use names such as "ctrl+s", '
            '"cmd+s", "alt+Tab", "Return" or "Escape".',
          );
        }
        final window = await _currentWindow();
        for (final key in chord.keys) {
          if (hold == null) {
            await _send(
              window,
              HostWindowKeyInput(key: key, modifiers: chord.modifiers),
            );
            continue;
          }
          await _send(
            window,
            HostWindowKeyInput(
              key: key,
              phase: HostWindowKeyPhase.down,
              modifiers: chord.modifiers,
            ),
          );
          try {
            await Future<void>.delayed(hold);
          } finally {
            await _send(
              window,
              HostWindowKeyInput(
                key: key,
                phase: HostWindowKeyPhase.up,
                modifiers: chord.modifiers,
              ),
            );
          }
        }
        return RigActionResult.ok('${action.summary}.');

      case ComputerType(:final text):
        final window = await _currentWindow();
        await _send(window, HostWindowTextInput(text));
        return RigActionResult.ok('${action.summary}.');

      case ComputerWait(:final duration):
        await Future<void>.delayed(duration);
        return RigActionResult.ok('${action.summary}.');

      case ComputerSetDisplay():
        return RigActionResult.error(
          'An app window has no display to set. Its size belongs to the app.',
        );

      case ComputerClipboardRead():
      case ComputerClipboardWrite():
        return RigActionResult.error(_clipboardRefusal);
    }
  }

  static const String _clipboardRefusal =
      'An app window has no clipboard of its own. It runs on the host, whose '
      'clipboard belongs to the person using it, so it is out of reach here. '
      'Use type to enter text.';

  static Set<HostWindowModifier> _modifiers(List<String> names) => {
    for (final name in names)
      switch (name.toLowerCase()) {
        'shift' => HostWindowModifier.shift,
        'ctrl' || 'control' => HostWindowModifier.control,
        'alt' || 'option' => HostWindowModifier.alt,
        _ => HostWindowModifier.meta,
      },
  };

  /// Splits [combo] into the keys to press and the modifiers around them.
  ///
  /// Modifiers ride on the key event rather than as separate presses, because
  /// an event posted to a process has no shared keyboard state to read them
  /// from. A combination of only modifiers presses the last one as the key.
  static ({List<String> keys, Set<HostWindowModifier> modifiers})? _chordFor(
    String combo,
  ) {
    final codes = qemuComboFor(combo);
    if (codes == null) {
      return null;
    }
    final keys = <String>[];
    final modifiers = <HostWindowModifier>{};
    String? lastModifier;
    for (final code in codes) {
      final modifier = switch (code) {
        'shift' || 'shift_r' => HostWindowModifier.shift,
        'ctrl' || 'ctrl_r' => HostWindowModifier.control,
        'alt' || 'alt_r' => HostWindowModifier.alt,
        'meta_l' || 'meta_r' => HostWindowModifier.meta,
        _ => null,
      };
      if (modifier == null) {
        keys.add(code);
      } else {
        modifiers.add(modifier);
        lastModifier = code;
      }
    }
    if (keys.isEmpty && lastModifier != null) {
      return (keys: [lastModifier], modifiers: const {});
    }
    return (keys: keys, modifiers: modifiers);
  }

  RigActionResult _failure(String verb, HostWindowException e) =>
      RigActionResult.error(switch (e.failure) {
        HostWindowFailure.permission =>
          '$verb failed: ${e.message} A person has to grant it in System '
              'Settings; retrying will not help.',
        HostWindowFailure.notOwned =>
          '$verb refused: ${e.message} Only this app\'s own windows are '
              'reachable.',
        HostWindowFailure.offDisplay =>
          '$verb failed: ${e.message} A person has to bring the window back.',
        HostWindowFailure.unsupported => e.message,
        _ => '$verb failed: ${e.message}',
      });

  @override
  Future<RigActionResult> captureForAgent() =>
      _serialize(_captureForAgentUnlocked);

  Future<RigActionResult> _captureForAgentUnlocked() async {
    try {
      final window = await _currentWindow();
      final target = _display.fitInside(RigDisplaySize.agentCeiling);
      final frame = await _port.capture(
        _scope,
        window.id,
        maxWidth: target.width,
        maxHeight: target.height,
      );
      return RigActionResult(
        text:
            'Screenshot of the $_display window, scaled to '
            '${frame.width}x${frame.height}. Coordinates in actions are in '
            'WINDOW pixels ($_display), not screenshot pixels.',
        imageBase64: base64Encode(frame.png),
        imageMediaType: 'image/png',
        displaySize: _display.toString(),
      );
    } on HostWindowException catch (e) {
      return _failure('screenshot', e);
    } on Object catch (e) {
      return RigActionResult.error('Screenshot failed: $e');
    }
  }

  @override
  Future<Stream<List<int>>?> openWatchStream(RigWatchRequest request) async {
    final HostWindowPermissions permissions;
    try {
      permissions = await _port.permissions();
    } on HostWindowException catch (e) {
      throw RigStreamUnavailable(
        code: 'window-unavailable',
        message: e.message,
      );
    }
    if (!permissions.screenCapture.isUsable) {
      throw const RigStreamUnavailable(
        code: 'screen-capture-denied',
        message:
            'The app window view needs Screen Recording. Grant it to Control '
            'Center in System Settings and reopen the view.',
      );
    }
    final controller = StreamController<List<int>>();
    _lanes.add(controller);
    final fps = request.fps.clamp(1, _fpsCeiling);
    final interval = Duration(milliseconds: (1000 / fps).round());
    var stopped = false;

    Future<void> shutdown() async {
      if (stopped) {
        return;
      }
      stopped = true;
      _lanes.remove(controller);
      if (!controller.isClosed) {
        await controller.close();
      }
    }

    controller.onCancel = shutdown;

    unawaited(() async {
      var failures = 0;
      while (!stopped && !_disposed) {
        final started = DateTime.now();
        if (!controller.isPaused) {
          try {
            final window = await _currentWindow();
            final frame = await _port.capture(
              _scope,
              window.id,
              maxWidth: request.size.width,
              maxHeight: request.size.height,
            );
            if (!controller.isClosed) {
              controller.add(frame.png);
            }
            failures = 0;
          } on HostWindowException catch (e) {
            // A minimized window, or an app between windows, is a normal state
            // that heals on its own, and the view holds its last frame.
            final recoverable =
                e.failure == HostWindowFailure.offDisplay ||
                e.failure == HostWindowFailure.notFound;
            if (!recoverable && ++failures >= _failureLimit) {
              CcInfraLog.warning('rig/window: closing the watch lane: $e');
              await shutdown();
              return;
            }
          } on Object catch (e) {
            if (++failures >= _failureLimit) {
              CcInfraLog.warning('rig/window: closing the watch lane: $e');
              await shutdown();
              return;
            }
          }
        }
        final remaining = interval - DateTime.now().difference(started);
        if (remaining > Duration.zero) {
          await Future<void>.delayed(remaining);
        }
      }
      await shutdown();
    }());

    return controller.stream;
  }

  /// The polled lane's ceiling, the same as the browser's. A capture costs
  /// about 120 ms of list, grab and PNG encode (measured on macOS).
  static const int _fpsCeiling = 6;

  /// How many captures in a row may fail for a non-transient reason.
  static const int _failureLimit = 10;

  @override
  Future<RigClipboardData> readClipboard(
    RigClipboardSelection selection,
  ) async => throw const RigSurfaceUnsupported(_clipboardRefusal);

  @override
  Future<void> writeClipboard(RigClipboardData data) async =>
      throw const RigSurfaceUnsupported(_clipboardRefusal);

  @override
  Future<RigDropResult> offerDroppedFiles(
    List<RigGuestFile> landed,
    RigDropRequest request,
  ) async => RigDropResult.error(
    'Dropping files onto an app window is not supported.',
  );

  @override
  Future<Stream<List<int>>?> openAudioStream() async => null;

  @override
  Future<bool> sendAudioInput(
    Uint8List bytes, {
    required String sessionId,
    required int sampleRate,
    required int channels,
    bool start = false,
    bool end = false,
  }) async => false;

  @override
  Future<void> dispose() async {
    _disposed = true;
    for (final lane in _lanes.toList()) {
      await lane.close();
    }
    _lanes.clear();
    try {
      await _commandTail;
    } on Object {
      // The operation already returned its own failure result.
    }
  }
}

/// [tree], the native `read_ui` JSON, as indented lines for a model.
String summarizeHostWindowTree(Map<String, dynamic> tree) {
  const maxChars = 24000;
  final lines = <String>[];
  var chars = 0;
  var omitted = 0;

  void visit(Object? raw, int depth) {
    if (raw is! Map) {
      return;
    }
    final parts = <String>[
      '${'  ' * depth}${raw['role'] ?? 'element'}',
      for (final field in const ['title', 'value', 'description'])
        if (raw[field] is String && (raw[field] as String).isNotEmpty)
          '$field=${jsonEncode(raw[field])}',
      if (raw['enabled'] == false) 'disabled',
      if (raw['focused'] == true) 'focused',
    ];
    final (x, y, w, h) = (raw['x'], raw['y'], raw['width'], raw['height']);
    if (x is num && y is num && w is num && h is num) {
      parts.add('center=[${(x + w / 2).round()}, ${(y + h / 2).round()}]');
    }
    final line = parts.join(' ');
    if (chars + line.length + 1 <= maxChars) {
      lines.add(line);
      chars += line.length + 1;
    } else {
      omitted++;
    }
    final children = raw['children'];
    if (children is List) {
      for (final child in children) {
        visit(child, depth + 1);
      }
    }
  }

  visit(tree['root'], 0);
  if (lines.isEmpty || (lines.length == 1 && lines.first == 'element')) {
    return 'The accessibility tree is empty.';
  }
  if (omitted > 0) {
    lines.add('… $omitted additional nodes omitted.');
  }
  if (tree['truncated'] == true) {
    lines.add('… the tree was cut off at the node limit.');
  }
  return lines.join('\n');
}
