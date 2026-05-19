import 'dart:ffi';

/// Base name of the native inference library (`libcc_inference.dylib` /
/// `libcc_inference.so` / `cc_inference.dll`), built by
/// `scripts/natives/build_inference.sh` from the in-repo Rust crate
/// `packages/cc_natives/native/inference/`.
///
/// ONE library covers both on-device ML workloads — speech (offline ASR, Silero
/// VAD, pyannote diarization, WeSpeaker voiceprints) and text embeddings —
/// because it statically links sherpa-onnx together with a single ONNX Runtime.
const String inferenceLibraryBaseName = 'cc_inference';

/// Env var overriding the inference dylib path (highest-priority candidate).
const String inferenceLibraryEnvVar = 'CC_INFERENCE_DYLIB';

/// The C ABI version this Dart binding speaks. Must equal the native's
/// `cc_inference_abi_version()`; a mismatch refuses to bind — and therefore
/// fails loudly — rather than misreading structs.
const int ccInferenceAbiVersion = 1;

/// `cc_spk_compute` / `cc_asr_transcribe` audio is 32-bit float mono at this
/// rate; PCM16 conversion stays in Dart.
const int ccInferenceSampleRate = 16000;

/// Mirror of the native `CcDiarSegment` (see `cc_inference.h`): one diarized
/// span in seconds, plus its speaker cluster index.
final class CcDiarSegment extends Struct {
  /// Span start, in seconds.
  @Float()
  external double startS;

  /// Span end, in seconds.
  @Float()
  external double endS;

  /// Speaker cluster index, as assigned by clustering.
  @Int32()
  external int speaker;
}

/// Typed bindings over the `cc_inference` dylib.
///
/// Every fallible entry point signals failure with NULL / -1 and leaves a
/// message in [lastError] (thread-local in the native, so it is only meaningful
/// on the isolate that made the failing call).
class CcInferenceBindings {
  CcInferenceBindings._({
    required this.lastError,
    required this.stringDestroy,
    required this.embedderCreate,
    required this.embedderRun,
    required this.embedderDestroy,
    required this.asrCreateWhisper,
    required this.asrCreateTransducer,
    required this.asrTranscribe,
    required this.asrDestroy,
    required this.vadCreate,
    required this.vadAccept,
    required this.vadIsDetected,
    required this.vadIsEmpty,
    required this.vadFront,
    required this.vadPop,
    required this.vadClear,
    required this.vadFlush,
    required this.vadDestroy,
    required this.diarCreate,
    required this.diarProcess,
    required this.diarSegmentsDestroy,
    required this.diarDestroy,
    required this.spkCreate,
    required this.spkDim,
    required this.spkCompute,
    required this.spkDestroy,
  });

  /// `cc_inference_last_error` — thread-local message; NULL when none.
  final Pointer<Uint8> Function() lastError;

  /// `cc_string_destroy` — frees a string the native returned.
  final void Function(Pointer<Uint8>) stringDestroy;

  /// `cc_embedder_create` — NULL on failure.
  final Pointer<Void> Function(Pointer<Uint8> modelPath, int numThreads)
  embedderCreate;

  /// `cc_embedder_run` — 0 ok, -1 error. Writes `seqLen * hidden` floats.
  final int Function(
    Pointer<Void> handle,
    Pointer<Int64> inputIds,
    Pointer<Int64> attentionMask,
    Pointer<Int64> tokenTypeIds,
    int seqLen,
    Pointer<Float> outHidden,
    int outCapacity,
    Pointer<Int32> outHiddenSize,
  )
  embedderRun;

  /// `cc_embedder_destroy` — NULL-safe.
  final void Function(Pointer<Void>) embedderDestroy;

  /// `cc_asr_create_whisper` — NULL on failure.
  final Pointer<Void> Function(
    Pointer<Uint8> encoder,
    Pointer<Uint8> decoder,
    Pointer<Uint8> tokens,
    Pointer<Uint8> language,
  )
  asrCreateWhisper;

  /// `cc_asr_create_transducer` — NULL on failure.
  final Pointer<Void> Function(
    Pointer<Uint8> encoder,
    Pointer<Uint8> decoder,
    Pointer<Uint8> joiner,
    Pointer<Uint8> tokens,
  )
  asrCreateTransducer;

  /// `cc_asr_transcribe` — malloc'd UTF-8 to free with [stringDestroy]; NULL on
  /// failure.
  final Pointer<Uint8> Function(
    Pointer<Void> handle,
    Pointer<Float> samples,
    int n,
    int sampleRate,
  )
  asrTranscribe;

  /// `cc_asr_destroy` — releases the model weights; NULL-safe.
  final void Function(Pointer<Void>) asrDestroy;

  /// `cc_vad_create` — NULL on failure.
  final Pointer<Void> Function(
    Pointer<Uint8> model,
    double threshold,
    double minSilenceS,
    double minSpeechS,
    int sampleRate,
    double bufferSizeS,
  )
  vadCreate;

  /// `cc_vad_accept` — feeds float samples in `[-1, 1]`.
  final void Function(Pointer<Void> handle, Pointer<Float> samples, int n)
  vadAccept;

  /// `cc_vad_is_detected` — 1 when speech is live.
  final int Function(Pointer<Void>) vadIsDetected;

  /// `cc_vad_is_empty` — 1 when the segment queue is empty.
  final int Function(Pointer<Void>) vadIsEmpty;

  /// `cc_vad_front` — 1 = range written, 0 = queue empty.
  final int Function(
    Pointer<Void> handle,
    Pointer<Int32> outStart,
    Pointer<Int32> outLen,
  )
  vadFront;

  /// `cc_vad_pop` — drops the queued segment.
  final void Function(Pointer<Void>) vadPop;

  /// `cc_vad_clear` — clears queue + detector state.
  final void Function(Pointer<Void>) vadClear;

  /// `cc_vad_flush` — flushes trailing speech into the queue.
  final void Function(Pointer<Void>) vadFlush;

  /// `cc_vad_destroy` — NULL-safe.
  final void Function(Pointer<Void>) vadDestroy;

  /// `cc_diar_create` — NULL on failure.
  final Pointer<Void> Function(
    Pointer<Uint8> segmentationModel,
    Pointer<Uint8> embeddingModel,
    int numThreads,
    double clusteringThreshold,
    double minDurationOnS,
    double minDurationOffS,
  )
  diarCreate;

  /// `cc_diar_process` — 0 ok (count may be 0), -1 error.
  final int Function(
    Pointer<Void> handle,
    Pointer<Float> samples,
    int n,
    Pointer<Pointer<CcDiarSegment>> outSegments,
    Pointer<IntPtr> outCount,
  )
  diarProcess;

  /// `cc_diar_segments_destroy` — frees a [diarProcess] array.
  final void Function(Pointer<CcDiarSegment> segments, int count)
  diarSegmentsDestroy;

  /// `cc_diar_destroy` — NULL-safe.
  final void Function(Pointer<Void>) diarDestroy;

  /// `cc_spk_create` — NULL on failure.
  final Pointer<Void> Function(Pointer<Uint8> model, int numThreads) spkCreate;

  /// `cc_spk_dim` — embedding width, -1 on a null handle.
  final int Function(Pointer<Void>) spkDim;

  /// `cc_spk_compute` — 0 ok, 1 = audio too short (skip), -1 error.
  final int Function(
    Pointer<Void> handle,
    Pointer<Float> samples,
    int n,
    int sampleRate,
    Pointer<Float> out,
    int outCapacity,
  )
  spkCompute;

  /// `cc_spk_destroy` — NULL-safe.
  final void Function(Pointer<Void>) spkDestroy;

  /// Binds against [lib], or returns null when a symbol is missing or the
  /// native speaks a different ABI version.
  ///
  /// Null is a broken install, never a degraded mode: callers turn it into a
  /// `NativeLibraryUnavailable`, and `cc_server`'s boot preflight refuses to
  /// start without the dylib.
  static CcInferenceBindings? tryFrom(DynamicLibrary lib) {
    try {
      final abiVersion = lib.lookupFunction<Uint32 Function(), int Function()>(
        'cc_inference_abi_version',
      );
      if (abiVersion() != ccInferenceAbiVersion) {
        return null;
      }
      return CcInferenceBindings._(
        lastError: lib.lookupFunction<Pointer<Uint8> Function(), Pointer<Uint8> Function()>(
          'cc_inference_last_error',
        ),
        stringDestroy: lib.lookupFunction<Void Function(Pointer<Uint8>), void Function(Pointer<Uint8>)>(
          'cc_string_destroy',
        ),
        embedderCreate: lib.lookupFunction<
          Pointer<Void> Function(Pointer<Uint8>, Int32),
          Pointer<Void> Function(Pointer<Uint8>, int)
        >('cc_embedder_create'),
        embedderRun: lib.lookupFunction<
          Int32 Function(Pointer<Void>, Pointer<Int64>, Pointer<Int64>, Pointer<Int64>, IntPtr, Pointer<Float>, IntPtr, Pointer<Int32>),
          int Function(Pointer<Void>, Pointer<Int64>, Pointer<Int64>, Pointer<Int64>, int, Pointer<Float>, int, Pointer<Int32>)
        >('cc_embedder_run'),
        embedderDestroy: lib.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>(
          'cc_embedder_destroy',
        ),
        asrCreateWhisper: lib.lookupFunction<
          Pointer<Void> Function(Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>),
          Pointer<Void> Function(Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>)
        >('cc_asr_create_whisper'),
        asrCreateTransducer: lib.lookupFunction<
          Pointer<Void> Function(Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>),
          Pointer<Void> Function(Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>)
        >('cc_asr_create_transducer'),
        asrTranscribe: lib.lookupFunction<
          Pointer<Uint8> Function(Pointer<Void>, Pointer<Float>, IntPtr, Int32),
          Pointer<Uint8> Function(Pointer<Void>, Pointer<Float>, int, int)
        >('cc_asr_transcribe'),
        asrDestroy: lib.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>(
          'cc_asr_destroy',
        ),
        vadCreate: lib.lookupFunction<
          Pointer<Void> Function(Pointer<Uint8>, Float, Float, Float, Int32, Float),
          Pointer<Void> Function(Pointer<Uint8>, double, double, double, int, double)
        >('cc_vad_create'),
        vadAccept: lib.lookupFunction<
          Void Function(Pointer<Void>, Pointer<Float>, IntPtr),
          void Function(Pointer<Void>, Pointer<Float>, int)
        >('cc_vad_accept'),
        vadIsDetected: lib.lookupFunction<Int32 Function(Pointer<Void>), int Function(Pointer<Void>)>(
          'cc_vad_is_detected',
        ),
        vadIsEmpty: lib.lookupFunction<Int32 Function(Pointer<Void>), int Function(Pointer<Void>)>(
          'cc_vad_is_empty',
        ),
        vadFront: lib.lookupFunction<
          Int32 Function(Pointer<Void>, Pointer<Int32>, Pointer<Int32>),
          int Function(Pointer<Void>, Pointer<Int32>, Pointer<Int32>)
        >('cc_vad_front'),
        vadPop: lib.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>(
          'cc_vad_pop',
        ),
        vadClear: lib.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>(
          'cc_vad_clear',
        ),
        vadFlush: lib.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>(
          'cc_vad_flush',
        ),
        vadDestroy: lib.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>(
          'cc_vad_destroy',
        ),
        diarCreate: lib.lookupFunction<
          Pointer<Void> Function(Pointer<Uint8>, Pointer<Uint8>, Int32, Float, Float, Float),
          Pointer<Void> Function(Pointer<Uint8>, Pointer<Uint8>, int, double, double, double)
        >('cc_diar_create'),
        diarProcess: lib.lookupFunction<
          Int32 Function(Pointer<Void>, Pointer<Float>, IntPtr, Pointer<Pointer<CcDiarSegment>>, Pointer<IntPtr>),
          int Function(Pointer<Void>, Pointer<Float>, int, Pointer<Pointer<CcDiarSegment>>, Pointer<IntPtr>)
        >('cc_diar_process'),
        diarSegmentsDestroy: lib.lookupFunction<
          Void Function(Pointer<CcDiarSegment>, IntPtr),
          void Function(Pointer<CcDiarSegment>, int)
        >('cc_diar_segments_destroy'),
        diarDestroy: lib.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>(
          'cc_diar_destroy',
        ),
        spkCreate: lib.lookupFunction<
          Pointer<Void> Function(Pointer<Uint8>, Int32),
          Pointer<Void> Function(Pointer<Uint8>, int)
        >('cc_spk_create'),
        spkDim: lib.lookupFunction<Int32 Function(Pointer<Void>), int Function(Pointer<Void>)>(
          'cc_spk_dim',
        ),
        spkCompute: lib.lookupFunction<
          Int32 Function(Pointer<Void>, Pointer<Float>, IntPtr, Int32, Pointer<Float>, IntPtr),
          int Function(Pointer<Void>, Pointer<Float>, int, int, Pointer<Float>, int)
        >('cc_spk_compute'),
        spkDestroy: lib.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>(
          'cc_spk_destroy',
        ),
      );
    } on ArgumentError {
      // Missing symbol — an unrelated, truncated or stale dylib.
      return null;
    }
  }
}
