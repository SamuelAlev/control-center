import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_host.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_labels.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_row_actions.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// A supervised process: its restarts, its terminal, Restart and Stop.
class EnvironmentProcessBody extends StatelessWidget {
  /// Creates an [EnvironmentProcessBody].
  const EnvironmentProcessBody({
    super.key,
    required this.spaceKey,
    required this.environment,
    required this.component,
    this.part = EnvironmentBodyPart.details,
  });

  /// The space it runs in.
  final EnvironmentSpaceKey spaceKey;

  /// The environment it belongs to.
  final SpaceEnvironment environment;

  /// Its reported state.
  final EnvironmentComponentState component;

  /// Which half of the row this renders.
  final EnvironmentBodyPart part;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final host = EnvironmentHostScope.maybeOf(context);
    final label = component.label ?? component.id;
    final sessionId = component.sessionId;
    final live = environmentHasLiveParts(environment.status);
    final idle = !environment.status.isBusy;
    final actions = EnvironmentRowActions(
      children: [
        if (host != null)
          EnvironmentOpenButton(
            label: l10n.openLabel,
            icon: AppIcons.terminal,
            // A process with no live PTY still has its log ring.
            onPressed: () => sessionId == null
                ? host.openLogs(
                    spaceId: spaceKey.spaceId,
                    target: component.id,
                    label: label,
                  )
                : host.openProcess(
                    spaceId: spaceKey.spaceId,
                    sessionId: sessionId,
                    label: label,
                  ),
          ),
        if (live)
          EnvironmentActionButton(
            spaceKey: spaceKey,
            actionKey: 'restart:${component.id}',
            label: l10n.environmentRestart,
            icon: AppIcons.rotateCw,
            enabled: idle,
            action: (repository) => repository.restartProcess(
              spaceKey.workspaceId,
              spaceKey.spaceId,
              component.id,
            ),
          ),
        if (live && component.state != 'stopped')
          EnvironmentActionButton(
            spaceKey: spaceKey,
            actionKey: 'stop:${component.id}',
            label: l10n.stop,
            icon: AppIcons.circleStop,
            enabled: idle,
            action: (repository) => repository.stopProcess(
              spaceKey.workspaceId,
              spaceKey.spaceId,
              component.id,
            ),
          ),
      ],
    );
    if (part == EnvironmentBodyPart.actions) {
      return actions;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (component.restarts > 0)
          Text(
            l10n.environmentRestarts(component.restarts),
            style: CcTypography.caption.copyWith(color: t.textTertiary),
          ),
      ],
    );
  }
}
