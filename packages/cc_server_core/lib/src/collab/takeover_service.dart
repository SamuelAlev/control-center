import 'dart:convert';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_persistence/database/daos/cache_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';

/// Take-over / hand-back (PRD 16 §8): a human holds mutating control; the agent may still observe.
///
/// Enforced at the act chokepoint, not by prompt. Control changes are attributed and sequenced.
class TakeoverService {
  /// Creates the service.
  TakeoverService({
    required WorkspaceDatabaseManager workspaceDbs,
    required this._runLogs,
    required this._messaging,
    required this._pauseRun,
    required this._resumeRun,
    required this._stopRun,
    required this._steerRun,
    required this._conversationChanges,
  }) : _dbs = workspaceDbs;

  /// The Caches kind holding take-over markers (key = space id).
  static const String cacheKind = 'takeover';

  final WorkspaceDatabaseManager _dbs;
  final AgentRunLogRepository _runLogs;
  final MessagingRepository _messaging;
  final Future<bool> Function(String runLogId) _pauseRun;
  final Future<bool> Function(String runLogId) _resumeRun;
  final Future<void> Function(String workspaceId, String runLogId) _stopRun;
  final Future<bool> Function(String runLogId, String message) _steerRun;
  final Future<List<PrFile>> Function(String workspaceId, String spaceId)
  _conversationChanges;

  /// Take-over markers live in the workspace's own database file, so the marker
  /// is always read and written in the workspace that owns the space.
  CacheDao _cache(String workspaceId) => _dbs.of(workspaceId).cacheDao;

  /// The active take-over marker for a space, or null.
  Future<Map<String, dynamic>?> status(
    String workspaceId,
    String spaceId,
  ) async {
    final raw = await _cache(workspaceId).read(workspaceId, cacheKind, spaceId);
    if (raw == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  /// Whether a take-over stands on [spaceId] (dispatch gating).
  Future<bool> isActive(String workspaceId, String spaceId) async =>
      await status(workspaceId, spaceId) != null;

  /// The take-over marker for [spaceId] as it changes (null when none
  /// stands). Backs `takeover.watch`, so clients follow the marker instead of
  /// polling `takeover.status`.
  Stream<Map<String, dynamic>?> watch(String workspaceId, String spaceId) =>
      _cache(workspaceId).watch(workspaceId, cacheKind, spaceId).map((raw) {
        if (raw == null) {
          return null;
        }
        try {
          final decoded = jsonDecode(raw);
          return decoded is Map<String, dynamic> ? decoded : null;
        } on FormatException {
          return null;
        }
      });

  /// Begins a take-over: claims the durable marker, then pauses/stops the
  /// space's active runs. Throws [StateError] when someone already holds it
  /// (one live editor per worktree — refuse loudly, never silently share).
  ///
  /// The claim is one conditional write ([CacheDao.putIfAbsent]), so two
  /// people starting a take-over at once cannot both pass. Claiming before
  /// pausing also means no run can start in the space mid-pause: dispatch is
  /// already gated on the marker. A failure while pausing releases the claim.
  Future<Map<String, dynamic>> begin({
    required String workspaceId,
    required String spaceId,
    required String userId,
    required String displayName,
  }) async {
    final marker = <String, dynamic>{
      'user_id': userId,
      'display_name': displayName,
      'since': DateTime.now().toIso8601String(),
      'paused_run_ids': <String>[],
      'stopped_run_ids': <String>[],
    };
    final cache = _cache(workspaceId);
    if (!await cache.putIfAbsent(
      workspaceId,
      cacheKind,
      spaceId,
      jsonEncode(marker),
    )) {
      final existing = await status(workspaceId, spaceId);
      throw StateError(
        'This conversation is already taken over by '
        '${existing?['display_name'] ?? existing?['user_id'] ?? 'someone else'}.',
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
      marker['paused_run_ids'] = paused;
      marker['stopped_run_ids'] = stopped;
      await cache.put(workspaceId, cacheKind, spaceId, jsonEncode(marker));
    } catch (_) {
      // Runs already paused stay listed nowhere, so resume them rather than
      // strand them behind a released claim.
      for (final runId in paused) {
        await _resumeRun(runId).catchError((Object _) => false);
      }
      await cache.deleteEntry(workspaceId, cacheKind, spaceId);
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
    return marker;
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
    final marker = await status(workspaceId, spaceId);
    if (marker == null) {
      throw StateError('No take-over stands on this conversation.');
    }
    final holder = marker['user_id'];
    if (holder != userId && !asAdmin) {
      throw StateError(
        'Only ${marker['display_name'] ?? holder} or a workspace admin can '
        'hand this conversation back.',
      );
    }
    final summary = await _diffSummary(workspaceId, spaceId);
    await _cache(workspaceId).deleteEntry(workspaceId, cacheKind, spaceId);

    final message = StringBuffer()
      ..write('$displayName handed the worktree back. ')
      ..write(summary);
    if (note.trim().isNotEmpty) {
      message.write('\nNote from $displayName: ${note.trim()}');
    }
    final paused = (marker['paused_run_ids'] as List?)?.cast<String>() ?? [];
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
