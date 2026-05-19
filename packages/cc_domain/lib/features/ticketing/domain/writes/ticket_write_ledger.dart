import 'dart:convert';

import 'package:cc_domain/features/ticketing/domain/writes/ticket_write_result.dart';

/// A persisted record of one completed agent ticket write, keyed by its
/// idempotency `writeId`. Workspace-scoped: a `writeId` is unique per workspace.
class TicketWriteLedgerEntry {
  /// Creates a [TicketWriteLedgerEntry].
  TicketWriteLedgerEntry({
    required this.workspaceId,
    required this.writeId,
    required this.operation,
    required this.resultJson,
    required this.createdAt,
  });

  /// Workspace scope.
  final String workspaceId;

  /// Caller-supplied idempotency token (UUID).
  final String writeId;

  /// The operation that was run (e.g. `comment_add`, `status_set`).
  final String operation;

  /// The JSON-encoded [TicketWriteResult] that was returned.
  final String resultJson;

  /// When the write completed.
  final DateTime createdAt;
}

/// Persistence boundary for the idempotency ledger (workspace-scoped).
abstract interface class TicketWriteLedgerRepository {
  /// The recorded entry for `(workspaceId, writeId)`, or null.
  Future<TicketWriteLedgerEntry?> find(String workspaceId, String writeId);

  /// Records a completed write. Idempotent on `(workspaceId, writeId)`.
  Future<void> record(TicketWriteLedgerEntry entry);
}

/// Deduplicates agent ticket writes by `writeId`.
///
/// An agent retrying a flaky write (a dropped connection mid-comment, a tool
/// re-invocation) passes the same `writeId`; [runOnce] then replays the
/// original result with `meta.deduplicated: true` instead of applying the
/// change a second time. A write with no `writeId` always runs (no dedupe).
class TicketWriteLedger {
  /// Creates a [TicketWriteLedger] over a persistence [repository]. [now] is
  /// injectable for deterministic tests.
  TicketWriteLedger({required this.repository, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// The ledger store.
  final TicketWriteLedgerRepository repository;

  final DateTime Function() _now;

  /// Runs [run] exactly once per `(workspaceId, writeId)`.
  ///
  /// When [writeId] is null/empty the write is not deduplicated and [run]
  /// executes normally. Otherwise: a prior record replays its result flagged
  /// deduplicated; a first run executes [run], persists a successful result,
  /// and returns it. A failing result is NOT recorded, so a transient failure
  /// can be retried with the same `writeId`.
  Future<TicketWriteResult> runOnce({
    required String workspaceId,
    required String? writeId,
    required String operation,
    required Future<TicketWriteResult> Function() run,
  }) async {
    if (writeId == null || writeId.isEmpty) {
      return run();
    }
    final existing = await repository.find(workspaceId, writeId);
    if (existing != null) {
      final decoded = jsonDecode(existing.resultJson);
      if (decoded is Map<String, dynamic>) {
        return TicketWriteResult.fromJson(decoded).asDeduplicated();
      }
    }
    final result = await run();
    // Only a successful write is durable: a failure must be retryable with the
    // same writeId rather than permanently cached as the answer.
    if (result.ok) {
      await repository.record(
        TicketWriteLedgerEntry(
          workspaceId: workspaceId,
          writeId: writeId,
          operation: operation,
          resultJson: jsonEncode(result.toJson()),
          createdAt: _now(),
        ),
      );
    }
    return result;
  }
}
