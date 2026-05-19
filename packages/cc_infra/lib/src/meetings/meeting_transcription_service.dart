import 'dart:async';
import 'dart:typed_data';

import 'package:cc_domain/features/meetings/domain/services/meeting_transcription_port.dart';
import 'package:cc_domain/features/meetings/domain/services/speech_activity_detector.dart';
import 'package:cc_domain/features/meetings/domain/services/speech_transcriber.dart';
import 'package:cc_domain/features/meetings/domain/services/transcribed_window.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// Drives rolling-window transcription over a continuous 16 kHz mono PCM16
/// stream (one audio channel — e.g. the microphone, or the system output).
///
/// A window is cut when either (a) trailing silence exceeds [silenceFlushMs]
/// and the window already holds at least [minWindowMs] of audio, or (b) the
/// window reaches [maxWindowMs]. Each cut window is decoded via
/// [SpeechTranscriber.transcribeChunk] and emitted with offsets measured from
/// the first sample.
///
/// Windows that never rose above [silenceRmsThreshold] are skipped without a
/// decode at all — Whisper renders silence as hallucinated non-speech tokens
/// ("(buzzer)") and the decode is wasted CPU, which matters because a quiet
/// channel (e.g. the mic when the user is listening) would otherwise fire a
/// decode roughly every [minWindowMs]. The decode itself runs off the UI thread
/// inside [SpeechTranscriber] (a worker isolate), so a slow window only delays
/// later windows on the same channel — captured audio is buffered, never lost.
class MeetingTranscriptionService implements MeetingTranscriptionPort {
  /// Creates a [MeetingTranscriptionService].
  ///
  /// [detectorFactory] builds the per-stream speech gate; it is invoked once per
  /// [transcribe] call so each channel (mic / system) gets its own stateful
  /// detector, and the detector is disposed when that stream closes. Defaults to
  /// an [RmsSpeechActivityDetector] using [silenceRmsThreshold]; pass a factory
  /// that builds a Silero-VAD detector for learned speech detection.
  MeetingTranscriptionService(
    this._transcriber, {
    this.sampleRate = 16000,
    this.minWindowMs = 1500,
    this.maxWindowMs = 5000,
    this.silenceFlushMs = 650,
    this.silenceRmsThreshold = 0.012,
    SpeechActivityDetector Function()? detectorFactory,
  }) : _detectorFactory = detectorFactory ??
            (() => RmsSpeechActivityDetector(threshold: silenceRmsThreshold));

  final SpeechTranscriber _transcriber;

  /// Builds a fresh per-stream speech gate (one per [transcribe] call).
  final SpeechActivityDetector Function() _detectorFactory;

  /// Input sample rate (Hz). Frames are mono 16-bit.
  final int sampleRate;

  /// Minimum audio (ms) before a silence-triggered cut is allowed.
  final int minWindowMs;

  /// Hard cap (ms) that forces a cut even without silence.
  final int maxWindowMs;

  /// Trailing silence (ms) that triggers a cut once past [minWindowMs].
  final int silenceFlushMs;

  /// RMS below this (normalized 0–1) counts as silence.
  final double silenceRmsThreshold;

  int get _bytesPerMs => (sampleRate * 2) ~/ 1000; // 16-bit mono

  /// Transcribes [pcm] (16 kHz mono PCM16), emitting one [TranscribedWindow]
  /// per cut window. Closes (after a final flush) when [pcm] closes.
  @override
  Stream<TranscribedWindow> transcribe(Stream<Uint8List> pcm) {
    final controller = StreamController<TranscribedWindow>();
    final window = BytesBuilder(copy: false);
    var consumedBytes = 0; // total bytes seen — drives the clock
    var windowStartByte = 0; // byte offset where the current window began
    var trailingSilenceMs = 0;
    var windowHadSpeech = false; // any chunk the detector flagged as speech
    final detector = _detectorFactory()..reset();
    // Per-stream generation guard. A window decodes asynchronously (off-isolate)
    // while the stream may be stopped/cancelled (a stop, or a stop→restart that
    // builds a new stream). When that happens this flag flips false and any
    // in-flight decode is discarded instead of being emitted into a dead or
    // already-replaced stream. One instance drives both channels, so this is
    // per-`transcribe`-call, never service-wide.
    var streamLive = true;

    int msFromBytes(int bytes) => bytes ~/ _bytesPerMs;

    Future<void> flush() async {
      final bytes = window.takeBytes();
      final hadSpeech = windowHadSpeech;
      windowHadSpeech = false;
      if (bytes.isEmpty) {
        return;
      }
      final startMs = msFromBytes(windowStartByte);
      final endMs = msFromBytes(windowStartByte + bytes.length);
      windowStartByte += bytes.length;
      if (!hadSpeech) {
        // Pure-silence window — never send it to Whisper (it would hallucinate a
        // non-speech token and burn a decode for nothing).
        CcInfraLog.info('skipped silent window ($startMs–${endMs}ms)',);
        return;
      }
      try {
        final text = (await _transcriber.transcribeChunk(bytes)).trim();
        if (!streamLive || controller.isClosed) {
          // The recording stopped (or the stream was cancelled / restarted)
          // while this window decoded — discard the stale result.
          return;
        }
        if (text.isEmpty) {
          CcInfraLog.info('window $startMs–${endMs}ms decoded to nothing',);
        } else if (isNonSpeechArtifact(text)) {
          CcInfraLog.info('dropped non-speech window ($startMs–${endMs}ms): "$text"',);
        } else if (isRepetitionHallucination(text)) {
          CcInfraLog.info('dropped repetition hallucination ($startMs–${endMs}ms): "$text"',);
        } else if (isHallucinatedBoilerplate(text)) {
          CcInfraLog.info('dropped boilerplate hallucination ($startMs–${endMs}ms): "$text"',);
        } else {
          controller.add(
            TranscribedWindow(text: text, startMs: startMs, endMs: endMs),
          );
        }
      } catch (e, s) {
        controller.addError(e, s);
      }
    }

    late StreamSubscription<Uint8List> sub;
    sub = pcm.listen(
      (chunk) async {
        window.add(chunk);
        consumedBytes += chunk.length;
        final windowMs = msFromBytes(consumedBytes - windowStartByte);

        final chunkMs = msFromBytes(chunk.length);
        if (detector.isSpeech(chunk)) {
          trailingSilenceMs = 0;
          windowHadSpeech = true;
        } else {
          trailingSilenceMs += chunkMs;
        }

        final hitSilence =
            trailingSilenceMs >= silenceFlushMs && windowMs >= minWindowMs;
        final hitMax = windowMs >= maxWindowMs;
        if (hitSilence || hitMax) {
          trailingSilenceMs = 0;
          // Suspend delivery while decoding so windows are emitted in order.
          sub.pause();
          await flush();
          sub.resume();
        }
      },
      onError: controller.addError,
      onDone: () async {
        await flush();
        detector.dispose();
        await controller.close();
      },
      cancelOnError: false,
    );

    controller.onCancel = () async {
      streamLive = false; // generation guard: discard any in-flight decode
      detector.dispose();
      await sub.cancel();
    };
    return controller.stream;
  }

  // Bracketed / parenthesised / musical markup Whisper emits for non-speech.
  static final _nonSpeechMarkup = RegExp(r'\[[^\]]*\]|\([^)]*\)|\*[^*]*\*');
  static final _nonSpeechGlyphs = RegExp(r'[♪♫…]+');
  static final _word = RegExp(r'[A-Za-z0-9]');

  /// Whether [text] is a Whisper non-speech placeholder rather than real
  /// speech. Whisper renders silent or noisy windows as tokens like
  /// `[BLANK_AUDIO]`, `[ Silence ]`, `[ Music ]`, `(buzzing)`, `♪…♪`, or `...` —
  /// these must never become transcript segments. Returns true when, after the
  /// markup is removed, no actual word characters remain. A window that mixes a
  /// tag with real speech (e.g. `[ Music ] okay so`) keeps its words and is not
  /// treated as an artifact.
  static bool isNonSpeechArtifact(String text) {
    final stripped = text
        .replaceAll(_nonSpeechMarkup, ' ')
        .replaceAll(_nonSpeechGlyphs, ' ');
    return !_word.hasMatch(stripped);
  }

  static final _tokenSplit = RegExp(r'[^a-z0-9]+');

  /// Whether [text] is a degenerate repetition that Whisper hallucinates on
  /// low-energy / echo-bleed audio — e.g. "agree agree agree agree agree",
  /// "Take Take Take Take", "the the the the the and". Real speech does not
  /// repeat one token four-plus times, so dropping these is high-precision; they
  /// were a visible chunk of the leaked-echo garbage in the mic channel that no
  /// amount of acoustic cancellation fully prevents on residual bleed.
  ///
  /// Conservative by design: a single distinct token must repeat ≥ 4 times, or
  /// one token must both occur ≥ 5 times and dominate ≥ 70% of the window.
  /// Short, varied windows (including genuine stutters like "is is") are kept.
  static bool isRepetitionHallucination(String text) {
    final tokens = text
        .toLowerCase()
        .split(_tokenSplit)
        .where((t) => t.isNotEmpty)
        .toList(growable: false);
    if (tokens.length < 4) {
      return false;
    }
    final counts = <String, int>{};
    var maxFreq = 0;
    for (final t in tokens) {
      final c = (counts[t] ?? 0) + 1;
      counts[t] = c;
      if (c > maxFreq) {
        maxFreq = c;
      }
    }
    if (counts.length == 1) {
      return true; // one word repeated ≥ 4 times
    }
    return maxFreq >= 5 && maxFreq / tokens.length >= 0.7;
  }

  // Canned phrases Whisper-family models hallucinate on silence / music / the
  // tail of a recording — scraped from YouTube-heavy training data. Matched
  // against the WHOLE normalized window only, so a real sentence that merely
  // contains "thank you" is never dropped.
  static final _boilerplateExact = <String>{
    'thank you for watching',
    'thanks for watching',
    'thank you for watching this video',
    'thank you so much for watching',
    'thank you very much for watching',
    'please subscribe',
    'please like and subscribe',
    'like and subscribe',
    'like comment and subscribe',
    'dont forget to subscribe',
    'see you in the next video',
    'see you next time',
    'subtitles by the amaraorg community',
    'transcription by castingwords',
  };

  // Credit / attribution lines ("Subtitles by …", "Transcription by …").
  static final _creditLine =
      RegExp(r'^(subtitle|subtitles|caption|captions|transcription|transcribed) '
          r'(by|by the) ');

  // A lone URL / domain token (no spaces) — e.g. "www.example.com".
  static final _urlOnly =
      RegExp(r'^(https?://|www\.)?\S+\.(com|org|net|io|tv|co)\S*$');

  /// Whether [text] is a canned hallucination Whisper-family models emit on
  /// non-speech audio rather than a real spoken line. High-precision: only
  /// whole-window matches against a curated phrase set, attribution lines, or a
  /// bare URL are dropped — anything mixed with other speech is kept.
  ///
  /// This is the prompt-leakage / boilerplate guard that complements
  /// [isNonSpeechArtifact] (markup) and [isRepetitionHallucination] (degenerate
  /// loops); it matters more as faster transducer models (Parakeet, Qwen-ASR)
  /// are added, which hallucinate different canned phrases than Whisper.
  static bool isHallucinatedBoilerplate(String text) {
    final norm = text
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (norm.isEmpty) {
      return false;
    }
    if (_boilerplateExact.contains(norm)) {
      return true;
    }
    if (_creditLine.hasMatch(norm)) {
      return true;
    }
    final raw = text.trim();
    return !raw.contains(' ') && _urlOnly.hasMatch(raw.toLowerCase());
  }
}
