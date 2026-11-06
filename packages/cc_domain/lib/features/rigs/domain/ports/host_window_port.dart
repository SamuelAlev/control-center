import 'dart:typed_data';

import 'package:cc_domain/features/rigs/domain/value_objects/rig_action.dart';

/// How input reaches a host window.
enum HostWindowInputMode {
  /// Posted to the owning process. The operator's cursor and focus stay put.
  background('background'),

  /// The window is activated and input is injected at the system level, which
  /// takes over the operator's cursor. Refused when another app's window would
  /// receive it.
  foreground('foreground');

  const HostWindowInputMode(this.wire);

  /// Stable wire string.
  final String wire;

  /// Parses [value], or null when unknown.
  static HostWindowInputMode? fromWire(String? value) {
    for (final mode in values) {
      if (mode.wire == value) {
        return mode;
      }
    }
    return null;
  }
}

/// Whether one OS permission is in place.
enum HostWindowPermission {
  /// Granted to this process.
  granted,

  /// Missing. The operator grants it in the OS settings.
  denied,

  /// This platform has no such permission.
  notRequired;

  /// Whether the capability it guards can be used.
  bool get isUsable => this != denied;
}

/// Which OS settings pane grants a permission.
enum HostWindowSettingsPane {
  /// Screen Recording.
  screenCapture,

  /// Accessibility, which covers input and the UI tree.
  accessibility,
}

/// The OS permissions window access depends on.
class HostWindowPermissions {
  /// Creates a [HostWindowPermissions].
  const HostWindowPermissions({
    required this.screenCapture,
    required this.input,
    required this.accessibility,
  });

  /// Needed to capture a window.
  final HostWindowPermission screenCapture;

  /// Needed to post input.
  final HostWindowPermission input;

  /// Needed to read the UI tree.
  final HostWindowPermission accessibility;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HostWindowPermissions &&
          other.screenCapture == screenCapture &&
          other.input == input &&
          other.accessibility == accessibility;

  @override
  int get hashCode => Object.hash(screenCapture, input, accessibility);
}

/// Why a window operation failed.
enum HostWindowFailure {
  /// Malformed arguments, or a process set that cannot own anything.
  invalid,

  /// The window or point is outside the allowed process tree.
  notOwned,

  /// The window no longer exists.
  notFound,

  /// An OS permission is missing.
  permission,

  /// The window is minimized, hidden or off every display.
  offDisplay,

  /// The coordinate is outside the window.
  outOfBounds,

  /// This host cannot do it.
  unsupported,

  /// The OS call failed.
  failed,

  /// The OS call did not answer in time.
  timeout,
}

/// A window operation failed, and [message] says why.
class HostWindowException implements Exception {
  /// Creates a [HostWindowException].
  const HostWindowException(this.failure, this.message);

  /// The stable category. Branch on this, not on [message].
  final HostWindowFailure failure;

  /// A sentence fit to reach a model or a person.
  final String message;

  @override
  String toString() => 'HostWindowException(${failure.name}): $message';
}

/// The processes a caller may reach, and where their windows live.
///
/// Every call carries one, because the native layer enforces it on every call:
/// nothing here is remembered between calls.
class HostWindowScope {
  /// Creates a [HostWindowScope]. [pids] are the launched roots; their
  /// descendants are included by the native layer.
  HostWindowScope({required Set<int> pids, this.display})
    : pids = Set.unmodifiable(pids) {
    if (pids.isEmpty) {
      throw ArgumentError.value(pids, 'pids', 'A scope needs a process');
    }
    if (pids.any((pid) => pid <= 1)) {
      throw ArgumentError.value(pids, 'pids', 'Not a launched process');
    }
  }

  /// The root process IDs.
  final Set<int> pids;

  /// The X display the app runs on (`:7`), or null on macOS and Windows, or
  /// to use the server's own.
  final String? display;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HostWindowScope &&
          other.display == display &&
          other.pids.length == pids.length &&
          other.pids.containsAll(pids);

  @override
  int get hashCode => Object.hash(Object.hashAllUnordered(pids), display);
}

/// One window of an app.
class HostWindow {
  /// Creates a [HostWindow].
  const HostWindow({
    required this.id,
    required this.pid,
    required this.title,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.isOnScreen,
  });

  /// The OS window handle.
  final int id;

  /// The owning process.
  final int pid;

  /// The title, as the app set it. Untrusted.
  final String title;

  /// Left edge in desktop coordinates.
  final int x;

  /// Top edge in desktop coordinates.
  final int y;

  /// Width in window pixels.
  final int width;

  /// Height in window pixels.
  final int height;

  /// Whether it is mapped on a display. False when minimized or on another
  /// space, where capture can fail.
  final bool isOnScreen;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HostWindow &&
          other.id == id &&
          other.pid == pid &&
          other.title == title &&
          other.x == x &&
          other.y == y &&
          other.width == width &&
          other.height == height &&
          other.isOnScreen == isOnScreen;

  @override
  int get hashCode =>
      Object.hash(id, pid, title, x, y, width, height, isOnScreen);
}

/// One captured window, as PNG.
class HostWindowFrame {
  /// Creates a [HostWindowFrame].
  const HostWindowFrame({
    required this.png,
    required this.width,
    required this.height,
  });

  /// The encoded image.
  final Uint8List png;

  /// Encoded width.
  final int width;

  /// Encoded height.
  final int height;
}

/// A modifier held through a pointer or key event.
enum HostWindowModifier {
  /// Shift.
  shift,

  /// Control.
  control,

  /// Alt, or Option on macOS.
  alt,

  /// Command on macOS, Super elsewhere.
  meta,
}

/// What a pointer event does.
enum HostWindowPointerPhase {
  /// Moves with no button held.
  move,

  /// Presses a button.
  down,

  /// Releases a button.
  up,

  /// Moves with a button held.
  drag,
}

/// What a key event does.
enum HostWindowKeyPhase {
  /// Presses and releases.
  tap,

  /// Presses.
  down,

  /// Releases.
  up,
}

/// One input event. Coordinates are window pixels from the top-left corner.
sealed class HostWindowInput {
  const HostWindowInput();
}

/// A pointer move, press or release.
class HostWindowPointerInput extends HostWindowInput {
  /// Creates a [HostWindowPointerInput].
  const HostWindowPointerInput({
    required this.phase,
    required this.x,
    required this.y,
    this.button = RigMouseButton.left,
    this.clickCount = 1,
    this.modifiers = const {},
  });

  /// What it does.
  final HostWindowPointerPhase phase;

  /// Window x.
  final int x;

  /// Window y.
  final int y;

  /// Which button, for every phase but [HostWindowPointerPhase.move].
  final RigMouseButton button;

  /// Which click of a multi-click this press or release is.
  final int clickCount;

  /// Modifiers held.
  final Set<HostWindowModifier> modifiers;
}

/// Wheel movement at a point.
class HostWindowScrollInput extends HostWindowInput {
  /// Creates a [HostWindowScrollInput].
  const HostWindowScrollInput({
    required this.x,
    required this.y,
    this.dx = 0,
    this.dy = 0,
    this.modifiers = const {},
  });

  /// Window x.
  final int x;

  /// Window y.
  final int y;

  /// Wheel lines; positive scrolls left.
  final int dx;

  /// Wheel lines; positive scrolls up.
  final int dy;

  /// Modifiers held.
  final Set<HostWindowModifier> modifiers;
}

/// One key, named by its QEMU qcode (`ret`, `a`, `f5`, `bracket_left`).
class HostWindowKeyInput extends HostWindowInput {
  /// Creates a [HostWindowKeyInput].
  const HostWindowKeyInput({
    required this.key,
    this.phase = HostWindowKeyPhase.tap,
    this.modifiers = const {},
  });

  /// The key.
  final String key;

  /// What it does.
  final HostWindowKeyPhase phase;

  /// Modifiers held.
  final Set<HostWindowModifier> modifiers;
}

/// Literal text, independent of the keyboard layout.
class HostWindowTextInput extends HostWindowInput {
  /// Creates a [HostWindowTextInput].
  const HostWindowTextInput(this.text);

  /// The text.
  final String text;
}

/// OS window access for apps Control Center launched.
///
/// Implementations enforce the own-windows rule below this interface: a window
/// outside [HostWindowScope] is refused with [HostWindowFailure.notOwned] on
/// every call, whatever the caller asked for. Every method throws
/// [HostWindowException] on failure.
abstract interface class HostWindowPort {
  /// The windows of [scope], frontmost first.
  Future<List<HostWindow>> listWindows(HostWindowScope scope);

  /// Captures [windowId], scaled down to fit [maxWidth] x [maxHeight] and never
  /// up. The app need not be active.
  Future<HostWindowFrame> capture(
    HostWindowScope scope,
    int windowId, {
    required int maxWidth,
    required int maxHeight,
  });

  /// Sends one [input] to [windowId].
  Future<void> sendInput(
    HostWindowScope scope,
    int windowId,
    HostWindowInput input, {
    HostWindowInputMode mode = HostWindowInputMode.background,
  });

  /// The accessibility tree of [windowId], decoded from the native JSON.
  ///
  /// Coverage varies by framework and nothing may depend on it:
  /// [HostWindowFailure.unsupported] is a normal answer.
  Future<Map<String, dynamic>> readUi(
    HostWindowScope scope,
    int windowId, {
    int maxNodes = 500,
  });

  /// The current OS permissions. Never prompts.
  Future<HostWindowPermissions> permissions();

  /// Opens the OS settings at [pane].
  Future<void> openSettings(HostWindowSettingsPane pane);
}
