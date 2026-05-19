import 'package:cc_domain/cc_domain.dart' show UndoClass;
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/undo/action_journal.dart';
import 'package:control_center/features/pr_review/presentation/widgets/review_finding_dismiss_dialog.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Moves a review finding to [status], asking for a reason on a dismissal.
///
/// The reason is not ceremony: it becomes the suppression fact future reviewers
/// read and that the finalizer matches new findings against, so a dismissal
/// with none hides a row and teaches nothing — the pattern returns on the next
/// pull request.
///
/// Lives beside the finding widgets rather than inside one because the same
/// three controls belong on any surface that shows a finding, and the undo
/// bookkeeping is the part that must not be reimplemented per host.
///
/// Returns true when the status changed. Failures are reported to the caller's
/// toast host and return false — a status the server refused must not leave the
/// row looking as if it took.
Future<bool> applyReviewFindingStatus(
  WidgetRef ref,
  BuildContext context, {
  required String spaceId,
  required String nodeMessageId,
  required ReviewNodeStatus status,
}) async {
  final l10n = AppLocalizations.of(context);
  final toaster = CcToastScope.of(context);

  String? reason;
  if (status == ReviewNodeStatus.dismissed) {
    reason = await promptForDismissalReason(context);
    if (reason == null) {
      return false;
    }
  }
  if (!context.mounted) {
    return false;
  }

  Future<Map<String, dynamic>> call(ReviewNodeStatus to, String? why) =>
      ref.read(rpcClientProvider).call('pr_review.setFindingStatus', {
        'workspace_id': ref.requireWorkspaceId(),
        'space_id': spaceId,
        'node_message_id': nodeMessageId,
        'status': to.wireName,
        if (why != null && why.isNotEmpty) 'reason': why,
      });

  try {
    final result = await call(status, reason);

    // The op reports what the status WAS, so undo restores the real prior value
    // rather than assuming `open` — undoing a reopen must not silently mark the
    // finding fixed.
    final previous =
        ReviewNodeStatus.fromName(result['previous_status'] as String?) ??
        ReviewNodeStatus.open;
    if (previous != status) {
      ref
          .read(actionJournalProvider.notifier)
          .record(
            UndoableAction(
              label: l10n.reviewFindingStatusUndoLabel,
              undoClass: UndoClass.reversible,
              // The reason is deliberately not replayed on undo: it described
              // the dismissal being taken back, and re-attaching it would teach
              // the suppression memory a lesson nobody meant.
              undo: () => call(previous, null),
              redo: () => call(status, reason),
            ),
          );
    }
    return true;
  } on Object catch (e) {
    toaster.show(
      l10n.reviewFindingStatusFailed('$e'),
      variant: CcToastVariant.danger,
    );
    return false;
  }
}
