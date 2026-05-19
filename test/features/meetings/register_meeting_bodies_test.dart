import 'package:control_center/core/infrastructure/speech/diarization_model_manager.dart';
import 'package:control_center/features/meetings/data/services/meeting_diarization_service.dart';
import 'package:control_center/features/meetings/domain/entities/meeting.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_decision.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_segment.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_speaker_label.dart';
import 'package:control_center/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:control_center/features/meetings/domain/services/meeting_diarization.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_context.dart';
import 'package:control_center/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:control_center/features/pipelines/domain/templates/register_meeting_bodies.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what the persist bodies write, and enforces workspace scoping in
/// [getById] (a foreign workspace → not found).
class _FakeMeetingRepository implements MeetingRepository {
  final Map<String, Meeting> _byId = {};

  Meeting? lastUpserted;
  List<MeetingActionItem>? lastActionItems;
  List<MeetingDecision>? lastDecisions;
  List<MeetingSegment> segments = const [];
  List<MeetingSegment>? lastSegments;

  void seed(Meeting meeting) => _byId[meeting.id] = meeting;

  @override
  Future<Meeting?> getById(String workspaceId, String id) async {
    final m = _byId[id];
    if (m == null || m.workspaceId != workspaceId) {
      return null;
    }
    return m;
  }

  @override
  Future<void> upsert(Meeting meeting) async {
    lastUpserted = meeting;
    _byId[meeting.id] = meeting;
  }

  @override
  Future<void> replaceActionItems(
    String workspaceId,
    String meetingId,
    List<MeetingActionItem> items,
  ) async {
    lastActionItems = items;
  }

  @override
  Future<void> replaceDecisions(
    String workspaceId,
    String meetingId,
    List<MeetingDecision> decisions,
  ) async {
    lastDecisions = decisions;
  }

  @override
  Future<void> replaceSegments(
    String w,
    String m,
    List<MeetingSegment> segments,
  ) async {
    lastSegments = segments;
  }

  // --- unused by these bodies -----------------------------------------------
  @override
  Future<void> appendSegment(MeetingSegment segment) async {}
  @override
  Future<void> setSegmentSpeakerLabel(String w, String s, String l) async {}
  @override
  Stream<List<MeetingSpeakerLabel>> watchSpeakers(String w, String m) =>
      const Stream.empty();
  @override
  Future<List<MeetingSpeakerLabel>> getSpeakers(String w, String m) async =>
      const [];
  @override
  Future<void> replaceSpeakers(
    String w,
    String m,
    List<MeetingSpeakerLabel> speakers,
  ) async {}
  @override
  Future<void> renameSpeaker({
    required String workspaceId,
    required String id,
    required String? displayName,
  }) async {}
  @override
  Future<void> delete(String workspaceId, String id) async {}
  @override
  Future<List<Meeting>> getByWorkspace(String workspaceId) async => [];
  @override
  Future<List<Meeting>> getUnfinalized() async => [];
  @override
  Future<List<MeetingSegment>> getSegments(String w, String m) async =>
      segments;
  @override
  Stream<List<Meeting>> watchByWorkspace(String workspaceId) =>
      const Stream.empty();
  @override
  Stream<List<MeetingSegment>> watchSegments(String w, String m) =>
      const Stream.empty();
  @override
  Stream<List<MeetingActionItem>> watchActionItems(String w, String m) =>
      const Stream.empty();
  @override
  Stream<List<MeetingDecision>> watchDecisions(String w, String m) =>
      const Stream.empty();
  @override
  Stream<Map<String, MeetingActionItemStats>> watchActionItemStats(String w) =>
      const Stream.empty();
  @override
  Stream<Map<String, int>> watchDecisionCounts(String w) => const Stream.empty();
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
  @override
  Future<void> addActionItem(MeetingActionItem item) async {}
  @override
  Future<void> updateActionItem({
    required String workspaceId,
    required String id,
    required String content,
    String? owner,
  }) async {}
  @override
  Future<void> deleteActionItem(String workspaceId, String id) async {}
  @override
  Future<void> addDecision(MeetingDecision decision) async {}
  @override
  Future<void> updateDecision({
    required String workspaceId,
    required String id,
    required String content,
  }) async {}
  @override
  Future<void> deleteDecision(String workspaceId, String id) async {}
}

Meeting _processing(String id, String ws) {
  final now = DateTime(2026, 1, 1);
  return Meeting(
    id: id,
    workspaceId: ws,
    title: 'M',
    status: MeetingStatus.processing,
    createdAt: now,
    updatedAt: now,
    startedAt: now,
  );
}

PipelineContext _ctx({
  required String workspaceId,
  required String meetingId,
  required Object outcome,
}) {
  return PipelineContext(
    pipelineRunId: 'run1',
    templateId: 'meeting_summary',
    stepId: 'step1',
    stepRunId: 'sr1',
    workspaceId: workspaceId,
    state: {'meetingId': meetingId, 'meetingOutcome': outcome},
  );
}

void main() {
  late _FakeMeetingRepository repo;
  late PipelineBodyRegistry registry;

  setUp(() {
    repo = _FakeMeetingRepository();
    registry = PipelineBodyRegistry();
    registerMeetingBodies(
      registry,
      meetingRepository: repo,
      diarizationModelManager: DiarizationModelManager(),
      diarizationService: const MeetingDiarizationService(),
    );
  });

  const outcome = {
    'summary': 'Short.',
    'enhancedNotes': '# Notes',
    'actionItems': [
      {'text': 'Do A', 'owner': 'Sam'},
      'Do B',
    ],
    'decisions': ['Chose X'],
  };

  test('meeting.saveNotes persists clean notes WITHOUT changing status '
      '(reconciler owns the done transition)', () async {
    repo.seed(_processing('m1', 'w1'));
    final result = await registry.body(BuiltInBodyKeys.meetingSaveNotes)(
      _ctx(workspaceId: 'w1', meetingId: 'm1', outcome: outcome),
    );

    expect(result.errorMessage, isNull);
    expect(repo.lastUpserted!.summary, 'Short.');
    expect(repo.lastUpserted!.enhancedNotes, '# Notes');
    // Stays processing — the meeting is finalized to done by the reconciler
    // once the whole run terminates, not by this step.
    expect(repo.lastUpserted!.status, MeetingStatus.processing);
  });

  test('meeting.addActionItems writes ordered rows with owners', () async {
    repo.seed(_processing('m1', 'w1'));
    final result = await registry.body(BuiltInBodyKeys.meetingAddActionItems)(
      _ctx(workspaceId: 'w1', meetingId: 'm1', outcome: outcome),
    );

    expect(result.errorMessage, isNull);
    final items = repo.lastActionItems!;
    expect(items.length, 2);
    expect(items[0].content, 'Do A');
    expect(items[0].owner, 'Sam');
    expect(items[0].sortOrder, 0);
    expect(items[1].content, 'Do B');
    expect(items[1].owner, isNull);
    expect(items[1].sortOrder, 1);
    expect(items.every((i) => i.workspaceId == 'w1' && i.meetingId == 'm1'),
        isTrue);
  });

  test('meeting.addDecisions writes ordered decision rows', () async {
    repo.seed(_processing('m1', 'w1'));
    final result = await registry.body(BuiltInBodyKeys.meetingAddDecisions)(
      _ctx(workspaceId: 'w1', meetingId: 'm1', outcome: outcome),
    );

    expect(result.errorMessage, isNull);
    expect(repo.lastDecisions!.single.content, 'Chose X');
  });

  test('a foreign-workspace meeting fails the step (no leak, no write)',
      () async {
    repo.seed(_processing('m1', 'w1'));
    final result = await registry.body(BuiltInBodyKeys.meetingSaveNotes)(
      _ctx(workspaceId: 'w2', meetingId: 'm1', outcome: outcome),
    );

    expect(result.errorMessage, isNotNull);
    expect(repo.lastUpserted, isNull);
  });

  test('a plain-markdown (non-structured) outcome saves notes but SKIPS the '
      'persist steps — never wipes existing rows', () async {
    repo.seed(_processing('m1', 'w1'));
    await registry.body(BuiltInBodyKeys.meetingSaveNotes)(
      _ctx(workspaceId: 'w1', meetingId: 'm1', outcome: '# only markdown'),
    );
    final aResult = await registry.body(BuiltInBodyKeys.meetingAddActionItems)(
      _ctx(workspaceId: 'w1', meetingId: 'm1', outcome: '# only markdown'),
    );
    final dResult = await registry.body(BuiltInBodyKeys.meetingAddDecisions)(
      _ctx(workspaceId: 'w1', meetingId: 'm1', outcome: '# only markdown'),
    );

    expect(repo.lastUpserted!.enhancedNotes, '# only markdown');
    // No replace was attempted (degraded output must not clear prior rows).
    expect(aResult.errorMessage, isNull);
    expect(dResult.errorMessage, isNull);
    expect(repo.lastActionItems, isNull);
    expect(repo.lastDecisions, isNull);
  });

  test('a structured outcome with empty lists DOES clear (legitimate replace)',
      () async {
    repo.seed(_processing('m1', 'w1'));
    await registry.body(BuiltInBodyKeys.meetingAddActionItems)(
      _ctx(
        workspaceId: 'w1',
        meetingId: 'm1',
        outcome: const {'summary': 'S', 'actionItems': <Object>[]},
      ),
    );
    expect(repo.lastActionItems, isEmpty);
  });

  test('meeting.updateTranscript labels + merges the transcript into turns',
      () async {
    repo.seed(_processing('m1', 'w1')); // remote mode → diarizes "them"
    final created = DateTime(2026);
    MeetingSegment them(String id, String text, int start, int end) =>
        MeetingSegment(
          id: id,
          meetingId: 'm1',
          workspaceId: 'w1',
          speaker: MeetingSpeaker.them,
          text: text,
          startMs: start,
          endMs: end,
          createdAt: created,
        );
    repo.segments = [
      them('s1', 'hello', 0, 1000),
      them('s2', 'world', 1000, 2000),
      them('s3', 'bye', 6000, 7000),
    ];
    final ctx = PipelineContext(
      pipelineRunId: 'run1',
      templateId: 'meeting_summary',
      stepId: 'step1',
      stepRunId: 'sr1',
      workspaceId: 'w1',
      state: {
        'meetingId': 'm1',
        'meetingDiarized': true,
        'diarizationSpans': encodeDiarizedSpans(const [
          DiarizedSpan(startMs: 0, endMs: 5000, speaker: 0),
          DiarizedSpan(startMs: 5000, endMs: 10000, speaker: 1),
        ]),
      },
    );

    final result =
        await registry.body(BuiltInBodyKeys.meetingUpdateTranscript)(ctx);

    expect(result.errorMessage, isNull);
    final out = repo.lastSegments!;
    expect(out.length, 2);
    expect(out[0].speakerLabel, 'Person 1');
    expect(out[0].text, 'hello world');
    expect(out[1].speakerLabel, 'Person 2');
    expect(out[1].text, 'bye');
  });

  test('meeting.updateTranscript is a no-op when diarization did not run',
      () async {
    repo.seed(_processing('m1', 'w1'));
    const ctx = PipelineContext(
      pipelineRunId: 'run1',
      templateId: 'meeting_summary',
      stepId: 'step1',
      stepRunId: 'sr1',
      workspaceId: 'w1',
      state: {'meetingId': 'm1', 'meetingDiarized': false},
    );

    final result =
        await registry.body(BuiltInBodyKeys.meetingUpdateTranscript)(ctx);

    expect(result.errorMessage, isNull);
    expect(repo.lastSegments, isNull);
  });
}
