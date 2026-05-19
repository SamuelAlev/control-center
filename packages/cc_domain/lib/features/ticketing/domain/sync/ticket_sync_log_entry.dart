import 'package:cc_domain/features/ticketing/domain/sync/sync_direction.dart';

/// The outcome recorded for one sync attempt.
enum SyncOutcome {
  /// The change was applied / pushed successfully.
  ok,

  /// The attempt failed (message carries the reason).
  failed,

  /// The change was intentionally not applied (e.g. direction disallows it,
  /// no link, or a CC-owned field with no vendor-won change).
  skipped,

  /// A re-delivered event was dropped before applying (dedupe).
  deduplicated;

  /// Parses a stored value, defaulting to [ok].
  static SyncOutcome fromStorage(String? value) => switch (value) {
    'ok' => SyncOutcome.ok,
    'failed' => SyncOutcome.failed,
    'skipped' => SyncOutcome.skipped,
    'deduplicated' => SyncOutcome.deduplicated,
    _ => SyncOutcome.ok,
  };

  /// Serializes for storage.
  String toStorageString() => name;
}

/// One append-only audit row for a sync attempt, workspace-scoped. The log is
/// the durable record behind the dedupe check (a `(vendor, dedupeKey)` already
/// recorded as `ok` means a webhook was already processed).
class TicketSyncLogEntry {
  /// Creates a [TicketSyncLogEntry].
  TicketSyncLogEntry({
    required this.id,
    required this.workspaceId,
    this.ticketId,
    required this.vendor,
    required this.direction,
    required this.outcome,
    this.message,
    this.dedupeKey,
    required this.createdAt,
  });

  /// Unique row id (UUID v4).
  final String id;

  /// Workspace scope.
  final String workspaceId;

  /// The Control Center ticket involved, when known.
  final String? ticketId;

  /// Vendor identifier.
  final String vendor;

  /// Direction of this attempt (push or pull).
  final SyncDirection direction;

  /// Outcome of the attempt.
  final SyncOutcome outcome;

  /// Human-readable detail (an error message, or a short note).
  final String? message;

  /// Vendor idempotency token (e.g. webhook delivery id) for dedupe.
  final String? dedupeKey;

  /// When the attempt happened.
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TicketSyncLogEntry &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
