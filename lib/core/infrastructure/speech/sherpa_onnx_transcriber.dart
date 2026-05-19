import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:control_center/core/infrastructure/speech/speech_transcriber.dart';
import 'package:control_center/core/infrastructure/speech/voice_model_manager.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/// On-device speech-to-text using sherpa-onnx + Whisper, decoded on a dedicated
/// worker isolate.
///
/// Whisper decoding is a *synchronous* native (FFI) call: a multi-second window
/// takes hundreds of milliseconds to a few seconds of solid CPU. Running it on
/// the main isolate froze the UI (Sentry "ANR") and starved live capture, so the
/// recognizer lives entirely on a long-lived worker isolate. The native
/// [sherpa.OfflineRecognizer] holds FFI handles that cannot cross isolates, so it
/// is created INSIDE the worker and fed PCM windows over a [SendPort]; only plain
/// bytes and strings travel between isolates. The worker's message loop processes
/// one request at a time, which serializes the single recognizer safely (matching
/// the previous single-recognizer behavior) — but now off the UI thread.
///
/// One static [sherpa.initBindings] call (made inside the worker) wires up the
/// native library; the `sherpa_onnx_macos`/`_linux`/`_windows` plugin packages
/// bundle the platform dylib into the process, so it resolves from any isolate.
class SherpaOnnxTranscriber implements SpeechTranscriber {
  /// Creates a [SherpaOnnxTranscriber].
  SherpaOnnxTranscriber({required this.paths});

  /// Resolved on-disk paths to the installed model files.
  final VoiceModelPaths paths;

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
  String get displayName => 'sherpa-onnx (Whisper base.en)';

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
        'encoder': paths.encoder,
        'decoder': paths.decoder,
        'tokens': paths.tokens,
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
        _pending.remove(msg['id'])?.completeError(
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

/// Worker-isolate entry point. Owns the native [sherpa.OfflineRecognizer] and
/// serves decode requests over a port; see [SherpaOnnxTranscriber] for the
/// rationale and the message protocol.
void _whisperWorkerMain(SendPort toMain) {
  final commands = ReceivePort();
  toMain.send(commands.sendPort);

  sherpa.OfflineRecognizer? recognizer;
  var bindingsInitialised = false;

  commands.listen((Object? message) {
    final msg = message as Map<Object?, Object?>;
    switch (msg['type']) {
      case 'init':
        try {
          if (!bindingsInitialised) {
            sherpa.initBindings();
            bindingsInitialised = true;
          }
          final config = sherpa.OfflineRecognizerConfig(
            model: sherpa.OfflineModelConfig(
              whisper: sherpa.OfflineWhisperModelConfig(
                encoder: msg['encoder']! as String,
                decoder: msg['decoder']! as String,
                language: 'en',
                task: 'transcribe',
              ),
              tokens: msg['tokens']! as String,
              modelType: 'whisper',
              // We are off the UI thread now, so use a few threads to keep each
              // window's decode well under real time and avoid a backlog when
              // both meeting channels (mic + system) feed the recognizer.
              numThreads: 4,
              provider: 'cpu',
              debug: false,
            ),
          );
          recognizer = sherpa.OfflineRecognizer(config);
          toMain.send(<String, Object?>{'type': 'ready'});
        } catch (e) {
          toMain.send(<String, Object?>{
            'type': 'init_error',
            'message': e.toString(),
          });
        }
      case 'decode':
        final id = msg['id']! as int;
        final rec = recognizer;
        if (rec == null) {
          toMain.send(<String, Object?>{
            'type': 'error',
            'id': id,
            'message': 'recognizer not initialised',
          });
          return;
        }
        try {
          final bytes =
              (msg['data']! as TransferableTypedData).materialize().asUint8List();
          final samples = _pcm16ToFloat32(bytes);
          final stream = rec.createStream();
          try {
            stream.acceptWaveform(samples: samples, sampleRate: 16000);
            rec.decode(stream);
            final text = rec.getResult(stream).text.trim();
            toMain.send(<String, Object?>{'type': 'result', 'id': id, 'text': text});
          } finally {
            stream.free();
          }
        } catch (e) {
          toMain.send(<String, Object?>{
            'type': 'error',
            'id': id,
            'message': e.toString(),
          });
        }
      case 'dispose':
        recognizer?.free();
        recognizer = null;
        commands.close();
    }
  });
}

/// Convert little-endian 16-bit PCM bytes into normalized Float32 samples in
/// `[-1, 1]`, which is what sherpa-onnx expects. Top-level so the worker isolate
/// entry point can reach it.
Float32List _pcm16ToFloat32(Uint8List bytes) {
  final sampleCount = bytes.lengthInBytes ~/ 2;
  final out = Float32List(sampleCount);
  final view = ByteData.sublistView(bytes);
  for (var i = 0; i < sampleCount; i++) {
    out[i] = view.getInt16(i * 2, Endian.little) / 32768.0;
  }
  return out;
}
