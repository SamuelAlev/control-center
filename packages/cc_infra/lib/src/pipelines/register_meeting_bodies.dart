import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_decision.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_speaker_label.dart';
import 'package:cc_domain/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:cc_domain/features/meetings/domain/repositories/voice_profile_repository.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_diarization.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_notes_merge.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_outcome.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_transcript_formatter.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_waveform.dart';
import 'package:cc_domain/features/meetings/domain/services/voice_profile_matching.dart';
import 'package:cc_domain/features/memory/domain/usecases/record_memory_fact_use_case.dart';
import 'package:cc_domain/features/memory/domain/value_objects/system_memory_domains.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/speech/diarization_model_manager.dart';
import 'package:cc_infra/src/util/wav_io.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

// Logging shims → cc_infra's CcInfraLog (the package cannot import the app's
// AppLog). Fold the tag into the message to match CcInfraLog's tagless API.
void _logI(String tag, String msg) => CcInfraLog.info('$tag: $msg');
void _logW(String tag, String msg) => CcInfraLog.warning('$tag: $msg');

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
  required VoiceProfileRepository voiceProfileRepository,
  required DiarizationModelManager diarizationModelManager,
  required MeetingDiarizationPort diarizationService,
  RecordMemoryFactUseCase? recordFact,
  AttendeeNamesResolver? attendeeNamesFor,
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
        _logI(
          'meeting.diarize',
          'skipped: no retained audio (audioPath empty) — diarization models '
              'must be installed BEFORE recording for audio to be kept',
        );
        return StepResult.ok(mutatedState: const {'meetingDiarized': false});
      }
      if (modelPaths == null) {
        _logI(
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
        _logI(
          'meeting.diarize',
          'skipped: $wavName has no audio samples (the capture channel was '
              'empty for this recording)',
        );
        return StepResult.ok(mutatedState: const {'meetingDiarized': false});
      }

      final diarization = await diarizationService.diarize(
        segmentationModelPath: modelPaths.segmentation,
        embeddingModelPath: modelPaths.embedding,
        samples: wav.samples,
      );
      final spans = diarization.spans;
      if (spans.isEmpty) {
        _logI(
          'meeting.diarize',
          'skipped: diarization produced no speaker spans for $wavName',
        );
        return StepResult.ok(mutatedState: const {'meetingDiarized': false});
      }

      // Assign each transcript segment on the channel its dominant speaker.
      // First pass only computes the (segment → cluster) mapping — it writes no
      // labels yet. The labels are persisted *after* the speaker rows below, so
      // a crash mid-step can never leave a segment showing `Person N` with no
      // speaker row (which would make it un-renameable in the transcript UI).
      final segments =
          await meetingRepository.getSegments(ctx.workspaceId, meetingId);
      final assignments = <({String segmentId, int cluster})>[];
      final assigned = <int>{};
      for (final seg in segments) {
        if (seg.speaker != channel) {
          continue;
        }
        final idx = assignSpeakerByOverlap(spans, seg.startMs, seg.endMs);
        if (idx == null) {
          continue;
        }
        assigned.add(idx);
        assignments.add((segmentId: seg.id, cluster: idx));
      }
      if (assigned.isEmpty) {
        _logI(
          'meeting.diarize',
          'skipped: no "$channel" transcript segments overlapped a speaker '
              'span (diarized ${spans.length} span(s))',
        );
        return StepResult.ok(mutatedState: const {'meetingDiarized': false});
      }
      _logI(
        'meeting.diarize',
        'diarized $wavName into ${assigned.length} speaker(s) across '
            '${spans.length} span(s)',
      );

      // Order the assigned clusters by first appearance (earliest span start)
      // so calendar invitees map onto speakers in a sensible default order.
      final firstMs = <int, int>{};
      for (final s in spans) {
        if (!assigned.contains(s.speaker)) {
          continue;
        }
        final cur = firstMs[s.speaker];
        if (cur == null || s.startMs < cur) {
          firstMs[s.speaker] = s.startMs;
        }
      }
      final orderedIdx = assigned.toList()
        ..sort((a, b) => (firstMs[a] ?? 0).compareTo(firstMs[b] ?? 0));

      // Pre-seed display names from the linked event's invitees (best-effort:
      // first-appearance speaker ↔ invitee order; the user can correct via the
      // rename chips). A prior rename always wins — replaceSpeakers carries
      // forward an existing displayName for a matching (channel, label).
      final inviteeNames = attendeeNamesFor == null
          ? const <String>[]
          : await attendeeNamesFor(ctx.workspaceId, meetingId, channel);
      final preSeed = <int, String>{};
      for (var i = 0; i < orderedIdx.length && i < inviteeNames.length; i++) {
        preSeed[orderedIdx[i]] = inviteeNames[i];
      }

      // Persist the distinct speakers (carrying forward any prior renames),
      // tagged with their representative embedding + pre-seeded invitee name.
      final now = DateTime.now();
      await meetingRepository.replaceSpeakers(
        ctx.workspaceId,
        meetingId,
        [
          for (final idx in orderedIdx)
            MeetingSpeakerLabel(
              id: uuid.v4(),
              meetingId: meetingId,
              workspaceId: ctx.workspaceId,
              channel: channel,
              label: personLabel(idx),
              displayName: preSeed[idx],
              embedding: diarization.embeddings[idx],
              createdAt: now,
            ),
        ],
      );

      // Now that the speaker rows exist, label the segments — every `Person N`
      // written here has a matching speaker row to rename.
      for (final a in assignments) {
        await meetingRepository.setSegmentSpeakerLabel(
          ctx.workspaceId,
          a.segmentId,
          personLabel(a.cluster),
        );
      }

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
          'meetingSpeakerCount': assigned.length,
          // Hand the raw spans to the parallel updateTranscript step so it can
          // re-separate the transcript into clean per-speaker turns without
          // re-running the (CPU-heavy) clustering.
          'diarizationSpans': encodeDiarizedSpans(spans),
        },
      );
    } catch (e, s) {
      // Never block summarization on diarization — fall through with the
      // original transcript (left untouched in state).
      _logW('meeting.diarize', 'diarization skipped: $e\n$s');
      return StepResult.ok(mutatedState: const {'meetingDiarized': false});
    }
  });

  // meeting.identifySpeakers — cross-meeting recognition. Runs after diarize
  // (which persisted this meeting's speakers + WeSpeaker embeddings) and before
  // summarize. Matches each still-unnamed speaker's embedding against the
  // workspace's saved voice profiles; a confident cosine match auto-applies the
  // profile's name (a weaker match is left for the rename UI to suggest). When
  // any name is applied, rewrites the `transcript` state so the summarize step
  // sees the recognized names. Best-effort — never blocks summarization.
  //
  // Precedence: only speakers with no name yet are considered, so a name the
  // user set or a prior run already applied (carried forward by replaceSpeakers)
  // is never overwritten.
  registry.registerBody(BuiltInBodyKeys.meetingIdentifySpeakers, (ctx) async {
    final meetingId = ctx.optional<String>('meetingId');
    if (meetingId == null || meetingId.isEmpty) {
      return StepResult.failed('meeting.identifySpeakers: missing meetingId');
    }
    try {
      // Workspace-scoped reads: a foreign meetingId simply yields no speakers.
      final speakers =
          await meetingRepository.getSpeakers(ctx.workspaceId, meetingId);
      if (speakers.isEmpty) {
        return StepResult.ok(
          mutatedState: const {'meetingSpeakersRecognized': 0},
        );
      }
      final profiles =
          await voiceProfileRepository.getByWorkspace(ctx.workspaceId);
      if (profiles.isEmpty) {
        return StepResult.ok(
          mutatedState: const {'meetingSpeakersRecognized': 0},
        );
      }
      var recognized = 0;
      for (final speaker in speakers) {
        if (speaker.displayName != null && speaker.displayName!.isNotEmpty) {
          continue; // user-set or prior auto-match wins — never override
        }
        final embedding = speaker.embedding;
        if (embedding == null || embedding.isEmpty) {
          continue;
        }
        final match = bestVoiceMatch(embedding, profiles);
        if (match == null || !isAutoApply(match)) {
          continue; // below the auto-apply bar: stays "Person N" (UI suggests)
        }
        await meetingRepository.renameSpeaker(
          workspaceId: ctx.workspaceId,
          id: speaker.id,
          displayName: match.profile.displayName,
        );
        recognized++;
      }
      if (recognized == 0) {
        return StepResult.ok(
          mutatedState: const {'meetingSpeakersRecognized': 0},
        );
      }
      _logI(
        'meeting.identifySpeakers',
        'auto-recognized $recognized speaker(s) from saved voice profiles',
      );
      // Rewrite the transcript with the recognized names so the summarize step
      // (which reads {{transcript}} from state) sees them.
      final updatedSpeakers =
          await meetingRepository.getSpeakers(ctx.workspaceId, meetingId);
      final segments =
          await meetingRepository.getSegments(ctx.workspaceId, meetingId);
      final displayNames = <String, String>{
        for (final s in updatedSpeakers)
          if (s.displayName != null && s.displayName!.isNotEmpty)
            s.label: s.displayName!,
      };
      final transcript =
          formatMeetingTranscript(segments, displayNames: displayNames);
      return StepResult.ok(
        mutatedState: {
          'transcript': transcript,
          'meetingSpeakersRecognized': recognized,
        },
      );
    } catch (e, s) {
      _logW('meeting.identifySpeakers', 'recognition skipped: $e\n$s');
      return StepResult.ok(
        mutatedState: const {'meetingSpeakersRecognized': 0},
      );
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
      _logI(
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
      _logW('meeting.updateTranscript', 'transcript update skipped: $e\n$s');
      return StepResult.ok(
        mutatedState: const {'meetingTranscriptUpdated': false},
      );
    }
  });

  // meeting.assemblePlayback — folds the retained per-channel WAVs (me.wav +
  // them.wav) into a single mixed.wav so playback is ready when the meeting
  // opens, instead of being mixed lazily on the UI thread on first view. No-op
  // when no audio was retained. Independent of the summarize agent — runs in
  // parallel with it off the diarize fan-out.
  registry.registerBody(BuiltInBodyKeys.meetingAssemblePlayback, (ctx) async {
    final meetingId = ctx.optional<String>('meetingId');
    if (meetingId == null || meetingId.isEmpty) {
      return StepResult.failed('meeting.assemblePlayback: missing meetingId');
    }
    final meeting = await meetingRepository.getById(ctx.workspaceId, meetingId);
    if (meeting == null) {
      return StepResult.failed(
        'meeting.assemblePlayback: meeting not found in this workspace',
      );
    }
    final dir = meeting.audioPath;
    if (dir == null || dir.isEmpty) {
      return StepResult.ok(mutatedState: const {'playbackAssembled': false});
    }
    try {
      final me = await readWavToFloat32(p.join(dir, 'me.wav'));
      final themFile = File(p.join(dir, 'them.wav'));
      final them = themFile.existsSync()
          ? await readWavToFloat32(themFile.path)
          : WavData(samples: Float32List(0), sampleRate: 16000);
      final mixed = mixTracksToMono([me.samples, them.samples]);
      if (mixed.isEmpty) {
        return StepResult.ok(mutatedState: const {'playbackAssembled': false});
      }
      final sampleRate = me.samples.isNotEmpty ? me.sampleRate : them.sampleRate;
      await writeMonoWav(p.join(dir, 'mixed.wav'), mixed, sampleRate: sampleRate);
      _logI(
        'meeting.assemblePlayback',
        'assembled mixed.wav (${mixed.length} samples @ ${sampleRate}Hz)',
      );
      return StepResult.ok(mutatedState: const {'playbackAssembled': true});
    } catch (e, s) {
      _logW('meeting.assemblePlayback', 'assembly skipped: $e\n$s');
      return StepResult.ok(mutatedState: const {'playbackAssembled': false});
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
    // Preserve the user's own written notes verbatim if the AI dropped any. Operates on the new
    // notes when present, else re-evaluates the existing ones (idempotent).
    final base = outcome.enhancedNotes ?? meeting.enhancedNotes;
    final mergedNotes = mergeManualNotes(
      userNotes: meeting.userNotes,
      enhanced: base,
    );
    // Apply a content-derived title only while the user hasn't named the
    // meeting themselves (and a linked calendar event hasn't), so a generated
    // title never clobbers a deliberate name.
    final generatedTitle = outcome.title?.trim();
    final newTitle = (!meeting.titleIsCustom &&
            generatedTitle != null &&
            generatedTitle.isNotEmpty)
        ? generatedTitle
        : meeting.title;
    await meetingRepository.upsert(
      meeting.copyWith(
        title: newTitle,
        summary: outcome.summary,
        // Keep existing notes if the agent produced none (degraded output).
        enhancedNotes: mergedNotes ?? meeting.enhancedNotes,
        updatedAt: DateTime.now(),
      ),
    );

    // Apply any speaker names the agent inferred from explicit transcript cues
    // ("Hi, I'm Dana"), mapping a diarization label → name. Precedence: only
    // fill speakers that still have NO name — a voiceprint auto-match (which ran
    // in meeting.identifySpeakers, before summarize) or a user rename always
    // wins. Best-effort — a failure here never fails the notes save.
    if (outcome.speakerNames.isNotEmpty) {
      try {
        final speakers =
            await meetingRepository.getSpeakers(ctx.workspaceId, meeting.id);
        final byLabel = {for (final s in speakers) s.label: s};
        for (final entry in outcome.speakerNames.entries) {
          final speaker = byLabel[entry.key];
          if (speaker == null) {
            continue;
          }
          if (speaker.displayName != null && speaker.displayName!.isNotEmpty) {
            continue;
          }
          await meetingRepository.renameSpeaker(
            workspaceId: ctx.workspaceId,
            id: speaker.id,
            displayName: entry.value,
          );
        }
      } on Object catch (e) {
        _logW('meeting.saveNotes', 'speaker-name apply skipped: $e');
      }
    }
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
        _logW('meeting.addDecisions', 'memory harvest skipped: $e');
      }
    }
    return StepResult.ok(
      mutatedState: {'meetingDecisionCount': decisions.length},
    );
  });
}

String _short(String s) => s.length <= 8 ? s : s.substring(0, 8);
