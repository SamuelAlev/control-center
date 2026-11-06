import 'dart:async';

import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_controls.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_feedback.dart';
import 'package:control_center/features/environments/providers/environment_actions.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shown when a change needs destroy and start. CC never acts on this alone.
class EnvironmentRecreateNotice extends ConsumerWidget {
  /// Creates an [EnvironmentRecreateNotice].
  const EnvironmentRecreateNotice({
    super.key,
    required this.spaceKey,
    required this.environment,
  });

  /// The space it runs in.
  final EnvironmentSpaceKey spaceKey;

  /// What the server last reported.
  final SpaceEnvironment environment;

  Future<void> _recreate(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmEnvironmentAction(
      context,
      title: l10n.environmentRecreateTitle,
      body: l10n.environmentRecreateBody(environment.name),
      confirmLabel: l10n.environmentRecreate,
    );
    if (confirmed && context.mounted) {
      await runEnvironmentAction(context, ref, spaceKey, 'recreate', (
        repository,
      ) async {
        await repository.destroy(spaceKey.workspaceId, spaceKey.spaceId);
        await repository.ensure(
          spaceKey.workspaceId,
          spaceKey.spaceId,
          definitionId: environment.definitionId,
          options: environment.options,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final busy = ref
        .watch(environmentActionsProvider(spaceKey))
        .contains('recreate');
    return CcAlert(
      variant: CcAlertVariant.warning,
      title: l10n.environmentNeedsRecreate,
      action: Align(
        alignment: AlignmentDirectional.centerStart,
        child: CcButton(
          variant: CcButtonVariant.secondary,
          size: CcButtonSize.sm,
          loading: busy,
          onPressed: busy ? null : () => unawaited(_recreate(context, ref)),
          child: Text(l10n.environmentRecreate),
        ),
      ),
    );
  }
}
