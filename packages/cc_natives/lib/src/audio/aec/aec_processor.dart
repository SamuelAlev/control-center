import 'dart:ffi';
import 'dart:typed_data';

import 'package:cc_natives/src/audio/aec/aec_ffi_bindings.dart';
import 'package:ffi/ffi.dart';

/// AEC3 echo metrics, read for diagnostics + the on-device tuning loop. All
/// fields are `null` until AEC3 has aggregated a value.
class AecMetrics {
  /// Creates a metrics snapshot; any field omitted is treated as "no value yet".
  const AecMetrics({this.erl, this.erle, this.residual, this.delayMs});

  /// Echo return loss (dB).
  final double? erl;

  /// Echo return loss enhancement (dB). **> 0 means AEC3 is actively removing
  /// echo**; ~0 / null means it is not — the key signal when tuning.
  final double? erle;

  /// Residual-echo likelihood (0..1).
  final double? residual;

  /// AEC3's own internal echo-path delay estimate (ms).
  final int? delayMs;

  /// An all-null metrics snapshot (no data yet / no engine).
  static const AecMetrics empty = AecMetrics();
}

/// The AEC capability [AecMicFilter](../../../features/meetings/data/services/aec_mic_filter.dart)
/// depends on. Implemented by [AecProcessor] over native FFI; tests supply a
/// fake. All blocks are exactly [AecProcessor.blockBytes] bytes of mono PCM16.
abstract class AecEngine {
  /// Feeds one far-end (loopback) reference block.
  void processReverse(Uint8List block);

  /// Cleans one near-end (mic) block, returning the echo-removed block.
  /// [streamDelayMs] is the measured far-end→capture lead fed to AEC3.
  Uint8List processCapture(Uint8List block, int streamDelayMs);

  /// AEC3's current echo metrics (ERL/ERLE/residual/delay).
  AecMetrics metrics();

  /// Releases any native resources. Idempotent.
  void dispose();
}

/// Stateful owner of one native WebRTC AEC3 instance.
///
/// Cancels the remote's speaker bleed out of the microphone using the system
/// loopback as the far-end reference. Works on fixed 10 ms blocks of mono PCM16
/// ([blockBytes] bytes = [blockFrames] samples @ 16 kHz). Feed each far-end
/// (loopback) block via [processReverse] and each near-end (mic) block via
/// [processCapture]; AEC3 estimates the echo-path delay internally and aligns
/// the two streams itself.
///
/// **Main-isolate only.** The instance wraps a raw native [Pointer] handle (not
/// sendable across isolates) and is stateful, so every call for a given
/// processor must come from the isolate that created it. Each 10 ms block is
/// sub-millisecond work, far cheaper than shipping audio over a port — mirroring
/// how rift does inline FFI while only the heavy sherpa decode is isolated.
///
/// [tryCreate] returns `null` when the native library is absent / incompatible;
/// callers then pass the mic through unchanged (the text `MeetingEchoFilter`
/// remains the echo defense). All target platforms are little-endian, matching
/// the PCM16 byte order on the wire.
class AecProcessor implements AecEngine {
  AecProcessor._(this._bindings, this._handle)
      : _ref = malloc<Int16>(blockFrames),
        _cap = malloc<Int16>(blockFrames),
        _out = malloc<Int16>(blockFrames),
        _mErl = malloc<Double>(),
        _mErle = malloc<Double>(),
        _mResidual = malloc<Double>(),
        _mDelay = malloc<Int32>();

  /// Samples per processing block (10 ms @ 16 kHz mono).
  static const int blockFrames = AecFfiBindings.framesPerBlock;

  /// Bytes per processing block (PCM16 → 2 bytes/sample).
  static const int blockBytes = blockFrames * 2;

  final AecFfiBindings _bindings;
  final Pointer<Void> _handle;
  final Pointer<Int16> _ref;
  final Pointer<Int16> _cap;
  final Pointer<Int16> _out;
  final Pointer<Double> _mErl;
  final Pointer<Double> _mErle;
  final Pointer<Double> _mResidual;
  final Pointer<Int32> _mDelay;
  bool _disposed = false;

  /// Loads the native AEC library and creates an instance, or returns `null`
  /// when the library is unavailable or instance creation fails.
  static AecProcessor? tryCreate({
    List<String> explicitPaths = const [],
    int sampleRate = 16000,
    int channels = 1,
  }) {
    final bindings = AecFfiBindings.tryLoad(explicitPaths: explicitPaths);
    if (bindings == null) {
      return null;
    }
    final handle = bindings.create(sampleRate, channels);
    if (handle == nullptr) {
      return null;
    }
    return AecProcessor._(bindings, handle);
  }

  /// Engine version string (for logging / FFI smoke tests).
  String? get version => _bindings.version();

  /// Feeds one far-end (loopback) block of exactly [blockBytes] bytes.
  @override
  void processReverse(Uint8List block) {
    assert(block.length == blockBytes, 'reverse block must be $blockBytes bytes');
    if (_disposed) {
      return;
    }
    _copyInto(_ref, block);
    _bindings.processReverse(_handle, _ref, blockFrames);
  }

  /// Cleans one near-end (mic) block of exactly [blockBytes] bytes and returns
  /// the echo-removed block (a fresh [blockBytes]-byte buffer). [streamDelayMs]
  /// is the measured far-end→capture lead (the per-session cross-correlation
  /// estimate); AEC3 uses it to align the reference, then refines internally.
  @override
  Uint8List processCapture(Uint8List block, int streamDelayMs) {
    assert(block.length == blockBytes, 'capture block must be $blockBytes bytes');
    if (_disposed) {
      return block;
    }
    _copyInto(_cap, block);
    _bindings.processCapture(_handle, _cap, _out, blockFrames, streamDelayMs);
    final cleaned = Uint8List(blockBytes);
    final dst = ByteData.sublistView(cleaned);
    final src = _out.asTypedList(blockFrames);
    for (var i = 0; i < blockFrames; i++) {
      dst.setInt16(i * 2, src[i], Endian.little);
    }
    return cleaned;
  }

  /// Reads AEC3's current echo metrics. Maps the native sentinels
  /// ([AecFfiBindings.metricUnavailable] / `-1`) back to `null`.
  @override
  AecMetrics metrics() {
    if (_disposed) {
      return AecMetrics.empty;
    }
    _bindings.getMetrics(_handle, _mErl, _mErle, _mResidual, _mDelay);
    double? d(Pointer<Double> p) {
      final v = p.value;
      return v <= AecFfiBindings.metricUnavailable ? null : v;
    }

    final delay = _mDelay.value;
    return AecMetrics(
      erl: d(_mErl),
      erle: d(_mErle),
      residual: d(_mResidual),
      delayMs: delay < 0 ? null : delay,
    );
  }

  /// Destroys the native instance and frees scratch buffers. Idempotent.
  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _bindings.destroy(_handle);
    malloc
      ..free(_ref)
      ..free(_cap)
      ..free(_out)
      ..free(_mErl)
      ..free(_mErle)
      ..free(_mResidual)
      ..free(_mDelay);
  }

  /// Copies [block]'s little-endian PCM16 bytes into the native [dst] scratch
  /// (byte-wise via ByteData — no alignment assumption on the source).
  static void _copyInto(Pointer<Int16> dst, Uint8List block) {
    final bd = ByteData.sublistView(block);
    final out = dst.asTypedList(blockFrames);
    for (var i = 0; i < blockFrames; i++) {
      out[i] = bd.getInt16(i * 2, Endian.little);
    }
  }
}
