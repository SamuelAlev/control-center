import 'package:cc_data/cc_data.dart' show RpcMeetingRepository;
import 'package:cc_data/src/repositories/rpc_meeting_repository.dart' show RpcMeetingRepository;
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates meetings, transcript segments, diarized speakers, and the
/// structured action items / decisions over the RPC client.
///
/// Meetings are workspace-scoped (bound server-side), so no call carries a
/// `workspace_id` — the host injects the authoritative one. Mirrors the
/// `meeting.*` ops + the `meeting.watch*` subscriptions in the host catalog.
/// Returns the raw wire maps; the [RpcMeetingRepository] wrapper maps them back
/// to domain entities. Recording itself stays device-only on the host, so the
/// recorder-only writes (upsert/appendSegment/replace*) have no RPC surface.
class RemoteMeetingRepository {
  /// Creates a [RemoteMeetingRepository] over [_client].
  RemoteMeetingRepository(this._client);

  final RemoteRpcClient _client;

  // ---- Reads ----

  /// All meetings in the bound workspace, newest first.
  Future<List<Map<String, dynamic>>> getByWorkspace() async {
    final data = await _client.call('meeting.getByWorkspace', const {});
    return _list(data, 'meetings');
  }

  /// A single meeting by id (scoped to the bound workspace server-side), or
  /// null when it doesn't exist / isn't owned.
  Future<Map<String, dynamic>?> getById(String meetingId) async {
    final data = await _client.call('meeting.getById', {
      'meeting_id': meetingId,
    });
    return _map(data, 'meeting');
  }

  /// Transcript segments for [meetingId], oldest first.
  Future<List<Map<String, dynamic>>> getSegments(String meetingId) async {
    final data = await _client.call('meeting.getSegments', {
      'meeting_id': meetingId,
    });
    return _list(data, 'segments');
  }

  /// Diarized speakers for [meetingId].
  Future<List<Map<String, dynamic>>> getSpeakers(String meetingId) async {
    final data = await _client.call('meeting.getSpeakers', {
      'meeting_id': meetingId,
    });
    return _list(data, 'speakers');
  }

  // ---- Mutations ----

  /// Deletes meeting [meetingId] (cascades to segments) in the bound workspace.
  Future<void> delete(String meetingId) =>
      _client.call('meeting.delete', {'meeting_id': meetingId});

  /// Updates only meeting [meetingId]'s [title] (the calendar link flow's
  /// title-adoption step).
  Future<void> updateTitle(String meetingId, String title) =>
      _client.call('meeting.updateTitle', {
        'meeting_id': meetingId,
        'title': title,
      });

  /// Updates only meeting [meetingId]'s user [notes] (the meeting screens'
  /// "augment my notes" edit).
  Future<void> updateNotes(String meetingId, String notes) =>
      _client.call('meeting.updateNotes', {
        'meeting_id': meetingId,
        'notes': notes,
      });

  /// Sets (or clears, when [name] is null) the per-segment speaker-name override
  /// on transcript segment [segmentId].
  Future<void> setSegmentSpeakerName(String segmentId, String? name) =>
      _client.call('meeting.setSegmentSpeakerName', {
        'segment_id': segmentId,
        'name': ?name,
      });

  /// Renames the diarized speaker identified by ([channel], [label]) within
  /// [meetingId]. A null [displayName] clears the override.
  Future<void> renameSpeakerByLabel({
    required String meetingId,
    required String channel,
    required String label,
    required String? displayName,
  }) => _client.call('meeting.renameSpeakerByLabel', {
    'meeting_id': meetingId,
    'channel': channel,
    'label': label,
    'display_name': ?displayName,
  });

  /// Clears every per-segment name override for the speaker ([channel], [label])
  /// within [meetingId].
  Future<void> clearSpeakerNameOverridesForLabel({
    required String meetingId,
    required String channel,
    required String label,
  }) => _client.call('meeting.clearSpeakerNameOverridesForLabel', {
    'meeting_id': meetingId,
    'channel': channel,
    'label': label,
  });

  /// Records (or clears, when [profileName] is null) the voice profile a
  /// speaker's voiceprint was enrolled into, for ([channel], [label]) within
  /// [meetingId].
  Future<void> setSpeakerEnrolledProfile({
    required String meetingId,
    required String channel,
    required String label,
    required String? profileName,
  }) => _client.call('meeting.setSpeakerEnrolledProfile', {
    'meeting_id': meetingId,
    'channel': channel,
    'label': label,
    'profile_name': ?profileName,
  });

  /// Inserts a single (user-authored) action item.
  Future<void> addActionItem(Map<String, dynamic> item) =>
      _client.call('meeting.addActionItem', {'item': item});

  /// Edits an action item's content + owner, marking it manual.
  Future<void> updateActionItem({
    required String id,
    required String content,
    String? owner,
  }) => _client.call('meeting.updateActionItem', {
    'id': id,
    'content': content,
    'owner': ?owner,
  });

  /// Deletes action item [id].
  Future<void> deleteActionItem(String id) =>
      _client.call('meeting.deleteActionItem', {'id': id});

  /// Sets the persisted done flag on action item [id].
  Future<void> setActionItemDone({
    required String id,
    required bool done,
  }) => _client.call('meeting.setActionItemDone', {'id': id, 'done': done});

  /// Links a created ticket to action item [id].
  Future<void> setActionItemTicket({
    required String id,
    required String ticketId,
  }) => _client.call('meeting.setActionItemTicket', {
    'id': id,
    'ticket_id': ticketId,
  });

  /// Inserts a single (user-authored) decision.
  Future<void> addDecision(Map<String, dynamic> decision) =>
      _client.call('meeting.addDecision', {'decision': decision});

  /// Edits a decision's content, marking it manual.
  Future<void> updateDecision({
    required String id,
    required String content,
  }) => _client.call('meeting.updateDecision', {'id': id, 'content': content});

  /// Deletes decision [id].
  Future<void> deleteDecision(String id) =>
      _client.call('meeting.deleteDecision', {'id': id});

  // ---- Watches ----

  /// Live meetings in the bound workspace, newest first.
  Stream<List<Map<String, dynamic>>> watchByWorkspace() => _client
      .subscribe('meeting.watchByWorkspace', const {})
      .map((data) => _list(data, 'meetings'));

  /// Live transcript segments for [meetingId].
  Stream<List<Map<String, dynamic>>> watchSegments(String meetingId) => _client
      .subscribe('meeting.watchSegments', {'meeting_id': meetingId})
      .map((data) => _list(data, 'segments'));

  /// Live diarized speakers for [meetingId].
  Stream<List<Map<String, dynamic>>> watchSpeakers(String meetingId) => _client
      .subscribe('meeting.watchSpeakers', {'meeting_id': meetingId})
      .map((data) => _list(data, 'speakers'));

  /// Live action items for [meetingId].
  Stream<List<Map<String, dynamic>>> watchActionItems(String meetingId) =>
      _client
          .subscribe('meeting.watchActionItems', {'meeting_id': meetingId})
          .map((data) => _list(data, 'items'));

  /// Live decisions for [meetingId].
  Stream<List<Map<String, dynamic>>> watchDecisions(String meetingId) => _client
      .subscribe('meeting.watchDecisions', {'meeting_id': meetingId})
      .map((data) => _list(data, 'decisions'));

  /// Live per-meeting action-item stats (a `{meetingId: {total, done}}` object).
  Stream<Map<String, dynamic>> watchActionItemStats() => _client
      .subscribe('meeting.watchActionItemStats', const {})
      .map((data) => _object(data, 'stats'));

  /// Live per-meeting decision counts (a `{meetingId: count}` object).
  Stream<Map<String, dynamic>> watchDecisionCounts() => _client
      .subscribe('meeting.watchDecisionCounts', const {})
      .map((data) => _object(data, 'counts'));

  List<Map<String, dynamic>> _list(Map<String, dynamic> data, String key) =>
      ((data[key] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();

  Map<String, dynamic>? _map(Map<String, dynamic> data, String key) {
    final value = data[key];
    return value is Map ? value.cast<String, dynamic>() : null;
  }

  Map<String, dynamic> _object(Map<String, dynamic> data, String key) {
    final value = data[key];
    return value is Map ? value.cast<String, dynamic>() : const {};
  }
}
