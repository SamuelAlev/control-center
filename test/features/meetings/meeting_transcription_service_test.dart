import 'dart:async';
import 'dart:typed_data';

import 'package:cc_domain/features/meetings/domain/services/speech_activity_detector.dart';
import 'package:cc_domain/features/meetings/domain/services/speech_transcriber.dart';
import 'package:cc_domain/features/meetings/domain/services/transcribed_window.dart';
import 'package:cc_infra/src/meetings/meeting_transcription_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// A detector that flags every chunk as speech; records dispose for assertions.
class _AlwaysSpeech implements SpeechActivityDetector {
  bool disposed = false;

  @override
  bool isSpeech(Uint8List pcm16) => true;

  @override
  void reset() {}

  @override
  void dispose() => disposed = true;
}

/// Records each decoded window and returns a numbered marker.
class _FakeTranscriber implements SpeechTranscriber {
  int calls = 0;

  @override
  bool get isReady => true;

  @override
  String get displayName => 'fake';

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}

  @override
  Stream<TranscriptionResult> transcribe(Stream<List<int>> audio) =>
      const Stream.empty();

  @override
  Future<String> transcribeChunk(Uint8List pcm16) async {
    calls++;
    return 'window$calls';
  }
}

/// Returns a fixed text for every window — used to exercise the non-speech
/// filter in the windowing path.
class _FixedTranscriber implements SpeechTranscriber {
  _FixedTranscriber(this.text);
  final String text;

  @override
  bool get isReady => true;
  @override
  String get displayName => 'fixed';
  @override
  Future<void> initialize() async {}
  @override
  Future<void> dispose() async {}
  @override
  Stream<TranscriptionResult> transcribe(Stream<List<int>> audio) =>
      const Stream.empty();
  @override
  Future<String> transcribeChunk(Uint8List pcm16) async => text;
}

/// A transcriber whose decode blocks on [gate] so a test can cancel the stream
/// mid-decode and assert the in-flight result is discarded.
class _GatedTranscriber implements SpeechTranscriber {
  final Completer<void> gate = Completer<void>();
  int calls = 0;

  @override
  bool get isReady => true;
  @override
  String get displayName => 'gated';
  @override
  Future<void> initialize() async {}
  @override
  Future<void> dispose() async {}
  @override
  Stream<TranscriptionResult> transcribe(Stream<List<int>> audio) =>
      const Stream.empty();
  @override
  Future<String> transcribeChunk(Uint8List pcm16) async {
    calls++;
    await gate.future;
    return 'late';
  }
}

Uint8List _pcm(int ms, int amplitude) {
  final n = (16000 * ms) ~/ 1000;
  final out = Uint8List(n * 2);
  final view = ByteData.sublistView(out);
  for (var i = 0; i < n; i++) {
    view.setInt16(i * 2, amplitude, Endian.little);
  }
  return out;
}

void main() {
  group('MeetingTranscriptionService', () {
    test('cuts a window on trailing silence after the minimum', () async {
      final fake = _FakeTranscriber();
      final service = MeetingTranscriptionService(
        fake,
        minWindowMs: 100,
        maxWindowMs: 5000,
        silenceFlushMs: 50,
      );
      final controller = StreamController<Uint8List>();
      final windows = <TranscribedWindow>[];
      final sub = service.transcribe(controller.stream).listen(windows.add);

      controller.add(_pcm(200, 12000)); // 200ms of speech
      controller.add(_pcm(80, 0)); // 80ms silence → triggers a cut
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await controller.close();
      await sub.asFuture<void>();
      await sub.cancel();

      expect(windows, isNotEmpty);
      expect(windows.first.text, 'window1');
      expect(windows.first.startMs, 0);
      expect(windows.first.endMs, greaterThan(0));
    });

    test('flushes the trailing buffer when the stream closes', () async {
      final fake = _FakeTranscriber();
      final service = MeetingTranscriptionService(
        fake,
        minWindowMs: 100,
        maxWindowMs: 100000,
        silenceFlushMs: 100000, // never silence-cut
      );
      final controller = StreamController<Uint8List>();
      final windows = <TranscribedWindow>[];
      final sub = service.transcribe(controller.stream).listen(windows.add);

      controller.add(_pcm(300, 9000));
      await controller.close();
      await sub.asFuture<void>();
      await sub.cancel();

      expect(windows, hasLength(1));
      expect(windows.first.text, 'window1');
    });

    test('drops empty (silence-only) windows', () async {
      final fake = _FakeTranscriber();
      final service = MeetingTranscriptionService(fake);
      final controller = StreamController<Uint8List>();
      final windows = <TranscribedWindow>[];
      final sub = service.transcribe(controller.stream).listen(windows.add);

      // No audio at all → onDone flush sees an empty buffer → no decode.
      await controller.close();
      await sub.asFuture<void>();
      await sub.cancel();

      expect(windows, isEmpty);
      expect(fake.calls, 0);
    });

    test('drops windows whose decode is a Whisper non-speech token', () async {
      // The window has real audio (so it IS decoded) but Whisper returns a
      // non-speech placeholder — it must not become a transcript segment.
      final service = MeetingTranscriptionService(
        _FixedTranscriber('[BLANK_AUDIO]'),
        minWindowMs: 100,
        maxWindowMs: 100000,
        silenceFlushMs: 100000,
      );
      final controller = StreamController<Uint8List>();
      final windows = <TranscribedWindow>[];
      final sub = service.transcribe(controller.stream).listen(windows.add);

      controller.add(_pcm(300, 9000));
      await controller.close();
      await sub.asFuture<void>();
      await sub.cancel();

      expect(windows, isEmpty);
    });

    test('uses an injected detector factory (one per stream) to gate windows',
        () async {
      // A detector that flags everything as speech — even a 0-amplitude buffer
      // the RMS gate would skip. Proves the factory overrides the gate and is
      // built per transcribe() call.
      final built = <_AlwaysSpeech>[];
      _AlwaysSpeech factory() {
        final d = _AlwaysSpeech();
        built.add(d);
        return d;
      }

      final fake = _FakeTranscriber();
      final service = MeetingTranscriptionService(
        fake,
        minWindowMs: 100,
        maxWindowMs: 100000,
        silenceFlushMs: 100000,
        detectorFactory: factory,
      );

      final c1 = StreamController<Uint8List>();
      final w1 = <TranscribedWindow>[];
      final s1 = service.transcribe(c1.stream).listen(w1.add);
      c1.add(_pcm(300, 0)); // pure silence, but the detector says "speech"
      await c1.close();
      await s1.asFuture<void>();
      await s1.cancel();

      // Decoded despite zero amplitude → the injected detector drove the gate.
      expect(w1, hasLength(1));
      expect(built, hasLength(1));
      expect(built.first.disposed, isTrue);

      // A second stream builds a fresh detector (per-channel state isolation).
      final c2 = StreamController<Uint8List>();
      final s2 = service.transcribe(c2.stream).listen((_) {});
      c2.add(_pcm(300, 0));
      await c2.close();
      await s2.asFuture<void>();
      await s2.cancel();
      expect(built, hasLength(2));
    });

    test('discards an in-flight decode after the stream is cancelled '
        '(generation guard)', () async {
      final t = _GatedTranscriber();
      final service = MeetingTranscriptionService(
        t,
        minWindowMs: 50,
        maxWindowMs: 150,
        silenceFlushMs: 100000, // never silence-cut; the max cut fires instead
        detectorFactory: _AlwaysSpeech.new,
      );
      final controller = StreamController<Uint8List>();
      final windows = <TranscribedWindow>[];
      final sub = service.transcribe(controller.stream).listen(windows.add);

      controller.add(_pcm(200, 12000)); // ≥ maxWindow → cut → flush awaits gate
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(t.calls, 1, reason: 'the window decode started');

      // Cancel the stream mid-decode, then release the (now-stale) decode.
      await sub.cancel();
      t.gate.complete();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(windows, isEmpty,
          reason: 'a decode that completes after cancel must not be emitted');
      await controller.close();
    });
  });

  group('MeetingTranscriptionService.isNonSpeechArtifact', () {
    test('treats Whisper non-speech tokens as artifacts', () {
      for (final t in [
        '[BLANK_AUDIO]',
        '[ Silence ]',
        '[silence]',
        '[ Music ]',
        '[ Applause ]',
        '[inaudible]',
        '(buzzing)',
        '(music)',
        '*laughs*',
        '♪♪',
        '♪ ♪',
        '…',
        '...',
        '. . .',
        '[',
        '   ',
      ]) {
        expect(
          MeetingTranscriptionService.isNonSpeechArtifact(t),
          isTrue,
          reason: 'expected "$t" to be a non-speech artifact',
        );
      }
    });

    test('keeps real speech, including speech mixed with a tag', () {
      for (final t in [
        'Let us ship it on Friday',
        'okay',
        'B2B',
        '[ Music ] okay so where were we',
        'We agreed [inaudible] to revert the change',
        'Number 3',
      ]) {
        expect(
          MeetingTranscriptionService.isNonSpeechArtifact(t),
          isFalse,
          reason: 'expected "$t" to be kept as real speech',
        );
      }
    });
  });

  group('MeetingTranscriptionService.isRepetitionHallucination', () {
    test('drops degenerate repetitions Whisper emits on echo bleed', () {
      for (final t in [
        'agree agree agree agree agree agree agree agree agree',
        'Take Take Take Take Take',
        'the the the the the and', // one token dominates a long window
        'so so so so',
      ]) {
        expect(
          MeetingTranscriptionService.isRepetitionHallucination(t),
          isTrue,
          reason: 'expected "$t" to be a repetition hallucination',
        );
      }
    });

    test('keeps real speech, including short and lightly-repetitive lines', () {
      for (final t in [
        'is is', // genuine stutter (< 4 tokens)
        'no no, that is wrong',
        'we need to ship the release on Friday',
        'okay okay let us move on', // varied, not one-token-dominated
        'I think I think we should wait',
        'that that is the plan for now',
      ]) {
        expect(
          MeetingTranscriptionService.isRepetitionHallucination(t),
          isFalse,
          reason: 'expected "$t" to be kept as real speech',
        );
      }
    });
  });

  group('MeetingTranscriptionService.isHallucinatedBoilerplate', () {
    test('drops canned non-speech boilerplate windows', () {
      for (final t in [
        'Thanks for watching!',
        'Thank you for watching.',
        'Please subscribe',
        'Like and subscribe',
        'See you in the next video',
        'Subtitles by the Amara.org community',
        'Transcription by CastingWords',
        'www.example.com',
        'https://acme.io/meeting',
      ]) {
        expect(
          MeetingTranscriptionService.isHallucinatedBoilerplate(t),
          isTrue,
          reason: 'expected "$t" to be dropped as boilerplate',
        );
      }
    });

    test('keeps real speech that merely contains a boilerplate substring', () {
      for (final t in [
        'thank you', // bare, ambiguous — kept on purpose
        'okay thanks for watching the demo earlier today',
        'can you subscribe me to the mailing list',
        'I will send the link to example.com later', // mixed with speech
        'lets ship the release on Friday',
      ]) {
        expect(
          MeetingTranscriptionService.isHallucinatedBoilerplate(t),
          isFalse,
          reason: 'expected "$t" to be kept as real speech',
        );
      }
    });
  });
}
