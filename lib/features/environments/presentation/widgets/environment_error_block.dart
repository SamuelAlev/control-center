import 'dart:async';

import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_host_approval.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_attended_start.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_command_box.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_feedback.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_host.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_host_approval.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_output_box.dart';
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

/// What stopped an environment, attached to it, with the one thing to do next.
///
/// A tool exits 3, 4 or 5 when only a person can take a start further: an
/// answer at a terminal, a sign-in, a dependency that isn't there. That reads
/// as a caution, never as a failure. When the definition lets the step run on
/// a terminal, **Continue in terminal** starts again with this person there
/// to answer: the tool asks for itself, and Control Center never runs a
/// command the tool printed. Without that, **Run in terminal** types the
/// tool's command at a prompt and stops, and **Retry** picks up once it has
/// been dealt with.
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

  /// What stopped it.
  final EnvironmentError error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Held for the server owner's approval: worded by its code, never the
    // server's sentence, and nothing here to retry until it is approved.
    if (error.code == environmentHostUnapprovedKind) {
      return EnvironmentHostUnapprovedAlert(
        spaceKey: spaceKey,
        environment: environment,
      );
    }
    final l10n = AppLocalizations.of(context);
    final command = error.command;
    final blocker = error.blocker;
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
    final operable = environmentOperable(ref, spaceKey);
    // The tool can ask for what it needs itself, on a terminal this surface
    // can show. That replaces the instructions for doing it by hand. Only a
    // tool's own verb runs there: a task that needs someone says how instead.
    final onTerminal =
        (blocker?.answersOnTerminal ?? false) &&
        host != null &&
        environment.components.any(
          (part) => part.kind == 'cli' && (part.phase?.isFailed ?? false),
        ) &&
        environmentCanFinishOnTerminal(
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
        parts.where((part) => part.phase?.isFailed ?? false).firstOrNull ??
        parts.firstOrNull;
    void startAgain() => unawaited(
      forwardEnsure(
        context,
        ref,
        spaceKey,
        definitionId: environment.definitionId,
        options: environment.options,
      ),
    );
    final actions = Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        if (!onTerminal && blocker != null && typeable && host != null)
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
          variant: CcButtonVariant.primary,
          icon: onTerminal ? AppIcons.terminal : AppIcons.rotateCw,
          loading: retrying,
          onPressed: retrying || !operable ? null : startAgain,
          child: Text(
            onTerminal ? l10n.environmentContinueInTerminal : l10n.retry,
          ),
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
    final detail = [
      if (blocker != null) error.message,
      // On a terminal the tool says the rest itself.
      if (onTerminal) l10n.environmentStartTerminalHint else ?error.hint,
    ].join('\n');
    return CcAlert(
      variant: blocker == null ? CcAlertVariant.danger : CcAlertVariant.warning,
      title: switch (blocker) {
        null => error.message,
        EnvironmentBlocker.input => l10n.environmentInputNeeded,
        EnvironmentBlocker.authentication => l10n.environmentSignInNeeded,
        EnvironmentBlocker.dependency => l10n.environmentDependencyNeeded,
      },
      description: detail.isEmpty ? null : Text(detail),
      action: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error.output case final output?) ...[
            EnvironmentOutputBox(output: output),
            const SizedBox(height: AppSpacing.xs),
          ],
          if (command != null && !onTerminal) ...[
            EnvironmentCommandBox(command: command),
            const SizedBox(height: AppSpacing.xs),
          ],
          actions,
        ],
      ),
    );
  }
}
