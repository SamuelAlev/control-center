import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_feedback.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asks before something that loses data.
Future<bool> confirmEnvironmentAction(
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
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.cancel),
        ),
        CcButton(
          variant: CcButtonVariant.destructive,
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Stops [environment], asking first when its data won't survive.
///
/// A definition still loading is treated as the dangerous case: a warning
/// nobody needed costs a click, a missing one costs the data.
Future<void> stopEnvironment(
  BuildContext context,
  WidgetRef ref,
  EnvironmentSpaceKey key,
  SpaceEnvironment environment, {
  EnvironmentDefinitionRecord? record,
}) async {
  final l10n = AppLocalizations.of(context);
  final definition = record == null ? null : environmentDefinitionOf(record);
  if (!(definition?.keepsDataOnStop ?? false)) {
    final confirmed = await confirmEnvironmentAction(
      context,
      title: l10n.environmentStopTitle,
      body: l10n.environmentStopDataLoss(environment.name),
      confirmLabel: l10n.environmentStopLoseData,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
  }
  await runEnvironmentAction(
    context,
    ref,
    key,
    'stop',
    (repository) => repository.down(key.workspaceId, key.spaceId),
  );
}

/// Destroys [environment] once someone has confirmed it.
Future<void> destroyEnvironment(
  BuildContext context,
  WidgetRef ref,
  EnvironmentSpaceKey key,
  SpaceEnvironment environment,
) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await confirmEnvironmentAction(
    context,
    title: l10n.environmentDestroyTitle,
    body: l10n.environmentDestroyBody(environment.name),
    confirmLabel: l10n.environmentDestroy,
  );
  if (confirmed && context.mounted) {
    await runEnvironmentAction(
      context,
      ref,
      key,
      'destroy',
      (repository) => repository.destroy(key.workspaceId, key.spaceId),
    );
  }
}
