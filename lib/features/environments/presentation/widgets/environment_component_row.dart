import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_app_body.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_compose_body.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_labels.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_process_body.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_row_actions.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_task_body.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// One component: what it is, how it stands and what can be done to it, on a
/// single line, with anything it has to explain underneath.
///
/// A task is a script, not a running part, and gets [EnvironmentScriptRow].
class EnvironmentComponentRow extends StatelessWidget {
  /// Creates an [EnvironmentComponentRow].
  const EnvironmentComponentRow({
    super.key,
    required this.spaceKey,
    required this.environment,
    required this.component,
    this.definition,
    this.runs = const [],
    this.error,
  });

  /// The space it runs in.
  final EnvironmentSpaceKey spaceKey;

  /// The environment it belongs to.
  final SpaceEnvironment environment;

  /// Its reported state.
  final EnvironmentComponentState component;

  /// The definition, once loaded. Rows degrade to the reported state without.
  final EnvironmentDefinition? definition;

  /// Recent runs, for a task's last result.
  final List<EnvironmentRun> runs;

  /// The failure that names this part. Explained at the top of the panel, one
  /// place for every problem; here it only decides the state shown.
  final EnvironmentError? error;

  /// States whose detail line is worth a line of its own. A healthy part's
  /// detail repeats what its state already says.
  static const _explained = {'failed', 'crashed', 'starting', 'pending'};

  @override
  Widget build(BuildContext context) {
    if (component.kind == 'task') {
      return EnvironmentScriptRow(
        spaceKey: spaceKey,
        environment: environment,
        component: component,
        definition: definition,
        runs: runs,
      );
    }
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final caption = CcTypography.caption.copyWith(color: t.textTertiary);
    final (stateLabel, tone) = error?.needsHostSetup ?? false
        ? (l10n.environmentNeedsSetup, CcStatusTone.caution)
        : environmentComponentStateDisplay(l10n, component.state);
    final name = component.label ?? component.id;
    final kind = environmentKindLabel(l10n, component.kind);
    final detail = component.detail;
    final failure = error;
    return Semantics(
      container: true,
      label: '$name, $kind, $stateLabel',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CcTooltip(
                  message: kind,
                  child: Icon(
                    environmentKindIcon(component.kind),
                    size: 14,
                    color: t.fgTertiary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.bodySm.copyWith(color: t.textPrimary),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                CcStatusDot(tone: tone, size: 6),
                const SizedBox(width: AppSpacing.xs),
                Text(stateLabel, style: caption),
                const SizedBox(width: AppSpacing.xxs),
                _part(EnvironmentBodyPart.actions),
              ],
            ),
            if (detail != null &&
                detail.isNotEmpty &&
                failure == null &&
                _explained.contains(component.state))
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: 14 + AppSpacing.sm,
                ),
                child: Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: caption,
                ),
              ),
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 14 + AppSpacing.sm,
              ),
              child: _part(EnvironmentBodyPart.details),
            ),
          ],
        ),
      ),
    );
  }

  Widget _part(EnvironmentBodyPart part) => switch (component.kind) {
    'compose' => EnvironmentComposeBody(
      spaceKey: spaceKey,
      environment: environment,
      component: component,
      part: part,
    ),
    'process' => EnvironmentProcessBody(
      spaceKey: spaceKey,
      environment: environment,
      component: component,
      part: part,
    ),
    'cli' => EnvironmentCliBody(
      spaceKey: spaceKey,
      environment: environment,
      component: component,
      definition: definition,
      part: part,
    ),
    'app' => EnvironmentAppBody(
      spaceKey: spaceKey,
      environment: environment,
      component: component,
      definition: definition,
      part: part,
    ),
    _ => const SizedBox.shrink(),
  };
}
