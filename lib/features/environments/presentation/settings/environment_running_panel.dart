import 'dart:async';

import 'package:cc_domain/features/environments/domain/ports/environment_port.dart'
    show EnvironmentInstance;
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/settings/environment_form_fields.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_feedback.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_labels.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_lifecycle_actions.dart';
import 'package:control_center/features/environments/providers/environment_actions.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What a definition still holds across every space, to free up from one place.
///
/// An environment keeps its memory and CPU until someone removes it, and the
/// space it runs in may be one nobody has open.
class EnvironmentRunningPanel extends ConsumerWidget {
  /// Creates an [EnvironmentRunningPanel].
  const EnvironmentRunningPanel({super.key, required this.form});

  /// The definition being edited.
  final EnvironmentForm form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final record = form.state.record;
    if (record == null) {
      return const SizedBox.shrink();
    }
    final instances = ref.watch(
      environmentInstancesProvider((
        workspaceId: form.workspaceId,
        definitionId: record.id,
      )),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: instances.when(
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: CcSpinner()),
        error: (error, _) => CcAlert(
          variant: CcAlertVariant.danger,
          title: environmentFailureMessage(error),
        ),
        data: (items) => items.isEmpty
            ? Text(
                l10n.environmentsNothingRunning,
                style: CcTypography.caption.copyWith(color: t.textTertiary),
              )
            : SettingsGroup(
                separator: SettingsGroupSeparator.rule,
                children: [
                  for (final instance in items)
                    _InstanceRow(
                      key: ValueKey(instance.environment.id),
                      workspaceId: form.workspaceId,
                      instance: instance,
                    ),
                ],
              ),
      ),
    );
  }
}

class _InstanceRow extends ConsumerWidget {
  const _InstanceRow({
    super.key,
    required this.workspaceId,
    required this.instance,
  });

  final String workspaceId;
  final EnvironmentInstance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final environment = instance.environment;
    final key = (workspaceId: workspaceId, spaceId: environment.spaceId);
    final inFlight = ref.watch(environmentActionsProvider(key));
    final (status, tone) = environmentDisplay(l10n, environment);
    final destroying =
        inFlight.contains('destroy') ||
        environment.status == EnvironmentStatus.destroying;
    final stopping = inFlight.contains('stop');
    return SettingsEntityRow(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      icon: AppIcons.boxes,
      title: instance.spaceName ?? environment.name,
      tone: tone,
      statusLabel: status,
      // RTL carve-out: an environment name is a branch-derived token.
      subtitleWidget: Directionality(
        textDirection: TextDirection.ltr,
        child: Text(environment.name, style: CcFonts.code()),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (environment.status.isRunning)
            CcIconButton(
              icon: AppIcons.circleStop,
              size: CcButtonSize.sm,
              tooltip: l10n.stop,
              loading: stopping,
              onPressed: stopping || environment.status.isBusy
                  ? null
                  : () => unawaited(
                      stopEnvironment(context, ref, key, environment),
                    ),
            ),
          CcIconButton(
            variant: CcButtonVariant.destructive,
            icon: AppIcons.trash2,
            size: CcButtonSize.sm,
            tooltip: l10n.environmentDestroy,
            loading: destroying,
            onPressed: destroying
                ? null
                : () => unawaited(
                    destroyEnvironment(context, ref, key, environment).then((
                      _,
                    ) {
                      // Gone now, not at the next refresh.
                      ref.invalidate(
                        environmentInstancesProvider((
                          workspaceId: workspaceId,
                          definitionId: environment.definitionId,
                        )),
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }
}
