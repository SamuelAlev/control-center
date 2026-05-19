import 'package:cc_data/cc_data.dart' show ClientSyncEngine;
import 'package:cc_domain/cc_domain.dart' show UndoClass, newIdempotencyKey;
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:control_center/core/providers/sync_engine_provider.dart';
import 'package:control_center/core/sync/optimistic_mutation.dart';
import 'package:control_center/core/undo/action_journal.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Applies a per-field ticket edit (title / description / priority / labels)
/// through the deterministic sync engine's optimistic path (PRD 16 §6).
///
/// [fields] is the `tickets.patch` wire shape (only `title`, `description`,
/// `priority`, `labels` are patchable — `priority` as its storage int, see
/// [TicketPriority.toStorageInt]; the host rejects any other key). When the
/// `tickets` store is live, the edit is applied to the local synced row
/// instantly (no flicker while the round trip is in flight) via
/// [ClientSyncEngine.storeFor]/`applyOptimistic`, acknowledged on success, and
/// reverted (then rethrown) on failure. When the kill-switch is off (or the
/// store demoted itself), this just calls the op — identical to the pre-PRD-16
/// behavior.
///
/// Status/assignee transitions are NOT routed through here — they stay on
/// `TicketWorkflowService`'s optimistic-locked `tickets.update` path, since
/// they can conflict with a concurrent transition in ways a per-field LWW
/// patch is not designed to arbitrate.
/// When [previousFields] and [undoLabel] are supplied, a successful patch is
/// recorded in the [ActionJournal] so `⌘Z` restores the prior values (PRD 19
/// §4/§5). [previousFields] must hold the SAME keys as [fields], carrying their
/// pre-edit values. The patch (and its inverse) each carry a fresh idempotency
/// key so a retry/replay collapses to one apply.
Future<void> patchTicketOptimistic(
  WidgetRef ref, {
  required String workspaceId,
  required String ticketId,
  required Map<String, dynamic> fields,
  Map<String, dynamic>? previousFields,
  String? undoLabel,
}) async {
  final store = ref.read(syncEngineProvider).storeFor('tickets', workspaceId);
  final repo = ref.read(remoteTicketRepositoryProvider);
  // Optimistic apply → reconcile; a rejection reverts and surfaces loudly
  // (never silently) so the operator never believes a failed edit landed.
  final applied = await runOptimistic(
    store: store,
    table: 'tickets',
    pk: ticketId,
    overlay: _rowOverlayFields(fields),
    mutate: () => repo.patchFields(
      workspaceId,
      ticketId,
      fields,
      idempotencyKey: newIdempotencyKey(),
    ),
    onError: surfaceOptimisticFailure,
  );
  if (applied && previousFields != null && undoLabel != null) {
    ref
        .read(actionJournalProvider.notifier)
        .record(
          UndoableAction(
            label: undoLabel,
            undoClass: UndoClass.reversible,
            undo: () => repo.patchFields(
              workspaceId,
              ticketId,
              previousFields,
              idempotencyKey: newIdempotencyKey(),
            ),
            redo: () => repo.patchFields(
              workspaceId,
              ticketId,
              fields,
              idempotencyKey: newIdempotencyKey(),
            ),
          ),
        );
  }
}

/// Translates the `tickets.patch` fields shape into the `tickets` store's row
/// shape (the `TicketDto`/`ticketToWire` shape the synced rows carry) so the
/// optimistic overlay never disagrees with what `TicketDto.fromJson` expects:
/// `priority` rides the wire as its enum NAME (see `ticketToWire`), not the
/// storage int the patch op takes. Every other patchable key (`title`,
/// `description`, `labels`) is already shaped identically in both places.
Map<String, dynamic> _rowOverlayFields(Map<String, dynamic> fields) {
  final priority = fields['priority'];
  if (priority is! int) {
    return fields;
  }
  return {...fields, 'priority': TicketPriority.fromStorage(priority).name};
}
