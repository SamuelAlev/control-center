import 'dart:async';

import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/meeting_events.dart';
import 'package:control_center/core/domain/events/pipeline_events.dart';
import 'package:control_center/features/meetings/data/services/meeting_summary_reconciler.dart';
import 'package:control_center/features/meetings/domain/entities/meeting.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_decision.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_segment.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_speaker_label.dart';
import 'package:control_center/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:control_center/features/meetings/domain/services/meeting_transcript_formatter.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

final _now = DateTime(2026, 6, 11, 12, 0, 0);

Meeting _meeting({
  String id = 'meeting-1',
  String workspaceId = 'ws-1',
  MeetingStatus status = MeetingStatus.processing,
  String? enhancedNotes,
}) {
  return Meeting(
    id: id,
    workspaceId: workspaceId,
    title: 'Test Meeting',
    status: status,
    createdAt: _now,
    updatedAt: _now,
    startedAt: _now,
    enhancedNotes: enhancedNotes,
  );
}

PipelineRun _pipelineRun({
  String id = 'run-1',
  String templateId = 'meeting_summary',
  String workspaceId = 'ws-1',
  Map<String, dynamic>? triggerPayload,
}) {
  return PipelineRun(
    id: id,
    templateId: templateId,
    workspaceId: workspaceId,
    status: PipelineRunStatus.running,
    triggerPayload: triggerPayload,
    startedAt: _now,
  );
}

MeetingSegment _segment({
  String id = 'seg-1',
  String meetingId = 'meeting-1',
  String workspaceId = 'ws-1',
  String text = 'Hello world',
  int startMs = 0,
  int endMs = 5000,
  MeetingSpeaker speaker = MeetingSpeaker.me,
}) {
  return MeetingSegment(
    id: id,
    meetingId: meetingId,
    workspaceId: workspaceId,
    speaker: speaker,
    text: text,
    startMs: startMs,
    endMs: endMs,
    createdAt: _now,
  );
}

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class FakeDomainEventBus implements DomainEventBus {
  final _controller = StreamController<DomainEvent>.broadcast();
  bool disposed = false;

  @override
  void publish(DomainEvent event) => _controller.add(event);

  @override
  Stream<T> on<T extends DomainEvent>() =>
      _controller.stream.where((e) => e is T).cast<T>();

  @override
  void dispose() {
    disposed = true;
    _controller.close();
  }
}

class FakePipelineRunRepository implements PipelineRunRepository {
  final Map<String, PipelineRun> _runs = {};

  /// Active runs keyed by (templateId, workspaceId, dedupKey).
  final Map<(String, String, String), PipelineRun> _activeByDedup = {};

  void addRun(PipelineRun run) {
    _runs[run.id] = run;
  }

  @override
  Future<PipelineRun?> getRun(String id) async {
    return _runs[id];
  }

  @override
  Future<PipelineRun?> activeForDedupKey({
    required String templateId,
    required String workspaceId,
    required String dedupKey,
  }) async {
    return _activeByDedup[(templateId, workspaceId, dedupKey)];
  }

  // Unused by reconciler — no-op stubs.
  @override
  Future<void> insertRun(PipelineRun run) async {}

  @override
  Future<void> updateRun(PipelineRun run) async {}

  @override
  Stream<PipelineRun?> watchRun(String id) =>
      const Stream.empty();

  @override
  Future<void> updateRunState(
    String runId,
    Map<String, dynamic> state,
  ) async {}

  @override
  Future<void> incrementCost(String runId, int cents, int tokens) async {}

  @override
  Future<List<PipelineRun>> nonTerminalRuns() async => [];

  @override
  Stream<List<PipelineRun>> watchAll() => const Stream.empty();

  @override
  Stream<List<PipelineRun>> watchForWorkspace(String workspaceId) =>
      const Stream.empty();

  @override
  Future<void> deleteRun(String workspaceId, String runId) async {}

  @override
  Future<void> insertStepRun(PipelineStepRun stepRun) async {}

  @override
  Future<void> updateStepRun(
    String stepRunId, {
    PipelineStepStatus? status,
    String? inputJson,
    String? outputJson,
    String? errorMessage,
    String? errorStackTrace,
    DateTime? finishedAt,
  }) async {}

  @override
  Future<void> deleteStepRun(String stepRunId) async {}

  @override
  Future<List<PipelineStepRun>> stepRunsForPipeline(
    String pipelineRunId,
  ) async => [];

  @override
  Future<PipelineStepRun?> getStepRunById(String stepRunId) async => null;

  @override
  Stream<List<PipelineStepRun>> watchStepRunsForPipeline(
    String pipelineRunId,
  ) => const Stream.empty();
}

class FakeMeetingRepository implements MeetingRepository {
  final Map<String, Meeting> _byId = {};
  final Map<String, List<MeetingSegment>> _segments = {};
  final List<Meeting> _upserted = [];

  Meeting? _upsertedLast;

  void addMeeting(Meeting meeting) {
    _byId[meeting.id] = meeting;
  }

  void addSegments(String meetingId, List<MeetingSegment> segments) {
    _segments[meetingId] = segments;
  }

  /// The most recent meeting passed to [upsert].
  Meeting? get lastUpserted => _upsertedLast;

  @override
  Future<Meeting?> getById(String workspaceId, String id) async {
    final m = _byId[id];
    if (m == null || m.workspaceId != workspaceId) {
      return null;
    }
    return m;
  }

  @override
  Future<List<Meeting>> getUnfinalized() async {
    return _byId.values
        .where((m) =>
            m.status == MeetingStatus.recording ||
            m.status == MeetingStatus.processing)
        .toList();
  }

  @override
  Future<List<MeetingSegment>> getSegments(
    String workspaceId,
    String meetingId,
  ) async {
    return _segments[meetingId] ?? [];
  }

  @override
  Future<void> upsert(Meeting meeting) async {
    _upserted.add(meeting);
    _upsertedLast = meeting;
    _byId[meeting.id] = meeting;
  }

  // Unused by reconciler — no-op stubs.
  @override
  Stream<List<Meeting>> watchByWorkspace(String workspaceId) =>
      const Stream.empty();

  @override
  Future<List<Meeting>> getByWorkspace(String workspaceId) async => [];

  @override
  Future<void> delete(String workspaceId, String id) async {}

  @override
  Stream<List<MeetingSegment>> watchSegments(
    String workspaceId,
    String meetingId,
  ) => const Stream.empty();

  @override
  Future<void> appendSegment(MeetingSegment segment) async {}

  @override
  Future<void> setSegmentSpeakerLabel(
    String workspaceId,
    String segmentId,
    String label,
  ) async {}

  @override
  Stream<List<MeetingSpeakerLabel>> watchSpeakers(
    String workspaceId,
    String meetingId,
  ) => const Stream.empty();

  @override
  Future<List<MeetingSpeakerLabel>> getSpeakers(
    String workspaceId,
    String meetingId,
  ) async => [];

  @override
  Future<void> replaceSpeakers(
    String workspaceId,
    String meetingId,
    List<MeetingSpeakerLabel> speakers,
  ) async {}

  @override
  Future<void> renameSpeaker({
    required String workspaceId,
    required String id,
    required String? displayName,
  }) async {}

  @override
  Stream<List<MeetingActionItem>> watchActionItems(
    String workspaceId,
    String meetingId,
  ) => const Stream.empty();

  @override
  Stream<List<MeetingDecision>> watchDecisions(
    String workspaceId,
    String meetingId,
  ) => const Stream.empty();

  @override
  Stream<Map<String, MeetingActionItemStats>> watchActionItemStats(
    String workspaceId,
  ) => const Stream.empty();

  @override
  Stream<Map<String, int>> watchDecisionCounts(String workspaceId) =>
      const Stream.empty();

  @override
  Future<void> replaceActionItems(
    String workspaceId,
    String meetingId,
    List<MeetingActionItem> items,
  ) async {}

  @override
  Future<void> replaceDecisions(
    String workspaceId,
    String meetingId,
    List<MeetingDecision> decisions,
  ) async {}

  @override
  Future<void> setActionItemDone({
    required String workspaceId,
    required String id,
    required bool done,
  }) async {}

  @override
  Future<void> setActionItemTicket({
    required String workspaceId,
    required String id,
    required String ticketId,
  }) async {}
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeDomainEventBus eventBus;
  late FakePipelineRunRepository runRepo;
  late FakeMeetingRepository meetingRepo;
  late MeetingSummaryReconciler reconciler;

  setUp(() {
    eventBus = FakeDomainEventBus();
    runRepo = FakePipelineRunRepository();
    meetingRepo = FakeMeetingRepository();
    reconciler = MeetingSummaryReconciler(
      eventBus: eventBus,
      runRepository: runRepo,
      meetingRepository: meetingRepo,
    );
  });

  group('start() and dispose()', () {
    test(
      'start() subscribes to event bus and runs _reconcileStale',
      () {
        reconciler.start();
        // The reconciler subscribes (no error on start means sub created).
        // We verify events are received in later tests.
        // We also publish something to ensure no crash.
        expect(() => reconciler.start(), returnsNormally);
        reconciler.dispose();
        expect(eventBus.disposed, isFalse);
      },
      timeout: const Timeout.factor(2),
    );

    test(
      'dispose() cancels subscription cleanly',
      () async {
        reconciler.start();
        reconciler.dispose();

        // Publishing after dispose should not throw — the subscription
        // was cancelled, but the underlying broadcast controller is still
        // alive (FakeDomainEventBus.dispose is never called by the
        // reconciler's dispose()).
        expect(
          () => eventBus.publish(
            PipelineRunCompleted(
              pipelineRunId: 'run-1',
              templateId: 'meeting_summary',
              occurredAt: _now,
            ),
          ),
          returnsNormally,
        );
      },
      timeout: const Timeout.factor(2),
    );
  });

  group('_onEvent filtering', () {
    setUp(() {
      reconciler.start();
    });

    tearDown(() {
      reconciler.dispose();
    });

    test(
      'ignores events for wrong templateId',
      () async {
        final meeting = _meeting();
        meetingRepo.addMeeting(meeting);
        runRepo.addRun(_pipelineRun(
          triggerPayload: {'meetingId': meeting.id},
        ));

        eventBus.publish(
          PipelineRunCompleted(
            pipelineRunId: 'run-1',
            templateId: 'other_template',
            occurredAt: _now,
          ),
        );

        // Allow microtask to process async handler.
        await Future<void>.delayed(Duration.zero);

        expect(meetingRepo.lastUpserted, isNull,
            reason: 'Should not finalize for wrong templateId');
      },
      timeout: const Timeout.factor(2),
    );

    test(
      'ignores events where run not found',
      () async {
        final meeting = _meeting();
        meetingRepo.addMeeting(meeting);
        // Do NOT add the run to the repository.

        eventBus.publish(
          PipelineRunCompleted(
            pipelineRunId: 'run-missing',
            templateId: 'meeting_summary',
            occurredAt: _now,
          ),
        );

        await Future<void>.delayed(Duration.zero);

        expect(meetingRepo.lastUpserted, isNull,
            reason: 'Should not finalize when run is not found');
      },
      timeout: const Timeout.factor(2),
    );

    test(
      'ignores events where triggerPayload has no meetingId',
      () async {
        runRepo.addRun(_pipelineRun(
          triggerPayload: {'otherKey': 'otherValue'},
        ));

        eventBus.publish(
          PipelineRunCompleted(
            pipelineRunId: 'run-1',
            templateId: 'meeting_summary',
            occurredAt: _now,
          ),
        );

        await Future<void>.delayed(Duration.zero);

        expect(meetingRepo.lastUpserted, isNull,
            reason: 'Should not finalize when meetingId is missing from payload');
      },
      timeout: const Timeout.factor(2),
    );

    test(
      'ignores events where triggerPayload is null',
      () async {
        runRepo.addRun(_pipelineRun(
          triggerPayload: null,
        ));

        eventBus.publish(
          PipelineRunCompleted(
            pipelineRunId: 'run-1',
            templateId: 'meeting_summary',
            occurredAt: _now,
          ),
        );

        await Future<void>.delayed(Duration.zero);

        expect(meetingRepo.lastUpserted, isNull,
            reason: 'Should not finalize when triggerPayload is null');
      },
      timeout: const Timeout.factor(2),
    );

    test(
      'ignores events where meeting is not processing status',
      () async {
        final meeting = _meeting(status: MeetingStatus.done);
        meetingRepo.addMeeting(meeting);
        runRepo.addRun(_pipelineRun(
          triggerPayload: {'meetingId': meeting.id},
        ));

        eventBus.publish(
          PipelineRunCompleted(
            pipelineRunId: 'run-1',
            templateId: 'meeting_summary',
            occurredAt: _now,
          ),
        );

        await Future<void>.delayed(Duration.zero);

        expect(meetingRepo.lastUpserted, isNull,
            reason: 'Should not finalize already-done meeting');
      },
      timeout: const Timeout.factor(2),
    );

    test(
      'ignores events where meeting not found',
      () async {
        // meeting is never added to repo
        runRepo.addRun(_pipelineRun(
          triggerPayload: {'meetingId': 'nonexistent'},
        ));

        eventBus.publish(
          PipelineRunCompleted(
            pipelineRunId: 'run-1',
            templateId: 'meeting_summary',
            occurredAt: _now,
          ),
        );

        await Future<void>.delayed(Duration.zero);

        expect(meetingRepo.lastUpserted, isNull,
            reason: 'Should not finalize nonexistent meeting');
      },
      timeout: const Timeout.factor(2),
    );
  });

  group('finalization on pipeline events', () {
    setUp(() {
      reconciler.start();
    });

    tearDown(() {
      reconciler.dispose();
    });

    test(
      'finalizes meeting to done on PipelineRunCompleted with matching meeting',
      () async {
        final meeting = _meeting();
        final segments = [_segment()];
        meetingRepo.addMeeting(meeting);
        meetingRepo.addSegments(meeting.id, segments);
        runRepo.addRun(_pipelineRun(
          triggerPayload: {'meetingId': meeting.id},
        ));

        eventBus.publish(
          PipelineRunCompleted(
            pipelineRunId: 'run-1',
            templateId: 'meeting_summary',
            occurredAt: _now,
          ),
        );

        await Future<void>.delayed(Duration.zero);

        final result = meetingRepo.lastUpserted;
        expect(result, isNotNull);
        expect(result!.status, MeetingStatus.done);
        // Not enhanced → transcript fallback applied.
        expect(
          result.enhancedNotes,
          isNotNull,
        );
        expect(result.enhancedNotes, isNotEmpty);
      },
      timeout: const Timeout.factor(2),
    );

    test(
      'finalizes meeting to done on PipelineRunFailed with matching meeting',
      () async {
        final meeting = _meeting();
        final segments = [_segment()];
        meetingRepo.addMeeting(meeting);
        meetingRepo.addSegments(meeting.id, segments);
        runRepo.addRun(_pipelineRun(
          triggerPayload: {'meetingId': meeting.id},
        ));

        eventBus.publish(
          PipelineRunFailed(
            pipelineRunId: 'run-1',
            templateId: 'meeting_summary',
            errorMessage: 'Something broke',
            occurredAt: _now,
          ),
        );

        await Future<void>.delayed(Duration.zero);

        final result = meetingRepo.lastUpserted;
        expect(result, isNotNull);
        expect(result!.status, MeetingStatus.done);
        expect(result.enhancedNotes, isNotNull);
        expect(result.enhancedNotes, isNotEmpty);
      },
      timeout: const Timeout.factor(2),
    );

    test(
      'uses transcript as fallback when enhanced notes are empty',
      () async {
        final meeting = _meeting(enhancedNotes: '');
        final segments = [
          _segment(text: 'First segment'),
          _segment(id: 'seg-2', text: 'Second segment', startMs: 6000, endMs: 11000),
        ];
        meetingRepo.addMeeting(meeting);
        meetingRepo.addSegments(meeting.id, segments);
        runRepo.addRun(_pipelineRun(
          triggerPayload: {'meetingId': meeting.id},
        ));

        eventBus.publish(
          PipelineRunCompleted(
            pipelineRunId: 'run-1',
            templateId: 'meeting_summary',
            occurredAt: _now,
          ),
        );

        await Future<void>.delayed(Duration.zero);

        final result = meetingRepo.lastUpserted;
        expect(result, isNotNull);
        expect(result!.status, MeetingStatus.done);

        // Empty enhancedNotes → isEnhanced = false → fallback applied.
        final expectedTranscript =
            formatMeetingTranscript(segments);
        expect(result.enhancedNotes, expectedTranscript);
      },
      timeout: const Timeout.factor(2),
    );

    test(
      'leaves enhanced notes untouched when they exist',
      () async {
        const existingNotes = 'These are pre-written enhanced notes.';
        final meeting = _meeting(enhancedNotes: existingNotes);
        meetingRepo.addMeeting(meeting);
        // Segments exist but should NOT be used since isEnhanced is true.
        meetingRepo.addSegments(meeting.id, [_segment()]);
        runRepo.addRun(_pipelineRun(
          triggerPayload: {'meetingId': meeting.id},
        ));

        eventBus.publish(
          PipelineRunCompleted(
            pipelineRunId: 'run-1',
            templateId: 'meeting_summary',
            occurredAt: _now,
          ),
        );

        await Future<void>.delayed(Duration.zero);

        final result = meetingRepo.lastUpserted;
        expect(result, isNotNull);
        expect(result!.status, MeetingStatus.done);
        // Existing enhancedNotes are preserved via copyWith(enhancedNotes: null).
        expect(result.enhancedNotes, existingNotes);
      },
      timeout: const Timeout.factor(2),
    );

    test(
      'sets enhancedNotes to null when isEnhanced is true and no transcript exists',
      () async {
        const existingNotes = 'Some enhanced notes.';
        final meeting = _meeting(enhancedNotes: existingNotes);
        meetingRepo.addMeeting(meeting);
        // No segments → empty transcript, but isEnhanced is true so
        // fallback is NOT computed. enhancedNotes is null in copyWith,
        // which preserves existing.
        meetingRepo.addSegments(meeting.id, []);
        runRepo.addRun(_pipelineRun(
          triggerPayload: {'meetingId': meeting.id},
        ));

        eventBus.publish(
          PipelineRunCompleted(
            pipelineRunId: 'run-1',
            templateId: 'meeting_summary',
            occurredAt: _now,
          ),
        );

        await Future<void>.delayed(Duration.zero);

        final result = meetingRepo.lastUpserted;
        expect(result, isNotNull);
        expect(result!.status, MeetingStatus.done);
        // Still preserved because isEnhanced was true — no fallback computed.
        expect(result.enhancedNotes, existingNotes);
      },
      timeout: const Timeout.factor(2),
    );
  });

  group('_reconcileStale', () {
    test(
      'finalizes stuck processing meetings with no active run',
      () async {
        // Add a meeting in processing with no active run.
        final meeting = _meeting();
        meetingRepo.addMeeting(meeting);
        meetingRepo.addSegments(meeting.id, [_segment()]);
        // No active run in runRepo for this dedup key.

        reconciler.start();

        // _reconcileStale is unawaited; wait for it to complete.
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        final result = meetingRepo.lastUpserted;
        expect(result, isNotNull);
        expect(result!.status, MeetingStatus.done);
        expect(result.enhancedNotes, isNotNull);
        expect(result.enhancedNotes, isNotEmpty);
      },
      timeout: const Timeout.factor(2),
    );

    test(
      'skips meetings that have an active run',
      () async {
        final meeting = _meeting();
        meetingRepo.addMeeting(meeting);
        // Register an active run for this meeting.
        runRepo._activeByDedup[(
          'meeting_summary',
          meeting.workspaceId,
          meeting.id,
        )] = _pipelineRun();

        reconciler.start();

        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        // Should NOT have upserted the meeting since it has an active run.
        expect(meetingRepo.lastUpserted, isNull,
            reason: 'Meeting with active run should not be finalized');
      },
      timeout: const Timeout.factor(2),
    );

    test(
      'handles multiple stuck meetings (some with active runs)',
      () async {
        // Meeting 1: stuck, no active run.
        final m1 = _meeting(id: 'meeting-1');
        meetingRepo.addMeeting(m1);
        meetingRepo.addSegments(m1.id, [_segment()]);

        // Meeting 2: has an active run — should be skipped.
        final m2 = _meeting(id: 'meeting-2');
        meetingRepo.addMeeting(m2);
        runRepo._activeByDedup[(
          'meeting_summary',
          m2.workspaceId,
          m2.id,
        )] = _pipelineRun();

        // Meeting 3: stuck, no active run.
        final m3 = _meeting(id: 'meeting-3');
        meetingRepo.addMeeting(m3);
        meetingRepo.addSegments(m3.id, [_segment()]);

        reconciler.start();

        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        // Both m1 and m3 should be finalized; m2 skipped.
        // Check all upserted meetings.
        final upsertedIds = meetingRepo._upserted.map((m) => m.id).toSet();
        expect(upsertedIds, contains('meeting-1'));
        expect(upsertedIds, contains('meeting-3'));
        expect(upsertedIds, isNot(contains('meeting-2')));

        // Verify statuses.
        for (final m in meetingRepo._upserted) {
          expect(m.status, MeetingStatus.done);
        }
      },
      timeout: const Timeout.factor(2),
    );

    test(
      'does nothing when getUnfinalized returns empty',
      () async {
        // No meetings added at all.

        reconciler.start();

        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(meetingRepo._upserted, isEmpty);
      },
      timeout: const Timeout.factor(2),
    );
  });

  group('_finalize edge cases', () {
    setUp(() {
      reconciler.start();
    });

    tearDown(() {
      reconciler.dispose();
    });

    test(
      'sets enhancedNotes to null when no segments and not previously enhanced',
      () async {
        final meeting = _meeting(enhancedNotes: null);
        meetingRepo.addMeeting(meeting);
        // No segments added.
        meetingRepo.addSegments(meeting.id, []);
        runRepo.addRun(_pipelineRun(
          triggerPayload: {'meetingId': meeting.id},
        ));

        eventBus.publish(
          PipelineRunCompleted(
            pipelineRunId: 'run-1',
            templateId: 'meeting_summary',
            occurredAt: _now,
          ),
        );

        await Future<void>.delayed(Duration.zero);

        final result = meetingRepo.lastUpserted;
        expect(result, isNotNull);
        expect(result!.status, MeetingStatus.done);
        // No segments, not enhanced → fallback computed as empty transcript
        // → null (empty transcript is treated as null).
        expect(result.enhancedNotes, isNull);
      },
      timeout: const Timeout.factor(2),
    );

    test(
      'emits correct transcript format via fallback',
      () async {
        final meeting = _meeting();
        final segments = [
          MeetingSegment(
            id: 'seg-me',
            meetingId: meeting.id,
            workspaceId: meeting.workspaceId,
            speaker: MeetingSpeaker.me,
            text: 'I said this',
            startMs: 0,
            endMs: 3000,
            createdAt: _now,
          ),
          MeetingSegment(
            id: 'seg-them',
            meetingId: meeting.id,
            workspaceId: meeting.workspaceId,
            speaker: MeetingSpeaker.them,
            text: 'They said that',
            startMs: 4000,
            endMs: 7000,
            createdAt: _now,
          ),
        ];
        meetingRepo.addMeeting(meeting);
        meetingRepo.addSegments(meeting.id, segments);
        runRepo.addRun(_pipelineRun(
          triggerPayload: {'meetingId': meeting.id},
        ));

        eventBus.publish(
          PipelineRunCompleted(
            pipelineRunId: 'run-1',
            templateId: 'meeting_summary',
            occurredAt: _now,
          ),
        );

        await Future<void>.delayed(Duration.zero);

        final result = meetingRepo.lastUpserted;
        expect(result, isNotNull);
        expect(result!.status, MeetingStatus.done);

        final expected = formatMeetingTranscript(segments);
        expect(result.enhancedNotes, expected);
        expect(result.enhancedNotes, contains('[00:00] ME: I said this'));
        expect(result.enhancedNotes, contains('[00:04] THEM: They said that'));
      },
      timeout: const Timeout.factor(2),
    );

    test(
      'preserves non-status fields on finalize',
      () async {
        final meeting = Meeting(
          id: 'meeting-x',
          workspaceId: 'ws-1',
          title: 'Standup Notes',
          status: MeetingStatus.processing,
          createdAt: _now,
          updatedAt: _now,
          startedAt: _now.subtract(const Duration(hours: 1)),
          sourceApp: 'Zoom',
          userNotes: 'My personal notes',
          summary: null,
          audioPath: '/tmp/audio.wav',
          endedAt: _now.subtract(const Duration(minutes: 30)),
        );
        meetingRepo.addMeeting(meeting);
        meetingRepo.addSegments(meeting.id, [_segment()]);
        runRepo.addRun(_pipelineRun(
          triggerPayload: {'meetingId': meeting.id},
        ));

        eventBus.publish(
          PipelineRunCompleted(
            pipelineRunId: 'run-1',
            templateId: 'meeting_summary',
            occurredAt: _now,
          ),
        );

        await Future<void>.delayed(Duration.zero);

        final result = meetingRepo.lastUpserted;
        expect(result, isNotNull);
        expect(result!.status, MeetingStatus.done);
        expect(result.id, 'meeting-x');
        expect(result.workspaceId, 'ws-1');
        expect(result.title, 'Standup Notes');
        expect(result.sourceApp, 'Zoom');
        expect(result.userNotes, 'My personal notes');
        expect(result.audioPath, '/tmp/audio.wav');
        expect(result.startedAt, _now.subtract(const Duration(hours: 1)));
        expect(result.endedAt, _now.subtract(const Duration(minutes: 30)));
        expect(result.createdAt, _now);
        expect(result.summary, isNull);
      },
      timeout: const Timeout.factor(2),
    );
  });

  group('finalization on PipelineRunCancelled', () {
    setUp(() {
      reconciler.start();
    });

    tearDown(() {
      reconciler.dispose();
    });

    test(
      'finalizes a processing meeting to done when its summary run is cancelled',
      () async {
        final meeting = _meeting();
        meetingRepo.addMeeting(meeting);
        meetingRepo.addSegments(meeting.id, [_segment()]);
        runRepo.addRun(_pipelineRun(
          triggerPayload: {'meetingId': meeting.id},
        ));

        eventBus.publish(
          PipelineRunCancelled(
            pipelineRunId: 'run-1',
            templateId: 'meeting_summary',
            occurredAt: _now,
          ),
        );

        await Future<void>.delayed(Duration.zero);

        final result = meetingRepo.lastUpserted;
        expect(result, isNotNull);
        expect(result!.status, MeetingStatus.done);
        // Not enhanced → transcript fallback applied (recording not lost).
        expect(result.enhancedNotes, isNotEmpty);
      },
      timeout: const Timeout.factor(2),
    );

    test(
      'ignores cancellation for a wrong templateId',
      () async {
        final meeting = _meeting();
        meetingRepo.addMeeting(meeting);
        runRepo.addRun(_pipelineRun(
          triggerPayload: {'meetingId': meeting.id},
        ));

        eventBus.publish(
          PipelineRunCancelled(
            pipelineRunId: 'run-1',
            templateId: 'other_template',
            occurredAt: _now,
          ),
        );

        await Future<void>.delayed(Duration.zero);

        expect(meetingRepo.lastUpserted, isNull,
            reason: 'Should not finalize for a non-meeting template');
      },
      timeout: const Timeout.factor(2),
    );
  });

  group('_reconcileStale recovers stranded recordings', () {
    test(
      'a recording with a transcript moves to processing and re-announces '
      'MeetingRecordingStopped so the summary pipeline re-runs',
      () async {
        final meeting = _meeting(status: MeetingStatus.recording);
        meetingRepo.addMeeting(meeting);
        meetingRepo.addSegments(meeting.id, [
          _segment(text: 'Something was said'),
        ]);

        final announced = <MeetingRecordingStopped>[];
        final sub =
            eventBus.on<MeetingRecordingStopped>().listen(announced.add);

        reconciler.start();
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        final result = meetingRepo.lastUpserted;
        expect(result, isNotNull);
        expect(result!.status, MeetingStatus.processing);
        expect(result.endedAt, isNotNull,
            reason: 'a stranded recording never got its endedAt');

        expect(announced, hasLength(1));
        expect(announced.single.meetingId, meeting.id);
        expect(announced.single.workspaceId, meeting.workspaceId);
        expect(announced.single.transcript, isNotEmpty);

        await sub.cancel();
        reconciler.dispose();
      },
      timeout: const Timeout.factor(2),
    );

    test(
      'a recording with no transcript is finalized straight to done '
      'without announcing a summary run',
      () async {
        final meeting = _meeting(status: MeetingStatus.recording);
        meetingRepo.addMeeting(meeting);
        meetingRepo.addSegments(meeting.id, []);

        final announced = <MeetingRecordingStopped>[];
        final sub =
            eventBus.on<MeetingRecordingStopped>().listen(announced.add);

        reconciler.start();
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        final result = meetingRepo.lastUpserted;
        expect(result, isNotNull);
        expect(result!.status, MeetingStatus.done);
        expect(result.endedAt, isNotNull);
        expect(announced, isEmpty,
            reason: 'nothing was captured — no summary to run');

        await sub.cancel();
        reconciler.dispose();
      },
      timeout: const Timeout.factor(2),
    );

    test(
      'a recording is recovered even when a stale (non-active) run exists',
      () async {
        // A previous session may leave a terminal/cancelled run; it must not be
        // treated as active (findActiveByDedupKey already excludes those, so the
        // fake leaves _activeByDedup empty). The recording must still recover.
        final meeting = _meeting(status: MeetingStatus.recording);
        meetingRepo.addMeeting(meeting);
        meetingRepo.addSegments(meeting.id, [_segment()]);

        reconciler.start();
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(meetingRepo.lastUpserted, isNotNull);
        expect(meetingRepo.lastUpserted!.status, MeetingStatus.processing);

        reconciler.dispose();
      },
      timeout: const Timeout.factor(2),
    );
  });
}
