import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_decision.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_speaker_label.dart';
import 'package:cc_domain/features/meetings/domain/entities/voice_profile.dart';
import 'package:cc_domain/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:cc_domain/features/meetings/domain/repositories/voice_profile_repository.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_diarization.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_infra/src/pipelines/register_meeting_bodies.dart';
import 'package:cc_infra/src/speech/diarization_model_manager.dart';
import 'package:cc_infra/src/util/cc_paths.dart';
import 'package:cc_infra/src/util/wav_io.dart';
import 'package:cc_natives/cc_natives.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Records what the persist bodies write, and enforces workspace scoping in
/// [getById] (a foreign workspace → not found).
class _FakeMeetingRepository implements MeetingRepository {
  final Map<String, Meeting> _byId = {};

  Meeting? lastUpserted;
  List<MeetingActionItem>? lastActionItems;
  List<MeetingDecision>? lastDecisions;
  List<MeetingSegment> segments = const [];
  List<MeetingSegment>? lastSegments;

  /// Diarized speakers, keyed by meeting id; mutated in place by [renameSpeaker].
  final Map<String, List<MeetingSpeakerLabel>> speakersByMeeting = {};

  /// Records (speakerId → displayName) for every [renameSpeaker] call.
  final Map<String, String?> renames = {};

  void seed(Meeting meeting) => _byId[meeting.id] = meeting;

  void seedSpeakers(String meetingId, List<MeetingSpeakerLabel> speakers) =>
      speakersByMeeting[meetingId] = [...speakers];

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
  Future<void> updateTitle({
    required String workspaceId,
    required String meetingId,
    required String title,
  }) async {
    final existing = _byId[meetingId];
    if (existing != null) {
      _byId[meetingId] = existing.copyWith(title: title);
    }
  }

  @override
  Future<void> updateNotes({
    required String workspaceId,
    required String meetingId,
    required String notes,
  }) async {
    final existing = _byId[meetingId];
    if (existing != null) {
      _byId[meetingId] = existing.copyWith(userNotes: notes);
    }
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
  Future<void> setSegmentSpeakerName(String w, String s, String? name) async {}
  @override
  Future<void> clearSpeakerNameOverridesForLabel({
    required String workspaceId,
    required String meetingId,
    required MeetingSpeaker channel,
    required String label,
  }) async {}
  @override
  Future<void> setSpeakerEnrolledProfile({
    required String workspaceId,
    required String meetingId,
    required MeetingSpeaker channel,
    required String label,
    required String? profileName,
  }) async {}
  @override
  Stream<List<MeetingSpeakerLabel>> watchSpeakers(String w, String m) =>
      const Stream.empty();
  @override
  Future<List<MeetingSpeakerLabel>> getSpeakers(String w, String m) async => [
        for (final s in speakersByMeeting[m] ?? const <MeetingSpeakerLabel>[])
          if (s.workspaceId == w) s,
      ];
  @override
  Future<void> replaceSpeakers(
    String w,
    String m,
    List<MeetingSpeakerLabel> speakers,
  ) async {
    speakersByMeeting[m] = [...speakers];
  }

  @override
  Future<void> renameSpeaker({
    required String workspaceId,
    required String id,
    required String? displayName,
  }) async {
    renames[id] = displayName;
    for (final list in speakersByMeeting.values) {
      for (var i = 0; i < list.length; i++) {
        final s = list[i];
        if (s.id == id && s.workspaceId == workspaceId) {
          list[i] = MeetingSpeakerLabel(
            id: s.id,
            meetingId: s.meetingId,
            workspaceId: s.workspaceId,
            channel: s.channel,
            label: s.label,
            displayName: displayName,
            embedding: s.embedding,
            createdAt: s.createdAt,
          );
        }
      }
    }
  }

  @override
  Future<void> renameSpeakerByLabel({
    required String workspaceId,
    required String meetingId,
    required MeetingSpeaker channel,
    required String label,
    required String? displayName,
  }) async {
    final list = speakersByMeeting[meetingId] ??= [];
    final i = list.indexWhere(
      (s) =>
          s.workspaceId == workspaceId &&
          s.channel == channel &&
          s.label == label,
    );
    if (i >= 0) {
      final s = list[i];
      list[i] = MeetingSpeakerLabel(
        id: s.id,
        meetingId: s.meetingId,
        workspaceId: s.workspaceId,
        channel: s.channel,
        label: s.label,
        displayName: displayName,
        embedding: s.embedding,
        createdAt: s.createdAt,
      );
      return;
    }
    list.add(MeetingSpeakerLabel(
      id: 'sp_${meetingId}_$label',
      meetingId: meetingId,
      workspaceId: workspaceId,
      channel: channel,
      label: label,
      displayName: displayName,
      createdAt: DateTime(2026),
    ));
  }
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

/// Minimal voice-profile repository fake: holds profiles per workspace and
/// records enrollments, so the identify/save bodies can be exercised.
class _FakeVoiceProfileRepository implements VoiceProfileRepository {
  final Map<String, List<VoiceProfile>> _byWorkspace = {};
  final List<({String workspaceId, String name, List<double> embedding})>
      enrollments = [];

  void seed(VoiceProfile profile) =>
      (_byWorkspace[profile.workspaceId] ??= []).add(profile);

  @override
  Future<List<VoiceProfile>> getByWorkspace(String workspaceId) async =>
      List.of(_byWorkspace[workspaceId] ?? const []);

  @override
  Stream<List<VoiceProfile>> watchByWorkspace(String workspaceId) =>
      Stream.value(List.of(_byWorkspace[workspaceId] ?? const []));

  @override
  Future<VoiceProfile?> getByName(String workspaceId, String displayName) async {
    for (final p in _byWorkspace[workspaceId] ?? const <VoiceProfile>[]) {
      if (p.displayName == displayName) {
        return p;
      }
    }
    return null;
  }

  @override
  Future<void> enroll({
    required String workspaceId,
    required String displayName,
    required List<double> sampleEmbedding,
  }) async {
    enrollments
        .add((workspaceId: workspaceId, name: displayName, embedding: sampleEmbedding));
  }

  @override
  Future<void> upsert(VoiceProfile profile) async => seed(profile);

  @override
  Future<void> unenroll({
    required String workspaceId,
    required String displayName,
    required List<double> sampleEmbedding,
  }) async {}

  @override
  Future<void> rename({
    required String workspaceId,
    required String id,
    required String displayName,
  }) async {}

  @override
  Future<void> delete(String workspaceId, String id) async {}
}

VoiceProfile _profile(
  String ws,
  String name,
  List<double> embedding, {
  String? id,
}) {
  final now = DateTime(2026, 1, 1);
  return VoiceProfile(
    id: id ?? 'vp_$name',
    workspaceId: ws,
    displayName: name,
    embedding: embedding,
    createdAt: now,
    updatedAt: now,
  );
}

MeetingSpeakerLabel _speaker(
  String ws,
  String meetingId,
  String label, {
  String? displayName,
  List<double>? embedding,
}) {
  return MeetingSpeakerLabel(
    id: 'sp_${meetingId}_$label',
    meetingId: meetingId,
    workspaceId: ws,
    channel: MeetingSpeaker.them,
    label: label,
    displayName: displayName,
    embedding: embedding,
    createdAt: DateTime(2026, 1, 1),
  );
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
  late _FakeVoiceProfileRepository voiceRepo;
  late PipelineBodyRegistry registry;

  setUp(() {
    repo = _FakeMeetingRepository();
    voiceRepo = _FakeVoiceProfileRepository();
    registry = PipelineBodyRegistry();
    registerMeetingBodies(
      registry,
      meetingRepository: repo,
      voiceProfileRepository: voiceRepo,
      diarizationModelManager: DiarizationModelManager(
        paths: CcPaths(Directory.systemTemp.path),
      ),
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

  group('meeting.assemblePlayback', () {
    test('mixes the retained WAVs into mixed.wav', () async {
      final dir = await Directory.systemTemp.createTemp('assemble_test');
      addTearDown(() async {
        if (dir.existsSync()) {
          await dir.delete(recursive: true);
        }
      });
      await writeMonoWav(
        p.join(dir.path, 'me.wav'),
        Float32List.fromList(List.filled(4000, 0.2)),
      );
      await writeMonoWav(
        p.join(dir.path, 'them.wav'),
        Float32List.fromList(List.filled(4000, 0.3)),
      );
      repo.seed(_processing('m1', 'w1').copyWith(audioPath: dir.path));

      final result =
          await registry.body(BuiltInBodyKeys.meetingAssemblePlayback)(
        _ctx(workspaceId: 'w1', meetingId: 'm1', outcome: const {}),
      );

      expect(result.errorMessage, isNull);
      expect(result.mutatedState?['playbackAssembled'], isTrue);
      expect(File(p.join(dir.path, 'mixed.wav')).existsSync(), isTrue);
    });

    test('is a no-op when the meeting kept no audio', () async {
      repo.seed(_processing('m1', 'w1')); // audioPath null
      final result =
          await registry.body(BuiltInBodyKeys.meetingAssemblePlayback)(
        _ctx(workspaceId: 'w1', meetingId: 'm1', outcome: const {}),
      );
      expect(result.errorMessage, isNull);
      expect(result.mutatedState?['playbackAssembled'], isFalse);
    });

    test('a foreign-workspace meeting fails the step', () async {
      repo.seed(_processing('m1', 'w1'));
      final result =
          await registry.body(BuiltInBodyKeys.meetingAssemblePlayback)(
        _ctx(workspaceId: 'w2', meetingId: 'm1', outcome: const {}),
      );
      expect(result.errorMessage, isNotNull);
    });
  });

  group('meeting.identifySpeakers (voiceprint recognition)', () {
    test('auto-applies a confident voice-profile match', () async {
      repo.seed(_processing('m1', 'w1'));
      repo.seedSpeakers('m1', [
        _speaker('w1', 'm1', 'Person 1', embedding: const [1, 0, 0]),
      ]);
      voiceRepo.seed(_profile('w1', 'Alex', const [1, 0, 0])); // cosine 1.0

      final result = await registry
          .body(BuiltInBodyKeys.meetingIdentifySpeakers)(
        _ctx(workspaceId: 'w1', meetingId: 'm1', outcome: const {}),
      );

      expect(result.errorMessage, isNull);
      expect(result.mutatedState?['meetingSpeakersRecognized'], 1);
      expect(repo.renames['sp_m1_Person 1'], 'Alex');
      // The transcript is rewritten so summarize sees the recognized name.
      expect(result.mutatedState?.containsKey('transcript'), isTrue);
    });

    test('leaves "Person N" when the best match is below the auto threshold',
        () async {
      repo.seed(_processing('m1', 'w1'));
      // cosine([1,0],[0.6,0.8]) = 0.6 — plausible (suggest) but not confident.
      repo.seedSpeakers('m1', [
        _speaker('w1', 'm1', 'Person 1', embedding: const [1, 0]),
      ]);
      voiceRepo.seed(_profile('w1', 'Alex', const [0.6, 0.8]));

      final result = await registry
          .body(BuiltInBodyKeys.meetingIdentifySpeakers)(
        _ctx(workspaceId: 'w1', meetingId: 'm1', outcome: const {}),
      );

      expect(result.mutatedState?['meetingSpeakersRecognized'], 0);
      expect(repo.renames, isEmpty);
    });

    test('never overrides a speaker that already has a name (user/prior wins)',
        () async {
      repo.seed(_processing('m1', 'w1'));
      repo.seedSpeakers('m1', [
        _speaker('w1', 'm1', 'Person 1',
            displayName: 'Bob', embedding: const [1, 0, 0]),
      ]);
      voiceRepo.seed(_profile('w1', 'Alex', const [1, 0, 0])); // cosine 1.0

      final result = await registry
          .body(BuiltInBodyKeys.meetingIdentifySpeakers)(
        _ctx(workspaceId: 'w1', meetingId: 'm1', outcome: const {}),
      );

      expect(result.mutatedState?['meetingSpeakersRecognized'], 0);
      expect(repo.renames, isEmpty);
    });

    test('is a no-op when the workspace has no saved profiles', () async {
      repo.seed(_processing('m1', 'w1'));
      repo.seedSpeakers('m1', [
        _speaker('w1', 'm1', 'Person 1', embedding: const [1, 0, 0]),
      ]);

      final result = await registry
          .body(BuiltInBodyKeys.meetingIdentifySpeakers)(
        _ctx(workspaceId: 'w1', meetingId: 'm1', outcome: const {}),
      );

      expect(result.mutatedState?['meetingSpeakersRecognized'], 0);
      expect(repo.renames, isEmpty);
    });
  });

  group('meeting.saveNotes (LLM speaker-name inference)', () {
    test('applies inferred names only to still-unnamed speakers', () async {
      repo.seed(_processing('m1', 'w1'));
      repo.seedSpeakers('m1', [
        _speaker('w1', 'm1', 'Person 1'), // unnamed
        _speaker('w1', 'm1', 'Person 2', displayName: 'Alex'), // already named
      ]);

      await registry.body(BuiltInBodyKeys.meetingSaveNotes)(
        _ctx(
          workspaceId: 'w1',
          meetingId: 'm1',
          outcome: const {
            'enhancedNotes': '# Notes',
            'speakerNames': {'Person 1': 'Dana', 'Person 2': 'Jordan'},
          },
        ),
      );

      // Person 1 (unnamed) gets the inferred name; Person 2 (named by a
      // voiceprint/user) is never overwritten by the LLM.
      expect(repo.renames['sp_m1_Person 1'], 'Dana');
      expect(repo.renames.containsKey('sp_m1_Person 2'), isFalse);
    });

    test('ignores inferred names for labels with no matching speaker', () async {
      repo.seed(_processing('m1', 'w1'));
      repo.seedSpeakers('m1', [_speaker('w1', 'm1', 'Person 1')]);

      await registry.body(BuiltInBodyKeys.meetingSaveNotes)(
        _ctx(
          workspaceId: 'w1',
          meetingId: 'm1',
          outcome: const {
            'enhancedNotes': '# Notes',
            'speakerNames': {'Person 9': 'Ghost'},
          },
        ),
      );

      expect(repo.renames, isEmpty);
    });
  });
}
