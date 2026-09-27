import 'dart:async';

import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_domain/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_server_core/src/demo/demo_world.dart' show kDemoCast;
import 'package:uuid/uuid.dart';

/// Server-owned fictional recording. No audio, speech model, or caller-supplied
/// transcript ever enters this path. The RPC catalog only installs it on the
/// public demo server; every control call is bound to the authenticated caller.
class DemoMeetingService {
  /// Creates the server-owned simulated recorder.
  DemoMeetingService(
    this._meetings, {
    Duration interval = const Duration(seconds: 3),
  }) : _interval = interval; // ignore: prefer_initializing_formals

  final MeetingRepository _meetings;
  final Duration _interval;
  final _sessions = <String, _DemoMeetingSession>{};
  final _activeByOwner = <String, String>{};
  static const _uuid = Uuid();

  // Content belongs to the server, not RPC input. Speaker names are deliberately
  // fictional, and the title marks the transcript as simulated in details too.
  static final _script = <(String, MeetingSpeaker, String)>[
    (
      kDemoCast[0].displayName,
      MeetingSpeaker.me,
      'Let’s review Helix eval-bench readiness. Are the run-group budgets stable for the release cut?',
    ),
    (
      kDemoCast[1].displayName,
      MeetingSpeaker.them,
      'PR #412 keys remaining tokens by run-group now. I’m checking the cancellation-path test.',
    ),
    (
      kDemoCast[2].displayName,
      MeetingSpeaker.them,
      'The retrieval suite passes identifier queries. I’m checking citation keys in hybrid search.',
    ),
    (
      kDemoCast[0].displayName,
      MeetingSpeaker.me,
      'Good. Keep the release review focused on evalkit budgets and the retrieval checks.',
    ),
    (
      kDemoCast[1].displayName,
      MeetingSpeaker.them,
      'I’ll share the cancellation-path run after lunch, alongside the HX-118 hang investigation.',
    ),
    (
      kDemoCast[2].displayName,
      MeetingSpeaker.them,
      'I’ll attach the retrieval results to the review and flag any citation regressions.',
    ),
    (
      kDemoCast[0].displayName,
      MeetingSpeaker.me,
      'Tomorrow we’ll decide whether the eval suite is green enough for the release cut.',
    ),
  ];

  String _ownerKey(String workspaceId, String userId) => '$workspaceId/$userId';

  /// Starts one scripted meeting for this authenticated visitor.
  Future<String> start({
    required String workspaceId,
    required String userId,
  }) async {
    final owner = _ownerKey(workspaceId, userId);
    if (_activeByOwner.containsKey(owner)) {
      throw StateError('A simulated meeting is already active.');
    }
    final now = DateTime.now();
    final id = _uuid.v4();
    final session = _DemoMeetingSession(workspaceId, userId);
    final initialWrite = Completer<void>();
    session.pending = initialWrite.future;
    // Reserve before the first await so concurrent starts cannot evade the cap.
    _activeByOwner[owner] = id;
    _sessions[id] = session;
    try {
      await _meetings.upsert(
        Meeting(
          id: id,
          workspaceId: workspaceId,
          title: 'Simulated Helix eval-release sync',
          status: MeetingStatus.recording,
          mode: MeetingMode.remote,
          startedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      );
      if (!session.active) {
        throw StateError('Simulated meeting expired before it could start.');
      }
      await _append(id, session);
      if (!session.active) {
        throw StateError('Simulated meeting expired before it could start.');
      }
      session.timer = Timer.periodic(_interval, (_) {
        unawaited(
          advance(id).catchError((Object error) {
            session.timer?.cancel();
            CcHostLog.warning('demo meeting transcript tick failed: $error');
          }),
        );
      });
      return id;
    } catch (_) {
      session.timer?.cancel();
      _sessions.remove(id);
      if (_activeByOwner[owner] == id) {
        _activeByOwner.remove(owner);
      }
      rethrow;
    } finally {
      initialWrite.complete();
    }
  }

  _DemoMeetingSession _owned(
    String workspaceId,
    String userId,
    String meetingId,
  ) {
    final session = _sessions[meetingId];
    if (session == null ||
        session.workspaceId != workspaceId ||
        session.userId != userId ||
        !session.active) {
      throw StateError('Simulated meeting not found for this visitor.');
    }
    return session;
  }

  /// The server clock's next transcript line. Also callable directly by tests;
  /// there is intentionally no corresponding RPC operation.
  Future<void> advance(String meetingId) async {
    final session = _sessions[meetingId];
    if (session == null) {
      return;
    }
    await _serialize(session, () async {
      if (!session.active ||
          session.paused ||
          session.index >= _script.length) {
        return;
      }
      await _append(meetingId, session);
      if (session.index == _script.length) {
        session.timer?.cancel();
      }
    });
  }

  /// Pauses delivery of the scripted transcript for its creator.
  Future<void> pause({
    required String workspaceId,
    required String userId,
    required String meetingId,
  }) async {
    final session = _owned(workspaceId, userId, meetingId);
    await _serialize(session, () async {
      if (session.active) {
        session.paused = true;
      }
    });
  }

  /// Resumes delivery of the scripted transcript for its creator.
  Future<void> resume({
    required String workspaceId,
    required String userId,
    required String meetingId,
  }) async {
    final session = _owned(workspaceId, userId, meetingId);
    await _serialize(session, () async {
      if (session.active) {
        session.paused = false;
      }
    });
  }

  /// Completes the fictional transcript and closes the meeting.
  Future<void> stop({
    required String workspaceId,
    required String userId,
    required String meetingId,
  }) async {
    final session = _owned(workspaceId, userId, meetingId);
    session.timer?.cancel();
    await _serialize(session, () async {
      if (!session.active) {
        return;
      }
      // Completing the fixed script gives even a short recording a coherent,
      // finished fictional transcript on its detail screen.
      while (session.index < _script.length) {
        await _append(meetingId, session);
      }
      final meeting = await _meetings.getById(workspaceId, meetingId);
      if (meeting == null) {
        throw StateError('Simulated meeting was removed.');
      }
      final now = DateTime.now();
      await _meetings.upsert(
        meeting.copyWith(
          status: MeetingStatus.done,
          endedAt: now,
          updatedAt: now,
        ),
      );
      session.active = false;
      _sessions.remove(meetingId);
      _activeByOwner.remove(_ownerKey(workspaceId, userId));
    });
  }

  Future<void> _append(String meetingId, _DemoMeetingSession session) async {
    final index = session.index;
    final (speakerName, channel, text) = _script[index];
    await _meetings.appendSegment(
      MeetingSegment(
        id: _uuid.v4(),
        meetingId: meetingId,
        workspaceId: session.workspaceId,
        speaker: channel,
        speakerLabel: speakerName,
        text: text,
        startMs: index * _interval.inMilliseconds,
        endMs: (index + 1) * _interval.inMilliseconds,
        createdAt: DateTime.now(),
      ),
    );
    session.index++;
  }

  Future<void> _serialize(
    _DemoMeetingSession session,
    Future<void> Function() action,
  ) {
    final next = session.pending.then((_) => action());
    session.pending = next.catchError((Object _) {});
    return next;
  }

  /// Called before a visitor's workspace is deleted, including lease expiry.
  Future<void> retireWorkspace(String workspaceId) async {
    final retired = [
      for (final entry in _sessions.entries)
        if (entry.value.workspaceId == workspaceId) entry,
    ];
    for (final entry in retired) {
      entry.value.timer?.cancel();
      entry.value.active = false;
    }
    await Future.wait(retired.map((entry) => entry.value.pending));
    for (final entry in retired) {
      _sessions.remove(entry.key);
      _activeByOwner.remove(_ownerKey(workspaceId, entry.value.userId));
    }
  }

  /// Cancels all timers before the demo runtime tears down visitor databases.
  Future<void> dispose() async {
    for (final session in _sessions.values) {
      session.timer?.cancel();
      session.active = false;
    }
    await Future.wait(_sessions.values.map((session) => session.pending));
    _sessions.clear();
    _activeByOwner.clear();
  }
}

class _DemoMeetingSession {
  _DemoMeetingSession(this.workspaceId, this.userId);

  final String workspaceId;
  final String userId;
  Timer? timer;
  Future<void> pending = Future<void>.value();
  int index = 0;
  bool active = true;
  bool paused = false;
}
