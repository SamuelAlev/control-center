import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/meeting_events.dart';
import 'package:cc_domain/core/domain/events/pipeline_events.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_domain/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_infra/src/meetings/meeting_summary_reconciler.dart';
import 'package:test/test.dart';

/// Exercises [MeetingSummaryReconciler]. The reconciler depends only on
/// injectable domain interfaces ([DomainEventBus], [PipelineRunRepository],
/// [MeetingRepository]); fakes drive every branch: the startup sweep over
/// stranded `recording` / `processing` meetings, the per-run terminal-event
/// finalizer, the transcript fallback when enhanced notes are missing, and
/// the skip-when-an-active-summary-run-exists path.
void main() {
  late DomainEventBus eventBus;
  late FakeMeetingRepository meetings;
  late FakePipelineRunRepository runs;
  late MeetingSummaryReconciler reconciler;

  setUp(() {
    eventBus = DomainEventBus();
    meetings = FakeMeetingRepository();
    runs = FakePipelineRunRepository();
    reconciler = MeetingSummaryReconciler(
      eventBus: eventBus,
      runRepository: runs,
      meetingRepository: meetings,
    );
  });

  tearDown(() => reconciler.dispose());

  Meeting meeting({
    String id = 'm1',
    MeetingStatus status = MeetingStatus.processing,
    List<MeetingSegment> segments = const [],
    String? enhancedNotes,
  }) {
    final m = Meeting(
      id: id,
      workspaceId: 'ws',
      title: 'Title',
      status: status,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      startedAt: DateTime.utc(2026, 1, 1),
      enhancedNotes: enhancedNotes,
    );
    // Stash the segments so the fake's getSegments() can find them.
    meetings.segmentsByMeeting[id] = segments;
    return m;
  }

  /// Convenience: registers a meeting under its id so getById can find it.
  Meeting register(Meeting m) {
    meetings.meetingsById[m.id] = m;
    return m;
  }

  group('startup sweep — stranded recording', () {
    test('finalizes to done with no transcript', () async {
      meetings.unfinalized = [meeting(status: MeetingStatus.recording)];
      reconciler.start();
      // The sweep is unawaited inside start(); pump the microtask queue.
      await Future<void>.delayed(Duration.zero);
      expect(meetings.upserted, hasLength(1));
      expect(meetings.upserted.single.status, MeetingStatus.done);
    });

    test(
      'moves to processing and re-announces MeetingRecordingStopped when transcript exists',
      () async {
        meetings.unfinalized = [
          meeting(
            status: MeetingStatus.recording,
            segments: [
              MeetingSegment(
                id: 's1',
                meetingId: 'm1',
                workspaceId: 'ws',
                speaker: MeetingSpeaker.me,
                text: 'hello world',
                startMs: 0,
                endMs: 1000,
                createdAt: DateTime.utc(2026, 1, 1),
              ),
            ],
          ),
        ];
        final events = <DomainEvent>[];
        eventBus.on<MeetingRecordingStopped>().listen(events.add);

        reconciler.start();
        await Future<void>.delayed(Duration.zero);

        expect(meetings.upserted.single.status, MeetingStatus.processing);
        expect(events, hasLength(1));
        expect(events.single, isA<MeetingRecordingStopped>());
        expect((events.single as MeetingRecordingStopped).meetingId, 'm1');
        expect(
          (events.single as MeetingRecordingStopped).transcript,
          isNotEmpty,
        );
      },
    );
  });

  group('startup sweep — stranded processing', () {
    test('finalizes to done when no active summary run is in flight', () async {
      meetings.unfinalized = [meeting(status: MeetingStatus.processing)];
      reconciler.start();
      await Future<void>.delayed(Duration.zero);
      expect(meetings.upserted.single.status, MeetingStatus.done);
    });

    test('leaves a meeting alone when an active summary run exists', () async {
      meetings.unfinalized = [meeting(status: MeetingStatus.processing)];
      // Pretend an active run is still running for this meeting's dedup key.
      runs.activeForDedupKeyResult = PipelineRun(
        id: 'run-1',
        templateId: MeetingSummaryReconciler.templateId,
        workspaceId: 'ws',
        status: PipelineRunStatus.running,
        startedAt: DateTime.utc(2026, 1, 1),
      );
      reconciler.start();
      await Future<void>.delayed(Duration.zero);
      expect(meetings.upserted, isEmpty);
    });

    test(
      'uses transcript as enhancedNotes fallback when not enhanced',
      () async {
        meetings.unfinalized = [
          meeting(
            status: MeetingStatus.processing,
            segments: [
              MeetingSegment(
                id: 's1',
                meetingId: 'm1',
                workspaceId: 'ws',
                speaker: MeetingSpeaker.me,
                text: 'fallback transcript text',
                startMs: 0,
                endMs: 100,
                createdAt: DateTime.utc(2026, 1, 1),
              ),
            ],
          ),
        ];
        reconciler.start();
        await Future<void>.delayed(Duration.zero);
        expect(meetings.upserted.single.status, MeetingStatus.done);
        expect(
          meetings.upserted.single.enhancedNotes,
          contains('fallback transcript text'),
        );
      },
    );

    test('preserves existing enhancedNotes (no fallback applied)', () async {
      meetings.unfinalized = [
        meeting(
          status: MeetingStatus.processing,
          enhancedNotes: 'already enhanced',
        ),
      ];
      reconciler.start();
      await Future<void>.delayed(Duration.zero);
      expect(meetings.upserted.single.enhancedNotes, 'already enhanced');
    });
  });

  group('terminal-event finalizer', () {
    PipelineRun runWithMeeting({required String meetingId}) {
      return PipelineRun(
        id: 'run-1',
        templateId: MeetingSummaryReconciler.templateId,
        workspaceId: 'ws',
        status: PipelineRunStatus.completed,
        startedAt: DateTime.utc(2026, 1, 1),
        triggerPayload: {'meetingId': meetingId},
      );
    }

    test('PipelineRunCompleted finalizes the linked meeting', () async {
      runs.runs['run-1'] = runWithMeeting(meetingId: 'm1');
      register(meeting(status: MeetingStatus.processing));

      reconciler.start();
      eventBus.publish(
        PipelineRunCompleted(
          pipelineRunId: 'run-1',
          templateId: MeetingSummaryReconciler.templateId,
          occurredAt: DateTime.utc(2026, 1, 2),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(meetings.upserted, hasLength(1));
      expect(meetings.upserted.single.status, MeetingStatus.done);
    });

    test('PipelineRunFailed finalizes the linked meeting', () async {
      runs.runs['run-1'] = runWithMeeting(meetingId: 'm1');
      register(meeting(status: MeetingStatus.processing));

      reconciler.start();
      eventBus.publish(
        PipelineRunFailed(
          pipelineRunId: 'run-1',
          templateId: MeetingSummaryReconciler.templateId,
          errorMessage: 'boom',
          occurredAt: DateTime.utc(2026, 1, 2),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(meetings.upserted.single.status, MeetingStatus.done);
    });

    test('PipelineRunCancelled finalizes the linked meeting', () async {
      runs.runs['run-1'] = runWithMeeting(meetingId: 'm1');
      register(meeting(status: MeetingStatus.processing));

      reconciler.start();
      eventBus.publish(
        PipelineRunCancelled(
          pipelineRunId: 'run-1',
          templateId: MeetingSummaryReconciler.templateId,
          occurredAt: DateTime.utc(2026, 1, 2),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(meetings.upserted.single.status, MeetingStatus.done);
    });

    test('ignores events for unrelated templates', () async {
      runs.runs['run-1'] = runWithMeeting(meetingId: 'm1');
      register(meeting(status: MeetingStatus.processing));
      reconciler.start();
      eventBus.publish(
        PipelineRunCompleted(
          pipelineRunId: 'run-1',
          templateId: 'other_template',
          occurredAt: DateTime.utc(2026, 1, 2),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(meetings.upserted, isEmpty);
    });

    test(
      'skips when the run has no meetingId in its trigger payload',
      () async {
        runs.runs['run-1'] = PipelineRun(
          id: 'run-1',
          templateId: MeetingSummaryReconciler.templateId,
          workspaceId: 'ws',
          status: PipelineRunStatus.completed,
          startedAt: DateTime.utc(2026, 1, 1),
          triggerPayload: const {},
        );
        reconciler.start();
        eventBus.publish(
          PipelineRunCompleted(
            pipelineRunId: 'run-1',
            templateId: MeetingSummaryReconciler.templateId,
            occurredAt: DateTime.utc(2026, 1, 2),
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(meetings.upserted, isEmpty);
      },
    );

    test('skips when the meeting is already finalized', () async {
      runs.runs['run-1'] = runWithMeeting(meetingId: 'm1');
      register(meeting(status: MeetingStatus.done));
      reconciler.start();
      eventBus.publish(
        PipelineRunCompleted(
          pipelineRunId: 'run-1',
          templateId: MeetingSummaryReconciler.templateId,
          occurredAt: DateTime.utc(2026, 1, 2),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(meetings.upserted, isEmpty);
    });

    test('skips when the run is missing', () async {
      // runs.runs is empty → getRun returns null.
      reconciler.start();
      eventBus.publish(
        PipelineRunCompleted(
          pipelineRunId: 'unknown',
          templateId: MeetingSummaryReconciler.templateId,
          occurredAt: DateTime.utc(2026, 1, 2),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(meetings.upserted, isEmpty);
    });

    test('ignores unrelated domain events', () async {
      reconciler.start();
      eventBus.publish(
        MeetingRecordingStopped(
          workspaceId: 'ws',
          meetingId: 'x',
          title: 't',
          userNotes: '',
          transcript: '',
          occurredAt: DateTime.utc(2026, 1, 2),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(meetings.upserted, isEmpty);
    });
  });

  group('lifecycle', () {
    test('dispose stops the subscription', () async {
      reconciler.start();
      reconciler.dispose();
      // After dispose, publishing a terminal event should not finalize.
      runs.runs['run-1'] = PipelineRun(
        id: 'run-1',
        templateId: MeetingSummaryReconciler.templateId,
        workspaceId: 'ws',
        status: PipelineRunStatus.completed,
        startedAt: DateTime.utc(2026, 1, 1),
        triggerPayload: {'meetingId': 'm1'},
      );
      register(meeting(status: MeetingStatus.processing));
      eventBus.publish(
        PipelineRunCompleted(
          pipelineRunId: 'run-1',
          templateId: MeetingSummaryReconciler.templateId,
          occurredAt: DateTime.utc(2026, 1, 2),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(meetings.upserted, isEmpty);
    });
  });
}

/// Fake [MeetingRepository]. Carries canned rows + segments in maps and
/// records every upsert.
class FakeMeetingRepository implements MeetingRepository {
  List<Meeting> unfinalized = const [];
  final Map<String, Meeting> meetingsById = {};
  final Map<String, List<MeetingSegment>> segmentsByMeeting = {};
  final List<Meeting> upserted = [];

  @override
  Future<List<Meeting>> getUnfinalized() async => unfinalized;

  @override
  Future<Meeting?> getById(String workspaceId, String id) async =>
      meetingsById[id];

  @override
  Future<void> upsert(Meeting meeting) async {
    upserted.add(meeting);
    // Reflect the upsert back into getById so subsequent reads see it.
    meetingsById[meeting.id] = meeting;
  }

  @override
  Future<List<MeetingSegment>> getSegments(
    String workspaceId,
    String meetingId,
  ) async => segmentsByMeeting[meetingId] ?? const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePipelineRunRepository implements PipelineRunRepository {
  final Map<String, PipelineRun> runs = {};
  PipelineRun? activeForDedupKeyResult;

  @override
  Future<PipelineRun?> getRun(String id) async => runs[id];

  @override
  Future<PipelineRun?> activeForDedupKey({
    required String templateId,
    required String workspaceId,
    required String dedupKey,
  }) async => activeForDedupKeyResult;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
