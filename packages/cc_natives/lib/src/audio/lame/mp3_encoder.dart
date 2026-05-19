import 'dart:ffi';
import 'dart:typed_data';

import 'package:cc_natives/src/audio/lame/lame_ffi_bindings.dart';
import 'package:ffi/ffi.dart';

/// Stateful owner of one native libmp3lame (LAME) CBR MP3 encoder.
///
/// Turns a stream of interleaved PCM16 into a frame-aligned MP3 byte stream:
/// feed raw PCM chunks to [encode] (appending the returned bytes), then call
/// [flush] once at the end to drain LAME's internal buffers. The encoder is
/// configured for constant bitrate (VBR off) so the output stays frame-stable
/// for incremental append.
///
/// **Main-isolate only.** The instance wraps a raw native [Pointer] handle (not
/// sendable across isolates) plus reusable malloc scratch buffers, and the LAME
/// encoder is stateful, so every call for a given encoder must come from the
/// isolate that created it — mirroring `AecProcessor`'s ownership model.
///
/// **No degraded mode.** [create] throws [LameUnavailable] when the native
/// library is absent / incompatible (no dylib, wrong arch, missing symbols) —
/// a broken install, not a reason to silently ship raw PCM. The dylib is
/// intentionally NOT linked into the app — it is discovered at runtime, exactly
/// like rift / fff / tree-sitter / aec — and `cc_server` refuses to boot when
/// its native preflight cannot resolve it.
///
/// **Licensing.** The core MP3 patents expired in 2017, so distributing an MP3
/// encoder is unencumbered. LAME itself is LGPL-2.1 and is loaded as a runtime
/// dynamic library (never statically linked into first-party Dart), keeping the
/// LGPL boundary at the dylib.
class Mp3Encoder {
  Mp3Encoder._(this._bindings, this._handle, this._channels)
    : _pcmCapacity = _initialFrames * _channels,
      _outCapacity = _worstCaseBytes(_initialFrames),
      _pcm = malloc<Int16>(_initialFrames * _channels),
      _out = malloc<Uint8>(_worstCaseBytes(_initialFrames));

  /// Initial per-channel frame capacity of the reusable scratch buffers. Grown
  /// on demand when a larger chunk arrives; a typical audio chunk is well under
  /// this (e.g. 20 ms @ 48 kHz = 960 frames).
  static const int _initialFrames = 8192;

  /// LAME's documented flush buffer floor (bytes).
  static const int _flushFloorBytes = 7200;

  final LameFfiBindings _bindings;
  final Pointer<Void> _handle;
  final int _channels;

  Pointer<Int16> _pcm;
  Pointer<Uint8> _out;
  int _pcmCapacity; // in samples (frames * channels)
  int _outCapacity; // in bytes
  bool _disposed = false;

  /// Loads the native LAME library and creates a CBR encoder.
  ///
  /// [sampleRate] and [channels] describe the interleaved PCM16 fed to [encode];
  /// there is no resampling (in == out rate). [bitrateKbps] is the constant
  /// output bitrate.
  ///
  /// Throws [LameUnavailable] when the dylib cannot be loaded (broken install)
  /// or when LAME refuses the requested format. There is no degraded mode — see
  /// the class doc.
  static Mp3Encoder create({
    List<String> explicitPaths = const [],
    int sampleRate = 48000,
    int channels = 2,
    int bitrateKbps = 128,
  }) {
    final bindings = LameFfiBindings.tryLoad(explicitPaths: explicitPaths);
    if (bindings == null) {
      throw const LameUnavailable('liblame_ffi could not be loaded');
    }
    final handle = bindings.create(sampleRate, channels, bitrateKbps);
    if (handle == nullptr) {
      throw LameUnavailable(
        'cc_lame_create returned null (sampleRate=$sampleRate, '
        'channels=$channels, bitrateKbps=$bitrateKbps)',
      );
    }
    return Mp3Encoder._(bindings, handle, channels);
  }

  /// libmp3lame version string (for logging / FFI smoke tests).
  String? get version => _bindings.version();

  /// Encodes one chunk of [interleavedPcm] (interleaved PCM16, `channels`
  /// channels) and returns the MP3 bytes produced — a fresh [Uint8List] copy,
  /// frame-aligned. Returns an **empty** list when LAME produced no output yet
  /// (it buffers internally until a full MP3 frame is available) or when the
  /// input is empty. Throws [StateError] on a negative LAME error code.
  Uint8List encode(Int16List interleavedPcm) {
    if (_disposed) {
      return Uint8List(0);
    }
    final samples = interleavedPcm.length;
    if (samples == 0) {
      return Uint8List(0);
    }
    final frames = samples ~/ _channels;
    _ensurePcmCapacity(samples);
    _ensureOutCapacity(_worstCaseBytes(frames));
    _pcm.asTypedList(samples).setAll(0, interleavedPcm);
    final n = _bindings.encode(_handle, _pcm, frames, _out, _outCapacity);
    if (n < 0) {
      throw StateError('LAME encode failed (code $n)');
    }
    if (n == 0) {
      return Uint8List(0);
    }
    return Uint8List.fromList(_out.asTypedList(n));
  }

  /// Flushes LAME's internal buffers, returning the trailing MP3 bytes (a fresh
  /// [Uint8List] copy). Call once when the stream ends. May return an empty
  /// list. Throws [StateError] on a negative LAME error code.
  Uint8List flush() {
    if (_disposed) {
      return Uint8List(0);
    }
    _ensureOutCapacity(_flushFloorBytes);
    final n = _bindings.flush(_handle, _out, _outCapacity);
    if (n < 0) {
      throw StateError('LAME flush failed (code $n)');
    }
    if (n == 0) {
      return Uint8List(0);
    }
    return Uint8List.fromList(_out.asTypedList(n));
  }

  /// Destroys the native encoder and frees the scratch buffers. Idempotent.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _bindings.destroy(_handle);
    malloc
      ..free(_pcm)
      ..free(_out);
  }

  /// Grows the PCM scratch buffer to hold at least [samples] interleaved
  /// samples, reallocating (free + malloc) only when it must.
  void _ensurePcmCapacity(int samples) {
    if (samples <= _pcmCapacity) {
      return;
    }
    malloc.free(_pcm);
    _pcmCapacity = samples;
    _pcm = malloc<Int16>(samples);
  }

  /// Grows the output buffer to at least [bytes], reallocating only when needed.
  void _ensureOutCapacity(int bytes) {
    if (bytes <= _outCapacity) {
      return;
    }
    malloc.free(_out);
    _outCapacity = bytes;
    _out = malloc<Uint8>(bytes);
  }

  /// LAME's worst-case output size for [frames] samples-per-channel:
  /// `1.25 * frames + 7200` bytes (the documented upper bound).
  static int _worstCaseBytes(int frames) =>
      (frames * 1.25).ceil() + _flushFloorBytes;
}
