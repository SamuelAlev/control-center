import 'dart:typed_data';

import 'package:cc_domain/features/meetings/domain/services/speech_activity_detector.dart';
import 'package:cc_domain/features/meetings/domain/services/speech_transcriber.dart';
import 'package:cc_infra/src/dictation/dictation_service.dart';
import 'package:cc_infra/src/meetings/meeting_transcription_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Flags every chunk as speech so the windowing path never drops a window.
class _AlwaysSpeech implements SpeechActivityDetector {
  @override
  bool isSpeech(Uint8List pcm16) => true;
  @override
  void reset() {}
  @override
  void dispose() {}
}

/// Returns a fixed transcript for every decoded window.
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

void main() {
  DictationService service(String text) => DictationService(
    transcriber: _FixedTranscriber('unused'),
    transcription: MeetingTranscriptionService(
      _FixedTranscriber(text),
      detectorFactory: _AlwaysSpeech.new,
    ),
  );

  // ~1.6s of 16 kHz mono PCM16 (content irrelevant — the detector always flags
  // speech); enough for the final flush to emit one window on stop.
  final pcm = Uint8List(16000 * 2 * 2);

  test(
    'start mints a workspace-scoped id; stop drains a final partial',
    () async {
      final s = service('hello world');
      final id = s.start('ws1');
      expect(id, contains('ws1'));

      final collected = s.watch(id).toList();
      s.ingest(id, pcm);
      await s.stop(id);

      final partials = await collected.timeout(const Duration(seconds: 5));
      expect(partials, isNotEmpty);
      expect(
        partials.any((p) => p.text == 'hello world'),
        isTrue,
        reason: 'the decoded window text must stream back',
      );
      expect(
        partials.last.isFinal,
        isTrue,
        reason: 'stop must emit a terminal isFinal partial',
      );
    },
  );

  test('watch on an unknown session is an empty stream', () async {
    final s = service('x');
    expect(await s.watch('nope').toList(), isEmpty);
  });

  test('two sessions get distinct ids', () {
    final s = service('x');
    expect(s.start('ws1'), isNot(s.start('ws1')));
  });
}
