import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

/// Raw `dart:ffi` binding for the bundled acoustic-echo-cancellation library
/// (`libaec_ffi`), a thin C ABI over WebRTC's AEC3 `AudioProcessing` module.
///
/// The library exposes a tiny C ABI (see `native/aec/aec_ffi.cc`):
///
/// ```c
/// void* aec_create(int sample_rate_hz, int num_channels);            // opaque handle / NULL
/// void  aec_process_reverse(void* h, const int16_t* ref, int n);     // far-end / render block
/// void  aec_process_capture(void* h, const int16_t* cap,
///                           int16_t* out, int n, int stream_delay_ms);// near-end -> cleaned
/// void  aec_get_metrics(void* h, double* erl, double* erle,
///                       double* residual, int* delay_ms);            // diagnostics
/// void  aec_destroy(void* h);
/// const char* aec_version(void);                                     // static, do not free
/// ```
///
/// Blocks are mono PCM16 of [framesPerBlock] samples (10 ms @ 16 kHz). Loading
/// degrades gracefully: [tryLoad] returns `null` when the dylib is absent or has
/// the wrong arch/symbols, mirroring `RiftFfiBindings`/`TreeSitterLoader`. The
/// caller (`AecProcessor`/`AecMicFilter`) then passes the mic through unchanged
/// and the text-based `MeetingEchoFilter` remains the echo defense.
class AecFfiBindings {
  AecFfiBindings._(
    this._create,
    this._reverse,
    this._capture,
    this._metrics,
    this._destroy,
    this._version,
  );

  /// PCM frames per processing block: 10 ms at 16 kHz mono (WebRTC AEC3's unit).
  static const int framesPerBlock = 160;

  /// Sentinel a `double` metric is set to when AEC3 has no value yet.
  static const double metricUnavailable = -1000.0;

  final _CreateDart _create;
  final _ReverseDart _reverse;
  final _CaptureDart _capture;
  final _MetricsDart _metrics;
  final _DestroyDart _destroy;
  final _VersionDart _version;

  /// Attempts to load the AEC dylib from [explicitPaths] first (caller-resolved
  /// dev / app-support / bundle locations), then platform default candidates.
  /// Returns `null` if nothing loads or the symbols are missing.
  static AecFfiBindings? tryLoad({List<String> explicitPaths = const []}) {
    final lib = _tryOpen([...explicitPaths, ..._candidates()]);
    if (lib == null) {
      return null;
    }
    try {
      final create =
          lib.lookupFunction<Pointer<Void> Function(Int32, Int32), _CreateDart>(
        'aec_create',
      );
      final reverse = lib.lookupFunction<
          Void Function(Pointer<Void>, Pointer<Int16>, Int32), _ReverseDart>(
        'aec_process_reverse',
        isLeaf: true,
      );
      final capture = lib.lookupFunction<
          Void Function(
              Pointer<Void>, Pointer<Int16>, Pointer<Int16>, Int32, Int32),
          _CaptureDart>(
        'aec_process_capture',
        isLeaf: true,
      );
      final metrics = lib.lookupFunction<
          Void Function(Pointer<Void>, Pointer<Double>, Pointer<Double>,
              Pointer<Double>, Pointer<Int32>),
          _MetricsDart>(
        'aec_get_metrics',
        isLeaf: true,
      );
      final destroy =
          lib.lookupFunction<Void Function(Pointer<Void>), _DestroyDart>(
        'aec_destroy',
      );
      final version =
          lib.lookupFunction<Pointer<Utf8> Function(), _VersionDart>(
        'aec_version',
      );
      return AecFfiBindings._(
          create, reverse, capture, metrics, destroy, version);
    } catch (_) {
      // Library loaded but didn't export the expected symbols — degrade.
      return null;
    }
  }

  /// Creates a native AEC instance; returns `nullptr` on failure.
  Pointer<Void> create(int sampleRateHz, int numChannels) =>
      _create(sampleRateHz, numChannels);

  /// Feeds one far-end (reference/loopback) block of [framesPerBlock] samples.
  void processReverse(Pointer<Void> handle, Pointer<Int16> ref, int frames) =>
      _reverse(handle, ref, frames);

  /// Cleans one near-end (mic) block of [framesPerBlock] samples: reads [cap],
  /// writes the echo-removed result into [out]. [streamDelayMs] is the measured
  /// far-end→capture lead (see `aec_process_capture`).
  void processCapture(
    Pointer<Void> handle,
    Pointer<Int16> cap,
    Pointer<Int16> out,
    int frames,
    int streamDelayMs,
  ) =>
      _capture(handle, cap, out, frames, streamDelayMs);

  /// Writes AEC3's current echo metrics into the provided scratch pointers.
  /// Doubles are set to [metricUnavailable] and `delayMs` to `-1` when AEC3 has
  /// no value yet.
  void getMetrics(
    Pointer<Void> handle,
    Pointer<Double> erl,
    Pointer<Double> erle,
    Pointer<Double> residual,
    Pointer<Int32> delayMs,
  ) =>
      _metrics(handle, erl, erle, residual, delayMs);

  /// Destroys the native AEC instance.
  void destroy(Pointer<Void> handle) => _destroy(handle);

  /// Version string of the bundled engine, or null if unavailable.
  String? version() {
    final p = _version();
    return p == nullptr ? null : p.toDartString();
  }

  static List<String> _candidates() {
    if (Platform.isMacOS) {
      return const [
        '@executable_path/../Frameworks/libaec_ffi.dylib',
        '@executable_path/../Resources/libaec_ffi.dylib',
        'libaec_ffi.dylib',
      ];
    }
    if (Platform.isLinux) {
      return const ['libaec_ffi.so'];
    }
    if (Platform.isWindows) {
      return const ['aec_ffi.dll', 'libaec_ffi.dll'];
    }
    return const [];
  }

  static DynamicLibrary? _tryOpen(List<String> candidates) {
    for (final candidate in candidates) {
      if (candidate.isEmpty) {
        continue;
      }
      try {
        return DynamicLibrary.open(candidate);
      } on ArgumentError {
        continue; // not present at this path
      } catch (_) {
        continue; // bad arch / missing symbols — degrade
      }
    }
    return null;
  }
}

typedef _CreateDart = Pointer<Void> Function(int, int);
typedef _ReverseDart = void Function(Pointer<Void>, Pointer<Int16>, int);
typedef _CaptureDart = void Function(
    Pointer<Void>, Pointer<Int16>, Pointer<Int16>, int, int);
typedef _MetricsDart = void Function(Pointer<Void>, Pointer<Double>,
    Pointer<Double>, Pointer<Double>, Pointer<Int32>);
typedef _DestroyDart = void Function(Pointer<Void>);
typedef _VersionDart = Pointer<Utf8> Function();
