import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:cc_domain/features/meetings/domain/services/speech_transcriber.dart';
import 'package:cc_infra/cc_infra.dart'
    show CcPaths, DictationService, MeetingRecordingService;
import 'package:cc_server_core/src/catalog/meeting_ops.dart';
import 'package:test/test.dart';

void main() {
  test(
    'high-frequency audio ingest ops opt out of the audit trail while lifecycle ops remain audited',
    () async {
      final dir = await Directory.systemTemp.createTemp('meeting_ops_audit');
      final bus = DomainEventBus();
      final repo = _FakeMeetingRepository();
      final transcriber = _FakeTranscriber();
      final recording = MeetingRecordingService(
        repository: repo,
        transcriber: transcriber,
        eventBus: bus,
        paths: CcPaths(dir.path),
      );
      final dictation = DictationService(transcriber: transcriber);

      try {
        final ops = buildMeetingOps(
          meetingRepository: repo,
          meetingRecording: recording,
          dictationService: dictation,
        );
        final byName = {for (final op in ops) op.name: op};

        expect(byName['meeting.ingestAudio']!.audited, isFalse);
        expect(byName['dictation.ingestAudio']!.audited, isFalse);

        expect(byName['meeting.startRecording']!.audited, isTrue);
        expect(byName['meeting.stopRecording']!.audited, isTrue);
        expect(byName['dictation.start']!.audited, isTrue);
        expect(byName['dictation.stop']!.audited, isTrue);
      } finally {
        await recording.dispose();
        await dictation.dispose();
        bus.dispose();
        if (dir.existsSync()) {
          await dir.delete(recursive: true);
        }
      }
    },
  );
}

class _FakeMeetingRepository implements MeetingRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTranscriber implements SpeechTranscriber {
  @override
  bool get isReady => true;

  @override
  String get displayName => 'fake';

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<String> transcribeChunk(Uint8List pcm16) async => '';

  @override
  Stream<TranscriptionResult> transcribe(Stream<List<int>> audio) =>
      const Stream.empty();
}
