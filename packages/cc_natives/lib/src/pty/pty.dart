import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cc_natives/src/native_library.dart';
import 'package:cc_natives/src/pty/pty_ffi_bindings.dart';
import 'package:ffi/ffi.dart';

/// Base name of the pseudo-terminal native (`libccpty.dylib` / `.so` /
/// `ccpty.dll`). Built by `scripts/natives/build_pty.sh`, loaded at runtime.
const String ptyLibraryBaseName = 'ccpty';

/// Env override pointing at an explicit `libccpty` path (dev / CI).
const String ptyLibraryEnvVar = 'CC_PTY_DYLIB';

/// Resolves the `libccpty` [DynamicLibrary], or `null` when the native is
/// absent (graceful degradation — the executor reports PTY-unavailable).
///
/// Mirrors the rift / fff / tree-sitter / aec policy: an explicit env override,
/// then the host-injected app-support root (where `build_pty.sh` installs it),
/// then the packaged-bundle candidates (see `nativeLibraryCandidates`).
typedef PtyLibraryResolver = DynamicLibrary? Function();

/// Pseudo-terminal over the vendored `flutter_pty` native, ported to be
/// Flutter-free so it runs in the pure-Dart `cc_server` binary (and the desktop
/// alike). The native ABI is unchanged; only the library *lookup* differs —
/// `flutter_pty` hard-codes `DynamicLibrary.open('flutter_pty.framework/…')`
/// (its Flutter bundle), whereas this resolves `libccpty` through the cc_natives
/// runtime loader.
///
/// API mirrors `flutter_pty`'s `Pty` so consumers (claude-relay, sandboxed
/// terminal sessions) port with no behavioural change.
class Pty {
  /// Spawns [executable] in a pseudo-terminal. Arguments mirror `Process.start`.
  ///
  /// [ackRead] makes the native wait for [ackRead] before sending the next
  /// chunk (back-pressure). Throws [PtyUnavailable] when `libccpty` cannot be
  /// loaded, and [StateError] when the native API table or the PTY fail to
  /// initialize.
  Pty.start(
    this.executable, {
    this.arguments = const [],
    String? workingDirectory,
    Map<String, String>? environment,
    int rows = 25,
    int columns = 80,
    bool ackRead = false,
  }) {
    final bindings = _ensureBindings();

    final effectiveEnv = <String, String>{
      'TERM': 'xterm-256color',
      // Keep tool output UTF-8 (vi etc. otherwise emit non-UTF-8 sequences).
      'LANG': 'en_US.UTF-8',
    };
    const envValuesToCopy = {
      'LOGNAME',
      'USER',
      'DISPLAY',
      'LC_TYPE',
      'HOME',
      'PATH',
    };
    for (final entry in Platform.environment.entries) {
      if (envValuesToCopy.contains(entry.key)) {
        effectiveEnv[entry.key] = entry.value;
      }
    }
    if (environment != null) {
      effectiveEnv.addAll(environment);
    }

    // argv: [executable, ...arguments, NULL]
    final argv = calloc<Pointer<Utf8>>(arguments.length + 2);
    argv[0] = executable.toNativeUtf8();
    for (var i = 0; i < arguments.length; i++) {
      argv[i + 1] = arguments[i].toNativeUtf8();
    }
    argv[arguments.length + 1] = nullptr;

    // envp: ["k=v", …, NULL]
    final envp = calloc<Pointer<Utf8>>(effectiveEnv.length + 1);
    var ei = 0;
    for (final entry in effectiveEnv.entries) {
      envp[ei++] = '${entry.key}=${entry.value}'.toNativeUtf8();
    }
    envp[effectiveEnv.length] = nullptr;

    final options = calloc<PtyOptions>();
    options.ref
      ..rows = rows
      ..cols = columns
      ..executable = executable.toNativeUtf8().cast()
      ..arguments = argv.cast()
      ..environment = envp.cast()
      ..stdout_port = _stdoutPort.sendPort.nativePort
      ..exit_port = _exitPort.sendPort.nativePort
      ..ackRead = ackRead
      ..working_directory =
          workingDirectory != null ? workingDirectory.toNativeUtf8().cast() : nullptr;

    _handle = bindings.pty_create(options);
    calloc.free(options);

    if (_handle == nullptr) {
      throw StateError('Failed to create PTY: ${_ptyError(bindings)}');
    }

    _exitPort.first.then(_onExitCode);
  }

  /// The executable running in the pseudo-terminal.
  final String executable;

  /// The arguments passed to [executable].
  final List<String> arguments;

  final _stdoutPort = ReceivePort();
  final _exitPort = ReceivePort();
  final _exitCodeCompleter = Completer<int>();
  late final Pointer<PtyHandle> _handle;

  /// Combined stdout+stderr byte stream (a PTY does not separate them).
  Stream<Uint8List> get output => _stdoutPort.cast();

  /// Completes with the process exit code (negative `-signal` if killed).
  Future<int> get exitCode => _exitCodeCompleter.future;

  /// The OS pid of the process in the pseudo-terminal.
  int get pid => _ensureBindings().pty_getpid(_handle);

  /// Writes [data] to the pseudo-terminal's input.
  void write(Uint8List data) {
    final buf = malloc<Int8>(data.length);
    buf.asTypedList(data.length).setAll(0, data);
    _ensureBindings().pty_write(_handle, buf.cast(), data.length);
    malloc.free(buf);
  }

  /// Resizes the pseudo-terminal window.
  void resize(int rows, int cols) => _ensureBindings().pty_resize(_handle, rows, cols);

  /// Sends [signal] to the process (default SIGTERM). Returns false if the pid
  /// no longer exists.
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) =>
      Process.killPid(pid, signal);

  /// Acknowledges a processed chunk so the native sends the next one (only
  /// meaningful when constructed with `ackRead: true`).
  void ackRead() => _ensureBindings().pty_ack_read(_handle);

  void _onExitCode(dynamic code) {
    _stdoutPort.close();
    _exitPort.close();
    if (!_exitCodeCompleter.isCompleted) {
      _exitCodeCompleter.complete(code as int);
    }
  }

  // --- native library resolution (shared, lazy, once per process) ---

  /// Host-overridable resolver. The server / desktop set this once at startup
  /// to point at their app-support root; defaults to env + bundle candidates so
  /// tests and tools work without wiring.
  static PtyLibraryResolver libraryResolver = defaultPtyLibraryResolver;

  static PtyBindings? _cachedBindings;

  static PtyBindings _ensureBindings() {
    final cached = _cachedBindings;
    if (cached != null) {
      return cached;
    }
    final lib = libraryResolver();
    if (lib == null) {
      throw const PtyUnavailable();
    }
    final bindings = PtyBindings(lib);
    final rc = bindings.Dart_InitializeApiDL(NativeApi.initializeApiDLData);
    if (rc != 0) {
      throw StateError('Failed to initialize Dart Native API for libccpty (rc=$rc)');
    }
    return _cachedBindings = bindings;
  }

  static String? _ptyError(PtyBindings bindings) {
    final err = bindings.pty_error();
    if (err == nullptr) {
      return null;
    }
    return err.cast<Utf8>().toDartString();
  }

  /// Whether `libccpty` can be loaded in this process (cheap; caches the lib).
  static bool get isAvailable {
    try {
      _ensureBindings();
      return true;
    } on PtyUnavailable {
      return false;
    } catch (_) {
      return false;
    }
  }
}

/// Default `libccpty` resolution: env override → bundle candidates. The host
/// installs a richer resolver (with its app-support root) via
/// [Pty.libraryResolver].
DynamicLibrary? defaultPtyLibraryResolver() => tryOpenFirst(
      nativeLibraryCandidates(ptyLibraryBaseName, envVar: ptyLibraryEnvVar),
    );

/// Thrown by [Pty.start] when the `libccpty` native is not present. Callers
/// degrade gracefully (the agent executor reports the PTY backend unavailable).
class PtyUnavailable implements Exception {
  /// Creates the marker exception.
  const PtyUnavailable();

  @override
  String toString() =>
      'PtyUnavailable: libccpty could not be loaded (build it with '
      'scripts/natives/build_pty.sh or set \$CC_PTY_DYLIB).';
}
