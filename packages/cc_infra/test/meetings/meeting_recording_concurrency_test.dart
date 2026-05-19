import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_domain/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:cc_domain/features/meetings/domain/services/speech_transcriber.dart';
import 'package:cc_infra/src/meetings/meeting_recording_session.dart';
import 'package:cc_infra/src/util/cc_paths.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// One `cc_server`, two clients, each recording its own meeting at the same
/// time. The host keys sessions by `(workspaceId, meetingId)` with a
/// server-minted id per `start`, so concurrent recordings never collide; this
/// pins that isolation: distinct ids + distinct audio dirs, and each session's
/// streamed PCM lands ONLY in its own `them.wav` (no cross-contamination).
void main() {
  group('MeetingRecordingService concurrency', () {
    late Directory dir;
    late _InMemoryMeetingRepo repo;
    late DomainEventBus bus;
    late MeetingRecordingService service;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('mtg_concurrency');
      repo = _InMemoryMeetingRepo();
      bus = DomainEventBus();
      service = MeetingRecordingService(
        repository: repo,
        transcriber: _SilentTranscriber(),
        eventBus: bus,
        paths: CcPaths(dir.path),
      );
    });

    tearDown(() async {
      await service.dispose();
      bus.dispose();
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    });

    test('two simultaneous recordings stay isolated', () async {
      const ws = 'ws-1';
      // Two clients open recordings concurrently against the same server.
      final idA = await service.start(workspaceId: ws, title: 'A', mode: 'remote');
      final idB = await service.start(workspaceId: ws, title: 'B', mode: 'remote');

      expect(idA, isNot(idB), reason: 'server mints a unique id per recording');
      expect(service.isRecording(ws, idA), isTrue);
      expect(service.isRecording(ws, idB), isTrue,
          reason: 'both recordings are live at once');

      // Each client streams a distinct, recognizable PCM pattern.
      final aBytes = Uint8List.fromList(List.filled(32000, 0x11));
      final bBytes = Uint8List.fromList(List.filled(32000, 0x22));
      await service.ingest(
          workspaceId: ws, meetingId: idA, channel: 'them', seq: 0, pcm: aBytes);
      await service.ingest(
          workspaceId: ws, meetingId: idB, channel: 'them', seq: 0, pcm: bBytes);

      await service.stop(workspaceId: ws, meetingId: idA);
      await service.stop(workspaceId: ws, meetingId: idB);

      expect(service.isRecording(ws, idA), isFalse);
      expect(service.isRecording(ws, idB), isFalse);

      final mA = await repo.getById(ws, idA);
      final mB = await repo.getById(ws, idB);
      expect(mA, isNotNull);
      expect(mB, isNotNull);
      expect(mA!.audioPath, isNotNull);
      expect(mB!.audioPath, isNotNull);
      expect(mA.audioPath, isNot(mB.audioPath),
          reason: 'each meeting retains audio in its own directory');

      // The retained per-channel WAV holds exactly that session's PCM, after the
      // 44-byte RIFF/WAVE header — neither stream bled into the other's file.
      final aWav = await File(p.join(mA.audioPath!, 'them.wav')).readAsBytes();
      final bWav = await File(p.join(mB.audioPath!, 'them.wav')).readAsBytes();
      expect(aWav.sublist(44), aBytes);
      expect(bWav.sublist(44), bBytes);
    });
  });
}

/// A transcriber that recognizes nothing — keeps the concurrency test
/// deterministic (no segments), since WAV retention is independent of decoding.
class _SilentTranscriber implements SpeechTranscriber {
  @override
  Future<void> initialize() async {}

  @override
  Future<String> transcribeChunk(Uint8List pcm16) async => '';

  @override
  Stream<TranscriptionResult> transcribe(Stream<List<int>> audio) =>
      const Stream.empty();

  @override
  Future<void> dispose() async {}

  @override
  bool get isReady => true;

  @override
  String get displayName => 'silent-fake';
}

/// Minimal in-memory [MeetingRepository] — only the methods the recording
/// session touches are implemented; the rest throw via [noSuchMethod].
class _InMemoryMeetingRepo implements MeetingRepository {
  final Map<String, Meeting> _meetings = {};
  final Map<String, List<MeetingSegment>> _segments = {};

  String _k(String workspaceId, String id) => '$workspaceId/$id';

  @override
  Future<void> upsert(Meeting meeting) async {
    _meetings[_k(meeting.workspaceId, meeting.id)] = meeting;
  }

  @override
  Future<Meeting?> getById(String workspaceId, String id) async =>
      _meetings[_k(workspaceId, id)];

  @override
  Future<void> appendSegment(MeetingSegment segment) async {
    (_segments[_k(segment.workspaceId, segment.meetingId)] ??= [])
        .add(segment);
  }

  @override
  Future<List<MeetingSegment>> getSegments(
    String workspaceId,
    String meetingId,
  ) async =>
      List.of(_segments[_k(workspaceId, meetingId)] ?? const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
        '${invocation.memberName} not stubbed in _InMemoryMeetingRepo',
      );
}
