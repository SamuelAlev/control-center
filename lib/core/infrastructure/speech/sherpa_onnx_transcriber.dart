import 'dart:async';
import 'dart:typed_data';

import 'package:control_center/core/infrastructure/speech/speech_transcriber.dart';
import 'package:control_center/core/infrastructure/speech/voice_model_manager.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/// On-device speech-to-text using sherpa-onnx + Whisper.
///
/// The transcriber is *offline* — it buffers everything from [transcribe]'s
/// input stream until the stream closes, then runs Whisper on the assembled
/// 16-bit PCM @ 16 kHz waveform. Whisper-base.en runs in roughly real-time
/// on a modern CPU for short utterances; longer ones may take a few seconds.
///
/// One static [sherpa.initBindings] call wires up the native library; the
/// `sherpa_onnx_macos`/`_linux`/`_windows` plugin packages bundle the
/// platform dylib, so no further setup is needed.
class SherpaOnnxTranscriber implements SpeechTranscriber {
  /// Creates a new [Sherpa onnx transcriber].
  SherpaOnnxTranscriber({required this.paths});

  /// Resolved on-disk paths to the installed model files.
  final VoiceModelPaths paths;

  static bool _bindingsInitialised = false;
  sherpa.OfflineRecognizer? _recognizer;

  @override
  bool get isReady => _recognizer != null;

  @override
  String get displayName => 'sherpa-onnx (Whisper base.en)';

  @override
  Future<void> initialize() async {
    if (_recognizer != null) {
      return;
    }
    if (!_bindingsInitialised) {
      sherpa.initBindings();
      _bindingsInitialised = true;
    }
    final config = sherpa.OfflineRecognizerConfig(
      model: sherpa.OfflineModelConfig(
        whisper: sherpa.OfflineWhisperModelConfig(
          encoder: paths.encoder,
          decoder: paths.decoder,
          language: 'en',
          task: 'transcribe',
        ),
        tokens: paths.tokens,
        modelType: 'whisper',
        numThreads: 1,
        provider: 'cpu',
        debug: false,
      ),
    );
    _recognizer = sherpa.OfflineRecognizer(config);
  }

  @override
  Stream<TranscriptionResult> transcribe(Stream<List<int>> audio) {
    final controller = StreamController<TranscriptionResult>();
    final buffer = BytesBuilder(copy: false);

    final sub = audio.listen(
      buffer.add,
      onError: controller.addError,
      onDone: () async {
        try {
          final text = await _decodeBuffered(buffer.takeBytes());
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

  Future<String> _decodeBuffered(Uint8List pcm16Bytes) async {
    if (_recognizer == null) {
      await initialize();
    }
    if (pcm16Bytes.isEmpty) {
      return '';
    }
    final samples = _pcm16ToFloat32(pcm16Bytes);
    final stream = _recognizer!.createStream();
    try {
      stream.acceptWaveform(samples: samples, sampleRate: 16000);
      _recognizer!.decode(stream);
      final result = _recognizer!.getResult(stream);
      return result.text.trim();
    } finally {
      stream.free();
    }
  }

  /// Convert little-endian 16-bit PCM bytes into normalized Float32 samples
  /// in `[-1, 1]`, which is what sherpa-onnx expects.
  static Float32List _pcm16ToFloat32(Uint8List bytes) {
    final sampleCount = bytes.lengthInBytes ~/ 2;
    final out = Float32List(sampleCount);
    final view = ByteData.sublistView(bytes);
    for (var i = 0; i < sampleCount; i++) {
      final s = view.getInt16(i * 2, Endian.little);
      out[i] = s / 32768.0;
    }
    return out;
  }

  @override
  Future<void> dispose() async {
    _recognizer?.free();
    _recognizer = null;
  }
}

