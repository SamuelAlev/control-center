import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart' show RpcMethods;
import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_decision.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_speaker_label.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RpcMeetingRepository] — the meeting read + user-edit surface —
/// over an in-process JSON-RPC host. The repository wraps
/// [RemoteMeetingRepository] (the raw-wire-map delegate) and maps each wire map
/// back to a meeting entity. These tests pin the op name, the args shape, the
/// entity-from-wire mapping, and the [UnsupportedError] host-only guards.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RpcMeetingRepository meetings', () {
    test('watchByWorkspace maps Meeting wire maps', () async {
      host.snapshotFor('meeting.watchByWorkspace', {
        'meetings': [
          {
            'id': 'm-1',
            'workspace_id': 'ws-1',
            'title': 'Sync',
            'status': 'done',
            'mode': 'remote',
            'source_app': 'zoom',
            'user_notes': 'notes',
            'enhanced_notes': 'enhanced',
            'summary': 'the summary',
            'summary_instructions': 'be brief',
            'audio_path': '/a.wav',
            'title_is_custom': true,
            'started_at': '2026-07-01T09:00:00.000',
            'ended_at': '2026-07-01T10:00:00.000',
            'created_at': '2026-07-01T08:00:00.000',
            'updated_at': '2026-07-01T11:00:00.000',
          },
        ],
      });
      final repo = RpcMeetingRepository(client);
      final meetings = await repo.watchByWorkspace('ws-1').first;
      final m = meetings.first;
      expect(m.id, 'm-1');
      expect(m.workspaceId, 'ws-1');
      expect(m.title, 'Sync');
      expect(m.status, MeetingStatus.done);
      expect(m.mode, MeetingMode.remote);
      expect(m.sourceApp, 'zoom');
      expect(m.userNotes, 'notes');
      expect(m.enhancedNotes, 'enhanced');
      expect(m.summary, 'the summary');
      expect(m.summaryInstructions, 'be brief');
      expect(m.audioPath, '/a.wav');
      expect(m.titleIsCustom, isTrue);
      expect(m.startedAt, DateTime(2026, 7, 1, 9));
      expect(m.endedAt, DateTime(2026, 7, 1, 10));
      expect(m.createdAt, DateTime(2026, 7, 1, 8));
      expect(m.updatedAt, DateTime(2026, 7, 1, 11));
      final sub = host.lastSubscribe!;
      expect(sub.query, 'meeting.watchByWorkspace');
      expect(sub.args, isEmpty);
    });

    test(
      'watchByWorkspace tolerates a non-string started_at (epoch)',
      () async {
        host.snapshotFor('meeting.watchByWorkspace', {
          'meetings': [
            {
              'id': 'm-1',
              'workspace_id': 'ws-1',
              'title': 'X',
              'status': 'recording',
            },
          ],
        });
        final repo = RpcMeetingRepository(client);
        final m = (await repo.watchByWorkspace('ws-1').first).first;
        expect(m.startedAt, DateTime.fromMillisecondsSinceEpoch(0));
        expect(m.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
        expect(m.endedAt, isNull);
        expect(m.status, MeetingStatus.recording);
        // A null mode falls back to remote.
        expect(m.mode, MeetingMode.remote);
      },
    );

    test('getByWorkspace maps the list', () async {
      host.callResults['meeting.getByWorkspace'] = {
        'meetings': [
          {'id': 'm-1', 'workspace_id': 'ws-1', 'title': 'A', 'status': 'done'},
        ],
      };
      final repo = RpcMeetingRepository(client);
      final meetings = await repo.getByWorkspace('ws-1');
      expect(meetings.length, 1);
      expect(meetings.first.id, 'm-1');
    });

    test('getById maps a single meeting', () async {
      host.callResults['meeting.getById'] = {
        'meeting': {
          'id': 'm-1',
          'workspace_id': 'ws-1',
          'title': 'Sync',
          'status': 'done',
        },
      };
      final repo = RpcMeetingRepository(client);
      final m = await repo.getById('ws-1', 'm-1');
      expect(m, isNotNull);
      expect(m!.id, 'm-1');
      final call = host.lastCall('meeting.getById')!;
      expect(call.args['meeting_id'], 'm-1');
    });

    test('getById returns null when no meeting is returned', () async {
      host.callResults['meeting.getById'] = const {};
      final repo = RpcMeetingRepository(client);
      expect(await repo.getById('ws-1', 'm-1'), isNull);
    });
  });

  group('RpcMeetingRepository segments', () {
    test('watchSegments maps MeetingSegment wire maps', () async {
      host.snapshotFor('meeting.watchSegments', {
        'segments': [
          {
            'id': 'seg-1',
            'meeting_id': 'm-1',
            'workspace_id': 'ws-1',
            'speaker': 'me',
            'speaker_label': 'Person 1',
            'speaker_name_override': 'Sam',
            'text': 'hello',
            'start_ms': 100,
            'end_ms': 200,
            'created_at': '2026-07-01T09:00:00.000',
          },
        ],
      });
      final repo = RpcMeetingRepository(client);
      final segments = await repo.watchSegments('ws-1', 'm-1').first;
      final s = segments.first;
      expect(s.id, 'seg-1');
      expect(s.meetingId, 'm-1');
      expect(s.workspaceId, 'ws-1');
      expect(s.speaker, MeetingSpeaker.me);
      expect(s.speakerLabel, 'Person 1');
      expect(s.speakerNameOverride, 'Sam');
      expect(s.text, 'hello');
      expect(s.startMs, 100);
      expect(s.endMs, 200);
      expect(s.createdAt, DateTime(2026, 7, 1, 9));
      final sub = host.lastSubscribe!;
      expect(sub.args['meeting_id'], 'm-1');
    });

    test('watchSegments defaults a null speaker to them', () async {
      host.snapshotFor('meeting.watchSegments', {
        'segments': [
          {'id': 'seg-1', 'workspace_id': 'ws-1', 'meeting_id': 'm-1'},
        ],
      });
      final repo = RpcMeetingRepository(client);
      final s = (await repo.watchSegments('ws-1', 'm-1').first).first;
      expect(s.speaker, MeetingSpeaker.them);
      expect(s.text, '');
      expect(s.startMs, 0);
    });

    test('getSegments maps the list', () async {
      host.callResults['meeting.getSegments'] = {
        'segments': [
          {'id': 'seg-1', 'workspace_id': 'ws-1', 'meeting_id': 'm-1'},
        ],
      };
      final repo = RpcMeetingRepository(client);
      final segments = await repo.getSegments('ws-1', 'm-1');
      expect(segments.first.id, 'seg-1');
      final call = host.lastCall('meeting.getSegments')!;
      expect(call.args['meeting_id'], 'm-1');
    });
  });

  group('RpcMeetingRepository speakers', () {
    test('watchSpeakers maps MeetingSpeakerLabel wire maps', () async {
      host.snapshotFor('meeting.watchSpeakers', {
        'speakers': [
          {
            'id': 'sp-1',
            'meeting_id': 'm-1',
            'workspace_id': 'ws-1',
            'channel': 'them',
            'label': 'Person 1',
            'display_name': 'Sam',
            'embedding': [0.1, 0.2],
            'enrolled_profile_name': 'sam-profile',
            'created_at': '2026-07-01T09:00:00.000',
          },
        ],
      });
      final repo = RpcMeetingRepository(client);
      final speakers = await repo.watchSpeakers('ws-1', 'm-1').first;
      final sp = speakers.first;
      expect(sp.id, 'sp-1');
      expect(sp.meetingId, 'm-1');
      expect(sp.workspaceId, 'ws-1');
      expect(sp.channel, MeetingSpeaker.them);
      expect(sp.label, 'Person 1');
      expect(sp.displayName, 'Sam');
      expect(sp.embedding, [0.1, 0.2]);
      expect(sp.enrolledProfileName, 'sam-profile');
      expect(sp.createdAt, DateTime(2026, 7, 1, 9));
      final sub = host.lastSubscribe!;
      expect(sub.args['meeting_id'], 'm-1');
    });

    test('getSpeakers maps the list', () async {
      host.callResults['meeting.getSpeakers'] = {
        'speakers': [
          {
            'id': 'sp-1',
            'workspace_id': 'ws-1',
            'meeting_id': 'm-1',
            'channel': 'me',
            'label': 'Person 0',
          },
        ],
      };
      final repo = RpcMeetingRepository(client);
      final speakers = await repo.getSpeakers('ws-1', 'm-1');
      expect(speakers.first.id, 'sp-1');
      expect(speakers.first.channel, MeetingSpeaker.me);
    });
  });

  group('RpcMeetingRepository action items + decisions', () {
    test('watchActionItems maps MeetingActionItem wire maps', () async {
      host.snapshotFor('meeting.watchActionItems', {
        'items': [
          {
            'id': 'ai-1',
            'meeting_id': 'm-1',
            'workspace_id': 'ws-1',
            'content': 'ship it',
            'owner': 'a-1',
            'done': true,
            'ticket_id': 't-1',
            'sort_order': 2,
            'is_manual': true,
            'created_at': '2026-07-01T09:00:00.000',
          },
        ],
      });
      final repo = RpcMeetingRepository(client);
      final items = await repo.watchActionItems('ws-1', 'm-1').first;
      final ai = items.first;
      expect(ai.id, 'ai-1');
      expect(ai.meetingId, 'm-1');
      expect(ai.workspaceId, 'ws-1');
      expect(ai.content, 'ship it');
      expect(ai.owner, 'a-1');
      expect(ai.done, isTrue);
      expect(ai.ticketId, 't-1');
      expect(ai.sortOrder, 2);
      expect(ai.isManual, isTrue);
      expect(ai.createdAt, DateTime(2026, 7, 1, 9));
      final sub = host.lastSubscribe!;
      expect(sub.args['meeting_id'], 'm-1');
    });

    test('watchDecisions maps MeetingDecision wire maps', () async {
      host.snapshotFor('meeting.watchDecisions', {
        'decisions': [
          {
            'id': 'dec-1',
            'meeting_id': 'm-1',
            'workspace_id': 'ws-1',
            'content': 'go with option A',
            'sort_order': 1,
            'is_manual': false,
            'created_at': '2026-07-01T09:00:00.000',
          },
        ],
      });
      final repo = RpcMeetingRepository(client);
      final decisions = await repo.watchDecisions('ws-1', 'm-1').first;
      final d = decisions.first;
      expect(d.id, 'dec-1');
      expect(d.meetingId, 'm-1');
      expect(d.workspaceId, 'ws-1');
      expect(d.content, 'go with option A');
      expect(d.sortOrder, 1);
      expect(d.isManual, isFalse);
      expect(d.createdAt, DateTime(2026, 7, 1, 9));
    });

    test('watchActionItemStats maps the per-meeting stats object', () async {
      host.snapshotFor('meeting.watchActionItemStats', {
        'stats': {
          'm-1': {'total': 5, 'done': 2},
        },
      });
      final repo = RpcMeetingRepository(client);
      final stats = await repo.watchActionItemStats('ws-1').first;
      expect(stats['m-1']!.total, 5);
      expect(stats['m-1']!.done, 2);
      final sub = host.lastSubscribe!;
      expect(sub.query, 'meeting.watchActionItemStats');
      expect(sub.args, isEmpty);
    });

    test('watchActionItemStats skips non-Map values', () async {
      host.snapshotFor('meeting.watchActionItemStats', {
        'stats': {
          'm-1': 'junk',
          'm-2': {'total': 3, 'done': 1},
        },
      });
      final repo = RpcMeetingRepository(client);
      final stats = await repo.watchActionItemStats('ws-1').first;
      expect(stats.length, 1);
      expect(stats['m-2']!.total, 3);
    });

    test('watchDecisionCounts maps the per-meeting counts object', () async {
      host.snapshotFor('meeting.watchDecisionCounts', {
        'counts': {'m-1': 4, 'm-2': 2},
      });
      final repo = RpcMeetingRepository(client);
      final counts = await repo.watchDecisionCounts('ws-1').first;
      expect(counts['m-1'], 4);
      expect(counts['m-2'], 2);
    });

    test('watchDecisionCounts coerces a null value to 0', () async {
      host.snapshotFor('meeting.watchDecisionCounts', {
        'counts': {'m-1': null},
      });
      final repo = RpcMeetingRepository(client);
      final counts = await repo.watchDecisionCounts('ws-1').first;
      expect(counts['m-1'], 0);
    });
  });

  group('RpcMeetingRepository user-facing mutations', () {
    test('delete forwards the meeting_id', () async {
      final repo = RpcMeetingRepository(client);
      await repo.delete('ws-1', 'm-1');
      expect(host.lastCall('meeting.delete')!.args['meeting_id'], 'm-1');
    });

    test('updateTitle forwards the meeting_id + title', () async {
      final repo = RpcMeetingRepository(client);
      await repo.updateTitle(
        workspaceId: 'ws-1',
        meetingId: 'm-1',
        title: 'New',
      );
      final call = host.lastCall('meeting.updateTitle')!;
      expect(call.args['meeting_id'], 'm-1');
      expect(call.args['title'], 'New');
    });

    test('updateNotes forwards the meeting_id + notes', () async {
      final repo = RpcMeetingRepository(client);
      await repo.updateNotes(
        workspaceId: 'ws-1',
        meetingId: 'm-1',
        notes: 'my notes',
      );
      final call = host.lastCall('meeting.updateNotes')!;
      expect(call.args['meeting_id'], 'm-1');
      expect(call.args['notes'], 'my notes');
    });

    test('setSegmentSpeakerName forwards the segment_id + name', () async {
      final repo = RpcMeetingRepository(client);
      await repo.setSegmentSpeakerName('ws-1', 'seg-1', 'Sam');
      final call = host.lastCall('meeting.setSegmentSpeakerName')!;
      expect(call.args['segment_id'], 'seg-1');
      expect(call.args['name'], 'Sam');
    });

    test('setSegmentSpeakerName omits a null name', () async {
      final repo = RpcMeetingRepository(client);
      await repo.setSegmentSpeakerName('ws-1', 'seg-1', null);
      final call = host.lastCall('meeting.setSegmentSpeakerName')!;
      expect(call.args['segment_id'], 'seg-1');
      expect(call.args.containsKey('name'), isFalse);
    });

    test('clearSpeakerNameOverridesForLabel forwards channel.name', () async {
      final repo = RpcMeetingRepository(client);
      await repo.clearSpeakerNameOverridesForLabel(
        workspaceId: 'ws-1',
        meetingId: 'm-1',
        channel: MeetingSpeaker.them,
        label: 'Person 1',
      );
      final call = host.lastCall('meeting.clearSpeakerNameOverridesForLabel')!;
      expect(call.args['meeting_id'], 'm-1');
      expect(call.args['channel'], 'them');
      expect(call.args['label'], 'Person 1');
    });

    test(
      'setSpeakerEnrolledProfile forwards channel.name + profileName',
      () async {
        final repo = RpcMeetingRepository(client);
        await repo.setSpeakerEnrolledProfile(
          workspaceId: 'ws-1',
          meetingId: 'm-1',
          channel: MeetingSpeaker.them,
          label: 'Person 1',
          profileName: 'sam-profile',
        );
        final call = host.lastCall('meeting.setSpeakerEnrolledProfile')!;
        expect(call.args['channel'], 'them');
        expect(call.args['label'], 'Person 1');
        expect(call.args['profile_name'], 'sam-profile');
      },
    );

    test('setSpeakerEnrolledProfile omits a null profileName', () async {
      final repo = RpcMeetingRepository(client);
      await repo.setSpeakerEnrolledProfile(
        workspaceId: 'ws-1',
        meetingId: 'm-1',
        channel: MeetingSpeaker.me,
        label: 'Person 0',
        profileName: null,
      );
      final call = host.lastCall('meeting.setSpeakerEnrolledProfile')!;
      expect(call.args.containsKey('profile_name'), isFalse);
    });

    test('renameSpeakerByLabel forwards channel.name + displayName', () async {
      final repo = RpcMeetingRepository(client);
      await repo.renameSpeakerByLabel(
        workspaceId: 'ws-1',
        meetingId: 'm-1',
        channel: MeetingSpeaker.them,
        label: 'Person 1',
        displayName: 'Sam',
      );
      final call = host.lastCall('meeting.renameSpeakerByLabel')!;
      expect(call.args['channel'], 'them');
      expect(call.args['label'], 'Person 1');
      expect(call.args['display_name'], 'Sam');
    });

    test('renameSpeakerByLabel omits a null displayName', () async {
      final repo = RpcMeetingRepository(client);
      await repo.renameSpeakerByLabel(
        workspaceId: 'ws-1',
        meetingId: 'm-1',
        channel: MeetingSpeaker.them,
        label: 'Person 1',
        displayName: null,
      );
      final call = host.lastCall('meeting.renameSpeakerByLabel')!;
      expect(call.args.containsKey('display_name'), isFalse);
    });

    test('addActionItem serializes the action item', () async {
      final repo = RpcMeetingRepository(client);
      await repo.addActionItem(_actionItem());
      final call = host.lastCall('meeting.addActionItem')!;
      final sent = (call.args['item'] as Map).cast<String, dynamic>();
      expect(sent['id'], 'ai-1');
      expect(sent['meeting_id'], 'm-1');
      expect(sent['workspace_id'], 'ws-1');
      expect(sent['content'], 'do it');
      expect(sent['owner'], 'a-1');
      expect(sent['done'], isTrue);
      expect(sent['ticket_id'], 't-1');
      expect(sent['sort_order'], 3);
      expect(sent['is_manual'], isTrue);
      expect(sent['created_at'], isA<String>());
    });

    test('addActionItem omits null owner/ticket_id', () async {
      final repo = RpcMeetingRepository(client);
      await repo.addActionItem(
        MeetingActionItem(
          id: 'ai-1',
          meetingId: 'm-1',
          workspaceId: 'ws-1',
          content: 'x',
          createdAt: DateTime(2026),
        ),
      );
      final sent = (host.lastCall('meeting.addActionItem')!.args['item'] as Map)
          .cast<String, dynamic>();
      expect(sent.containsKey('owner'), isFalse);
      expect(sent.containsKey('ticket_id'), isFalse);
    });

    test('updateActionItem forwards id + content + owner', () async {
      final repo = RpcMeetingRepository(client);
      await repo.updateActionItem(
        workspaceId: 'ws-1',
        id: 'ai-1',
        content: 'updated',
        owner: 'a-2',
      );
      final call = host.lastCall('meeting.updateActionItem')!;
      expect(call.args['id'], 'ai-1');
      expect(call.args['content'], 'updated');
      expect(call.args['owner'], 'a-2');
    });

    test('updateActionItem omits a null owner', () async {
      final repo = RpcMeetingRepository(client);
      await repo.updateActionItem(
        workspaceId: 'ws-1',
        id: 'ai-1',
        content: 'updated',
      );
      final call = host.lastCall('meeting.updateActionItem')!;
      expect(call.args.containsKey('owner'), isFalse);
    });

    test('deleteActionItem forwards the id', () async {
      final repo = RpcMeetingRepository(client);
      await repo.deleteActionItem('ws-1', 'ai-1');
      expect(host.lastCall('meeting.deleteActionItem')!.args['id'], 'ai-1');
    });

    test('setActionItemDone forwards id + done', () async {
      final repo = RpcMeetingRepository(client);
      await repo.setActionItemDone(workspaceId: 'ws-1', id: 'ai-1', done: true);
      final call = host.lastCall('meeting.setActionItemDone')!;
      expect(call.args['id'], 'ai-1');
      expect(call.args['done'], isTrue);
    });

    test('setActionItemTicket forwards id + ticket_id', () async {
      final repo = RpcMeetingRepository(client);
      await repo.setActionItemTicket(
        workspaceId: 'ws-1',
        id: 'ai-1',
        ticketId: 't-9',
      );
      final call = host.lastCall('meeting.setActionItemTicket')!;
      expect(call.args['id'], 'ai-1');
      expect(call.args['ticket_id'], 't-9');
    });

    test('addDecision serializes the decision', () async {
      final repo = RpcMeetingRepository(client);
      await repo.addDecision(_decision());
      final call = host.lastCall('meeting.addDecision')!;
      final sent = (call.args['decision'] as Map).cast<String, dynamic>();
      expect(sent['id'], 'dec-1');
      expect(sent['meeting_id'], 'm-1');
      expect(sent['workspace_id'], 'ws-1');
      expect(sent['content'], 'decided');
      expect(sent['sort_order'], 1);
      expect(sent['is_manual'], isTrue);
      expect(sent['created_at'], isA<String>());
    });

    test('updateDecision forwards id + content', () async {
      final repo = RpcMeetingRepository(client);
      await repo.updateDecision(
        workspaceId: 'ws-1',
        id: 'dec-1',
        content: 'updated',
      );
      final call = host.lastCall('meeting.updateDecision')!;
      expect(call.args['id'], 'dec-1');
      expect(call.args['content'], 'updated');
    });

    test('deleteDecision forwards the id', () async {
      final repo = RpcMeetingRepository(client);
      await repo.deleteDecision('ws-1', 'dec-1');
      expect(host.lastCall('meeting.deleteDecision')!.args['id'], 'dec-1');
    });
  });

  group('RpcMeetingRepository host-only surface throws', () {
    test('getUnfinalized throws UnsupportedError', () async {
      final repo = RpcMeetingRepository(client);
      expect(repo.getUnfinalized, throwsUnsupportedError);
    });

    test('upsert throws UnsupportedError', () async {
      final repo = RpcMeetingRepository(client);
      expect(() => repo.upsert(_meeting()), throwsUnsupportedError);
    });

    test('appendSegment throws UnsupportedError', () async {
      final repo = RpcMeetingRepository(client);
      expect(() => repo.appendSegment(_segment()), throwsUnsupportedError);
    });

    test('replaceSegments throws UnsupportedError', () async {
      final repo = RpcMeetingRepository(client);
      expect(
        () => repo.replaceSegments('ws-1', 'm-1', [_segment()]),
        throwsUnsupportedError,
      );
    });

    test('setSegmentSpeakerLabel throws UnsupportedError', () async {
      final repo = RpcMeetingRepository(client);
      expect(
        () => repo.setSegmentSpeakerLabel('ws-1', 'seg-1', 'Person 1'),
        throwsUnsupportedError,
      );
    });

    test('replaceSpeakers throws UnsupportedError', () async {
      final repo = RpcMeetingRepository(client);
      expect(
        () => repo.replaceSpeakers('ws-1', 'm-1', [_speaker()]),
        throwsUnsupportedError,
      );
    });

    test('renameSpeaker (by id) throws UnsupportedError', () async {
      final repo = RpcMeetingRepository(client);
      expect(
        () => repo.renameSpeaker(
          workspaceId: 'ws-1',
          id: 'sp-1',
          displayName: 'Sam',
        ),
        throwsUnsupportedError,
      );
    });

    test('replaceActionItems throws UnsupportedError', () async {
      final repo = RpcMeetingRepository(client);
      expect(
        () => repo.replaceActionItems('ws-1', 'm-1', [_actionItem()]),
        throwsUnsupportedError,
      );
    });

    test('replaceDecisions throws UnsupportedError', () async {
      final repo = RpcMeetingRepository(client);
      expect(
        () => repo.replaceDecisions('ws-1', 'm-1', [_decision()]),
        throwsUnsupportedError,
      );
    });
  });
}

Meeting _meeting() => Meeting(
  id: 'm-1',
  workspaceId: 'ws-1',
  title: 'Sync',
  status: MeetingStatus.done,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  startedAt: DateTime(2026),
);

MeetingSegment _segment() => MeetingSegment(
  id: 'seg-1',
  meetingId: 'm-1',
  workspaceId: 'ws-1',
  speaker: MeetingSpeaker.me,
  text: 'hi',
  startMs: 0,
  endMs: 1,
  createdAt: DateTime(2026),
);

MeetingSpeakerLabel _speaker() => MeetingSpeakerLabel(
  id: 'sp-1',
  meetingId: 'm-1',
  workspaceId: 'ws-1',
  channel: MeetingSpeaker.them,
  label: 'Person 1',
  createdAt: DateTime(2026),
);

MeetingActionItem _actionItem() => MeetingActionItem(
  id: 'ai-1',
  meetingId: 'm-1',
  workspaceId: 'ws-1',
  content: 'do it',
  owner: 'a-1',
  done: true,
  ticketId: 't-1',
  sortOrder: 3,
  isManual: true,
  createdAt: DateTime(2026),
);

MeetingDecision _decision() => MeetingDecision(
  id: 'dec-1',
  meetingId: 'm-1',
  workspaceId: 'ws-1',
  content: 'decided',
  sortOrder: 1,
  isManual: true,
  createdAt: DateTime(2026),
);

/// Records a `repo/call` invocation.
class _Call {
  const _Call({required this.op, required this.args});
  final String op;
  final Map<String, dynamic> args;
}

/// A recorded `sub/subscribe`.
class _Sub {
  const _Sub({required this.query, required this.args});
  final String query;
  final Map<String, dynamic> args;
}

/// In-process host that scripts `repo/call` results and `sub/subscribe`
/// snapshots. Mirrors the wire shape the server catalog emits.
class _Host {
  _Host(this.channel) {
    channel.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort channel;
  final List<_Call> calls = [];
  final List<_Sub> subs = [];

  /// Scripted `repo/call` results keyed by op name.
  final Map<String, Map<String, dynamic>> callResults = {};

  /// Scripted snapshots keyed by watch query (pushed on subscribe).
  final Map<String, Map<String, dynamic>> snapshots = {};

  _Call? lastCall(String op) => calls.lastWhere(
    (c) => c.op == op,
    orElse: () => const _Call(op: '', args: {}),
  );
  _Sub? get lastSubscribe => subs.isEmpty ? null : subs.last;

  /// Scripts the snapshot pushed to the next subscription for [query].
  void snapshotFor(String query, Map<String, dynamic> data) =>
      snapshots[query] = data;

  void _onFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    final method = frame['method'] as String?;
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    switch (method) {
      case 'initialize':
        _reply(id, {'capabilities': <String, dynamic>{}});
      case RpcMethods.subscribe:
        final query = params['query'] as String;
        final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
        subs.add(_Sub(query: query, args: args));
        _reply(id, {'subscriptionId': 's1', 'rev': 0});
        // Immediately push the scripted snapshot for this query (if any).
        final snapshot = snapshots[query];
        if (snapshot != null) {
          channel.send({
            'jsonrpc': '2.0',
            'method': RpcMethods.subSnapshot,
            'params': {
              'subscriptionId': 's1',
              'rev': 1,
              'full': true,
              'data': snapshot,
            },
          });
        }
      case RpcMethods.unsubscribe:
        _reply(id, {'ok': true});
      case RpcMethods.repoCall:
        final op = params['op'] as String;
        final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
        calls.add(_Call(op: op, args: args));
        final data = callResults[op] ?? const <String, dynamic>{};
        _reply(id, {'op': op, 'data': data});
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      channel.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
