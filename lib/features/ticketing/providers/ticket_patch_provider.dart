import 'package:cc_domain/cc_domain.dart' show UndoClass, newIdempotencyKey;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/undo/action_journal.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Applies a per-field ticket edit (title / description / priority / labels)
/// through the `tickets.patch` per-column LWW op.
/// [fields] is the `tickets.patch` wire shape (only `title`, `description`, `priority`,
/// `labels` are patchable — `priority` as its storage int, see
/// `TicketPriority.toStorageInt`; the host rejects any other key).
/// [previousFields] must hold the SAME keys as [fields], carrying their pre-edit values.
/// The patch (and its inverse) each carry a fresh idempotency key so a retry/replay
/// collapses to one apply.
Future<void> patchTicketFields(
  WidgetRef ref, {
  required String workspaceId,
  required String ticketId,
  required Map<String, dynamic> fields,
  Map<String, dynamic>? previousFields,
  String? undoLabel,
}) async {
  final repo = ref.read(remoteTicketRepositoryProvider);
  try {
    await repo.patchFields(
      workspaceId,
      ticketId,
      fields,
      idempotencyKey: newIdempotencyKey(),
    );
  } catch (_) {
    // A rejection surfaces loudly (never silently) so the operator never
    // believes a failed edit landed.
    _surfacePatchFailure();
    return;
  }
  if (previousFields != null && undoLabel != null) {
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

/// Shows a danger toast on the root overlay (which sits under the app's
/// [CcToastScope]); called from a callback with no local context.
void _surfacePatchFailure() {
  final ctx = rootNavigatorKey.currentContext;
  if (ctx == null) {
    return;
  }
  CcToastScope.maybeOf(ctx)?.show(
    AppLocalizations.of(ctx).optimisticChangeReverted,
    variant: CcToastVariant.danger,
  );
}
