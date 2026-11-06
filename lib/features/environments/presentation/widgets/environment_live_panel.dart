import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:collection/collection.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_component_row.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_controls.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_endpoint_rows.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_error_block.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_labels.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_recreate_notice.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_step_list.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The component an environment's last error belongs to, or null when it is
/// about the environment as a whole.
String? failingComponentId(SpaceEnvironment environment) => environment
    .components
    .firstWhereOrNull(
      (component) =>
          component.state == 'failed' || component.state == 'crashed',
    )
    ?.id;

/// An environment that exists: what it is, where it answers, and each part.
class EnvironmentLivePanel extends ConsumerWidget {
  /// Creates an [EnvironmentLivePanel].
  const EnvironmentLivePanel({
    super.key,
    required this.spaceKey,
    required this.environment,
  });

  /// The space it runs in.
  final EnvironmentSpaceKey spaceKey;

  /// What the server last reported.
  final SpaceEnvironment environment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runs =
        ref.watch(spaceEnvironmentRunsProvider(spaceKey)).value ??
        const <EnvironmentRun>[];
    final record = environmentRecordFor(ref, spaceKey, environment);
    final definition = record == null ? null : environmentDefinitionOf(record);
    final failing = failingComponentId(environment);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EnvironmentSummary(
          spaceKey: spaceKey,
          environment: environment,
          runs: runs,
        ),
        if (environment.endpoints.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          EnvironmentEndpointRows(
            spaceKey: spaceKey,
            endpoints: environment.endpoints,
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        for (final component in environment.components)
          EnvironmentComponentRow(
            key: ValueKey(component.id),
            spaceKey: spaceKey,
            environment: environment,
            component: component,
            definition: definition,
            runs: runs,
            error: component.id == failing ? environment.lastError : null,
          ),
      ],
    );
  }
}

/// The stored definition [environment] was started from, when it still exists.
EnvironmentDefinitionRecord? environmentRecordFor(
  WidgetRef ref,
  EnvironmentSpaceKey spaceKey,
  SpaceEnvironment environment,
) => ref.watch(
  environmentDefinitionRecordProvider((
    workspaceId: spaceKey.workspaceId,
    definitionId: environment.definitionId,
  )),
);

/// What an environment is and how it is doing: its name, one status, the steps
/// of a start in progress, and anything that needs a person, with the one thing
/// to do next.
class EnvironmentSummary extends ConsumerWidget {
  /// Creates an [EnvironmentSummary].
  const EnvironmentSummary({
    super.key,
    required this.spaceKey,
    required this.environment,
    required this.runs,
    this.menu = false,
  });

  /// The space it runs in.
  final EnvironmentSpaceKey spaceKey;

  /// What the server last reported.
  final SpaceEnvironment environment;

  /// The space's runs, for the steps of a start in progress.
  final List<EnvironmentRun> runs;

  /// Whether this carries the overflow menu, for a surface with no section
  /// header to hold it.
  final bool menu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final record = environmentRecordFor(ref, spaceKey, environment);
    final (statusLabel, tone) = environmentDisplay(l10n, environment);
    final error = environment.lastError;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                record?.name ?? environment.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CcTypography.body.copyWith(
                  color: t.textPrimary,
                  fontWeight: CcTypography.semiboldWeight,
                ),
              ),
            ),
            if (menu)
              EnvironmentOverflowMenu(
                spaceKey: spaceKey,
                environment: environment,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Row(
          children: [
            CcStatusTag(label: statusLabel, tone: tone),
            const SizedBox(width: AppSpacing.sm),
            if (environment.placement == 'rig') ...[
              CcBadge(label: l10n.environmentPlacementRig),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              // RTL carve-out: an environment name is a branch-derived token.
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  environment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CcFonts.code(
                    textStyle: CcTypography.caption.copyWith(
                      color: t.textTertiary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (environment.status.isBusy) ...[
          const SizedBox(height: AppSpacing.sm),
          EnvironmentStepList(environment: environment, runs: runs),
        ],
        for (final warning in environment.warnings)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              warning,
              style: CcTypography.caption.copyWith(color: t.textWarningPrimary),
            ),
          ),
        if (environment.needsRecreate) ...[
          const SizedBox(height: AppSpacing.sm),
          EnvironmentRecreateNotice(
            spaceKey: spaceKey,
            environment: environment,
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          EnvironmentErrorBlock(
            spaceKey: spaceKey,
            environment: environment,
            error: error,
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        EnvironmentControls(
          spaceKey: spaceKey,
          environment: environment,
          record: record,
        ),
      ],
    );
  }
}
