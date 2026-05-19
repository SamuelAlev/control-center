import 'dart:ffi';

import 'package:cc_natives/src/native_library.dart';
import 'package:cc_natives/src/rift/rift_exception.dart';
import 'package:ffi/ffi.dart';

/// Raw `dart:ffi` binding for the bundled rift shared library.
///
/// The library exposes a tiny C ABI (see `crates/ffi/src/lib.rs` in the rift
/// project): a JSON-in / JSON-out call plus a free for the returned string.
///
/// ```c
/// char* rift_ffi_call(const char* request_json);  // heap-allocated response
/// void  rift_ffi_free(char* response);            // frees it
/// ```
///
/// Loading degrades gracefully: [tryLoad] returns `null` when the dylib is
/// absent or has the wrong arch, mirroring `TreeSitterLoader`/`FffFileSearch`.
/// Callers must fall back (to a plain `git worktree`) when null.
class RiftFfiBindings {
  RiftFfiBindings._(this._call, this._free);

  final _RiftCallDart _call;
  final _RiftFreeDart _free;

  /// Attempts to load the rift dylib from [explicitPaths] first (caller-resolved
  /// dev / app-support / bundle locations), then platform default candidates.
  /// Returns `null` if nothing loads or the symbols are missing.
  static RiftFfiBindings? tryLoad({List<String> explicitPaths = const []}) {
    final lib = tryOpenFirst([
      ...explicitPaths,
      ...bundledLibraryCandidates('rift_ffi'),
    ]);
    if (lib == null) {
      return null;
    }
    try {
      final call = lib.lookupFunction<Pointer<Utf8> Function(Pointer<Utf8>),
          _RiftCallDart>('rift_ffi_call');
      final free = lib.lookupFunction<Void Function(Pointer<Utf8>),
          _RiftFreeDart>('rift_ffi_free');
      return RiftFfiBindings._(call, free);
    } catch (_) {
      // Library loaded but didn't export the expected symbols.
      return null;
    }
  }

  /// Sends [requestJson] to rift and returns the raw response JSON.
  ///
  /// Memory contract: the input buffer is always freed; the response pointer is
  /// freed exactly once after its contents are copied into a Dart string.
  String call(String requestJson) {
    final inPtr = requestJson.toNativeUtf8();
    try {
      final outPtr = _call(inPtr);
      if (outPtr == nullptr) {
        throw const RiftFfiNullResponse();
      }
      try {
        return outPtr.toDartString();
      } finally {
        _free(outPtr);
      }
    } finally {
      malloc.free(inPtr);
    }
  }

}

typedef _RiftCallDart = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _RiftFreeDart = void Function(Pointer<Utf8>);
