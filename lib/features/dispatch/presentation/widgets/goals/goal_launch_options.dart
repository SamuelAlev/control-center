import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_command.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/dispatch/presentation/widgets/goals/goal_checks_editor.dart';
import 'package:control_center/features/dispatch/presentation/widgets/goals/goal_edit_dialogs.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// What a person adds to a goal before it starts: machine checks, a separate
/// checker, whether each segment starts fresh, and whether an unanswered
/// question is released after 10 minutes.
class GoalLaunchChoice {
  /// Creates a choice.
  const GoalLaunchChoice({
    this.checks = const [],
    this.checkerAgentId,
    this.fresh = false,
    this.assume = false,
  });

  /// The checks, at most [GoalContract.maxChecks].
  final List<GoalCheck> checks;

  /// The checker agent, or null for none.
  final String? checkerAgentId;

  /// `--fresh`.
  final bool fresh;

  /// `--unattended assume`.
  final bool assume;

  /// A copy with the given fields replaced; [clearChecker] drops the checker.
  GoalLaunchChoice copyWith({
    List<GoalCheck>? checks,
    String? checkerAgentId,
    bool clearChecker = false,
    bool? fresh,
    bool? assume,
  }) => GoalLaunchChoice(
    checks: checks ?? this.checks,
    checkerAgentId: clearChecker ? null : checkerAgentId ?? this.checkerAgentId,
    fresh: fresh ?? this.fresh,
    assume: assume ?? this.assume,
  );
}

/// The `/goal` body for [objective] with [choice] added, in the shape the
/// server reads (the guided step's text transport): the flags first
/// (`--checker <id>`, `--fresh`, `--unattended assume`), then the objective,
/// then a `## Checks` section ([GoalCommand.checksSection]). A flag or
/// section the objective already carries is not added twice (a repeated flag
/// is refused).
String composeGoalBody(String objective, GoalLaunchChoice choice) {
  GoalCommand? parsed;
  try {
    parsed = GoalCommand.parse(objective);
  } on ValidationException {
    parsed = null;
  }
  final hasChecks = (parsed?.contract?.checks ?? const []).isNotEmpty;
  final flags = [
    if (choice.checkerAgentId case final id? when parsed?.checkerRef == null)
      '--checker $id',
    if (choice.fresh && !(parsed?.fresh ?? false)) '--fresh',
    if (choice.assume && parsed?.unattended == null) '--unattended assume',
  ];
  final body = StringBuffer();
  if (flags.isNotEmpty) {
    body.write('${flags.join(' ')} ');
  }
  body.write(objective.trim());
  if (choice.checks.isNotEmpty && !hasChecks) {
    body.write('\n\n${GoalCommand.checksSection(choice.checks)}');
  }
  return body.toString();
}

/// The options a goal gains before it starts ([GoalLaunchChoice]), each a
/// plain control with one sentence on what it does.
class GoalLaunchOptions extends StatelessWidget {
  /// Creates the options.
  const GoalLaunchOptions({
    super.key,
    required this.agents,
    required this.goalAgentId,
    required this.choice,
    required this.onChanged,
  });

  /// The workspace's agents (the checker candidates).
  final List<Agent> agents;

  /// The goal's agent, when known; it is not offered as its checker.
  final String? goalAgentId;

  /// The current choice.
  final GoalLaunchChoice choice;

  /// Called with the new choice, and with whether every check is valid when
  /// the checks changed (null otherwise).
  final void Function(GoalLaunchChoice choice, bool? checksValid) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    final caption = CcTypography.caption.copyWith(color: ds.textSecondary);
    Widget option(
      String label,
      String help,
      bool value,
      ValueChanged<bool> f,
    ) => Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CcCheckbox(value: value, onChanged: f, semanticLabel: label),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: CcTypography.bodySm),
                Text(help, style: caption),
              ],
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.goalLaunchChecks, style: CcTypography.label),
        Text(l10n.goalLaunchChecksHelp, style: caption),
        const SizedBox(height: AppSpacing.xs),
        GoalChecksEditor(
          initial: choice.checks,
          onChanged: (checks, valid) =>
              onChanged(choice.copyWith(checks: checks), valid),
        ),
        const SizedBox(height: AppSpacing.md),
        GoalCheckerPicker(
          agents: agents,
          goalAgentId: goalAgentId,
          value: choice.checkerAgentId,
          onChanged: (id) => onChanged(
            choice.copyWith(checkerAgentId: id, clearChecker: id == null),
            null,
          ),
        ),
        option(
          l10n.goalLaunchFresh,
          l10n.goalLaunchFreshHelp,
          choice.fresh,
          (v) => onChanged(choice.copyWith(fresh: v), null),
        ),
        option(
          l10n.goalLaunchAssume,
          l10n.goalLaunchAssumeHelp,
          choice.assume,
          (v) => onChanged(choice.copyWith(assume: v), null),
        ),
      ],
    );
  }
}
