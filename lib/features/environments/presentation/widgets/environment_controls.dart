import 'dart:async';

import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/environment_setup_prompt.dart';
import 'package:control_center/features/environments/presentation/settings/environment_editor_seed.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_feedback.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_lifecycle_actions.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_start.dart';
import 'package:control_center/features/environments/providers/environment_actions.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:control_center/features/environments/presentation/widgets/environment_lifecycle_actions.dart'
    show confirmEnvironmentAction;

/// Stop, or Start again, for the environment as a whole.
class EnvironmentControls extends ConsumerWidget {
  /// Creates an [EnvironmentControls].
  const EnvironmentControls({
    super.key,
    required this.spaceKey,
    required this.environment,
    this.record,
  });

  /// The space it runs in.
  final EnvironmentSpaceKey spaceKey;

  /// What the server last reported.
  final SpaceEnvironment environment;

  /// Its definition, once loaded.
  final EnvironmentDefinitionRecord? record;

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final record = this.record;
    if (record == null) {
      await forwardEnsure(
        context,
        ref,
        spaceKey,
        definitionId: environment.definitionId,
        options: environment.options,
      );
      return;
    }
    await beginEnvironmentStart(
      context,
      ref,
      workspaceId: spaceKey.workspaceId,
      definitions: [record],
      initialOptions: environment.options,
      onStart: (context, definitionId, options) => forwardEnsure(
        context,
        ref,
        spaceKey,
        definitionId: definitionId,
        options: options,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final inFlight = ref.watch(environmentActionsProvider(spaceKey));
    final status = environment.status;
    // A failed environment whose other parts still run needs Stop too: without
    // it those parts stay up with nothing to bring them down but Destroy.
    final canStop =
        (status.isRunning && status != EnvironmentStatus.starting) ||
        (status == EnvironmentStatus.failed &&
            environment.components.any(
              (part) =>
                  const {'running', 'ready', 'starting'}.contains(part.state),
            ));
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        if (canStop)
          CcButton(
            variant: CcButtonVariant.secondary,
            size: CcButtonSize.sm,
            icon: AppIcons.circleStop,
            loading: inFlight.contains('stop'),
            onPressed: inFlight.contains('stop')
                ? null
                : () => unawaited(
                    stopEnvironment(
                      context,
                      ref,
                      spaceKey,
                      environment,
                      record: record,
                    ),
                  ),
            child: Text(l10n.stop),
          )
        // A failure offers Retry where it is explained: one way to go again.
        else if (!status.isBusy &&
            !(status == EnvironmentStatus.failed &&
                environment.lastError != null))
          CcButton(
            size: CcButtonSize.sm,
            icon: AppIcons.play,
            loading: inFlight.contains('start'),
            onPressed: inFlight.contains('start')
                ? null
                : () => unawaited(_start(context, ref)),
            child: Text(l10n.startLabel),
          ),
        // In plain sight: what isn't destroyed keeps its memory and CPU.
        CcButton(
          variant: CcButtonVariant.destructive,
          size: CcButtonSize.sm,
          icon: AppIcons.trash2,
          loading: inFlight.contains('destroy'),
          onPressed:
              inFlight.contains('destroy') ||
                  status == EnvironmentStatus.destroying
              ? null
              : () => unawaited(
                  destroyEnvironment(context, ref, spaceKey, environment),
                ),
          child: Text(l10n.environmentDestroy),
        ),
      ],
    );
  }
}

/// The actions a person needs now and then, kept off the row they press all day.
class EnvironmentOverflowMenu extends ConsumerWidget {
  /// Creates an [EnvironmentOverflowMenu].
  const EnvironmentOverflowMenu({
    super.key,
    required this.spaceKey,
    required this.environment,
  });

  /// The space it runs in.
  final EnvironmentSpaceKey spaceKey;

  /// What the server last reported.
  final SpaceEnvironment environment;

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmEnvironmentAction(
      context,
      title: l10n.environmentResetTitle,
      body: l10n.environmentResetBody(environment.name),
      confirmLabel: l10n.environmentResetData,
    );
    if (confirmed && context.mounted) {
      await runEnvironmentAction(
        context,
        ref,
        spaceKey,
        'reset',
        (repository) =>
            repository.reset(spaceKey.workspaceId, spaceKey.spaceId),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final idle = !environment.status.isBusy;
    final record = ref.watch(
      environmentDefinitionRecordProvider((
        workspaceId: spaceKey.workspaceId,
        definitionId: environment.definitionId,
      )),
    );
    final isAdmin =
        ref.watch(myWorkspaceRoleProvider(spaceKey.workspaceId))?.isAdmin ??
        false;
    return CcMenu(
      semanticLabel: l10n.environmentMoreActions,
      targetAnchor: AlignmentDirectional.bottomEnd,
      followerAnchor: AlignmentDirectional.topEnd,
      items: [
        if (environment.status.isRunning)
          CcMenuItem(
            label: l10n.refresh,
            icon: AppIcons.refreshCw,
            enabled: idle,
            onSelected: () => unawaited(
              runEnvironmentAction(
                context,
                ref,
                spaceKey,
                'refresh',
                (repository) =>
                    repository.refresh(spaceKey.workspaceId, spaceKey.spaceId),
              ),
            ),
          ),
        if (isAdmin && record != null)
          CcMenuItem(
            label: l10n.environmentEditDefinition,
            icon: AppIcons.pencil,
            onSelected: () => openEnvironmentEditor(
              context,
              ref,
              EnvironmentEditorSeed.record(record),
            ),
          ),
        CcMenuItem(
          label: l10n.environmentResetData,
          icon: AppIcons.rotateCcw,
          enabled: idle,
          onSelected: () => unawaited(_reset(context, ref)),
        ),
      ],
      // Inert target: the menu's own tappable drives it.
      target: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: CcIcon(AppIcons.moreHorizontal, size: 16, color: t.fgTertiary),
      ),
    );
  }
}
