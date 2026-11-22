import 'package:cc_data/src/wire_decode.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/conversation_wakes_repository.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_admission.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Decodes one `wakes.watchForConversation` row. Throws on a row the client
/// cannot read (an unknown reason, state or lane), which `decodeRows` drops.
WakeView wakeViewFromWire(Map<String, dynamic> w) => WakeView(
  id: w['id'] as String,
  workspaceId: w['workspace_id'] as String,
  spaceId: w['space_id'] as String? ?? '',
  conversationId: w['conversation_id'] as String,
  agentId: w['agent_id'] as String,
  reason:
      WakeReasonWire.tryParse(w['reason'] as String?) ??
      (throw FormatException('unknown wake reason ${w['reason']}')),
  origin: w['origin'] as String? ?? '',
  headline: w['headline'] as String? ?? '',
  state:
      WakeStateWire.tryParse(w['state'] as String?) ??
      (throw FormatException('unknown wake state ${w['state']}')),
  stateReason: w['state_reason'] as String?,
  lane:
      WakeLaneWire.tryParse(w['lane'] as String?) ??
      (throw FormatException('unknown wake lane ${w['lane']}')),
  notBefore: DateTime.parse(w['not_before'] as String),
  expiresAt: switch (w['expires_at']) {
    final String at => DateTime.parse(at),
    _ => null,
  },
  createdAt: DateTime.parse(w['created_at'] as String),
  requestedByUserId: w['requested_by_user_id'] as String?,
  attempt: (w['attempt'] as num?)?.toInt() ?? 0,
  // The server's answer for this viewer; absent reads as "not yours".
  canRelease: w['can_release'] == true,
  sourceAgentId: w['source_agent_id'] as String?,
  goalId: w['goal_id'] as String?,
  ruleId: w['rule_id'] as String?,
  askId: w['ask_id'] as String?,
);

/// Decodes a `wakes.deliverNow` receipt.
WakeReceipt wakeReceiptFromWire(Map<String, dynamic> w) =>
    switch (w['outcome']) {
      'started' => WakeStarted(w['run_id'] as String),
      'pushed' => WakePushed(w['run_id'] as String),
      'waiting' => WakeWaiting(w['kind'] as String? ?? ''),
      'skipped' => WakeSkipped(w['kind'] as String? ?? ''),
      'duplicate' => const WakeDuplicate(),
      final other => throw FormatException('unknown wake receipt $other'),
    };

/// [ConversationWakesRepository] over the `wakes.*` RPC ops.
class RpcConversationWakesRepository implements ConversationWakesRepository {
  /// Creates the repository over [_client].
  RpcConversationWakesRepository(this._client);

  final RemoteRpcClient _client;

  @override
  Stream<List<WakeView>> watchForConversation(
    String workspaceId,
    String conversationId,
  ) => _client
      .subscribe('wakes.watchForConversation', {
        'workspace_id': workspaceId,
        'conversation_id': conversationId,
      })
      .map(
        (data) => decodeRows(
          [
            for (final row in (data['wakes'] as List?) ?? const [])
              if (row is Map) row.cast<String, dynamic>(),
          ],
          wakeViewFromWire,
          what: 'wake',
        ),
      );

  @override
  Future<bool> cancel(String workspaceId, String wakeId) async {
    final data = await _client.call('wakes.cancel', {
      'workspace_id': workspaceId,
      'wake_id': wakeId,
    });
    return data['cancelled'] == true;
  }

  @override
  Future<int> release(
    String workspaceId, {
    String? wakeId,
    String? conversationId,
  }) async {
    if (wakeId == null && conversationId == null) {
      throw ArgumentError('release needs a wake id or a conversation id');
    }
    final data = await _client.call('wakes.release', {
      'workspace_id': workspaceId,
      'wake_id': ?wakeId,
      'conversation_id': ?conversationId,
    });
    return (data['released'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<WakeReceipt> deliverNow(String workspaceId, String wakeId) async =>
      wakeReceiptFromWire(
        await _client.call('wakes.deliverNow', {
          'workspace_id': workspaceId,
          'wake_id': wakeId,
        }),
      );
}
