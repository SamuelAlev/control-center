import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/mouse_navigation_handler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Opens [fact] on the Memory page.
void openMemoryFact(BuildContext context, MemoryFact fact) =>
    GoRouter.of(context).go(memoryFactRoute(fact.workspaceId, fact.id));

/// Opens [policy] on the Memory page.
void openMemoryPolicy(BuildContext context, MemoryPolicy policy) =>
    GoRouter.of(context).go(memoryPolicyRoute(policy.workspaceId, policy.id));

/// Steps back out of an open record: records link to each other, so a policy's
/// source fact returns to that policy, and the first record to the list.
void leaveMemoryRecord(WidgetRef ref, String workspaceId) => ref
    .read(navigationHistoryProvider.notifier)
    .backOr(memoryRoute(workspaceId));

/// Deletes [fact] once confirmed. Returns whether it went.
Future<bool> deleteMemoryFact(
  BuildContext context,
  WidgetRef ref,
  MemoryFact fact,
) async {
  final l10n = AppLocalizations.of(context);
  // Read first: the row asking may be gone by the time the dialog answers.
  final repo = ref.read(memoryFactRepositoryProvider);
  final confirmed = await _confirmDelete(
    context,
    title: l10n.deleteFact,
    body: l10n.deleteTopicConfirm(fact.topic),
  );
  if (confirmed) {
    await repo.delete(fact.workspaceId, fact.id);
  }
  return confirmed;
}

/// Deletes [policy] once confirmed. Returns whether it went.
Future<bool> deleteMemoryPolicy(
  BuildContext context,
  WidgetRef ref,
  MemoryPolicy policy,
) async {
  final l10n = AppLocalizations.of(context);
  final repo = ref.read(memoryPolicyRepositoryProvider);
  final confirmed = await _confirmDelete(
    context,
    title: l10n.deletePolicy,
    body: l10n.deletePolicyConfirm,
  );
  if (confirmed) {
    await repo.delete(policy.workspaceId, policy.id);
  }
  return confirmed;
}

/// Turns [policy] on or off.
Future<void> setMemoryPolicyActive(
  WidgetRef ref,
  MemoryPolicy policy, {
  required bool active,
}) => ref
    .read(memoryPolicyRepositoryProvider)
    .upsert(policy.copyWith(active: active, updatedAt: DateTime.now()));

/// Whether unsaved edits may go: asks only when there are some.
Future<bool> mayDiscardMemoryEdits(
  BuildContext context, {
  required bool dirty,
}) async {
  if (!dirty) {
    return true;
  }
  final l10n = AppLocalizations.of(context);
  return _confirm(
    context,
    title: l10n.discardChangesTitle,
    body: l10n.discardChangesConfirm,
    confirmLabel: l10n.discard,
  );
}

Future<bool> _confirmDelete(
  BuildContext context, {
  required String title,
  required String body,
}) => _confirm(
  context,
  title: title,
  body: body,
  confirmLabel: AppLocalizations.of(context).delete,
);

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showCcDialog<bool>(
    context: context,
    builder: (dialogContext) => CcDialog(
      title: title,
      content: Text(body),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancel),
        ),
        CcButton(
          variant: CcButtonVariant.destructive,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed == true;
}
