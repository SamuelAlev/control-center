import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_takeover.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/space_takeover_repository.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';

/// Take-over / hand-back (PRD 16 §8): a human holds mutating control; the agent may still observe.
///
/// Enforced at the act chokepoint, not by prompt. Control changes are attributed and sequenced.
class TakeoverService {
  /// Creates the service.
  TakeoverService({
    required this._takeovers,
    required this._runLogs,
    required this._messaging,
    required this._pauseRun,
    required this._resumeRun,
    required this._stopRun,
    required this._steerRun,
    required this._conversationChanges,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// The durable markers, one per space, in the space's own workspace.
  final SpaceTakeoverRepository _takeovers;
  final DateTime Function() _now;
  final AgentRunLogRepository _runLogs;
  final MessagingRepository _messaging;
  final Future<bool> Function(String runLogId) _pauseRun;
  final Future<bool> Function(String runLogId) _resumeRun;
  final Future<void> Function(String workspaceId, String runLogId) _stopRun;
  final Future<bool> Function(String runLogId, String message) _steerRun;
  final Future<List<PrFile>> Function(String workspaceId, String spaceId)
  _conversationChanges;

  /// The active take-over marker for a space (its wire form), or null.
  Future<Map<String, dynamic>?> status(
    String workspaceId,
    String spaceId,
  ) async => (await _takeovers.get(workspaceId, spaceId))?.toWire();

  /// Whether a take-over stands on [spaceId] (dispatch gating).
  Future<bool> isActive(String workspaceId, String spaceId) async =>
      await _takeovers.get(workspaceId, spaceId) != null;

  /// The take-over marker for [spaceId] as it changes (null when none
  /// stands). Backs `takeover.watch`, so clients follow the marker instead of
  /// polling `takeover.status`.
  Stream<Map<String, dynamic>?> watch(String workspaceId, String spaceId) =>
      _takeovers.watch(workspaceId, spaceId).map((t) => t?.toWire());

  /// Begins a take-over: claims the durable marker, then pauses/stops the
  /// space's active runs. Throws [StateError] when someone already holds it
  /// (one live editor per worktree — refuse loudly, never silently share).
  ///
  /// The claim is one conditional write ([SpaceTakeoverRepository.claim]), so
  /// two people starting a take-over at once cannot both pass. Claiming before
  /// pausing also means no run can start in the space mid-pause: dispatch is
  /// already gated on the marker. A failure while pausing releases the claim.
  Future<Map<String, dynamic>> begin({
    required String workspaceId,
    required String spaceId,
    required String userId,
    required String displayName,
  }) async {
    final takeover = SpaceTakeover(
      spaceId: spaceId,
      userId: userId,
      displayName: displayName,
      since: _now(),
    );
    if (!await _takeovers.claim(workspaceId, takeover)) {
      final existing = await _takeovers.get(workspaceId, spaceId);
      throw StateError(
        'This conversation is already taken over by '
        '${existing?.displayName ?? existing?.userId ?? 'someone else'}.',
      );
    }
    final paused = <String>[];
    final stopped = <String>[];
    try {
      final active = await _runLogs
          .watchActiveBySpace(workspaceId, spaceId)
          .first;
      for (final run in active) {
        if (run.status != RunStatus.running &&
            run.status != RunStatus.pending) {
          continue;
        }
        if (await _pauseRun(run.id)) {
          paused.add(run.id);
        } else {
          // No safe turn boundary (external CLI transport): stop instead —
          // honest and the run stays retryable after hand-back.
          await _stopRun(workspaceId, run.id);
          stopped.add(run.id);
        }
      }
      await _takeovers.recordHeldRuns(
        workspaceId,
        spaceId,
        paused: paused,
        stopped: stopped,
      );
    } catch (_) {
      // Runs already paused stay listed nowhere, so resume them rather than
      // strand them behind a released claim.
      for (final runId in paused) {
        await _resumeRun(runId).catchError((Object _) => false);
      }
      await _takeovers.release(workspaceId, spaceId);
      rethrow;
    }
    await _messaging.sendMessage(
      workspaceId: workspaceId,
      spaceId: spaceId,
      content:
          '$displayName took over this conversation\'s worktree'
          '${paused.isEmpty ? '' : ' (${paused.length} run(s) paused at a turn boundary)'}'
          '${stopped.isEmpty ? '' : ' (${stopped.length} run(s) stopped)'}.',
      senderId: 'system',
      senderType: 'system',
      messageType: 'system',
    );
    return SpaceTakeover(
      spaceId: spaceId,
      userId: userId,
      displayName: displayName,
      since: takeover.since,
      pausedRunIds: paused,
      stoppedRunIds: stopped,
    ).toWire();
  }

  /// Hands control back: clears the marker, posts the diff summary, then
  /// steers + resumes the paused runs. Returns the summary that was posted.
  ///
  /// Only the person holding the take-over may hand it back, or a workspace
  /// admin ([asAdmin]) ending a take-over someone left behind. The marker is
  /// cleared FIRST: a resumed run's first act is checked against it, and a
  /// failure posting the summary or resuming a run must not leave the
  /// conversation stuck in a take-over nobody holds.
  Future<Map<String, dynamic>> handBack({
    required String workspaceId,
    required String spaceId,
    required String userId,
    required String displayName,
    bool asAdmin = false,
    String note = '',
  }) async {
    final marker = await _takeovers.get(workspaceId, spaceId);
    if (marker == null) {
      throw StateError('No take-over stands on this conversation.');
    }
    if (marker.userId != userId && !asAdmin) {
      throw StateError(
        'Only ${marker.displayName} or a workspace admin can '
        'hand this conversation back.',
      );
    }
    final summary = await _diffSummary(workspaceId, spaceId);
    await _takeovers.release(workspaceId, spaceId);

    final message = StringBuffer()
      ..write('$displayName handed the worktree back. ')
      ..write(summary);
    if (note.trim().isNotEmpty) {
      message.write('\nNote from $displayName: ${note.trim()}');
    }
    final paused = marker.pausedRunIds;
    final resumed = <String>[];
    Object? firstError;
    try {
      await _messaging.sendMessage(
        workspaceId: workspaceId,
        spaceId: spaceId,
        content: message.toString(),
        senderId: 'system',
        senderType: 'system',
        messageType: 'system',
      );
    } catch (e) {
      firstError = e;
    }
    for (final runId in paused) {
      // The agent re-reads the hand-back before resuming: the steering
      // message is drained at the top of the resumed turn. One run failing
      // to resume must not keep the others paused.
      try {
        await _steerRun(
          runId,
          'The human took over the worktree and handed it back. $message '
          'Re-read the recent changes before continuing.',
        );
        if (await _resumeRun(runId)) {
          resumed.add(runId);
        }
      } catch (e) {
        firstError ??= e;
      }
    }
    if (firstError != null) {
      throw StateError(
        'The worktree was handed back, but notifying the agent failed: '
        '$firstError',
      );
    }
    return {'summary': summary, 'resumed_run_ids': resumed};
  }

  Future<String> _diffSummary(String workspaceId, String spaceId) async {
    try {
      final files = await _conversationChanges(workspaceId, spaceId);
      if (files.isEmpty) {
        return 'No uncommitted changes in the worktree.';
      }
      final names = files.take(12).map((f) => f.filename).join(', ');
      final more = files.length > 12 ? ' and ${files.length - 12} more' : '';
      var additions = 0;
      var deletions = 0;
      for (final f in files) {
        additions += f.additions;
        deletions += f.deletions;
      }
      return '${files.length} file(s) changed '
          '(+$additions/-$deletions): $names$more.';
    } catch (_) {
      return 'Worktree diff unavailable.';
    }
  }
}
