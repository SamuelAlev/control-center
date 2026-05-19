import 'dart:convert';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_persistence/database/daos/cache_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';

/// The take-over / hand-back mechanism (PRD 16 §8) — defined, not vibes:
///
///  1. **Begin**: every active run in the conversation is paused at its next
///     clean turn boundary (built-in harness) or stopped (external CLI — no
///     safe boundary exists). The per-turn git snapshot taken at that
///     boundary makes the take-over reversible. A DURABLE take-over marker
///     lands in the `Caches` table, so a server restart comes back paused —
///     never auto-resuming into a human's half-finished edit — and new
///     dispatches into the space are refused while it stands.
///  2. The human edits the SAME rift worktree through the embedded
///     code-server IDE (already shipped; the client opens it).
///  3. **Hand back**: a structured diff summary of the worktree is posted to
///     the space, queued as steering for every paused run (the agent
///     re-reads it before resuming), the runs resume and the marker clears.
///
/// One live editor per worktree is a SOFT claim: the marker + the presence
/// lane make a second take-over visible and refused, not silently merged.
class TakeoverService {
  /// Creates the service.
  TakeoverService({
    required WorkspaceDatabaseManager workspaceDbs,
    required AgentRunLogRepository runLogs,
    required MessagingRepository messaging,
    required Future<bool> Function(String runLogId) pauseRun,
    required Future<bool> Function(String runLogId) resumeRun,
    required Future<void> Function(String workspaceId, String runLogId) stopRun,
    required Future<bool> Function(String runLogId, String message) steerRun,
    required Future<List<PrFile>> Function(String workspaceId, String spaceId)
    conversationChanges,
  }) : _dbs = workspaceDbs,
       _runLogs = runLogs,
       _messaging = messaging,
       _pauseRun = pauseRun,
       _resumeRun = resumeRun,
       _stopRun = stopRun,
       _steerRun = steerRun,
       _conversationChanges = conversationChanges;

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
    } catch (_) {
      return null;
    }
  }

  /// Whether a take-over stands on [spaceId] (dispatch gating).
  Future<bool> isActive(String workspaceId, String spaceId) async =>
      await status(workspaceId, spaceId) != null;

  /// Begins a take-over: pauses/stops the space's active runs and writes
  /// the durable marker. Throws [StateError] when someone already holds it
  /// (one live editor per worktree — refuse loudly, never silently share).
  Future<Map<String, dynamic>> begin({
    required String workspaceId,
    required String spaceId,
    required String userId,
    required String displayName,
  }) async {
    final existing = await status(workspaceId, spaceId);
    if (existing != null) {
      throw StateError(
        'This conversation is already taken over by '
        '${existing['display_name'] ?? existing['user_id']}.',
      );
    }
    final active = await _runLogs
        .watchActiveBySpace(workspaceId, spaceId)
        .first;
    final paused = <String>[];
    final stopped = <String>[];
    for (final run in active) {
      if (run.status != RunStatus.running && run.status != RunStatus.pending) {
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
    final marker = <String, dynamic>{
      'user_id': userId,
      'display_name': displayName,
      'since': DateTime.now().toIso8601String(),
      'paused_run_ids': paused,
      'stopped_run_ids': stopped,
    };
    await _cache(
      workspaceId,
    ).put(workspaceId, cacheKind, spaceId, jsonEncode(marker));
    await _messaging.sendMessage(
      workspaceId: workspaceId,
      spaceId: spaceId,
      content:
          '$displayName took over this conversation\'s worktree'
          '${paused.isEmpty ? '' : ' (${paused.length} run(s) paused at a turn boundary)'}'
          '${stopped.isEmpty ? '' : ' (${stopped.length} run(s) stopped)'}.',
      senderId: 'system',
      senderType: 'agent',
      messageType: 'system',
    );
    return marker;
  }

  /// Hands control back: posts the diff summary, steers + resumes the paused
  /// runs, clears the marker. Returns the summary that was posted.
  Future<Map<String, dynamic>> handBack({
    required String workspaceId,
    required String spaceId,
    required String userId,
    required String displayName,
    String note = '',
  }) async {
    final marker = await status(workspaceId, spaceId);
    if (marker == null) {
      throw StateError('No take-over stands on this conversation.');
    }
    final summary = await _diffSummary(workspaceId, spaceId);
    final message = StringBuffer()
      ..write('$displayName handed the worktree back. ')
      ..write(summary);
    if (note.trim().isNotEmpty) {
      message.write('\nNote from $displayName: ${note.trim()}');
    }
    await _messaging.sendMessage(
      workspaceId: workspaceId,
      spaceId: spaceId,
      content: message.toString(),
      senderId: 'system',
      senderType: 'agent',
      messageType: 'system',
    );

    final paused = (marker['paused_run_ids'] as List?)?.cast<String>() ?? [];
    for (final runId in paused) {
      // The agent re-reads the hand-back before resuming: the steering
      // message is drained at the top of the resumed turn.
      await _steerRun(
        runId,
        'The human took over the worktree and handed it back. $message '
        'Re-read the recent changes before continuing.',
      );
      await _resumeRun(runId);
    }
    await _cache(workspaceId).deleteEntry(workspaceId, cacheKind, spaceId);
    return {'summary': summary, 'resumed_run_ids': paused};
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
