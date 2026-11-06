import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:collection/collection.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Where one step stands.
enum EnvironmentStepState {
  /// Not reached yet.
  pending,

  /// Under way.
  running,

  /// Finished.
  done,

  /// Failed.
  failed,
}

/// One line of the live step list.
typedef EnvironmentStep = ({String label, EnvironmentStepState state});

EnvironmentStepState _stepState(String? wire) => switch (wire) {
  'done' ||
  'ok' ||
  'ready' ||
  'completed' ||
  'succeeded' => EnvironmentStepState.done,
  'failed' || 'error' || 'crashed' => EnvironmentStepState.failed,
  'running' ||
  'start' ||
  'started' ||
  'starting' => EnvironmentStepState.running,
  _ => EnvironmentStepState.pending,
};

/// The steps of what [environment] is doing now.
///
/// A tool's own `step` lines are the better story, so they win. Until one
/// reports anything, the components are the steps.
List<EnvironmentStep> environmentSteps(
  SpaceEnvironment environment,
  List<EnvironmentRun> runs,
) {
  final run = runs.firstWhereOrNull(
    (run) =>
        run.status == EnvironmentRunStatus.running &&
        run.environmentId == environment.id,
  );
  final reported = <String, EnvironmentStepState>{};
  for (final line in (run?.output ?? '').split('\n')) {
    final progress = EnvironmentProgress.tryParseLine(line);
    final label = progress?.label;
    if (progress?.type == 'step' && label != null) {
      reported[label] = _stepState(progress?.state);
    }
  }
  if (reported.isNotEmpty) {
    return [
      for (final entry in reported.entries)
        (label: entry.key, state: entry.value),
    ];
  }
  return [
    for (final component in environment.components)
      (
        label: component.label ?? component.id,
        state: _stepState(component.state),
      ),
  ];
}

/// The live step list, shown while an environment is changing.
class EnvironmentStepList extends StatelessWidget {
  /// Creates an [EnvironmentStepList].
  const EnvironmentStepList({
    super.key,
    required this.environment,
    required this.runs,
  });

  /// What is changing.
  final SpaceEnvironment environment;

  /// Recent runs, whose output carries the tool's own steps.
  final List<EnvironmentRun> runs;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final step in environmentSteps(environment, runs))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: 14,
                  child: switch (step.state) {
                    EnvironmentStepState.running => const CcSpinner(size: 12),
                    EnvironmentStepState.done => Icon(
                      AppIcons.check,
                      size: 14,
                      color: t.fgSuccessPrimary,
                    ),
                    EnvironmentStepState.failed => Icon(
                      AppIcons.x,
                      size: 14,
                      color: t.textErrorPrimary,
                    ),
                    EnvironmentStepState.pending => Icon(
                      AppIcons.circleDashed,
                      size: 14,
                      color: t.textTertiary,
                    ),
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    step.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.caption.copyWith(
                      color: step.state == EnvironmentStepState.pending
                          ? t.textTertiary
                          : t.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
