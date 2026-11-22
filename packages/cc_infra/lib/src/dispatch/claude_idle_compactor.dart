import 'dart:async';

import 'package:cc_domain/features/settings/domain/entities/claude_session_settings.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// What a turn that ended cleanly leaves behind for [ClaudeIdleCompactor].
class ClaudeSettledTurn {
  /// Creates a [ClaudeSettledTurn].
  const ClaudeSettledTurn({
    required this.workspaceId,
    required this.spaceId,
    required this.conversationId,
    required this.agentId,
    required this.contextTokens,
    required this.cacheTtl,
    this.requestedByUserId,
  });

  /// The workspace the conversation is in.
  final String workspaceId;

  /// The space the conversation is in.
  final String spaceId;

  /// The conversation whose native session this turn ran in.
  final String conversationId;

  /// The agent that ran the turn.
  final String agentId;

  /// How much context the session holds.
  final int contextTokens;

  /// How long the prompt cache of the turn's last write lasts. Null when the
  /// turn wrote nothing to it, which leaves the expiry unknown.
  final Duration? cacheTtl;

  /// Who the turn ran for, so a compaction is attributed to them too.
  final String? requestedByUserId;
}

/// Compacts an idle Claude Code session just before its prompt cache expires.
///
/// A long conversation left idle past its cache costs a full uncached read the
/// next time anyone speaks in it. Compacting while the cache is warm reads the
/// same context at the cached price, and the next turn starts small. Waiting
/// timers live in memory: a server restart skips the ones still waiting, which
/// only ever costs the saving, never a wrong compaction.
class ClaudeIdleCompactor {
  /// Creates a [ClaudeIdleCompactor]. The setting is read when a turn settles
  /// and again when its timer fires, so turning it off stops what is waiting.
  ClaudeIdleCompactor({required this._enabled});

  final bool Function() _enabled;
  final _timers = <String, Timer>{};

  /// The prompt-cache lifetime the last settled turn of each conversation
  /// reported (insertion-ordered, so the oldest is dropped first).
  final _ttls = <String, Duration>{};

  /// The most conversations whose cache lifetime is remembered.
  static const int maxRememberedTtls = 4096;

  /// Starts the compaction turn. Assigned once the messaging layer exists,
  /// which is built after the dispatch layer that reports to this class.
  Future<Object?> Function(ClaudeSettledTurn turn)? compact;

  /// How long before expiry to start: enough for the session to resume and
  /// send the compaction while the cache is still warm.
  static const Duration lead = Duration(minutes: 2);

  static String _key(String workspaceId, String conversationId) =>
      '$workspaceId/$conversationId';

  /// A run started in this conversation: whatever was waiting is out of date,
  /// and that run's own end decides what happens next.
  void runStarted(String workspaceId, String conversationId) =>
      _timers.remove(_key(workspaceId, conversationId))?.cancel();

  /// A turn ended cleanly. Waits for its cache's expiry when it is worth it.
  void turnSettled(ClaudeSettledTurn turn) {
    final ttl = turn.cacheTtl;
    if (ttl != null) {
      final ttlKey = _key(turn.workspaceId, turn.conversationId);
      _ttls.remove(ttlKey);
      _ttls[ttlKey] = ttl;
      if (_ttls.length > maxRememberedTtls) {
        _ttls.remove(_ttls.keys.first);
      }
    }
    if (ttl == null ||
        turn.contextTokens < ClaudeSessionSettings.minIdleCompactTokens ||
        !_enabled()) {
      return;
    }
    final key = _key(turn.workspaceId, turn.conversationId);
    _timers.remove(key)?.cancel();
    final wait = ttl - lead;
    _timers[key] = Timer(wait.isNegative ? Duration.zero : wait, () {
      _timers.remove(key);
      if (_enabled()) {
        unawaited(_run(turn));
      }
    });
  }

  Future<void> _run(ClaudeSettledTurn turn) async {
    try {
      await compact?.call(turn);
    } on Object catch (e) {
      CcInfraLog.warning(
        'idle compaction of ${turn.conversationId} skipped: $e',
      );
    }
  }

  /// The prompt-cache lifetime the last Claude turn in this conversation
  /// reported (five minutes on an API key, an hour on a subscription), or
  /// null when no Claude turn has settled there since the server started.
  Duration? cacheTtlFor(String workspaceId, String conversationId) =>
      _ttls[_key(workspaceId, conversationId)];

  /// Cancels everything waiting.
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }
}
