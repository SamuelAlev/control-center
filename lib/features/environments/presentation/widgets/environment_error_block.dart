import 'dart:async';

import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_command_box.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_host.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_host_setup.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_start.dart';
import 'package:control_center/features/environments/providers/environment_actions.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/features/sandboxing/presentation/terminal_session_controller.dart'
    show terminalPrefillText;
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A structured failure, attached to whatever failed.
///
/// Exit 3 means a person has to do something on the host. With a `setup` verb
/// a person's Start goes straight to its terminal, and that tab says why it
/// opened, so all that stays here is the way back to it. Without one CC never
/// runs the command itself: **Run in terminal** types it at a prompt and stops,
/// and **Retry** picks up once it has been dealt with.
class EnvironmentErrorBlock extends ConsumerWidget {
  /// Creates an [EnvironmentErrorBlock].
  const EnvironmentErrorBlock({
    super.key,
    required this.spaceKey,
    required this.environment,
    required this.error,
  });

  /// The space it happened in.
  final EnvironmentSpaceKey spaceKey;

  /// The environment it happened to.
  final SpaceEnvironment environment;

  /// What went wrong.
  final EnvironmentError error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final command = error.command;
    final host = EnvironmentHostScope.maybeOf(context);
    // A multi-line script, or a Windows host's shell, gets Copy only: typing it
    // at a prompt would either run part of it or mean something else.
    final typeable =
        command != null &&
        defaultTargetPlatform != TargetPlatform.windows &&
        terminalPrefillText(command) != null;
    final retrying = ref
        .watch(environmentActionsProvider(spaceKey))
        .contains('start');
    // A terminal Control Center runs itself replaces the instructions for
    // doing this by hand, command and all. The status already says it waits.
    final setUp =
        error.needsHostSetup &&
        host != null &&
        environmentCanSetUp(
          ref.watch(
            environmentDefinitionRecordProvider((
              workspaceId: spaceKey.workspaceId,
              definitionId: environment.definitionId,
            )),
          ),
        );
    // What to read next: the part that broke, else the first thing that runs.
    final parts = environment.components.where((part) => part.kind != 'task');
    final logs =
        parts
            .where((part) => const {'failed', 'crashed'}.contains(part.state))
            .firstOrNull ??
        parts.firstOrNull;
    final actions = Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        if (setUp)
          CcButton(
            size: CcButtonSize.sm,
            variant: CcButtonVariant.primary,
            icon: AppIcons.terminal,
            onPressed: () => unawaited(openHostSetup(context, ref, spaceKey)),
            child: Text(l10n.environmentContinueInTerminal),
          )
        else if (error.needsHostSetup && typeable && host != null)
          CcButton(
            size: CcButtonSize.sm,
            variant: CcButtonVariant.secondary,
            icon: AppIcons.terminal,
            onPressed: () => host.openPrefilledTerminal(
              spaceId: spaceKey.spaceId,
              command: command,
            ),
            child: Text(l10n.environmentRunInTerminal),
          ),
        CcButton(
          size: CcButtonSize.sm,
          variant: setUp ? CcButtonVariant.secondary : CcButtonVariant.primary,
          icon: AppIcons.rotateCw,
          loading: retrying,
          onPressed: retrying
              ? null
              : () => unawaited(
                  forwardEnsure(
                    context,
                    ref,
                    spaceKey,
                    definitionId: environment.definitionId,
                    options: environment.options,
                  ),
                ),
          child: Text(l10n.retry),
        ),
        if (host != null && logs != null)
          CcButton(
            size: CcButtonSize.sm,
            variant: CcButtonVariant.ghost,
            icon: AppIcons.scrollText,
            onPressed: () => host.openLogs(
              spaceId: spaceKey.spaceId,
              target: logs.id,
              label: logs.label ?? logs.id,
            ),
            child: Text(l10n.logs),
          ),
      ],
    );
    if (setUp) {
      return actions;
    }
    final detail =
        (error.needsHostSetup ? [error.message, ?error.hint] : [?error.hint])
            .join('\n');
    return CcAlert(
      variant: error.needsHostSetup
          ? CcAlertVariant.warning
          : CcAlertVariant.danger,
      title: error.needsHostSetup
          ? l10n.environmentHostSetupNeeded
          : error.message,
      description: detail.isEmpty ? null : Text(detail),
      action: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (command != null) ...[
            EnvironmentCommandBox(command: command),
            const SizedBox(height: AppSpacing.xs),
          ],
          actions,
        ],
      ),
    );
  }
}
