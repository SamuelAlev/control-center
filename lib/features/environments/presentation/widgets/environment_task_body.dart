import 'dart:async';

import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_component.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:collection/collection.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_compose_body.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_exec_dialog.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_feedback.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_host.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_labels.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_row_actions.dart';
import 'package:control_center/features/environments/providers/environment_actions.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One script: what it is, how it last went, and Run when it runs on request.
///
/// A script has no state between runs, so there is no status tag: the last
/// result is the fact worth reading. One that runs by itself says when.
class EnvironmentScriptRow extends ConsumerWidget {
  /// Creates an [EnvironmentScriptRow].
  const EnvironmentScriptRow({
    super.key,
    required this.spaceKey,
    required this.environment,
    required this.component,
    this.definition,
    this.runs = const [],
  });

  /// The space it runs in.
  final EnvironmentSpaceKey spaceKey;

  /// Its environment.
  final SpaceEnvironment environment;

  /// The task.
  final EnvironmentComponentState component;

  /// The definition, for its triggers.
  final EnvironmentDefinition? definition;

  /// The space's runs, newest first.
  final List<EnvironmentRun> runs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final caption = CcTypography.caption.copyWith(color: t.textTertiary);
    final task = definition?.component(component.id);
    final triggers = task is TaskEnvironmentComponent
        ? task.when
        : const <EnvironmentTaskTrigger>[];
    final onRequest = triggers.contains(EnvironmentTaskTrigger.manual);
    final automatic = [
      for (final trigger in triggers)
        if (trigger != EnvironmentTaskTrigger.manual)
          environmentTriggerLabel(l10n, trigger),
    ];
    final run = runs.firstWhereOrNull(
      (run) => run.kind == EnvironmentRunKind.task && run.label == component.id,
    );
    final pressed = ref
        .watch(environmentActionsProvider(spaceKey))
        .contains('run:${component.id}');
    final running = pressed || run?.status == EnvironmentRunStatus.running;
    final at = run?.completedAt ?? run?.startedAt ?? component.lastRunAt;
    final exitCode = run?.exitCode ?? component.lastExitCode;
    final failed =
        run?.status == EnvironmentRunStatus.failed ||
        run?.status == EnvironmentRunStatus.timedOut ||
        (exitCode != null && exitCode != 0);
    final (result, tone) = running
        ? (l10n.running, CcStatusTone.caution)
        : at == null
        ? (l10n.environmentTaskNeverRun, CcStatusTone.neutral)
        : failed
        ? (l10n.failed, CcStatusTone.negative)
        : (l10n.passed, CcStatusTone.positive);
    final name = component.label ?? component.id;
    return Semantics(
      container: true,
      label: '$name, $result',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.bodySm.copyWith(color: t.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      CcStatusDot(tone: tone, size: 6),
                      Text(result, style: caption),
                      if (!running && at != null)
                        AppTimestamp.relative(at, style: caption),
                      if (!running && failed && exitCode != null)
                        Text(
                          l10n.environmentExitCode(exitCode),
                          style: caption,
                        ),
                    ],
                  ),
                  if (automatic.isNotEmpty)
                    Text(
                      automatic.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: caption,
                    ),
                ],
              ),
            ),
            if (onRequest)
              CcIconButton(
                icon: AppIcons.play,
                size: CcButtonSize.sm,
                tooltip: l10n.environmentRun,
                loading: running,
                onPressed: environment.status.isBusy || running
                    ? null
                    : () => unawaited(
                        runEnvironmentAction(
                          context,
                          ref,
                          spaceKey,
                          'run:${component.id}',
                          (repository) => repository.runTask(
                            spaceKey.workspaceId,
                            spaceKey.spaceId,
                            component.id,
                          ),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A tool that owns its lifecycle: the endpoints and services it reports.
class EnvironmentCliBody extends StatelessWidget {
  /// Creates an [EnvironmentCliBody].
  const EnvironmentCliBody({
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
    final services = [
      for (final service in component.services)
        if (environmentServiceName(service).isNotEmpty)
          environmentServiceName(service),
    ];
    final tool = definition?.component(component.id);
    final verbs = tool is CliEnvironmentComponent
        ? tool.verbs.keys.toSet()
        : const <String>{};
    final actions = EnvironmentRowActions(
      children: [
        if (host != null && verbs.contains('logs'))
          EnvironmentOpenButton(
            label: l10n.logs,
            icon: AppIcons.scrollText,
            onPressed: () => host.openLogs(
              spaceId: spaceKey.spaceId,
              target: component.id,
              label: component.label ?? component.id,
            ),
          ),
        if (verbs.contains('exec') && services.isNotEmpty)
          EnvironmentOpenButton(
            label: l10n.environmentExec,
            icon: AppIcons.terminal,
            onPressed: environment.status.isRunning
                ? () => unawaited(
                    showEnvironmentExecDialog(
                      context,
                      spaceKey: spaceKey,
                      services: services,
                    ),
                  )
                : null,
          ),
      ],
    );
    if (part == EnvironmentBodyPart.actions) {
      return actions;
    }
    // Its endpoints are in Open and its services in the exec dialog: the row
    // has nothing to add under its header.
    return const SizedBox.shrink();
  }
}
