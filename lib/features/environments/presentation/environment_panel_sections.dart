import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_component_row.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_live_panel.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_run_row.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/collapsible_sidebar_section.dart';
import 'package:flutter/widgets.dart';

/// The most runs the activity list shows. Older ones stay in the database; the
/// list is for what just happened.
const int _activityLimit = 30;

/// One group of an environment's components: its services and processes, or
/// its scripts.
class EnvironmentComponentsSection extends StatelessWidget {
  /// Creates an [EnvironmentComponentsSection].
  const EnvironmentComponentsSection({
    super.key,
    required this.icon,
    required this.label,
    required this.spaceKey,
    required this.environment,
    required this.components,
    required this.definition,
    required this.runs,
  });

  /// The section's icon.
  final IconData icon;

  /// The section's name.
  final String label;

  /// The space acted on.
  final EnvironmentSpaceKey spaceKey;

  /// The environment they belong to.
  final SpaceEnvironment environment;

  /// The components to list.
  final List<EnvironmentComponentState> components;

  /// The definition they came from, when it still exists.
  final EnvironmentDefinition? definition;

  /// The space's runs, for each script's last result.
  final List<EnvironmentRun> runs;

  @override
  Widget build(BuildContext context) {
    final failing = failingComponentId(environment);
    return CollapsibleSidebarSection(
      icon: icon,
      label: label,
      count: '${components.length}',
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final component in components)
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
        ),
      ),
    );
  }
}

/// Everything that ran in the space, newest first, each with its output: the
/// starts and stops, the scripts, and the worktree's provision and archive
/// tasks.
class EnvironmentActivitySection extends StatelessWidget {
  /// Creates an [EnvironmentActivitySection].
  const EnvironmentActivitySection({super.key, required this.runs});

  /// The space's runs, in any order.
  final List<EnvironmentRun> runs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final recent = [...runs]
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final shown = recent.take(_activityLimit).toList();
    return CollapsibleSidebarSection(
      icon: AppIcons.activity,
      label: l10n.activity,
      count: '${runs.length}',
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final run in shown)
              EnvironmentRunRow(key: ValueKey(run.id), run: run),
          ],
        ),
      ),
    );
  }
}
