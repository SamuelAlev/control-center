// ignore_for_file: camel_case_types, non_constant_identifier_names
// ignore_for_file: public_member_api_docs
//
// Hand-trimmed FFI bindings for libccpty (vendored flutter_pty C — see
// packages/cc_natives/native/pty/PROVENANCE.md). Upstream ffigen emits the full
// Dart Native API DL accessor surface (~600 lines); the PTY only needs
// `Dart_InitializeApiDL` (to wire the DL symbol table the C posts output
// through) plus the six `pty_*` ABI calls and the two structs, so only those
// are bound here. Everything else (Dart_PostCObject_DL et al.) is resolved and
// called from the C side, never from Dart.
import 'dart:ffi' as ffi;

/// The pseudo-terminal options passed by value to `pty_create`. Field order and
/// types must match `PtyOptions` in `native/pty/flutter_pty.h` exactly.
final class PtyOptions extends ffi.Struct {
  @ffi.Int()
  external int rows;

  @ffi.Int()
  external int cols;

  external ffi.Pointer<ffi.Char> executable;

  external ffi.Pointer<ffi.Pointer<ffi.Char>> arguments;

  external ffi.Pointer<ffi.Pointer<ffi.Char>> environment;

  external ffi.Pointer<ffi.Char> working_directory;

  /// Dart_Port (Int64) the read thread posts Uint8List chunks to.
  @ffi.Int64()
  external int stdout_port;

  /// Dart_Port (Int64) the wait-exit thread posts the exit code to.
  @ffi.Int64()
  external int exit_port;

  @ffi.Bool()
  external bool ackRead;
}

/// Opaque native handle returned by `pty_create`.
final class PtyHandle extends ffi.Opaque {}

/// Minimal symbol-bound surface over libccpty.
class PtyBindings {
  PtyBindings(ffi.DynamicLibrary dynamicLibrary) : _lookup = dynamicLibrary.lookup;

  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
  _lookup;

  /// Wires the dynamically-linked Dart Native API symbol table so the C read /
  /// wait-exit threads can `Dart_PostCObject_DL` / `Dart_PostInteger_DL` back
  /// into this isolate. Pass `NativeApi.initializeApiDLData`. Returns 0 on
  /// success. MUST be called (once) before `pty_create`.
  late final Dart_InitializeApiDL = _lookup<
      ffi.NativeFunction<ffi.IntPtr Function(ffi.Pointer<ffi.Void>)>>(
    'Dart_InitializeApiDL',
  ).asFunction<int Function(ffi.Pointer<ffi.Void>)>();

  late final pty_create = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<PtyHandle> Function(ffi.Pointer<PtyOptions>)>>(
    'pty_create',
  ).asFunction<ffi.Pointer<PtyHandle> Function(ffi.Pointer<PtyOptions>)>();

  late final pty_write = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              ffi.Pointer<PtyHandle>, ffi.Pointer<ffi.Char>, ffi.Int)>>(
    'pty_write',
  ).asFunction<
      void Function(ffi.Pointer<PtyHandle>, ffi.Pointer<ffi.Char>, int)>();

  late final pty_ack_read = _lookup<
      ffi.NativeFunction<ffi.Void Function(ffi.Pointer<PtyHandle>)>>(
    'pty_ack_read',
  ).asFunction<void Function(ffi.Pointer<PtyHandle>)>();

  late final pty_resize = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<PtyHandle>, ffi.Int, ffi.Int)>>(
    'pty_resize',
  ).asFunction<int Function(ffi.Pointer<PtyHandle>, int, int)>();

  late final pty_getpid = _lookup<
      ffi.NativeFunction<ffi.Int Function(ffi.Pointer<PtyHandle>)>>(
    'pty_getpid',
  ).asFunction<int Function(ffi.Pointer<PtyHandle>)>();

  late final pty_error = _lookup<
      ffi.NativeFunction<ffi.Pointer<ffi.Char> Function()>>(
    'pty_error',
  ).asFunction<ffi.Pointer<ffi.Char> Function()>();
}
