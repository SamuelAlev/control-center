import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cc_domain/features/meetings/domain/services/meeting_transcription_port.dart';
import 'package:cc_domain/features/meetings/domain/services/speech_activity_detector.dart';
import 'package:cc_domain/features/meetings/domain/services/speech_transcriber.dart';
import 'package:cc_domain/features/meetings/domain/services/transcribed_window.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// Rolling-window transcription over continuous 16 kHz mono PCM16.
///
/// Incoming chunks are evaluated in ~32 ms sub-frames so speech onset and
/// natural pauses are detected cleanly even when upstream batches arrive at
/// 250 ms. Leading silence before speech onset is trimmed to [preRollMs].
/// Windows cut on trailing silence ≥ [silenceFlushMs] (when ≥ [minWindowMs]),
/// at [softMaxWindowMs] on a shorter [softSilenceFlushMs] pause, or at
/// [maxWindowMs] using a low-energy valley cut in the trailing audio.
class MeetingTranscriptionService implements MeetingTranscriptionPort {
  /// Creates a [MeetingTranscriptionService].
  ///
  /// [detectorFactory] builds the per-stream speech gate; it is invoked once per
  /// [transcribe] call so each channel (mic / system) gets its own stateful
  /// detector and the detector is disposed when that stream closes. Defaults to
  /// an [RmsSpeechActivityDetector] using [silenceRmsThreshold]; pass a factory
  /// that builds a Silero-VAD detector for learned speech detection.
  MeetingTranscriptionService(
    this._transcriber, {
    this.sampleRate = 16000,
    this.minWindowMs = 1500,
    this.maxWindowMs = 12000,
    this.softMaxWindowMs = 8000,
    this.silenceFlushMs = 500,
    this.softSilenceFlushMs = 250,
    this.preRollMs = 250,
    this.minSpeechMs = 128,
    this.silenceRmsThreshold = 0.012,
    SpeechActivityDetector Function()? detectorFactory,
  }) : _detectorFactory =
           detectorFactory ??
           (() => RmsSpeechActivityDetector(threshold: silenceRmsThreshold));

  final SpeechTranscriber _transcriber;

  /// Builds a fresh per-stream speech gate (one per [transcribe] call).
  final SpeechActivityDetector Function() _detectorFactory;

  /// Input sample rate (Hz). Frames are mono 16-bit.
  final int sampleRate;

  /// Minimum audio (ms) before a silence-triggered cut is allowed.
  final int minWindowMs;

  /// Hard cap (ms) that forces a valley-cut flush even without a full pause.
  final int maxWindowMs;

  /// Soft cap (ms) after which a shorter pause ([softSilenceFlushMs]) triggers
  /// a clean sentence/clause boundary flush.
  final int softMaxWindowMs;

  /// Trailing silence (ms) that triggers a cut once past [minWindowMs].
  final int silenceFlushMs;

  /// Shorter trailing silence (ms) that triggers a cut once past
  /// [softMaxWindowMs].
  final int softSilenceFlushMs;

  /// Pre-speech audio (ms) retained before speech onset when trimming idle
  /// leading silence.
  final int preRollMs;

  /// Minimum cumulative speech (ms) required in a window before sending it to
  /// the ASR decoder (caps to [minWindowMs] for short-window configurations).
  final int minSpeechMs;

  /// RMS below this (normalized 0–1) counts as silence.
  final double silenceRmsThreshold;

  static const int _subFrameMs = 32;
  static const int _valleySearchMaxMs = 2000;
  static const int _valleyStepMs = 64;

  int get _bytesPerMs => (sampleRate * 2) ~/ 1000; // 16-bit mono

  /// Transcribes [pcm] (16 kHz mono PCM16), emitting one [TranscribedWindow]
  /// per cut window. Closes (after a final flush) when [pcm] closes.
  @override
  Stream<TranscribedWindow> transcribe(Stream<Uint8List> pcm) {
    final controller = StreamController<TranscribedWindow>();
    final window = BytesBuilder(copy: false);
    final sliceLog = <({int bytes, bool speech})>[];
    var consumedBytes = 0; // total bytes seen — drives the clock
    var windowStartByte = 0; // byte offset where the current window began
    var trailingSilenceMs = 0;
    var windowSpeechMs = 0;
    var inSpeech = false;
    final detector = _detectorFactory()..reset();
    // Per-stream generation guard. A window decodes asynchronously (off-isolate)
    // while the stream may be stopped/cancelled (a stop, or a stop→restart that
    // builds a new stream). When that happens this flag flips false and any
    // in-flight decode is discarded instead of being emitted into a dead or
    // already-replaced stream. One instance drives both channels, so this is
    // per-`transcribe`-call, never service-wide.
    var streamLive = true;

    final bytesPerMs = _bytesPerMs;
    final subFrameBytes = math.max(2, (_subFrameMs * bytesPerMs) & ~1);
    final preRollBytes = math.max(0, (preRollMs * bytesPerMs) & ~1);
    final effectiveMinSpeechMs = math.min(minSpeechMs, minWindowMs);

    int msFromBytes(int bytes) => bytes ~/ bytesPerMs;

    void trimLeadingSilence() {
      if (window.length <= preRollBytes) {
        return;
      }
      final all = window.takeBytes();
      var drop = (all.length - preRollBytes) & ~1;
      if (drop <= 0) {
        window.add(all);
        return;
      }
      if (drop >= all.length) {
        drop = all.length & ~1;
      }
      windowStartByte += drop;
      if (drop < all.length) {
        window.add(Uint8List.sublistView(all, drop));
      }
      var remainingDrop = drop;
      while (remainingDrop > 0 && sliceLog.isNotEmpty) {
        final first = sliceLog.first;
        if (first.bytes <= remainingDrop) {
          remainingDrop -= first.bytes;
          sliceLog.removeAt(0);
        } else {
          sliceLog[0] = (
            bytes: first.bytes - remainingDrop,
            speech: first.speech,
          );
          remainingDrop = 0;
        }
      }
    }

    Future<void> decodeAndEmit(
      Uint8List bytes,
      int startMs,
      int endMs,
      int speechMs, {
      required bool allowShortFinal,
    }) async {
      final durationMs = endMs - startMs;
      final minRequired = allowShortFinal && durationMs < effectiveMinSpeechMs
          ? 1
          : effectiveMinSpeechMs;
      if (speechMs <= 0 || speechMs < minRequired) {
        CcInfraLog.info(
          'skipped silent/brief window ($startMs–${endMs}ms, speech=${speechMs}ms)',
        );
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
          CcInfraLog.info('window $startMs–${endMs}ms decoded to nothing');
        } else if (isNonSpeechArtifact(text)) {
          CcInfraLog.info(
            'dropped non-speech window ($startMs–${endMs}ms): "$text"',
          );
        } else if (isRepetitionHallucination(text)) {
          CcInfraLog.info(
            'dropped repetition hallucination ($startMs–${endMs}ms): "$text"',
          );
        } else if (isHallucinatedBoilerplate(text)) {
          CcInfraLog.info(
            'dropped boilerplate hallucination ($startMs–${endMs}ms): "$text"',
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

    Future<void> flushWhole({bool allowShortFinal = false}) async {
      final bytes = window.takeBytes();
      final speechMs = windowSpeechMs;
      sliceLog.clear();
      windowSpeechMs = 0;
      trailingSilenceMs = 0;
      inSpeech = false;
      if (bytes.isEmpty) {
        return;
      }
      final startMs = msFromBytes(windowStartByte);
      final endMs = msFromBytes(windowStartByte + bytes.length);
      windowStartByte += bytes.length;
      await decodeAndEmit(
        bytes,
        startMs,
        endMs,
        speechMs,
        allowShortFinal: allowShortFinal,
      );
    }

    Future<void> flushAtValley() async {
      final bytes = window.takeBytes();
      if (bytes.isEmpty) {
        sliceLog.clear();
        windowSpeechMs = 0;
        trailingSilenceMs = 0;
        inSpeech = false;
        return;
      }
      final minKeepBytes = math.min(
        bytes.length,
        math.max(2, (minWindowMs * bytesPerMs) & ~1),
      );
      final searchTailBytes = math.min(
        bytes.length - minKeepBytes,
        (_valleySearchMaxMs * bytesPerMs) & ~1,
      );
      final cutByte = searchTailBytes > 0
          ? _findValleyCutByte(
              bytes,
              minKeepBytes: minKeepBytes,
              searchTailBytes: searchTailBytes,
              stepBytes: math.max(2, (_valleyStepMs * bytesPerMs) & ~1),
            )
          : bytes.length;

      final flushBytes = cutByte < bytes.length
          ? Uint8List.sublistView(bytes, 0, cutByte)
          : bytes;
      final remainder = cutByte < bytes.length
          ? Uint8List.sublistView(bytes, cutByte)
          : Uint8List(0);

      // Partition sliceLog at cutByte to preserve exact speechMs for both parts.
      var flushedSpeechBytes = 0;
      var remaining = cutByte;
      while (remaining > 0 && sliceLog.isNotEmpty) {
        final head = sliceLog.first;
        if (head.bytes <= remaining) {
          if (head.speech) {
            flushedSpeechBytes += head.bytes;
          }
          remaining -= head.bytes;
          sliceLog.removeAt(0);
        } else {
          if (head.speech) {
            flushedSpeechBytes += remaining;
          }
          sliceLog[0] = (bytes: head.bytes - remaining, speech: head.speech);
          remaining = 0;
        }
      }

      // Recompute speech / trailing silence state for the carried remainder.
      var remSpeechBytes = 0;
      var remTrailingSilenceBytes = 0;
      for (final entry in sliceLog) {
        if (entry.speech) {
          remSpeechBytes += entry.bytes;
          remTrailingSilenceBytes = 0;
        } else {
          remTrailingSilenceBytes += entry.bytes;
        }
      }
      windowSpeechMs = msFromBytes(remSpeechBytes);
      trailingSilenceMs = msFromBytes(remTrailingSilenceBytes);
      inSpeech = remSpeechBytes > 0;
      if (remainder.isNotEmpty) {
        window.add(remainder);
      }

      final startMs = msFromBytes(windowStartByte);
      final endMs = msFromBytes(windowStartByte + flushBytes.length);
      windowStartByte += flushBytes.length;

      await decodeAndEmit(
        flushBytes,
        startMs,
        endMs,
        msFromBytes(flushedSpeechBytes),
        allowShortFinal: false,
      );
    }

    late StreamSubscription<Uint8List> sub;
    sub = pcm.listen(
      (chunk) async {
        var off = 0;
        while (off < chunk.length) {
          if (!streamLive) {
            return;
          }
          final end = math.min(off + subFrameBytes, chunk.length);
          final slice = Uint8List.sublistView(chunk, off, end);
          off = end;

          window.add(slice);
          consumedBytes += slice.length;
          final sliceMs = msFromBytes(slice.length);
          final speech = detector.isSpeech(slice);
          sliceLog.add((bytes: slice.length, speech: speech));

          if (!inSpeech) {
            if (speech) {
              inSpeech = true;
              trailingSilenceMs = 0;
              windowSpeechMs += sliceMs;
            } else {
              trimLeadingSilence();
              continue;
            }
          } else {
            if (speech) {
              trailingSilenceMs = 0;
              windowSpeechMs += sliceMs;
            } else {
              trailingSilenceMs += sliceMs;
              // Discard isolated sub-threshold clicks/pops once silence
              // returns so they don't anchor windowStartByte seconds early.
              if (windowSpeechMs < effectiveMinSpeechMs &&
                  trailingSilenceMs >= silenceFlushMs) {
                windowSpeechMs = 0;
                trailingSilenceMs = 0;
                inSpeech = false;
                trimLeadingSilence();
                continue;
              }
            }
          }

          final windowMs = msFromBytes(consumedBytes - windowStartByte);
          final hitSilence =
              trailingSilenceMs >= silenceFlushMs && windowMs >= minWindowMs;
          final hitSoftMax =
              windowMs >= softMaxWindowMs &&
              trailingSilenceMs >= softSilenceFlushMs;
          final hitMax = windowMs >= maxWindowMs;

          if (hitSilence || hitSoftMax) {
            // Suspend delivery while decoding so windows are emitted in order.
            sub.pause();
            await flushWhole();
            sub.resume();
          } else if (hitMax) {
            sub.pause();
            await flushAtValley();
            sub.resume();
          }
        }
      },
      onError: controller.addError,
      onDone: () async {
        await flushWhole(allowShortFinal: true);
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

  /// Scans `[bytes.length - searchTailBytes, bytes.length)` (never earlier than
  /// [minKeepBytes]) in [stepBytes] windows and returns the 2-byte-aligned
  /// midpoint of the quietest step so forced `maxWindowMs` cuts land in natural
  /// inter-word pauses instead of slicing mid-syllable.
  static int _findValleyCutByte(
    Uint8List bytes, {
    required int minKeepBytes,
    required int searchTailBytes,
    required int stepBytes,
  }) {
    final searchStart = math.max(minKeepBytes, bytes.length - searchTailBytes);
    if (searchStart + stepBytes > bytes.length) {
      return bytes.length;
    }
    var bestOffset = bytes.length;
    var bestRms = double.infinity;
    for (var pos = searchStart; pos + stepBytes <= bytes.length; pos += stepBytes) {
      final r = rmsOfPcm16(Uint8List.sublistView(bytes, pos, pos + stepBytes));
      if (r <= bestRms) {
        bestRms = r;
        bestOffset = (pos + stepBytes ~/ 2) & ~1;
      }
    }
    return bestOffset.clamp(minKeepBytes, bytes.length);
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
  static final _creditLine = RegExp(
    r'^(subtitle|subtitles|caption|captions|transcription|transcribed) '
    r'(by|by the) ',
  );

  // A lone URL / domain token (no spaces) — e.g. "www.example.com".
  static final _urlOnly = RegExp(
    r'^(https?://|www\.)?\S+\.(com|org|net|io|tv|co)\S*$',
  );

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
