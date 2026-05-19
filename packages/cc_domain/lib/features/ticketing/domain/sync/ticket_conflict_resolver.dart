import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_field_conflict_policy.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_delta.dart';

/// The outcome of merging a vendor [TicketSyncDelta] into a local [Ticket]
/// under a [TicketFieldConflictPolicy].
class TicketMergeResult {
  /// Creates a [TicketMergeResult].
  const TicketMergeResult({
    required this.merged,
    required this.appliedFromVendor,
  });

  /// The ticket after applying every vendor-won field that actually changed.
  final Ticket merged;

  /// The fields whose value was taken from the vendor. Empty when the pull was
  /// a no-op (every diverging field is CC-owned, or nothing diverged).
  final Set<TicketSyncField> appliedFromVendor;

  /// Whether the merge changed anything.
  bool get changed => appliedFromVendor.isNotEmpty;
}

/// Resolves field-level conflicts when a vendor pull lands on a ticket that
/// also exists in Control Center. Each field is taken from the vendor only when
/// the [TicketFieldConflictPolicy] says the vendor wins AND the incoming value
/// is both present and different — so a vendor-won field that did not change is
/// not counted as an applied change and a CC-won field is never overwritten.
///
/// Assignee is deliberately not merged here: a vendor assignee is a vendor user
/// id, not a Control Center agent, so the engine translates it separately.
class TicketConflictResolver {
  /// Creates a [TicketConflictResolver].
  const TicketConflictResolver();

  /// Merges [incoming] into [local] under [policy].
  TicketMergeResult merge({
    required Ticket local,
    required TicketSyncDelta incoming,
    required TicketFieldConflictPolicy policy,
  }) {
    final applied = <TicketSyncField>{};
    var result = local;

    if (policy.vendorWins(TicketSyncField.title) &&
        incoming.title != null &&
        incoming.title != local.title) {
      result = result.copyWith(title: incoming.title);
      applied.add(TicketSyncField.title);
    }
    if (policy.vendorWins(TicketSyncField.description) &&
        incoming.description != null &&
        incoming.description != local.description) {
      result = result.copyWith(description: incoming.description);
      applied.add(TicketSyncField.description);
    }
    if (policy.vendorWins(TicketSyncField.priority) &&
        incoming.priority != null &&
        incoming.priority != local.priority) {
      result = result.copyWith(priority: incoming.priority);
      applied.add(TicketSyncField.priority);
    }
    if (policy.vendorWins(TicketSyncField.labels) &&
        incoming.labels != null &&
        !_sameLabels(incoming.labels!, local.labels)) {
      result = result.copyWith(labels: incoming.labels);
      applied.add(TicketSyncField.labels);
    }
    if (policy.vendorWins(TicketSyncField.status) &&
        incoming.status != null &&
        incoming.status != local.status) {
      result = result.copyWith(
        status: incoming.status,
        rawStatus: incoming.rawStatus,
      );
      applied.add(TicketSyncField.status);
    }

    return TicketMergeResult(merged: result, appliedFromVendor: applied);
  }

  static bool _sameLabels(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    final sortedA = [...a]..sort();
    final sortedB = [...b]..sort();
    for (var i = 0; i < sortedA.length; i++) {
      if (sortedA[i] != sortedB[i]) {
        return false;
      }
    }
    return true;
  }
}
