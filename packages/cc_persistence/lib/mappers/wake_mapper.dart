import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_detail.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_run_options.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

/// Maps between [Wake] and `agent_wakes` rows. Drift reads a `dateTime()`
/// column back as a local time; every time is turned back into UTC here.
///
/// Reading is defensive: a row the entity refuses (an unknown reason after a
/// downgrade, a payload over the limit written by hand) reads as null and is
/// left out of lists rather than failing every read of the queue. The JSON
/// columns degrade on their own: a malformed detail reads as empty, malformed
/// run options as the defaults.
class WakeMapper {
  /// Creates a [WakeMapper].
  const WakeMapper();

  /// The wake [row] holds, or null when it is not a valid wake.
  Wake? tryToDomain(AgentWakesTableData row) {
    final reason = WakeReasonWire.tryParse(row.reason);
    final lane = WakeLaneWire.tryParse(row.lane);
    final state = WakeStateWire.tryParse(row.state);
    if (reason == null || lane == null || state == null) {
      return null;
    }
    try {
      return Wake(
        id: row.id,
        workspaceId: row.workspaceId,
        spaceId: row.spaceId,
        conversationId: row.conversationId,
        agentId: row.agentId,
        reason: reason,
        lane: lane,
        payload: row.payload,
        detail: WakeDetail.tryParse(row.detail),
        runOptions: WakeRunOptions.tryParse(row.runOptions),
        dedupKey: row.dedupKey,
        notBefore: row.notBefore.toUtc(),
        expiresAt: row.expiresAt?.toUtc(),
        requestedByUserId: row.requestedByUserId,
        chain: decodeIds(row.chain),
        expectsReply: row.expectsReply,
        state: state,
        stateReason: row.stateReason,
        deliveredRunId: row.deliveredRunId,
        attempt: row.attempt,
        createdAt: row.createdAt.toUtc(),
        claimedAt: row.claimedAt?.toUtc(),
        settledAt: row.settledAt?.toUtc(),
      );
    } on ArgumentError {
      return null;
    }
  }

  /// The valid wakes among [rows], in order.
  List<Wake> toDomainList(Iterable<AgentWakesTableData> rows) => [
    for (final row in rows) ?tryToDomain(row),
  ];

  /// Every column of [wake].
  AgentWakesTableCompanion toCompanion(Wake wake) => AgentWakesTableCompanion(
    id: Value(wake.id),
    workspaceId: Value(wake.workspaceId),
    spaceId: Value(wake.spaceId),
    conversationId: Value(wake.conversationId),
    agentId: Value(wake.agentId),
    reason: Value(wake.reason.wire),
    lane: Value(wake.lane.wire),
    payload: Value(wake.payload),
    detail: Value(wake.detail.encode()),
    runOptions: Value(wake.runOptions?.encode()),
    dedupKey: Value(wake.dedupKey),
    notBefore: Value(wake.notBefore),
    expiresAt: Value(wake.expiresAt),
    requestedByUserId: Value(wake.requestedByUserId),
    chain: Value(jsonEncode(wake.chain)),
    expectsReply: Value(wake.expectsReply),
    state: Value(wake.state.wire),
    stateReason: Value(wake.stateReason),
    deliveredRunId: Value(wake.deliveredRunId),
    attempt: Value(wake.attempt),
    createdAt: Value(wake.createdAt),
    claimedAt: Value(wake.claimedAt),
    settledAt: Value(wake.settledAt),
  );

  /// The non-empty strings of a JSON array column; empty for anything else.
  static List<String> decodeIds(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }
      return [
        for (final item in decoded)
          if (item is String && item.isNotEmpty) item,
      ];
    } on FormatException {
      return const [];
    }
  }
}
