// One typedef pair per C signature keeps the ABI readable in one place.
// ignore_for_file: avoid_private_typedef_functions
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cc_natives/src/git/rig_worktree_guard.dart';
import 'package:cc_natives/src/native_library.dart';
import 'package:cc_natives/src/native_unavailable.dart';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

/// Base name of the window library (`libcc_window.dylib` / `libcc_window.so` /
/// `cc_window.dll`), built by `scripts/natives/build_window.sh` from
/// `packages/cc_natives/native/window/`.
const String windowLibraryBaseName = 'cc_window';

/// Env var overriding the library path (highest-priority candidate).
const String windowLibraryEnvVar = 'CC_WINDOW_DYLIB';

/// The C ABI this binding speaks. Must equal `cc_window_abi_version()`; a
/// mismatch refuses to bind.
const int ccWindowAbiVersion = 1;

/// Status codes of `cc_window.h`. ABI: extend, never renumber.
enum CcWindowStatus {
  /// `CC_WINDOW_ERR_INVALID`.
  invalid(1),

  /// `CC_WINDOW_ERR_NOT_OWNED`.
  notOwned(2),

  /// `CC_WINDOW_ERR_NOT_FOUND`.
  notFound(3),

  /// `CC_WINDOW_ERR_PERMISSION`.
  permission(4),

  /// `CC_WINDOW_ERR_OFF_DISPLAY`.
  offDisplay(5),

  /// `CC_WINDOW_ERR_OUT_OF_BOUNDS`.
  outOfBounds(6),

  /// `CC_WINDOW_ERR_UNSUPPORTED`.
  unsupported(7),

  /// `CC_WINDOW_ERR_FAILED`.
  failed(8),

  /// `CC_WINDOW_ERR_TIMEOUT`.
  timeout(9);

  const CcWindowStatus(this.code);

  /// The native value.
  final int code;

  /// The status for [code]; an unknown one from a newer native is [failed].
  static CcWindowStatus fromCode(int code) {
    for (final status in values) {
      if (status.code == code) {
        return status;
      }
    }
    return failed;
  }
}

/// A `cc_window` call failed.
class CcWindowFailure implements Exception {
  /// Creates a [CcWindowFailure].
  const CcWindowFailure(this.status, this.message);

  /// The stable category.
  final CcWindowStatus status;

  /// The native reason.
  final String message;

  @override
  String toString() => 'CcWindowFailure(${status.name}): $message';
}

/// The library is absent, the wrong architecture or a different ABI.
class CcWindowUnavailable implements NativeLibraryUnavailable {
  /// Creates a [CcWindowUnavailable].
  const CcWindowUnavailable(this.message);

  @override
  final String message;

  @override
  String toString() =>
      'CcWindowUnavailable: $message (build it with '
      'scripts/natives/build_window.sh, or set \$$windowLibraryEnvVar)';
}

/// One PNG from `cc_window_capture`.
class CcWindowImage {
  /// Creates a [CcWindowImage].
  const CcWindowImage(this.png, this.width, this.height);

  /// The encoded bytes.
  final Uint8List png;

  /// Encoded width.
  final int width;

  /// Encoded height.
  final int height;
}

/// `cc_window_mouse` phases.
abstract final class CcWindowPointerPhase {
  /// `CC_WINDOW_POINTER_MOVE`.
  static const int move = 0;

  /// `CC_WINDOW_POINTER_DOWN`.
  static const int down = 1;

  /// `CC_WINDOW_POINTER_UP`.
  static const int up = 2;

  /// `CC_WINDOW_POINTER_DRAG`.
  static const int drag = 3;
}

/// Where one window operation applies. Plain data, so it crosses isolates.
class CcWindowTarget {
  /// Creates a [CcWindowTarget].
  const CcWindowTarget({required this.pids, this.display, this.windowId = 0});

  /// The launched roots.
  final List<int> pids;

  /// The X display, on Linux.
  final String? display;

  /// The window, when the call has one.
  final int windowId;
}

typedef _ListC =
    Int32 Function(
      Pointer<Int32>,
      Int32,
      Pointer<Utf8>,
      Pointer<Pointer<Utf8>>,
      Pointer<Pointer<Utf8>>,
    );
typedef _ListD =
    int Function(
      Pointer<Int32>,
      int,
      Pointer<Utf8>,
      Pointer<Pointer<Utf8>>,
      Pointer<Pointer<Utf8>>,
    );
typedef _CaptureC =
    Int32 Function(
      Pointer<Int32>,
      Int32,
      Pointer<Utf8>,
      Uint64,
      Int32,
      Int32,
      Pointer<Pointer<Uint8>>,
      Pointer<Int64>,
      Pointer<Int32>,
      Pointer<Int32>,
      Pointer<Pointer<Utf8>>,
    );
typedef _CaptureD =
    int Function(
      Pointer<Int32>,
      int,
      Pointer<Utf8>,
      int,
      int,
      int,
      Pointer<Pointer<Uint8>>,
      Pointer<Int64>,
      Pointer<Int32>,
      Pointer<Int32>,
      Pointer<Pointer<Utf8>>,
    );
typedef _MouseC =
    Int32 Function(
      Pointer<Int32>,
      Int32,
      Pointer<Utf8>,
      Uint64,
      Int32,
      Int32,
      Int32,
      Double,
      Double,
      Int32,
      Uint32,
      Pointer<Pointer<Utf8>>,
    );
typedef _MouseD =
    int Function(
      Pointer<Int32>,
      int,
      Pointer<Utf8>,
      int,
      int,
      int,
      int,
      double,
      double,
      int,
      int,
      Pointer<Pointer<Utf8>>,
    );
typedef _ScrollC =
    Int32 Function(
      Pointer<Int32>,
      Int32,
      Pointer<Utf8>,
      Uint64,
      Int32,
      Double,
      Double,
      Int32,
      Int32,
      Uint32,
      Pointer<Pointer<Utf8>>,
    );
typedef _ScrollD =
    int Function(
      Pointer<Int32>,
      int,
      Pointer<Utf8>,
      int,
      int,
      double,
      double,
      int,
      int,
      int,
      Pointer<Pointer<Utf8>>,
    );
typedef _KeyC =
    Int32 Function(
      Pointer<Int32>,
      Int32,
      Pointer<Utf8>,
      Uint64,
      Int32,
      Pointer<Utf8>,
      Int32,
      Uint32,
      Pointer<Pointer<Utf8>>,
    );
typedef _KeyD =
    int Function(
      Pointer<Int32>,
      int,
      Pointer<Utf8>,
      int,
      int,
      Pointer<Utf8>,
      int,
      int,
      Pointer<Pointer<Utf8>>,
    );
typedef _TextC =
    Int32 Function(
      Pointer<Int32>,
      Int32,
      Pointer<Utf8>,
      Uint64,
      Int32,
      Pointer<Utf8>,
      Pointer<Pointer<Utf8>>,
    );
typedef _TextD =
    int Function(
      Pointer<Int32>,
      int,
      Pointer<Utf8>,
      int,
      int,
      Pointer<Utf8>,
      Pointer<Pointer<Utf8>>,
    );
typedef _ReadUiC =
    Int32 Function(
      Pointer<Int32>,
      Int32,
      Pointer<Utf8>,
      Uint64,
      Int32,
      Pointer<Pointer<Utf8>>,
      Pointer<Pointer<Utf8>>,
    );
typedef _ReadUiD =
    int Function(
      Pointer<Int32>,
      int,
      Pointer<Utf8>,
      int,
      int,
      Pointer<Pointer<Utf8>>,
      Pointer<Pointer<Utf8>>,
    );
typedef _PermissionsC =
    Int32 Function(Pointer<Pointer<Utf8>>, Pointer<Pointer<Utf8>>);
typedef _PermissionsD =
    int Function(Pointer<Pointer<Utf8>>, Pointer<Pointer<Utf8>>);
typedef _SettingsC = Int32 Function(Int32, Pointer<Pointer<Utf8>>);
typedef _SettingsD = int Function(int, Pointer<Pointer<Utf8>>);

/// Typed function pointers over one opened library.
class _Bindings {
  _Bindings(DynamicLibrary lib)
    : free = lib
          .lookupFunction<
            Void Function(Pointer<Void>),
            void Function(Pointer<Void>)
          >('cc_window_free'),
      list = lib.lookupFunction<_ListC, _ListD>('cc_window_list'),
      capture = lib.lookupFunction<_CaptureC, _CaptureD>('cc_window_capture'),
      mouse = lib.lookupFunction<_MouseC, _MouseD>('cc_window_mouse'),
      scroll = lib.lookupFunction<_ScrollC, _ScrollD>('cc_window_scroll'),
      key = lib.lookupFunction<_KeyC, _KeyD>('cc_window_key'),
      text = lib.lookupFunction<_TextC, _TextD>('cc_window_text'),
      readUi = lib.lookupFunction<_ReadUiC, _ReadUiD>('cc_window_read_ui'),
      permissions = lib.lookupFunction<_PermissionsC, _PermissionsD>(
        'cc_window_permissions',
      ),
      openSettings = lib.lookupFunction<_SettingsC, _SettingsD>(
        'cc_window_open_settings',
      );

  final void Function(Pointer<Void>) free;
  final _ListD list;
  final _CaptureD capture;
  final _MouseD mouse;
  final _ScrollD scroll;
  final _KeyD key;
  final _TextD text;
  final _ReadUiD readUi;
  final _PermissionsD permissions;
  final _SettingsD openSettings;
}

/// Whether [path] opens and speaks [ccWindowAbiVersion].
bool _speaksOurAbi(String path) {
  try {
    final version = DynamicLibrary.open(path)
        .lookupFunction<Int32 Function(), int Function()>(
          'cc_window_abi_version',
        )();
    return version == ccWindowAbiVersion;
  } on Object {
    return false;
  }
}

/// Runs [call], freeing its error string and turning a status into a throw.
void _check(
  _Bindings b,
  Arena arena,
  int Function(Pointer<Pointer<Utf8>>) call,
) {
  final error = arena<Pointer<Utf8>>();
  final status = call(error);
  if (status == 0) {
    return;
  }
  var message = 'cc_window failed with status $status.';
  if (error.value != nullptr) {
    message = error.value.toDartString();
    b.free(error.value.cast());
  }
  throw CcWindowFailure(CcWindowStatus.fromCode(status), message);
}

Pointer<Int32> _pids(Arena arena, List<int> pids) {
  final out = arena<Int32>(pids.length);
  for (var i = 0; i < pids.length; i++) {
    out[i] = pids[i];
  }
  return out;
}

Pointer<Utf8> _display(Arena arena, String? display) =>
    display?.toNativeUtf8(allocator: arena) ?? nullptr;

String _takeString(_Bindings b, Pointer<Utf8> pointer) {
  final text = pointer.toDartString();
  b.free(pointer.cast());
  return text;
}

// The entry points below run on a worker isolate, so they are top-level and
// take plain data: a closure over `this` could not cross, and the library path
// has to travel because a host-injected resolver is per-isolate state.

String _listOn(String path, CcWindowTarget target) => using((arena) {
  final b = _Bindings(DynamicLibrary.open(path));
  final json = arena<Pointer<Utf8>>();
  _check(
    b,
    arena,
    (error) => b.list(
      _pids(arena, target.pids),
      target.pids.length,
      _display(arena, target.display),
      json,
      error,
    ),
  );
  return _takeString(b, json.value);
});

CcWindowImage _captureOn(
  String path,
  CcWindowTarget target,
  int maxWidth,
  int maxHeight,
) => using((arena) {
  final b = _Bindings(DynamicLibrary.open(path));
  final png = arena<Pointer<Uint8>>();
  final length = arena<Int64>();
  final width = arena<Int32>();
  final height = arena<Int32>();
  _check(
    b,
    arena,
    (error) => b.capture(
      _pids(arena, target.pids),
      target.pids.length,
      _display(arena, target.display),
      target.windowId,
      maxWidth,
      maxHeight,
      png,
      length,
      width,
      height,
      error,
    ),
  );
  final bytes = Uint8List.fromList(png.value.asTypedList(length.value));
  b.free(png.value.cast());
  return CcWindowImage(bytes, width.value, height.value);
});

void _mouseOn(
  String path,
  CcWindowTarget target,
  int mode,
  int phase,
  int button,
  double x,
  double y,
  int clickCount,
  int modifiers,
) => using((arena) {
  final b = _Bindings(DynamicLibrary.open(path));
  _check(
    b,
    arena,
    (error) => b.mouse(
      _pids(arena, target.pids),
      target.pids.length,
      _display(arena, target.display),
      target.windowId,
      mode,
      phase,
      button,
      x,
      y,
      clickCount,
      modifiers,
      error,
    ),
  );
});

void _scrollOn(
  String path,
  CcWindowTarget target,
  int mode,
  double x,
  double y,
  int dx,
  int dy,
  int modifiers,
) => using((arena) {
  final b = _Bindings(DynamicLibrary.open(path));
  _check(
    b,
    arena,
    (error) => b.scroll(
      _pids(arena, target.pids),
      target.pids.length,
      _display(arena, target.display),
      target.windowId,
      mode,
      x,
      y,
      dx,
      dy,
      modifiers,
      error,
    ),
  );
});

void _keyOn(
  String path,
  CcWindowTarget target,
  int mode,
  String key,
  int action,
  int modifiers,
) => using((arena) {
  final b = _Bindings(DynamicLibrary.open(path));
  _check(
    b,
    arena,
    (error) => b.key(
      _pids(arena, target.pids),
      target.pids.length,
      _display(arena, target.display),
      target.windowId,
      mode,
      key.toNativeUtf8(allocator: arena),
      action,
      modifiers,
      error,
    ),
  );
});

void _textOn(String path, CcWindowTarget target, int mode, String text) =>
    using((arena) {
      final b = _Bindings(DynamicLibrary.open(path));
      _check(
        b,
        arena,
        (error) => b.text(
          _pids(arena, target.pids),
          target.pids.length,
          _display(arena, target.display),
          target.windowId,
          mode,
          text.toNativeUtf8(allocator: arena),
          error,
        ),
      );
    });

String _readUiOn(String path, CcWindowTarget target, int maxNodes) =>
    using((arena) {
      final b = _Bindings(DynamicLibrary.open(path));
      final json = arena<Pointer<Utf8>>();
      _check(
        b,
        arena,
        (error) => b.readUi(
          _pids(arena, target.pids),
          target.pids.length,
          _display(arena, target.display),
          target.windowId,
          maxNodes,
          json,
          error,
        ),
      );
      return _takeString(b, json.value);
    });

String _permissionsOn(String path) => using((arena) {
  final b = _Bindings(DynamicLibrary.open(path));
  final json = arena<Pointer<Utf8>>();
  _check(b, arena, (error) => b.permissions(json, error));
  return _takeString(b, json.value);
});

void _openSettingsOn(String path, int pane) => using((arena) {
  final b = _Bindings(DynamicLibrary.open(path));
  _check(b, arena, (error) => b.openSettings(pane, error));
});

/// The `cc_window` native.
///
/// Every call blocks in the OS, a capture for tens of milliseconds, so each one
/// runs on a worker isolate rather than the isolate answering RPCs. Own-window
/// enforcement is in the native layer; this class only marshals.
class CcWindow {
  const CcWindow._(this._path);

  final String _path;

  /// Where the library may be. The host adds its data directory, the same way
  /// it sets the PTY library resolver.
  static List<String> Function() libraryCandidates = () =>
      nativeLibraryCandidates(
        windowLibraryBaseName,
        envVar: windowLibraryEnvVar,
      );

  /// The resolved library path, or null when none opens and speaks our ABI.
  static String? resolvePath() {
    for (final candidate in libraryCandidates()) {
      if (candidate.isNotEmpty && _speaksOurAbi(candidate)) {
        return candidate;
      }
    }
    return null;
  }

  /// Whether the library resolves: the boot preflight's probe. Never throws.
  static bool get isAvailable => resolvePath() != null;

  /// A bound instance. Throws [CcWindowUnavailable] when the library cannot be
  /// used: there is no degraded mode.
  static CcWindow get require {
    final path = resolvePath();
    if (path == null) {
      throw const CcWindowUnavailable(
        'the cc_window dynamic library could not be opened or speaks a '
        'different ABI',
      );
    }
    return CcWindow._(path);
  }

  /// The windows of [target]'s tree, decoded from the native JSON.
  Future<List<Map<String, dynamic>>> list(CcWindowTarget target) async {
    final path = _path;
    final json = await Isolate.run(() => _listOn(path, target));
    return (jsonDecode(json) as List).cast<Map<String, dynamic>>();
  }

  /// Captures [target]'s window, scaled to fit and never up.
  Future<CcWindowImage> capture(
    CcWindowTarget target, {
    required int maxWidth,
    required int maxHeight,
  }) {
    final path = _path;
    return Isolate.run(() => _captureOn(path, target, maxWidth, maxHeight));
  }

  /// Sends one pointer event.
  Future<void> mouse(
    CcWindowTarget target, {
    required int mode,
    required int phase,
    required int button,
    required double x,
    required double y,
    required int clickCount,
    required int modifiers,
  }) {
    final path = _path;
    return Isolate.run(
      () => _mouseOn(
        path,
        target,
        mode,
        phase,
        button,
        x,
        y,
        clickCount,
        modifiers,
      ),
    );
  }

  /// Sends wheel movement.
  Future<void> scroll(
    CcWindowTarget target, {
    required int mode,
    required double x,
    required double y,
    required int dx,
    required int dy,
    required int modifiers,
  }) {
    final path = _path;
    return Isolate.run(
      () => _scrollOn(path, target, mode, x, y, dx, dy, modifiers),
    );
  }

  /// Sends one key event.
  Future<void> key(
    CcWindowTarget target, {
    required int mode,
    required String key,
    required int action,
    required int modifiers,
  }) {
    final path = _path;
    return Isolate.run(
      () => _keyOn(path, target, mode, key, action, modifiers),
    );
  }

  /// Types [text].
  Future<void> text(
    CcWindowTarget target, {
    required int mode,
    required String text,
  }) {
    final path = _path;
    return Isolate.run(() => _textOn(path, target, mode, text));
  }

  /// The accessibility tree, decoded from the native JSON.
  Future<Map<String, dynamic>> readUi(
    CcWindowTarget target, {
    required int maxNodes,
  }) async {
    final path = _path;
    final json = await Isolate.run(() => _readUiOn(path, target, maxNodes));
    return jsonDecode(json) as Map<String, dynamic>;
  }

  /// The permission states, as the native spells them.
  Future<Map<String, dynamic>> permissions() async {
    final path = _path;
    final json = await Isolate.run(() => _permissionsOn(path));
    return jsonDecode(json) as Map<String, dynamic>;
  }

  /// Opens the settings pane for [pane].
  Future<void> openSettings(int pane) {
    final path = _path;
    return Isolate.run(() => _openSettingsOn(path, pane));
  }
}

/// Points the rig natives at the server's [dataDir]: where `cc_window` may be
/// installed, and where the worktree quarantine persists across restarts.
void configureRigNatives({required String dataDir}) {
  CcWindow.libraryCandidates = () => nativeLibraryCandidates(
    windowLibraryBaseName,
    appSupportRoot: dataDir,
    envVar: windowLibraryEnvVar,
  );
  RigWorktreeGuard.storePath = p.join(
    dataDir,
    'rigs',
    'worktree-quarantine.json',
  );
}
