import 'dart:ffi';

import 'package:cc_natives/src/native_library.dart';
import 'package:cc_natives/src/native_unavailable.dart';
import 'package:ffi/ffi.dart';

/// Thrown when the `liblame_ffi` native cannot be loaded (absent, wrong arch, or
/// missing symbols) or the encoder refuses to instantiate.
///
/// There is no degraded mode: the dylib ships inside the host bundle and
/// `cc_server` refuses to boot without it, so a miss is a broken install rather
/// than a reason to ship raw PCM. See [NativeLibraryUnavailable].
class LameUnavailable implements NativeLibraryUnavailable {
  /// Creates a [LameUnavailable].
  const LameUnavailable(this.message);

  /// What failed (load vs. instantiation, with the parameters when relevant).
  @override
  final String message;

  @override
  String toString() =>
      'LameUnavailable: $message (build it with '
      'scripts/natives/build_lame.sh — on Windows '
      'scripts/release/windows_natives.sh — or rebuild the host bundle with '
      'the natives staged)';
}

/// Raw `dart:ffi` binding for the bundled MP3 encoder library (`liblame_ffi`),
/// a thin C ABI over libmp3lame (LAME).
///
/// The library exposes a tiny C ABI (see `packages/cc_natives/native/lame_ffi.cc`):
///
/// ```c
/// void* cc_lame_create(int sample_rate, int channels, int bitrate_kbps);   // opaque handle / NULL
/// int   cc_lame_encode(void* h, const short* pcm_interleaved, int frames,
///                      unsigned char* out, int out_cap);                    // bytes written / < 0 error
/// int   cc_lame_flush(void* h, unsigned char* out, int out_cap);           // bytes written / < 0 error
/// void  cc_lame_destroy(void* h);
/// const char* cc_lame_version(void);                                        // static, do not free
/// ```
///
/// [tryLoad] returning `null` is a PROBE RESULT, not a licence to degrade — the
/// dylib is required. `Mp3Encoder.create` converts it into a thrown
/// [LameUnavailable].
class LameFfiBindings {
  LameFfiBindings._(
    this._create,
    this._encode,
    this._flush,
    this._destroy,
    this._version,
  );

  final _CreateDart _create;
  final _EncodeDart _encode;
  final _FlushDart _flush;
  final _DestroyDart _destroy;
  final _VersionDart _version;

  /// Probes for the LAME dylib in [explicitPaths] first (caller-resolved dev /
  /// app-support / bundle locations), then platform default candidates. Returns
  /// `null` if nothing loads or the symbols are missing — callers use
  /// `Mp3Encoder.create`, which turns that into a [LameUnavailable].
  static LameFfiBindings? tryLoad({List<String> explicitPaths = const []}) {
    final lib = tryOpenFirst([
      ...explicitPaths,
      ...bundledLibraryCandidates('lame_ffi'),
    ]);
    if (lib == null) {
      return null;
    }
    try {
      final create = lib
          .lookupFunction<
            Pointer<Void> Function(Int32, Int32, Int32),
            _CreateDart
          >('cc_lame_create');
      final encode = lib
          .lookupFunction<
            Int32 Function(
              Pointer<Void>,
              Pointer<Int16>,
              Int32,
              Pointer<Uint8>,
              Int32,
            ),
            _EncodeDart
          >('cc_lame_encode', isLeaf: true);
      final flush = lib
          .lookupFunction<
            Int32 Function(Pointer<Void>, Pointer<Uint8>, Int32),
            _FlushDart
          >('cc_lame_flush', isLeaf: true);
      final destroy = lib
          .lookupFunction<Void Function(Pointer<Void>), _DestroyDart>(
            'cc_lame_destroy',
          );
      final version = lib
          .lookupFunction<Pointer<Utf8> Function(), _VersionDart>(
            'cc_lame_version',
          );
      return LameFfiBindings._(create, encode, flush, destroy, version);
    } catch (_) {
      // Library loaded but didn't export the expected symbols — degrade.
      return null;
    }
  }

  /// Creates a native CBR MP3 encoder; returns `nullptr` on failure.
  Pointer<Void> create(int sampleRate, int channels, int bitrateKbps) =>
      _create(sampleRate, channels, bitrateKbps);

  /// Encodes [frames] interleaved PCM16 samples-per-channel from [pcm] into
  /// [out] (capacity [outCap] bytes). Returns bytes written (0 is valid), or a
  /// negative LAME error code.
  int encode(
    Pointer<Void> handle,
    Pointer<Int16> pcm,
    int frames,
    Pointer<Uint8> out,
    int outCap,
  ) => _encode(handle, pcm, frames, out, outCap);

  /// Flushes LAME's internal buffers into [out] (capacity [outCap] bytes).
  /// Returns bytes written (may be 0), or a negative error code.
  int flush(Pointer<Void> handle, Pointer<Uint8> out, int outCap) =>
      _flush(handle, out, outCap);

  /// Destroys the native encoder instance.
  void destroy(Pointer<Void> handle) => _destroy(handle);

  /// libmp3lame version string, or `null` if unavailable.
  String? version() {
    final p = _version();
    return p == nullptr ? null : p.toDartString();
  }
}

typedef _CreateDart = Pointer<Void> Function(int, int, int);
typedef _EncodeDart =
    int Function(Pointer<Void>, Pointer<Int16>, int, Pointer<Uint8>, int);
typedef _FlushDart = int Function(Pointer<Void>, Pointer<Uint8>, int);
typedef _DestroyDart = void Function(Pointer<Void>);
typedef _VersionDart = Pointer<Utf8> Function();
