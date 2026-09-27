import 'dart:async';

import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_domain/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:cc_host/cc_host.dart' show RepoOpContext;
import 'package:cc_server_core/src/catalog/meeting_ops.dart';
import 'package:cc_server_core/src/demo/demo_meeting_service.dart';
import 'package:cc_server_core/src/demo/demo_profile.dart';
import 'package:test/test.dart';

void main() {
  late _MeetingStore store;
  late DemoMeetingService service;

  setUp(() {
    store = _MeetingStore();
    service = DemoMeetingService(store);
  });
  tearDown(() async {
    await service.dispose();
    await store.dispose();
  });

  test(
    'demo RPCs exist only with demo wiring and ignore forged transcript input',
    () async {
      final production = buildMeetingOps(meetingRepository: store);
      expect(
        production.map((op) => op.name),
        isNot(contains('meeting.demoStart')),
      );

      final demo = buildMeetingOps(
        meetingRepository: store,
        demoMeeting: service,
      );
      final names = demo.map((op) => op.name).toSet();
      expect(
        names,
        containsAll([
          'meeting.demoStart',
          'meeting.demoPause',
          'meeting.demoResume',
          'meeting.demoStop',
        ]),
      );
      expect(names, isNot(contains('meeting.startRecording')));
      expect(names, isNot(contains('meeting.ingestAudio')));
      expect(
        const DemoProfile().allowedMutations,
        containsAll([
          'meeting.demoStart',
          'meeting.demoPause',
          'meeting.demoResume',
          'meeting.demoStop',
        ]),
      );
      expect(
        const DemoProfile().deniedMutations,
        containsAll([
          'meeting.startRecording',
          'meeting.ingestAudio',
          'meeting.stopRecording',
        ]),
      );

      final start = demo.singleWhere((op) => op.name == 'meeting.demoStart');
      final result = await start.handler(
        const RepoOpContext(
          workspaceId: 'visitor-a',
          userId: 'alice',
          deviceId: 'alice-device',
          args: {
            'workspace_id': 'visitor-b',
            'user_id': 'bob',
            'text': 'Attacker-supplied transcript',
          },
        ),
      );
      final id = result['meeting_id'] as String;
      expect(await store.getById('visitor-b', id), isNull);
      final lines = await store.getSegments('visitor-a', id);
      expect(lines.single.text, isNot(contains('Attacker-supplied')));
      await service.stop(
        workspaceId: 'visitor-a',
        userId: 'alice',
        meetingId: id,
      );
    },
  );

  test(
    'a demo recording streams fixed attributed lines and finishes without audio',
    () async {
      final id = await service.start(workspaceId: 'visitor-a', userId: 'alice');
      final recording = await store.getById('visitor-a', id);
      expect(recording?.status, MeetingStatus.recording);
      expect(recording?.title, contains('Simulated'));
      expect(recording?.audioPath, isNull);

      final seen = <List<MeetingSegment>>[];
      final sub = store.watchSegments('visitor-a', id).listen(seen.add);
      await service.advance(id);
      final live = await store.getSegments('visitor-a', id);
      expect(live, hasLength(2));
      expect(live.first.speakerLabel, 'Maya Okonkwo');
      expect(live.last.speakerLabel, 'Diego Ferrer');
      expect(live.first.text, contains('eval-bench readiness'));
      expect(seen.last, hasLength(2));

      await service.stop(
        workspaceId: 'visitor-a',
        userId: 'alice',
        meetingId: id,
      );
      final finished = await store.getById('visitor-a', id);
      final transcript = await store.getSegments('visitor-a', id);
      expect(finished?.status, MeetingStatus.done);
      expect(finished?.endedAt, isNotNull);
      expect(finished?.audioPath, isNull);
      expect(transcript, hasLength(7));
      expect(transcript.map((line) => line.speakerLabel).toSet(), {
        'Maya Okonkwo',
        'Diego Ferrer',
        'Priya Raman',
      });
      expect(seen.last, hasLength(7));
      await sub.cancel();
      await service.advance(id);
      expect(await store.getSegments('visitor-a', id), hasLength(7));
    },
  );

  test(
    'pause freezes progression and resume continues from the same line',
    () async {
      final id = await service.start(workspaceId: 'visitor-a', userId: 'alice');
      await service.pause(
        workspaceId: 'visitor-a',
        userId: 'alice',
        meetingId: id,
      );
      await service.advance(id);
      await service.advance(id);
      expect(await store.getSegments('visitor-a', id), hasLength(1));
      await service.resume(
        workspaceId: 'visitor-a',
        userId: 'alice',
        meetingId: id,
      );
      await service.advance(id);
      expect(await store.getSegments('visitor-a', id), hasLength(2));
      await service.stop(
        workspaceId: 'visitor-a',
        userId: 'alice',
        meetingId: id,
      );
    },
  );

  test(
    'server timer emits lines while active and remains quiet while paused',
    () async {
      await service.dispose();
      service = DemoMeetingService(
        store,
        interval: const Duration(milliseconds: 200),
      );
      final id = await service.start(workspaceId: 'visitor-a', userId: 'alice');
      final second = store
          .watchSegments('visitor-a', id)
          .firstWhere((lines) => lines.length == 2);
      await second.timeout(const Duration(seconds: 2));
      await service.pause(
        workspaceId: 'visitor-a',
        userId: 'alice',
        meetingId: id,
      );
      final count = (await store.getSegments('visitor-a', id)).length;
      await Future<void>.delayed(const Duration(milliseconds: 460));
      expect(await store.getSegments('visitor-a', id), hasLength(count));
      final next = store
          .watchSegments('visitor-a', id)
          .firstWhere((lines) => lines.length > count);
      await service.resume(
        workspaceId: 'visitor-a',
        userId: 'alice',
        meetingId: id,
      );
      await next.timeout(const Duration(seconds: 2));
      await service.stop(
        workspaceId: 'visitor-a',
        userId: 'alice',
        meetingId: id,
      );
      expect(
        (await store.getById('visitor-a', id))?.status,
        MeetingStatus.done,
      );
    },
  );

  test(
    'only the creator in the bound workspace can control a meeting',
    () async {
      final id = await service.start(workspaceId: 'visitor-a', userId: 'alice');
      await expectLater(
        service.start(workspaceId: 'visitor-a', userId: 'alice'),
        throwsStateError,
      );
      for (final (workspace, user) in [
        ('visitor-b', 'alice'),
        ('visitor-a', 'bob'),
      ]) {
        await expectLater(
          service.pause(workspaceId: workspace, userId: user, meetingId: id),
          throwsStateError,
        );
        await expectLater(
          service.resume(workspaceId: workspace, userId: user, meetingId: id),
          throwsStateError,
        );
        await expectLater(
          service.stop(workspaceId: workspace, userId: user, meetingId: id),
          throwsStateError,
        );
      }
      expect(
        (await store.getById('visitor-a', id))?.status,
        MeetingStatus.recording,
      );
      expect(await store.getById('visitor-b', id), isNull);
      await service.stop(
        workspaceId: 'visitor-a',
        userId: 'alice',
        meetingId: id,
      );
      await expectLater(
        service.stop(workspaceId: 'visitor-a', userId: 'alice', meetingId: id),
        throwsStateError,
      );
    },
  );

  test(
    'visitor expiry cancels queued work without touching another workspace',
    () async {
      final first = await service.start(
        workspaceId: 'visitor-a',
        userId: 'alice',
      );
      final second = await service.start(
        workspaceId: 'visitor-b',
        userId: 'bob',
      );
      await service.retireWorkspace('visitor-a');
      await service.advance(first);
      await service.advance(second);
      expect(await store.getSegments('visitor-a', first), hasLength(1));
      expect(await store.getSegments('visitor-b', second), hasLength(2));
      await service.stop(
        workspaceId: 'visitor-b',
        userId: 'bob',
        meetingId: second,
      );
    },
  );
}

class _MeetingStore implements MeetingRepository {
  final meetings = <(String, String), Meeting>{};
  final segments = <(String, String), List<MeetingSegment>>{};
  final changes =
      StreamController<((String, String), List<MeetingSegment>)>.broadcast(
        sync: true,
      );

  @override
  Future<void> upsert(Meeting meeting) async {
    meetings[(meeting.workspaceId, meeting.id)] = meeting;
  }

  @override
  Future<Meeting?> getById(String workspaceId, String id) async =>
      meetings[(workspaceId, id)];

  @override
  Future<void> appendSegment(MeetingSegment segment) async {
    final key = (segment.workspaceId, segment.meetingId);
    (segments[key] ??= []).add(segment);
    changes.add((key, List.of(segments[key]!)));
  }

  @override
  Future<List<MeetingSegment>> getSegments(
    String workspaceId,
    String meetingId,
  ) async => List.of(segments[(workspaceId, meetingId)] ?? const []);

  @override
  Stream<List<MeetingSegment>> watchSegments(
    String workspaceId,
    String meetingId,
  ) => changes.stream
      .where((change) => change.$1 == (workspaceId, meetingId))
      .map((change) => change.$2);

  Future<void> dispose() => changes.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'Unexpected meeting repository call: ${invocation.memberName}',
  );
}
