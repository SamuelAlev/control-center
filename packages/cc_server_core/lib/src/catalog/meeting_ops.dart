import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_domain/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart' show DictationService, MeetingAudioRequest, MeetingRecordingService, loadMeetingAudioClip;

import 'package:cc_server_core/src/catalog/catalog_wire.dart';

/// Builds the `meeting.*` + `dictation.*` repo-ops that the catalog spreads.
///
/// Workspace-scoped at the [meetingRepository]. Handlers that reference the
/// recording / dictation services are guarded by null — absent when the host
/// has no voice model installed.
List<RepoOp> buildMeetingOps({
  required MeetingRepository meetingRepository,
  MeetingRecordingService? meetingRecording,
  DictationService? dictationService,
}) => [
  RepoOp(
    name: 'meeting.getByWorkspace',
    kind: RepoOpKind.read,
    handler: (ctx) async {
      final meetings = await meetingRepository.getByWorkspace(
        ctx.workspaceId!,
      );
      return {'meetings': meetings.map(meetingToWire).toList()};
    },
  ),
  RepoOp(
    name: 'meeting.getById',
    kind: RepoOpKind.read,
    requiredArgs: ['meeting_id'],
    handler: (ctx) async {
      final meeting = await meetingRepository.getById(
        ctx.workspaceId!,
        ctx.args['meeting_id'] as String,
      );
      return {'meeting': meeting == null ? null : meetingToWire(meeting)};
    },
  ),
  RepoOp(
    name: 'meeting.getSegments',
    kind: RepoOpKind.read,
    requiredArgs: ['meeting_id'],
    handler: (ctx) async {
      final segments = await meetingRepository.getSegments(
        ctx.workspaceId!,
        ctx.args['meeting_id'] as String,
      );
      return {'segments': segments.map(meetingSegmentToWire).toList()};
    },
  ),
  RepoOp(
    name: 'meeting.getSpeakers',
    kind: RepoOpKind.read,
    requiredArgs: ['meeting_id'],
    handler: (ctx) async {
      final speakers = await meetingRepository.getSpeakers(
        ctx.workspaceId!,
        ctx.args['meeting_id'] as String,
      );
      return {'speakers': speakers.map(meetingSpeakerLabelToWire).toList()};
    },
  ),
  RepoOp(
    name: 'meeting.audioClip',
    kind: RepoOpKind.read,
    requiredArgs: ['meeting_id'],
    handler: (ctx) async {
      final meeting = await meetingRepository.getById(
        ctx.workspaceId!,
        ctx.args['meeting_id'] as String,
      );
      final dir = meeting?.audioPath;
      if (meeting == null || dir == null || dir.isEmpty) {
        return {'available': false};
      }
      final clip = await loadMeetingAudioClip(
        MeetingAudioRequest(audioDirPath: dir),
      );
      if (clip == null) {
        return {'available': false};
      }
      return {
        'available': true,
        'waveform': clip.waveform,
        'duration_ms': clip.durationMs,
      };
    },
  ),
  RepoOp(
    name: 'meeting.delete',
    kind: RepoOpKind.mutate,
    requiredArgs: ['meeting_id'],
    handler: (ctx) async {
      await meetingRepository.delete(
        ctx.workspaceId!,
        ctx.args['meeting_id'] as String,
      );
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'meeting.updateTitle',
    kind: RepoOpKind.mutate,
    requiredArgs: ['meeting_id', 'title'],
    handler: (ctx) async {
      await meetingRepository.updateTitle(
        workspaceId: ctx.workspaceId!,
        meetingId: ctx.args['meeting_id'] as String,
        title: ctx.args['title'] as String,
      );
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'meeting.updateNotes',
    kind: RepoOpKind.mutate,
    requiredArgs: ['meeting_id', 'notes'],
    handler: (ctx) async {
      await meetingRepository.updateNotes(
        workspaceId: ctx.workspaceId!,
        meetingId: ctx.args['meeting_id'] as String,
        notes: ctx.args['notes'] as String,
      );
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'meeting.setSegmentSpeakerName',
    kind: RepoOpKind.mutate,
    requiredArgs: ['segment_id'],
    handler: (ctx) async {
      await meetingRepository.setSegmentSpeakerName(
        ctx.workspaceId!,
        ctx.args['segment_id'] as String,
        ctx.args['name'] as String?,
      );
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'meeting.renameSpeakerByLabel',
    kind: RepoOpKind.mutate,
    requiredArgs: ['meeting_id', 'channel', 'label'],
    handler: (ctx) async {
      await meetingRepository.renameSpeakerByLabel(
        workspaceId: ctx.workspaceId!,
        meetingId: ctx.args['meeting_id'] as String,
        channel: MeetingSpeaker.fromStorage(ctx.args['channel'] as String?),
        label: ctx.args['label'] as String,
        displayName: ctx.args['display_name'] as String?,
      );
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'meeting.clearSpeakerNameOverridesForLabel',
    kind: RepoOpKind.mutate,
    requiredArgs: ['meeting_id', 'channel', 'label'],
    handler: (ctx) async {
      await meetingRepository.clearSpeakerNameOverridesForLabel(
        workspaceId: ctx.workspaceId!,
        meetingId: ctx.args['meeting_id'] as String,
        channel: MeetingSpeaker.fromStorage(ctx.args['channel'] as String?),
        label: ctx.args['label'] as String,
      );
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'meeting.setSpeakerEnrolledProfile',
    kind: RepoOpKind.mutate,
    requiredArgs: ['meeting_id', 'channel', 'label'],
    handler: (ctx) async {
      await meetingRepository.setSpeakerEnrolledProfile(
        workspaceId: ctx.workspaceId!,
        meetingId: ctx.args['meeting_id'] as String,
        channel: MeetingSpeaker.fromStorage(ctx.args['channel'] as String?),
        label: ctx.args['label'] as String,
        profileName: ctx.args['profile_name'] as String?,
      );
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'meeting.addActionItem',
    kind: RepoOpKind.mutate,
    requiredArgs: ['item'],
    handler: (ctx) async {
      final item = meetingActionItemFromWire(
        (ctx.args['item'] as Map).cast<String, dynamic>(),
      );
      if (item.workspaceId != ctx.workspaceId) {
        throw const WorkspaceMismatchException(
          'Meeting action item belongs to a different workspace',
        );
      }
      await meetingRepository.addActionItem(item);
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'meeting.updateActionItem',
    kind: RepoOpKind.mutate,
    requiredArgs: ['id', 'content'],
    handler: (ctx) async {
      await meetingRepository.updateActionItem(
        workspaceId: ctx.workspaceId!,
        id: ctx.args['id'] as String,
        content: ctx.args['content'] as String,
        owner: ctx.args['owner'] as String?,
      );
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'meeting.deleteActionItem',
    kind: RepoOpKind.mutate,
    requiredArgs: ['id'],
    handler: (ctx) async {
      await meetingRepository.deleteActionItem(
        ctx.workspaceId!,
        ctx.args['id'] as String,
      );
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'meeting.setActionItemDone',
    kind: RepoOpKind.mutate,
    requiredArgs: ['id', 'done'],
    handler: (ctx) async {
      await meetingRepository.setActionItemDone(
        workspaceId: ctx.workspaceId!,
        id: ctx.args['id'] as String,
        done: ctx.args['done'] as bool,
      );
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'meeting.setActionItemTicket',
    kind: RepoOpKind.mutate,
    requiredArgs: ['id', 'ticket_id'],
    handler: (ctx) async {
      await meetingRepository.setActionItemTicket(
        workspaceId: ctx.workspaceId!,
        id: ctx.args['id'] as String,
        ticketId: ctx.args['ticket_id'] as String,
      );
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'meeting.addDecision',
    kind: RepoOpKind.mutate,
    requiredArgs: ['decision'],
    handler: (ctx) async {
      final decision = meetingDecisionFromWire(
        (ctx.args['decision'] as Map).cast<String, dynamic>(),
      );
      if (decision.workspaceId != ctx.workspaceId) {
        throw const WorkspaceMismatchException(
          'Meeting decision belongs to a different workspace',
        );
      }
      await meetingRepository.addDecision(decision);
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'meeting.updateDecision',
    kind: RepoOpKind.mutate,
    requiredArgs: ['id', 'content'],
    handler: (ctx) async {
      await meetingRepository.updateDecision(
        workspaceId: ctx.workspaceId!,
        id: ctx.args['id'] as String,
        content: ctx.args['content'] as String,
      );
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'meeting.deleteDecision',
    kind: RepoOpKind.mutate,
    requiredArgs: ['id'],
    handler: (ctx) async {
      await meetingRepository.deleteDecision(
        ctx.workspaceId!,
        ctx.args['id'] as String,
      );
      return {'ok': true};
    },
  ),
  if (meetingRecording != null) ...[
    RepoOp(
      name: 'meeting.startRecording',
      kind: RepoOpKind.mutate,
      requiredArgs: ['title', 'mode'],
      handler: (ctx) async {
        final meetingId = await meetingRecording.start(
          workspaceId: ctx.workspaceId!,
          title: ctx.args['title'] as String,
          mode: ctx.args['mode'] as String,
        );
        return {'ok': true, 'meeting_id': meetingId};
      },
    ),
    RepoOp(
      name: 'meeting.ingestAudio',
      kind: RepoOpKind.mutate,
      requiredArgs: ['meeting_id', 'channel', 'seq', 'pcm'],
      handler: (ctx) async {
        await meetingRecording.ingest(
          workspaceId: ctx.workspaceId!,
          meetingId: ctx.args['meeting_id'] as String,
          channel: ctx.args['channel'] as String,
          seq: (ctx.args['seq'] as num).toInt(),
          pcm: base64Decode(ctx.args['pcm'] as String),
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'meeting.stopRecording',
      kind: RepoOpKind.mutate,
      requiredArgs: ['meeting_id'],
      handler: (ctx) async {
        await meetingRecording.stop(
          workspaceId: ctx.workspaceId!,
          meetingId: ctx.args['meeting_id'] as String,
          summaryInstructions: ctx.args['summary_instructions'] as String?,
        );
        return {'ok': true};
      },
    ),
  ],
  if (dictationService != null) ...[
    RepoOp(
      name: 'dictation.start',
      kind: RepoOpKind.mutate,
      handler: (ctx) async {
        final id = dictationService.start(ctx.workspaceId!);
        return {'ok': true, 'dictation_id': id};
      },
    ),
    RepoOp(
      name: 'dictation.ingestAudio',
      kind: RepoOpKind.mutate,
      requiredArgs: ['dictation_id', 'pcm'],
      handler: (ctx) async {
        dictationService.ingest(
          ctx.args['dictation_id'] as String,
          base64Decode(ctx.args['pcm'] as String),
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'dictation.stop',
      kind: RepoOpKind.mutate,
      requiredArgs: ['dictation_id'],
      handler: (ctx) async {
        await dictationService.stop(ctx.args['dictation_id'] as String);
        return {'ok': true};
      },
    ),
  ],
];
