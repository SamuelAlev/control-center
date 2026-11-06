import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_controls.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_feedback.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asks, then deletes a definition. True once it is gone.
Future<bool> deleteEnvironmentDefinition(
  BuildContext context,
  WidgetRef ref, {
  required String workspaceId,
  required String id,
  required String name,
}) async {
  final l10n = AppLocalizations.of(context);
  final toasts = CcToastScope.maybeOf(context);
  final confirmed = await confirmEnvironmentAction(
    context,
    title: l10n.environmentsDeleteTitle(name),
    body: l10n.environmentsDeleteBody,
    confirmLabel: l10n.delete,
  );
  if (!confirmed || !context.mounted) {
    return false;
  }
  try {
    await ref
        .read(environmentRepositoryProvider)
        .deleteDefinition(workspaceId, id);
    ref.invalidate(environmentDefinitionsProvider(workspaceId));
    return true;
  } on Object catch (error) {
    toasts?.show(
      environmentFailureMessage(error),
      variant: CcToastVariant.danger,
    );
    return false;
  }
}
