import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// One line of the live step list: a part of the environment, where it
/// stands, and what it is doing right now when it says.
typedef EnvironmentStep = ({
  String label,
  EnvironmentStepState state,
  String? detail,
});

EnvironmentStepState _stateOf(EnvironmentComponentState component) =>
    switch (component.phase) {
      EnvironmentComponentPhase.starting ||
      EnvironmentComponentPhase.interactive ||
      EnvironmentComponentPhase.waiting => EnvironmentStepState.running,
      EnvironmentComponentPhase.running ||
      EnvironmentComponentPhase.ready ||
      EnvironmentComponentPhase.completed => EnvironmentStepState.done,
      EnvironmentComponentPhase.failed ||
      EnvironmentComponentPhase.crashed => EnvironmentStepState.failed,
      EnvironmentComponentPhase.pending ||
      EnvironmentComponentPhase.idle ||
      EnvironmentComponentPhase.stopped ||
      EnvironmentComponentPhase.closed ||
      null => EnvironmentStepState.pending,
    };

/// What a part under way is doing: the step its tool last reported, else its
/// own one-line detail. On a terminal the notice below the list says it, and
/// a part that is not under way has nothing to add.
String? _detailOf(EnvironmentComponentState component) {
  if (component.phase != EnvironmentComponentPhase.starting &&
      component.phase != EnvironmentComponentPhase.waiting) {
    return null;
  }
  final detail = component.currentStep?.label ?? component.detail;
  return detail == null || detail.trim().isEmpty ? null : detail;
}

/// The steps of what [environment] is doing now: the parts this start goes
/// through, in order.
///
/// The list keeps its shape from the first frame to the last. A tool's own
/// `step` lines don't add rows: they say what its part is doing, on that
/// part's row, and the run's output keeps every one of them.
List<EnvironmentStep> environmentSteps(SpaceEnvironment environment) => [
  for (final component in environment.startComponents)
    (
      label: component.label ?? component.id,
      state: _stateOf(component),
      detail: _detailOf(component),
    ),
];

/// The live step list, shown while an environment is changing.
class EnvironmentStepList extends StatelessWidget {
  /// Creates an [EnvironmentStepList].
  const EnvironmentStepList({super.key, required this.environment});

  /// What is changing.
  final SpaceEnvironment environment;

  static const double _glyph = 14;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final step in environmentSteps(environment))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    SizedBox.square(
                      dimension: _glyph,
                      child: switch (step.state) {
                        EnvironmentStepState.running => const CcSpinner(
                          size: 12,
                        ),
                        EnvironmentStepState.done => Icon(
                          AppIcons.check,
                          size: _glyph,
                          color: t.fgSuccessPrimary,
                        ),
                        EnvironmentStepState.failed => Icon(
                          AppIcons.x,
                          size: _glyph,
                          color: t.textErrorPrimary,
                        ),
                        EnvironmentStepState.pending => Icon(
                          AppIcons.circleDashed,
                          size: _glyph,
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
                if (step.detail case final detail?)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: _glyph + AppSpacing.sm,
                    ),
                    child: Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CcTypography.caption.copyWith(
                        color: t.textTertiary,
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
