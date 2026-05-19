import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:control_center/core/infrastructure/speech/speech_transcriber.dart';
import 'package:control_center/core/utils/app_log.dart';

/// A transcribed window emitted by [MeetingTranscriptionService].
class TranscribedWindow {
  /// Creates a [TranscribedWindow].
  const TranscribedWindow({
    required this.text,
    required this.startMs,
    required this.endMs,
  });

  /// Recognized text for this window.
  final String text;

  /// Start offset (ms) from the first sample of the stream.
  final int startMs;

  /// End offset (ms) from the first sample of the stream.
  final int endMs;
}

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
class MeetingTranscriptionService {
  /// Creates a [MeetingTranscriptionService].
  MeetingTranscriptionService(
    this._transcriber, {
    this.sampleRate = 16000,
    this.minWindowMs = 1500,
    this.maxWindowMs = 5000,
    this.silenceFlushMs = 650,
    this.silenceRmsThreshold = 0.012,
  });

  final SpeechTranscriber _transcriber;

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
  Stream<TranscribedWindow> transcribe(Stream<Uint8List> pcm) {
    final controller = StreamController<TranscribedWindow>();
    final window = BytesBuilder(copy: false);
    var consumedBytes = 0; // total bytes seen — drives the clock
    var windowStartByte = 0; // byte offset where the current window began
    var trailingSilenceMs = 0;
    var windowHadSpeech = false; // any chunk rose above the silence floor

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
        AppLog.d(
          'MeetingTranscription',
          'skipped silent window ($startMs–${endMs}ms)',
        );
        return;
      }
      try {
        final text = (await _transcriber.transcribeChunk(bytes)).trim();
        if (text.isEmpty) {
          AppLog.d(
            'MeetingTranscription',
            'window $startMs–${endMs}ms decoded to nothing',
          );
        } else if (isNonSpeechArtifact(text)) {
          AppLog.d(
            'MeetingTranscription',
            'dropped non-speech window ($startMs–${endMs}ms): "$text"',
          );
        } else if (isRepetitionHallucination(text)) {
          AppLog.d(
            'MeetingTranscription',
            'dropped repetition hallucination ($startMs–${endMs}ms): "$text"',
          );
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

        final rms = _rms(chunk);
        final chunkMs = msFromBytes(chunk.length);
        if (rms < silenceRmsThreshold) {
          trailingSilenceMs += chunkMs;
        } else {
          trailingSilenceMs = 0;
          windowHadSpeech = true;
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
        await controller.close();
      },
      cancelOnError: false,
    );

    controller.onCancel = sub.cancel;
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

  /// Root-mean-square amplitude of a PCM16 buffer, normalized to 0–1.
  static double _rms(Uint8List pcm16) {
    if (pcm16.length < 2) {
      return 0;
    }
    final view = ByteData.sublistView(pcm16);
    final n = pcm16.length ~/ 2;
    var sumSq = 0.0;
    for (var i = 0; i < n; i++) {
      final s = view.getInt16(i * 2, Endian.little) / 32768.0;
      sumSq += s * s;
    }
    final mean = sumSq / n;
    return mean <= 0 ? 0 : math.sqrt(mean);
  }
}
