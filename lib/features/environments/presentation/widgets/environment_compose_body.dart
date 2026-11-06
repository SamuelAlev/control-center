import 'dart:async';

import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_exec_dialog.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_feedback.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_host.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_labels.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_row_actions.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The name of a reported service.
String environmentServiceName(Map<String, dynamic> service) =>
    '${service['name'] ?? ''}';

/// A compose stack: its services, then what can be done to the whole stack.
class EnvironmentComposeBody extends StatelessWidget {
  /// Creates an [EnvironmentComposeBody].
  const EnvironmentComposeBody({
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
    final host = EnvironmentHostScope.maybeOf(context);
    final services = [
      for (final service in component.services)
        if (environmentServiceName(service).isNotEmpty)
          environmentServiceName(service),
    ];
    final live = environmentHasLiveParts(environment.status);
    final idle = !environment.status.isBusy;
    final actions = EnvironmentRowActions(
      children: [
        if (host != null)
          EnvironmentOpenButton(
            label: l10n.logs,
            icon: AppIcons.scrollText,
            onPressed: () => host.openLogs(
              spaceId: spaceKey.spaceId,
              target: component.id,
              label: component.label ?? component.id,
            ),
          ),
        if (live && services.isNotEmpty)
          EnvironmentOpenButton(
            label: l10n.environmentExec,
            icon: AppIcons.terminal,
            onPressed: idle
                ? () => unawaited(
                    showEnvironmentExecDialog(
                      context,
                      spaceKey: spaceKey,
                      services: services,
                    ),
                  )
                : null,
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
      ],
    );
    if (part == EnvironmentBodyPart.actions) {
      return actions;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final service in component.services)
          _ServiceRow(
            spaceKey: spaceKey,
            service: service,
            enabled: live && idle,
          ),
      ],
    );
  }
}

class _ServiceRow extends ConsumerWidget {
  const _ServiceRow({
    required this.spaceKey,
    required this.service,
    required this.enabled,
  });

  final EnvironmentSpaceKey spaceKey;
  final Map<String, dynamic> service;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final host = EnvironmentHostScope.maybeOf(context);
    final name = environmentServiceName(service);
    final (stateLabel, tone) = environmentComponentStateDisplay(
      l10n,
      '${service['state'] ?? 'pending'}',
    );
    final health = switch (service['health']) {
      'healthy' => l10n.environmentHealthHealthy,
      'unhealthy' => l10n.environmentHealthUnhealthy,
      'starting' => l10n.rigPhaseStarting,
      final String other when other.isNotEmpty => other,
      _ => null,
    };
    final ports = [
      for (final port in (service['ports'] as List?) ?? const []) '$port',
    ];
    final facts = [stateLabel, ?health].join(' · ');
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.xxs),
      child: Row(
        children: [
          CcStatusDot(tone: tone, size: 6),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Wrap(
              spacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  name,
                  style: CcFonts.code(
                    textStyle: CcTypography.caption.copyWith(
                      color: t.textSecondary,
                    ),
                  ),
                ),
                Text(
                  facts,
                  style: CcTypography.caption.copyWith(color: t.textTertiary),
                ),
                if (ports.isNotEmpty)
                  // RTL carve-out: port numbers are machine values.
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      ports.join(', '),
                      style: CcFonts.code(
                        textStyle: CcTypography.caption.copyWith(
                          color: t.textTertiary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          CcMenu(
            semanticLabel: l10n.environmentServiceActions(name),
            items: [
              if (host != null)
                CcMenuItem(
                  label: l10n.logs,
                  icon: AppIcons.scrollText,
                  onSelected: () => host.openLogs(
                    spaceId: spaceKey.spaceId,
                    target: name,
                    label: name,
                  ),
                ),
              CcMenuItem(
                label: l10n.environmentExec,
                icon: AppIcons.terminal,
                enabled: enabled,
                onSelected: () => unawaited(
                  showEnvironmentExecDialog(
                    context,
                    spaceKey: spaceKey,
                    services: [name],
                  ),
                ),
              ),
              CcMenuItem(
                label: l10n.environmentRestart,
                icon: AppIcons.rotateCw,
                enabled: enabled,
                onSelected: () => unawaited(
                  runEnvironmentAction(
                    context,
                    ref,
                    spaceKey,
                    'restart:$name',
                    (repository) => repository.restartProcess(
                      spaceKey.workspaceId,
                      spaceKey.spaceId,
                      name,
                    ),
                  ),
                ),
              ),
            ],
            // Inert target: the menu's own tappable drives it.
            target: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxs),
              child: CcIcon(
                AppIcons.moreHorizontal,
                size: 14,
                color: t.fgSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
