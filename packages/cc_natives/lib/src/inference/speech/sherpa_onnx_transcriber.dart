import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cc_domain/features/meetings/domain/services/speech_transcriber.dart';
import 'package:cc_domain/features/meetings/domain/value_objects/voice_model_paths.dart';
import 'package:cc_natives/src/inference/cc_inference_bindings.dart';
import 'package:cc_natives/src/inference/inference_library.dart';
import 'package:ffi/ffi.dart';

/// On-device speech-to-text using sherpa-onnx + Whisper, decoded on a dedicated
/// worker isolate.
///
/// Whisper decoding is a *synchronous* native (FFI) call: a multi-second window
/// takes hundreds of milliseconds to a few seconds of solid CPU. Running it on
/// the main isolate froze the UI (Sentry "ANR") and starved live capture, so the
/// recognizer lives entirely on a long-lived worker isolate. The native
/// recognizer handle cannot cross isolates, so it is created INSIDE the worker
/// and fed PCM windows over a [SendPort]; only plain bytes and strings travel
/// between isolates. The worker's message loop processes
/// one request at a time, which serializes the single recognizer safely (matching
/// the previous single-recognizer behavior) — but now off the UI thread.
///
/// The worker binds the `cc_inference` dylib for ITS OWN isolate
/// ([ensureInferenceBindings]): FFI bindings are per-isolate, so the host's
/// binding does not carry over. The dylib statically links sherpa-onnx and its
/// ONNX Runtime, so there is nothing else to locate alongside it.
class SherpaOnnxTranscriber implements SpeechTranscriber {
  /// Creates a [SherpaOnnxTranscriber].
  ///
  /// [libPath], when given, is the absolute path of the `cc_inference` dylib;
  /// the decode worker (a separate isolate that cannot see the host's
  /// preferred-path static) loads the native from there. A host resolves it
  /// with [resolveInferenceLibraryPath]; null lets the worker resolve it from
  /// the environment and bundle layout itself.
  SherpaOnnxTranscriber({required this.paths, this.libPath});

  /// Resolved on-disk paths to the installed model files.
  final VoiceModelPaths paths;

  /// Absolute path of the `cc_inference` dylib, forwarded to the decode worker;
  /// null = let the worker resolve it itself.
  final String? libPath;

  Isolate? _isolate;
  SendPort? _commands; // main → worker
  ReceivePort? _fromWorker; // worker → main (also the spawn error/exit port)
  StreamSubscription<dynamic>? _fromWorkerSub;
  Completer<void>? _ready;
  final Map<int, Completer<String>> _pending = {};
  int _nextRequestId = 0;
  bool _disposed = false;

  @override
  bool get isReady => (_ready?.isCompleted ?? false) && !_disposed;

  @override
  String get displayName => switch (paths.type) {
    VoiceModelType.whisper => 'sherpa-onnx (Whisper)',
    VoiceModelType.transducer => 'sherpa-onnx (transducer)',
  };

  @override
  Future<void> initialize() {
    final existing = _ready;
    if (existing != null) {
      return existing.future; // already initialised or in flight
    }
    final ready = _ready = Completer<void>();
    unawaited(_spawnWorker(ready));
    return ready.future;
  }

  Future<void> _spawnWorker(Completer<void> ready) async {
    try {
      final fromWorker = _fromWorker = ReceivePort();
      final handshake = Completer<SendPort>();
      _fromWorkerSub = fromWorker.listen((Object? message) {
        if (message is SendPort) {
          handshake.complete(message);
        } else if (message is List) {
          // Uncaught error / abnormal exit forwarded via onError/onExit.
          _onWorkerCrash(message);
        } else if (message is Map) {
          _onWorkerMessage(message);
        }
      });
      _isolate = await Isolate.spawn(
        _whisperWorkerMain,
        fromWorker.sendPort,
        debugName: 'whisper-transcriber',
        onError: fromWorker.sendPort,
        onExit: fromWorker.sendPort,
      );
      final commands = _commands = await handshake.future;
      commands.send(<String, Object?>{
        'type': 'init',
        'modelType': paths.type.name,
        'encoder': paths.encoder,
        'decoder': paths.decoder,
        'joiner': paths.joiner,
        'tokens': paths.tokens,
        'language': paths.language,
        // Where the worker isolate loads the inference dylib from.
        'libPath': libPath,
      });
      // `ready` is completed by _onWorkerMessage on 'ready'/'init_error'.
    } catch (e) {
      if (!ready.isCompleted) {
        ready.completeError(e);
      }
    }
  }

  void _onWorkerMessage(Map<Object?, Object?> msg) {
    switch (msg['type']) {
      case 'ready':
        if (!(_ready?.isCompleted ?? true)) {
          _ready!.complete();
        }
      case 'init_error':
        if (!(_ready?.isCompleted ?? true)) {
          _ready!.completeError(
            StateError(msg['message'] as String? ?? 'recognizer init failed'),
          );
        }
      case 'result':
        _pending.remove(msg['id'])?.complete(msg['text'] as String? ?? '');
      case 'error':
        _pending
            .remove(msg['id'])
            ?.completeError(
              StateError(msg['message'] as String? ?? 'decode failed'),
            );
    }
  }

  /// The worker isolate threw or exited abnormally. Fail everything in flight so
  /// no caller hangs; further [transcribeChunk] calls will rethrow via [_ready].
  void _onWorkerCrash(List<Object?> error) {
    final detail = error.isNotEmpty ? '${error.first}' : 'unknown error';
    final err = StateError('whisper worker isolate crashed: $detail');
    if (!(_ready?.isCompleted ?? true)) {
      _ready!.completeError(err);
    }
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(err);
      }
    }
    _pending.clear();
  }

  @override
  Stream<TranscriptionResult> transcribe(Stream<List<int>> audio) {
    final controller = StreamController<TranscriptionResult>();
    final buffer = BytesBuilder(copy: false);

    final sub = audio.listen(
      (chunk) =>
          buffer.add(chunk is Uint8List ? chunk : Uint8List.fromList(chunk)),
      onError: controller.addError,
      onDone: () async {
        try {
          final text = await transcribeChunk(buffer.takeBytes());
          controller.add(TranscriptionResult(text: text, isFinal: true));
        } catch (e, s) {
          controller.addError(e, s);
        } finally {
          await controller.close();
        }
      },
      cancelOnError: false,
    );
    controller.onCancel = sub.cancel;
    return controller.stream;
  }

  @override
  Future<String> transcribeChunk(Uint8List pcm16) async {
    if (_disposed) {
      return '';
    }
    await initialize();
    final commands = _commands;
    if (_disposed || commands == null || pcm16.isEmpty) {
      return '';
    }
    final id = _nextRequestId++;
    final completer = Completer<String>();
    _pending[id] = completer;
    commands.send(<String, Object?>{
      'type': 'decode',
      'id': id,
      // Move the bytes to the worker without copying.
      'data': TransferableTypedData.fromList(<Uint8List>[pcm16]),
    });
    return completer.future;
  }

  /// Releases the worker isolate and the native recognizer while keeping this
  /// transcriber REUSABLE — unlike [dispose], the next [initialize] (or
  /// [transcribeChunk], which initializes on demand) respawns the worker and
  /// reloads the model.
  ///
  /// The loaded ASR model is by far the largest allocation in an idle server
  /// (hundreds of MB for Whisper/Parakeet weights), so the recording service
  /// unloads it when the last live session stops; the next recording pays a
  /// one-time reload while its first audio window buffers.
  ///
  /// No-op while an [initialize] is still in flight or decodes are pending —
  /// unloading mid-work would strand their completers.
  Future<void> unload() async {
    if (_disposed || !(_ready?.isCompleted ?? false) || _pending.isNotEmpty) {
      return;
    }
    _commands?.send(<String, Object?>{'type': 'dispose'});
    await _fromWorkerSub?.cancel();
    _fromWorker?.close();
    _isolate?.kill(priority: Isolate.beforeNextEvent);
    _isolate = null;
    _commands = null;
    _fromWorker = null;
    _fromWorkerSub = null;
    _ready = null;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _commands?.send(<String, Object?>{'type': 'dispose'});
    await _fromWorkerSub?.cancel();
    _fromWorker?.close();
    _isolate?.kill(priority: Isolate.beforeNextEvent);
    _isolate = null;
    _commands = null;
    _fromWorker = null;
    _fromWorkerSub = null;
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.complete('');
      }
    }
    _pending.clear();
  }
}

/// Worker-isolate entry point. Owns the native recognizer and serves decode
/// requests over a port; see [SherpaOnnxTranscriber] for the rationale and the
/// message protocol.
void _whisperWorkerMain(SendPort toMain) {
  final commands = ReceivePort();
  toMain.send(commands.sendPort);

  CcInferenceBindings? bindings;
  Pointer<Void> recognizer = nullptr;

  void freeRecognizer() {
    if (recognizer != nullptr) {
      bindings?.asrDestroy(recognizer);
      recognizer = nullptr;
    }
  }

  commands.listen((Object? message) {
    final msg = message as Map<Object?, Object?>;
    switch (msg['type']) {
      case 'init':
        try {
          // Bind for THIS isolate — FFI bindings never cross isolate
          // boundaries, and this is where a genuine load failure can be
          // reported as an actionable `init_error`.
          final libPath = msg['libPath'] as String?;
          final loaded = ensureInferenceBindings(explicitPath: libPath);
          if (loaded == null) {
            throw StateError(
              inferenceLibraryUnavailableMessage(searchedPath: libPath),
            );
          }
          bindings = loaded;

          final modelType = msg['modelType'] as String? ?? 'whisper';
          final encoder = (msg['encoder']! as String).toNativeUtf8(allocator: calloc);
          final decoder = (msg['decoder']! as String).toNativeUtf8(allocator: calloc);
          final joiner = ((msg['joiner'] as String?) ?? '').toNativeUtf8(allocator: calloc);
          final tokens = (msg['tokens']! as String).toNativeUtf8(allocator: calloc);
          final language = ((msg['language'] as String?) ?? '').toNativeUtf8(allocator: calloc);
          try {
            recognizer = modelType == 'transducer'
                ? loaded.asrCreateTransducer(
                    encoder.cast<Uint8>(),
                    decoder.cast<Uint8>(),
                    joiner.cast<Uint8>(),
                    tokens.cast<Uint8>(),
                  )
                : loaded.asrCreateWhisper(
                    encoder.cast<Uint8>(),
                    decoder.cast<Uint8>(),
                    tokens.cast<Uint8>(),
                    language.cast<Uint8>(),
                  );
          } finally {
            calloc.free(encoder);
            calloc.free(decoder);
            calloc.free(joiner);
            calloc.free(tokens);
            calloc.free(language);
          }
          if (recognizer == nullptr) {
            throw StateError(
              readInferenceError(
                loaded,
                fallback: 'recognizer init failed',
              ),
            );
          }
          toMain.send(<String, Object?>{'type': 'ready'});
        } catch (e) {
          toMain.send(<String, Object?>{
            'type': 'init_error',
            'message': e.toString(),
          });
        }
      case 'decode':
        final id = msg['id']! as int;
        final loaded = bindings;
        if (loaded == null || recognizer == nullptr) {
          toMain.send(<String, Object?>{
            'type': 'error',
            'id': id,
            'message': 'recognizer not initialised',
          });
          return;
        }
        try {
          final bytes = (msg['data']! as TransferableTypedData)
              .materialize()
              .asUint8List();
          final samples = _pcm16ToFloat32(bytes);
          final buffer = calloc<Float>(samples.length);
          try {
            buffer.asTypedList(samples.length).setAll(0, samples);
            final raw = loaded.asrTranscribe(
              recognizer,
              buffer,
              samples.length,
              ccInferenceSampleRate,
            );
            if (raw == nullptr) {
              throw StateError(
                readInferenceError(loaded, fallback: 'decode failed'),
              );
            }
            final String text;
            try {
              text = raw.cast<Utf8>().toDartString().trim();
            } finally {
              loaded.stringDestroy(raw);
            }
            toMain.send(<String, Object?>{
              'type': 'result',
              'id': id,
              'text': text,
            });
          } finally {
            calloc.free(buffer);
          }
        } catch (e) {
          toMain.send(<String, Object?>{
            'type': 'error',
            'id': id,
            'message': e.toString(),
          });
        }
      case 'dispose':
        freeRecognizer();
        commands.close();
    }
  });
}

/// Convert little-endian 16-bit PCM bytes into normalized Float32 samples in
/// `[-1, 1]`, which is what the recognizer expects. Top-level so the worker
/// isolate entry point can reach it.
Float32List _pcm16ToFloat32(Uint8List bytes) {
  final sampleCount = bytes.lengthInBytes ~/ 2;
  final out = Float32List(sampleCount);
  final view = ByteData.sublistView(bytes);
  for (var i = 0; i < sampleCount; i++) {
    out[i] = view.getInt16(i * 2, Endian.little) / 32768.0;
  }
  return out;
}
