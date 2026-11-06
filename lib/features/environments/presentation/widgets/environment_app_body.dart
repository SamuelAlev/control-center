import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_component.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:collection/collection.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_host.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_row_actions.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// A desktop app. It starts only on an explicit Launch, and closing it is a
/// normal state rather than a failure.
class EnvironmentAppBody extends StatelessWidget {
  /// Creates an [EnvironmentAppBody].
  const EnvironmentAppBody({
    super.key,
    required this.spaceKey,
    required this.environment,
    required this.component,
    this.part = EnvironmentBodyPart.details,
    this.definition,
  });

  /// The space it runs in.
  final EnvironmentSpaceKey spaceKey;

  /// The environment it belongs to.
  final SpaceEnvironment environment;

  /// Its reported state.
  final EnvironmentComponentState component;

  /// Which half of the row this renders.
  final EnvironmentBodyPart part;

  /// The definition, once loaded.
  final EnvironmentDefinition? definition;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final host = EnvironmentHostScope.maybeOf(context);
    final open = component.state == 'running' || component.state == 'ready';
    final status = environment.status;
    // Launch needs a running environment: a stopped one has no contract.
    final canLaunch =
        !status.isBusy &&
        status != EnvironmentStatus.stopped &&
        status != EnvironmentStatus.gone;
    final app = definition?.component(component.id);
    final prepares = app is! AppEnvironmentComponent || app.prepare != null;
    final viewer = component.services.firstWhereOrNull(
      (service) => service['name'] == 'window' && service['rig_id'] is String,
    );
    final sessionId = component.sessionId;
    final label = component.label ?? component.id;
    final t = context.designSystem ?? DesignSystemTokens.light();
    final actions = EnvironmentRowActions(
      children: [
        if (!open)
          EnvironmentActionButton(
            spaceKey: spaceKey,
            actionKey: 'launch:${component.id}',
            label: l10n.environmentLaunch,
            icon: AppIcons.play,
            enabled: canLaunch,
            action: (repository) => repository.launchApp(
              spaceKey.workspaceId,
              spaceKey.spaceId,
              component.id,
            ),
          ),
        if (prepares)
          EnvironmentActionButton(
            spaceKey: spaceKey,
            actionKey: 'rebuild:${component.id}',
            label: l10n.environmentRebuildRelaunch,
            icon: AppIcons.refreshCw,
            enabled: canLaunch,
            action: (repository) => repository.launchApp(
              spaceKey.workspaceId,
              spaceKey.spaceId,
              component.id,
              rebuild: true,
            ),
          ),
        if (open && viewer != null && host != null)
          EnvironmentOpenButton(
            label: l10n.environmentOpenViewer,
            icon: AppIcons.appWindow,
            onPressed: () => host.openViewer(
              spaceId: spaceKey.spaceId,
              componentId: component.id,
              label: label,
            ),
          ),
        if (host != null)
          EnvironmentOpenButton(
            label: sessionId == null ? l10n.logs : l10n.terminal,
            icon: sessionId == null ? AppIcons.scrollText : AppIcons.terminal,
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
        if (open)
          EnvironmentActionButton(
            spaceKey: spaceKey,
            actionKey: 'stopApp:${component.id}',
            label: l10n.stop,
            icon: AppIcons.circleStop,
            enabled: !status.isBusy,
            action: (repository) => repository.stopApp(
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
        if (open && viewer == null)
          Text(
            l10n.environmentViewerUnavailable,
            style: CcTypography.caption.copyWith(color: t.textTertiary),
          ),
      ],
    );
  }
}
