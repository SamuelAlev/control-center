import 'package:control_center/core/infrastructure/audio/wav_io.dart';
import 'package:control_center/core/infrastructure/speech/diarization_model_manager.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/meetings/domain/entities/meeting.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_decision.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_segment.dart';
import 'package:control_center/features/meetings/domain/entities/meeting_speaker_label.dart';
import 'package:control_center/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:control_center/features/meetings/domain/services/meeting_diarization.dart';
import 'package:control_center/features/meetings/domain/services/meeting_outcome.dart';
import 'package:control_center/features/meetings/domain/services/meeting_transcript_formatter.dart';
import 'package:control_center/features/memory/domain/usecases/record_memory_fact_use_case.dart';
import 'package:control_center/features/memory/domain/value_objects/system_memory_domains.dart';
import 'package:control_center/features/pipelines/domain/entities/step_result.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_context.dart';
import 'package:control_center/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Registers the deterministic `meeting.*` persist bodies used by the built-in
/// `meeting_summary` pipeline.
///
/// The pipeline's agent step returns ONE structured payload —
/// `{summary, enhancedNotes, actionItems[], decisions[]}` (see [MeetingOutcome])
/// — through the pipeline task-output channel, which the engine writes under the
/// step's `outputKey` (`meetingOutcome`). These bodies read that payload from
/// state and persist each part into its own table, so action items / decisions
/// are reliable structured rows rather than text scraped out of the notes
/// markdown. Each body re-fetches the meeting scoped to `workspaceId`, so a
/// run that somehow targets a foreign meeting simply fails rather than leaking.
void registerMeetingBodies(
  PipelineBodyRegistry registry, {
  required MeetingRepository meetingRepository,
  required DiarizationModelManager diarizationModelManager,
  required MeetingDiarizationPort diarizationService,
  RecordMemoryFactUseCase? recordFact,
}) {
  const uuid = Uuid();

  /// Loads the owned meeting + the parsed outcome, or null when the meeting is
  /// missing / belongs to another workspace (the caller fails the step).
  Future<(Meeting, MeetingOutcome)?> load(PipelineContext ctx) async {
    final meetingId = ctx.optional<String>('meetingId');
    if (meetingId == null || meetingId.isEmpty) {
      return null;
    }
    final meeting = await meetingRepository.getById(ctx.workspaceId, meetingId);
    if (meeting == null) {
      return null;
    }
    return (meeting, MeetingOutcome.parse(ctx.state['meetingOutcome']));
  }

  // meeting.diarize — offline speaker diarization (entry step of the
  // meeting_summary pipeline). Relabels the transcript segments of the
  // diarizable channel (remote → "them"; in-person → the mic) into individual
  // speakers ("Person 1", …) and rewrites the `transcript` state so the
  // downstream summarize step sees per-speaker context. Degrades to a no-op
  // (the original transcript flows through unchanged) when audio wasn't
  // retained, the models aren't installed, or diarization yields nothing — so a
  // missing/failed diarization never blocks summarization.
  registry.registerBody(BuiltInBodyKeys.meetingDiarize, (ctx) async {
    final meetingId = ctx.optional<String>('meetingId');
    if (meetingId == null || meetingId.isEmpty) {
      return StepResult.failed('meeting.diarize: missing meetingId');
    }
    final meeting = await meetingRepository.getById(ctx.workspaceId, meetingId);
    if (meeting == null) {
      return StepResult.failed(
        'meeting.diarize: meeting not found in this workspace',
      );
    }
    try {
      final audioDir = meeting.audioPath;
      final modelPaths = await diarizationModelManager.resolve();
      if (audioDir == null || audioDir.isEmpty) {
        AppLog.i(
          'meeting.diarize',
          'skipped: no retained audio (audioPath empty) — diarization models '
              'must be installed BEFORE recording for audio to be kept',
        );
        return StepResult.ok(mutatedState: const {'meetingDiarized': false});
      }
      if (modelPaths == null) {
        AppLog.i(
          'meeting.diarize',
          'skipped: diarization models not resolved on disk',
        );
        return StepResult.ok(mutatedState: const {'meetingDiarized': false});
      }

      // Remote meetings diarize the "them" channel; in-person diarizes the mic.
      final channel = meeting.mode == MeetingMode.inPerson
          ? MeetingSpeaker.me
          : MeetingSpeaker.them;
      final wavName = channel == MeetingSpeaker.me ? 'me.wav' : 'them.wav';
      final wav = await readWavToFloat32(p.join(audioDir, wavName));
      if (wav.samples.isEmpty) {
        AppLog.i(
          'meeting.diarize',
          'skipped: $wavName has no audio samples (the capture channel was '
              'empty for this recording)',
        );
        return StepResult.ok(mutatedState: const {'meetingDiarized': false});
      }

      final spans = await diarizationService.diarize(
        segmentationModelPath: modelPaths.segmentation,
        embeddingModelPath: modelPaths.embedding,
        samples: wav.samples,
      );
      if (spans.isEmpty) {
        AppLog.i(
          'meeting.diarize',
          'skipped: diarization produced no speaker spans for $wavName',
        );
        return StepResult.ok(mutatedState: const {'meetingDiarized': false});
      }

      // Assign each transcript segment on the channel the dominant speaker.
      final segments =
          await meetingRepository.getSegments(ctx.workspaceId, meetingId);
      final labels = <String>{};
      for (final seg in segments) {
        if (seg.speaker != channel) {
          continue;
        }
        final idx = assignSpeakerByOverlap(spans, seg.startMs, seg.endMs);
        if (idx == null) {
          continue;
        }
        final label = personLabel(idx);
        labels.add(label);
        await meetingRepository.setSegmentSpeakerLabel(
          ctx.workspaceId,
          seg.id,
          label,
        );
      }
      if (labels.isEmpty) {
        AppLog.i(
          'meeting.diarize',
          'skipped: no "$channel" transcript segments overlapped a speaker '
              'span (diarized ${spans.length} span(s))',
        );
        return StepResult.ok(mutatedState: const {'meetingDiarized': false});
      }
      AppLog.i(
        'meeting.diarize',
        'diarized $wavName into ${labels.length} speaker(s) across '
            '${spans.length} span(s)',
      );

      // Persist the distinct speakers (carrying forward any prior renames).
      final now = DateTime.now();
      final sortedLabels = labels.toList()..sort();
      await meetingRepository.replaceSpeakers(
        ctx.workspaceId,
        meetingId,
        [
          for (final label in sortedLabels)
            MeetingSpeakerLabel(
              id: uuid.v4(),
              meetingId: meetingId,
              workspaceId: ctx.workspaceId,
              channel: channel,
              label: label,
              createdAt: now,
            ),
        ],
      );

      // Rewrite the transcript from the now-relabeled segments so the summarize
      // step (which reads {{transcript}} from state) sees per-speaker context.
      final relabeled =
          await meetingRepository.getSegments(ctx.workspaceId, meetingId);
      final speakers =
          await meetingRepository.getSpeakers(ctx.workspaceId, meetingId);
      final displayNames = <String, String>{
        for (final s in speakers)
          if (s.displayName != null && s.displayName!.isNotEmpty)
            s.label: s.displayName!,
      };
      final transcript =
          formatMeetingTranscript(relabeled, displayNames: displayNames);
      return StepResult.ok(
        mutatedState: {
          'transcript': transcript,
          'meetingDiarized': true,
          'meetingSpeakerCount': labels.length,
          // Hand the raw spans to the parallel updateTranscript step so it can
          // re-separate the transcript into clean per-speaker turns without
          // re-running the (CPU-heavy) clustering.
          'diarizationSpans': encodeDiarizedSpans(spans),
        },
      );
    } catch (e, s) {
      // Never block summarization on diarization — fall through with the
      // original transcript (left untouched in state).
      AppLog.w('meeting.diarize', 'diarization skipped: $e\n$s');
      return StepResult.ok(mutatedState: const {'meetingDiarized': false});
    }
  });

  // meeting.updateTranscript — runs IN PARALLEL with the summarize step (both
  // fan out from diarize). Takes the diarization spans the diarize step emitted
  // and rewrites the meeting's transcript into clean per-speaker turns: each
  // window is tagged with its dominant `Person N`, and consecutive same-speaker
  // fragments are merged into one turn. The cleaned segments are persisted with
  // `replaceSegments`; the live transcript UI (which watches segments) updates
  // as soon as this lands. Best-effort — a no-op when diarization produced no
  // spans, so it never blocks the run's completion (the terminal joins it).
  registry.registerBody(BuiltInBodyKeys.meetingUpdateTranscript, (ctx) async {
    final meetingId = ctx.optional<String>('meetingId');
    if (meetingId == null || meetingId.isEmpty) {
      return StepResult.failed('meeting.updateTranscript: missing meetingId');
    }
    final diarized = ctx.state['meetingDiarized'] == true;
    final spansJson = ctx.optional<String>('diarizationSpans');
    if (!diarized || spansJson == null || spansJson.isEmpty) {
      return StepResult.ok(
        mutatedState: const {'meetingTranscriptUpdated': false},
      );
    }
    try {
      final meeting =
          await meetingRepository.getById(ctx.workspaceId, meetingId);
      if (meeting == null) {
        return StepResult.failed(
          'meeting.updateTranscript: meeting not found in this workspace',
        );
      }
      final spans = decodeDiarizedSpans(spansJson);
      if (spans.isEmpty) {
        return StepResult.ok(
          mutatedState: const {'meetingTranscriptUpdated': false},
        );
      }
      // Same channel diarize clustered: remote → "them", in-person → the mic.
      final channel = meeting.mode == MeetingMode.inPerson
          ? MeetingSpeaker.me
          : MeetingSpeaker.them;
      final segments =
          await meetingRepository.getSegments(ctx.workspaceId, meetingId);
      final separated = separateTranscriptBySpeaker(
        segments: segments,
        spans: spans,
        channel: channel,
      );
      await meetingRepository.replaceSegments(
        ctx.workspaceId,
        meetingId,
        separated,
      );
      AppLog.i(
        'meeting.updateTranscript',
        'rewrote transcript into ${separated.length} turn(s) '
            '(from ${segments.length} window(s))',
      );
      return StepResult.ok(
        mutatedState: {
          'meetingTranscriptUpdated': true,
          'meetingTranscriptTurns': separated.length,
        },
      );
    } catch (e, s) {
      AppLog.w('meeting.updateTranscript', 'transcript update skipped: $e\n$s');
      return StepResult.ok(
        mutatedState: const {'meetingTranscriptUpdated': false},
      );
    }
  });

  // meeting.saveNotes — clean summary + enhanced notes. Does NOT change status:
  // the meeting reaches `done` via MeetingSummaryReconciler once the whole run
  // terminates (so a sibling persist failure can't leave it half-finished while
  // already marked done). Runs in parallel with the action-item / decision
  // steps; the recording's notes are preserved even if a sibling fails.
  registry.registerBody(BuiltInBodyKeys.meetingSaveNotes, (ctx) async {
    final loaded = await load(ctx);
    if (loaded == null) {
      return StepResult.failed(
        'meeting.saveNotes: meeting not found in this workspace',
      );
    }
    final (meeting, outcome) = loaded;
    await meetingRepository.upsert(
      meeting.copyWith(
        summary: outcome.summary,
        // Keep existing notes if the agent produced none (degraded output).
        enhancedNotes: outcome.enhancedNotes ?? meeting.enhancedNotes,
        updatedAt: DateTime.now(),
      ),
    );
    return StepResult.ok(mutatedState: const {'meetingNotesSaved': true});
  });

  // meeting.addActionItems — replaces the meeting's action items with the
  // agent's structured list (replace = idempotent re-run; the repository
  // carries forward each item's `done` + `ticketId` by content). SKIPS when the
  // agent produced no structured output (markdown-only / nothing), so a degraded
  // run never wipes previously-saved action items.
  registry.registerBody(BuiltInBodyKeys.meetingAddActionItems, (ctx) async {
    final loaded = await load(ctx);
    if (loaded == null) {
      return StepResult.failed(
        'meeting.addActionItems: meeting not found in this workspace',
      );
    }
    final (meeting, outcome) = loaded;
    if (!outcome.isStructured) {
      return StepResult.ok(mutatedState: const {'meetingActionItemsSkipped': true});
    }
    final now = DateTime.now();
    final items = <MeetingActionItem>[
      for (var i = 0; i < outcome.actionItems.length; i++)
        MeetingActionItem(
          id: uuid.v4(),
          meetingId: meeting.id,
          workspaceId: ctx.workspaceId,
          content: outcome.actionItems[i].text,
          owner: outcome.actionItems[i].owner,
          sortOrder: i,
          createdAt: now,
        ),
    ];
    await meetingRepository.replaceActionItems(
      ctx.workspaceId,
      meeting.id,
      items,
    );
    return StepResult.ok(
      mutatedState: {'meetingActionItemCount': items.length},
    );
  });

  // meeting.addDecisions — replaces the meeting's decisions with the agent's
  // structured list. SKIPS on non-structured output (same rationale as
  // addActionItems — never wipe previously-saved decisions on a degraded run).
  registry.registerBody(BuiltInBodyKeys.meetingAddDecisions, (ctx) async {
    final loaded = await load(ctx);
    if (loaded == null) {
      return StepResult.failed(
        'meeting.addDecisions: meeting not found in this workspace',
      );
    }
    final (meeting, outcome) = loaded;
    if (!outcome.isStructured) {
      return StepResult.ok(mutatedState: const {'meetingDecisionsSkipped': true});
    }
    final now = DateTime.now();
    final decisions = <MeetingDecision>[
      for (var i = 0; i < outcome.decisions.length; i++)
        MeetingDecision(
          id: uuid.v4(),
          meetingId: meeting.id,
          workspaceId: ctx.workspaceId,
          content: outcome.decisions[i],
          sortOrder: i,
          createdAt: now,
        ),
    ];
    await meetingRepository.replaceDecisions(
      ctx.workspaceId,
      meeting.id,
      decisions,
    );

    // Cross-feature memory: surface each decision as a fact in the shared
    // `decisions` domain so an agent working a ticket can recall what was
    // decided in a meeting. Best-effort — never fails the persist step.
    if (recordFact != null && decisions.isNotEmpty) {
      final topic = '${meeting.title} — meeting ${_short(meeting.id)}';
      try {
        for (final d in decisions) {
          await recordFact.record(
            workspaceId: ctx.workspaceId,
            domain: SystemMemoryDomains.decisions,
            topic: topic,
            content: d.content,
          );
        }
        await recordFact.reconcileTopic(
          workspaceId: ctx.workspaceId,
          topic: topic,
          liveContents: {for (final d in decisions) d.content},
        );
      } on Object catch (e) {
        AppLog.w('meeting.addDecisions', 'memory harvest skipped: $e');
      }
    }
    return StepResult.ok(
      mutatedState: {'meetingDecisionCount': decisions.length},
    );
  });
}

String _short(String s) => s.length <= 8 ? s : s.substring(0, 8);
