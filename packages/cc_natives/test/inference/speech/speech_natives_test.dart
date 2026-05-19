@TestOn('vm')
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cc_domain/features/meetings/domain/value_objects/voice_model_paths.dart';
import 'package:cc_natives/src/inference/cc_inference_bindings.dart';
import 'package:cc_natives/src/inference/inference_library.dart';
import 'package:cc_natives/src/inference/speech/meeting_diarization_service.dart';
import 'package:cc_natives/src/inference/speech/meeting_offline_vad.dart';
import 'package:cc_natives/src/inference/speech/sherpa_onnx_transcriber.dart';
import 'package:cc_natives/src/inference/speech/silero_vad_detector.dart';
import 'package:test/test.dart';

/// End-to-end exercise of the speech natives against REAL models and REAL
/// speech.
///
/// The unit tests around these entry points only cover failure paths (missing
/// model, null handle), which never construct a working engine — so a wrong
/// config field, a swapped argument or a mis-sized buffer would pass them all
/// and surface only in a recording.
///
/// **These tests must never be vacuous.** Silero and pyannote are trained on
/// speech: synthetic tones produce ZERO spans, so a test that only walks the
/// returned list asserts nothing while looking green. Every case here therefore
/// demands non-empty output first and the audio is real speech from `say`
/// rather than a generated waveform.
void main() {
  final repoRoot = _repoRoot();
  final sileroModel = File('$repoRoot/assets/models/silero-vad/silero_vad.onnx');
  final modelsRoot =
      '${Platform.environment['HOME']}/Library/Application Support/'
      'control-center/models';
  final segmentationModel = File(
    '$modelsRoot/sherpa-onnx-diarization/'
    'sherpa-onnx-pyannote-segmentation-3-0/model.onnx',
  );
  final embeddingModel = File(
    '$modelsRoot/sherpa-onnx-diarization/'
    'wespeaker_en_voxceleb_resnet34_LM.onnx',
  );

  final libPath = resolveInferenceLibraryPath();

  // Synthesized eagerly, NOT in setUpAll: `skip:` is evaluated while the group
  // is being declared, so a fixture created in setUpAll would not exist yet.
  final tempDir = Directory.systemTemp.createTempSync('cc-speech-natives');
  final speech = _synthesizeSpeech(tempDir);
  tearDownAll(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  String? skipReason({bool needsDiarization = false}) {
    if (libPath == null) {
      return 'cc_inference not staged';
    }
    if (!sileroModel.existsSync()) {
      return 'silero model missing';
    }
    if (speech == null) {
      return 'no speech fixture — `say` is unavailable (macOS only)';
    }
    if (needsDiarization &&
        (!segmentationModel.existsSync() || !embeddingModel.existsSync())) {
      return 'diarization models not installed under $modelsRoot';
    }
    return null;
  }

  group('Silero VAD (streaming)', () {
    test('fires on speech, not on silence', () {
      final detector = SileroVadDetector.create(
        modelPath: sileroModel.path,
        libPath: libPath,
      );
      addTearDown(detector.dispose);

      expect(
        detector.isSpeech(Uint8List(ccInferenceSampleRate * 2)),
        isFalse,
        reason: 'a second of digital silence must not read as speech',
      );
      detector.reset();

      // 100 ms chunks, the shape the transcription service feeds it.
      const chunkBytes = ccInferenceSampleRate ~/ 10 * 2;
      var detected = 0;
      var chunks = 0;
      for (var o = 0; o + chunkBytes <= speech!.pcm16.length; o += chunkBytes) {
        chunks++;
        if (detector.isSpeech(
          Uint8List.sublistView(speech.pcm16, o, o + chunkBytes),
        )) {
          detected++;
        }
      }
      expect(chunks, greaterThan(10), reason: 'fixture too short to be a test');
      expect(
        detected,
        greaterThan(chunks ~/ 2),
        reason:
            'only $detected of $chunks speech chunks registered — the detector '
            'is receiving the wrong samples or is misconfigured',
      );
    }, skip: skipReason());

    test('dispose is idempotent and makes further calls inert', () {
      final detector = SileroVadDetector.create(
        modelPath: sileroModel.path,
        libPath: libPath,
      );
      detector.dispose();
      detector.dispose();
      // Must not dereference the freed handle.
      expect(detector.isSpeech(Uint8List(1024)), isFalse);
      detector.reset();
    }, skip: skipReason());
  });

  group('Silero VAD (offline)', () {
    test('returns ordered, in-bounds spans covering the speech', () async {
      final totalMs = (speech!.samples.length * 1000 / ccInferenceSampleRate)
          .round();

      final spans = await const MeetingOfflineVad().detect(
        samples: speech.samples,
        modelPath: sileroModel.path,
        libPath: libPath,
      );

      expect(
        spans,
        isNotEmpty,
        reason:
            'no speech spans over ${totalMs}ms of real speech — the offline '
            'window loop or the sample-range conversion is broken',
      );

      var previousEnd = -1;
      var covered = 0;
      for (final span in spans) {
        expect(span.startMs, greaterThanOrEqualTo(0));
        expect(span.endMs, greaterThan(span.startMs));
        expect(
          span.endMs,
          lessThanOrEqualTo(totalMs),
          reason:
              'span ends at ${span.endMs}ms but the recording is ${totalMs}ms '
              '— the sample-range → milliseconds conversion is wrong',
        );
        expect(
          span.startMs,
          greaterThanOrEqualTo(previousEnd),
          reason: 'spans must come out in time order',
        );
        previousEnd = span.endMs;
        covered += span.endMs - span.startMs;
      }
      expect(
        covered,
        greaterThan(totalMs ~/ 3),
        reason: 'spans cover only ${covered}ms of ${totalMs}ms of speech',
      );
    }, skip: skipReason());

    test('an empty recording yields no spans', () async {
      expect(
        await const MeetingOfflineVad().detect(
          samples: Float32List(0),
          modelPath: sileroModel.path,
          libPath: libPath,
        ),
        isEmpty,
      );
    }, skip: skipReason());
  });

  group('diarization', () {
    test('produces in-bounds spans and unit-norm voiceprints', () async {
      final totalMs = (speech!.samples.length * 1000 / ccInferenceSampleRate)
          .round();

      final result = await MeetingDiarizationService(libPath: libPath).diarize(
        segmentationModelPath: segmentationModel.path,
        embeddingModelPath: embeddingModel.path,
        samples: speech.samples,
      );

      expect(
        result.spans,
        isNotEmpty,
        reason:
            'no diarized spans over ${totalMs}ms of real speech — the config '
            'or the segment copy-out is broken',
      );

      for (final span in result.spans) {
        expect(span.startMs, greaterThanOrEqualTo(0));
        expect(span.endMs, greaterThan(span.startMs));
        expect(
          span.endMs,
          lessThanOrEqualTo(totalMs),
          reason:
              'span ends at ${span.endMs}ms but the recording is ${totalMs}ms '
              '— the seconds → milliseconds conversion is wrong',
        );
        expect(span.speaker, greaterThanOrEqualTo(0));
      }

      expect(
        result.embeddings,
        isNotEmpty,
        reason: 'spans were produced but no voiceprint was extracted',
      );
      for (final entry in result.embeddings.entries) {
        expect(entry.value, isNotEmpty);
        var sumSq = 0.0;
        for (final v in entry.value) {
          sumSq += v * v;
        }
        // The cross-meeting match thresholds are cosine values calibrated
        // against unit vectors, so an unnormalized voiceprint silently breaks
        // speaker matching rather than failing loudly.
        expect(
          math.sqrt(sumSq),
          closeTo(1.0, 1e-4),
          reason: 'voiceprint for speaker ${entry.key} is not unit-norm',
        );
        expect(
          result.spans.any((s) => s.speaker == entry.key),
          isTrue,
          reason: 'a voiceprint was keyed to a speaker with no spans',
        );
      }
    }, skip: skipReason(needsDiarization: true));

    test('an empty recording is a no-op', () async {
      final result = await MeetingDiarizationService(libPath: libPath).diarize(
        segmentationModelPath: segmentationModel.path,
        embeddingModelPath: embeddingModel.path,
        samples: Float32List(0),
      );
      expect(result.spans, isEmpty);
      expect(result.embeddings, isEmpty);
    }, skip: skipReason(needsDiarization: true));
  });

  group('offline ASR', () {
    // Whichever Whisper model happens to be installed. Set
    // CC_WHISPER_MODEL_DIR to point at an unpacked sherpa Whisper directory
    // (encoder/decoder/tokens) to run this without installing one through the
    // app.
    final whisper = _findWhisperModel();

    test('transcribes real speech and survives an unload/reload', () async {
      final transcriber = SherpaOnnxTranscriber(
        paths: whisper!,
        libPath: libPath,
      );
      addTearDown(transcriber.dispose);

      await transcriber.initialize();
      expect(transcriber.isReady, isTrue);

      final text = await transcriber.transcribeChunk(speech!.pcm16);
      // Not an accuracy assertion: these words are what the fixture says and
      // getting them back proves the whole chain — config fields, worker
      // protocol, PCM16→float conversion and the malloc'd-UTF8 round trip
      // through the C ABI.
      expect(text.toLowerCase(), contains('quick brown fox'));
      expect(text.toLowerCase(), contains('lazy dog'));

      // An empty window must be cheap and silent, not an error.
      expect(await transcriber.transcribeChunk(Uint8List(0)), isEmpty);

      // unload() releases the weights but keeps the transcriber REUSABLE — the
      // recording service relies on that between sessions.
      await transcriber.unload();
      expect(transcriber.isReady, isFalse);
      final afterReload = await transcriber.transcribeChunk(speech.pcm16);
      expect(afterReload.toLowerCase(), contains('quick brown fox'));
    }, timeout: const Timeout(Duration(minutes: 5)), skip: libPath == null
        ? 'cc_inference not staged'
        : speech == null
        ? 'no speech fixture — `say` is unavailable (macOS only)'
        : whisper == null
        ? 'no Whisper model installed (set CC_WHISPER_MODEL_DIR)'
        : null);
  });
}

/// An installed Whisper model, or null.
///
/// Looks at CC_WHISPER_MODEL_DIR first, then any `sherpa-onnx-whisper-*`
/// directory the app has installed under its models root.
VoiceModelPaths? _findWhisperModel() {
  final roots = <Directory>[
    if (Platform.environment['CC_WHISPER_MODEL_DIR'] case final d?)
      Directory(d),
    ...() {
      final models = Directory(
        '${Platform.environment['HOME']}/Library/Application Support/'
        'control-center/models',
      );
      if (!models.existsSync()) {
        return const <Directory>[];
      }
      return models
          .listSync()
          .whereType<Directory>()
          .where((d) => d.path.contains('whisper'));
    }(),
  ];

  for (final dir in roots) {
    if (!dir.existsSync()) {
      continue;
    }
    final files = dir.listSync().whereType<File>().map((f) => f.path).toList();
    String? pick(bool Function(String) matches) =>
        files.where(matches).firstOrNull;
    // Prefer the int8 weights: same graph, a quarter of the load time.
    final encoder =
        pick((p) => p.endsWith('-encoder.int8.onnx')) ??
        pick((p) => p.endsWith('-encoder.onnx'));
    final decoder =
        pick((p) => p.endsWith('-decoder.int8.onnx')) ??
        pick((p) => p.endsWith('-decoder.onnx'));
    final tokens = pick((p) => p.endsWith('-tokens.txt'));
    if (encoder != null && decoder != null && tokens != null) {
      return VoiceModelPaths(
        type: VoiceModelType.whisper,
        encoder: encoder,
        decoder: decoder,
        joiner: '',
        tokens: tokens,
        language: 'en',
      );
    }
  }
  return null;
}

/// Decoded 16 kHz mono audio, in both shapes the natives consume.
class _Audio {
  _Audio(this.samples, this.pcm16);

  /// Float samples in `[-1, 1]` (offline VAD + diarization).
  final Float32List samples;

  /// Little-endian PCM16 bytes (the streaming detector).
  final Uint8List pcm16;
}

/// Synthesizes real speech with macOS `say`, or returns null where it is
/// unavailable.
///
/// Real speech rather than a generated waveform because these models are
/// trained on it: a sine tone yields zero spans everywhere, which would make
/// every assertion below vacuously true.
_Audio? _synthesizeSpeech(Directory dir) {
  if (!Platform.isMacOS) {
    return null;
  }
  final wav = File('${dir.path}/speech.wav');
  const script =
      'Hello, this is a test of the voice activity detector. '
      'The quick brown fox jumps over the lazy dog.';
  final result = Process.runSync('say', [
    '-o',
    wav.path,
    '--data-format=LEI16@16000',
    script,
  ]);
  if (result.exitCode != 0 || !wav.existsSync()) {
    return null;
  }
  return _decodeWav(wav);
}

/// Minimal RIFF reader for the mono 16-bit PCM `say` produces. Walks the chunk
/// list rather than assuming a 44-byte header, which `say` does not always emit.
_Audio _decodeWav(File file) {
  final bytes = file.readAsBytesSync();
  final view = ByteData.sublistView(bytes);
  var offset = 12; // past "RIFF<size>WAVE"
  while (offset + 8 <= bytes.length) {
    final id = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final size = view.getUint32(offset + 4, Endian.little);
    if (id == 'data') {
      final pcm = Uint8List.fromList(
        bytes.sublist(offset + 8, offset + 8 + size),
      );
      final pcmView = ByteData.sublistView(pcm);
      final samples = Float32List(size ~/ 2);
      for (var i = 0; i < samples.length; i++) {
        samples[i] = pcmView.getInt16(i * 2, Endian.little) / 32768.0;
      }
      return _Audio(samples, pcm);
    }
    offset += 8 + size + (size.isOdd ? 1 : 0);
  }
  throw StateError('no data chunk in ${file.path}');
}

/// The repo root, walking up from the package dir (tests run with the package
/// as cwd).
String _repoRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 5; i++) {
    if (Directory('${dir.path}/assets/models').existsSync()) {
      return dir.path;
    }
    dir = dir.parent;
  }
  return Directory.current.path;
}
