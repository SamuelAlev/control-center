import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/dispatch/presentation/dispatch_text.dart';
import 'package:control_center/features/dispatch/presentation/widgets/goals/goal_contract_editor.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the contract editor for a paused [goal]; Save sends
/// `agentGoalRuns.setContract`. A refusal (`goal_not_paused`,
/// `goal_contract_invalid`) shows its sentence and keeps the dialog open.
Future<void> showGoalContractDialog(BuildContext context, AgentGoalRun goal) =>
    showCcDialog<void>(
      context: context,
      builder: (_) => _ContractDialog(goal: goal),
    );

class _ContractDialog extends ConsumerStatefulWidget {
  const _ContractDialog({required this.goal});

  final AgentGoalRun goal;

  @override
  ConsumerState<_ContractDialog> createState() => _ContractDialogState();
}

class _ContractDialogState extends ConsumerState<_ContractDialog> {
  late GoalContract? _contract = widget.goal.contract;
  bool _valid = true;
  bool _busy = false;
  String? _error;

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(agentGoalRunRepositoryProvider)
          .setContract(widget.goal.workspaceId, widget.goal.id, _contract);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object catch (e) {
      if (mounted) {
        setState(
          () =>
              _error = dispatchFailureMessage(AppLocalizations.of(context), e),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcDialog(
      title: l10n.goalContractEditTitle,
      maxWidth: 720,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 560),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              GoalContractEditor(
                initial: widget.goal.contract,
                onChanged: (contract, valid) => setState(() {
                  _contract = contract;
                  _valid = valid;
                }),
              ),
              if (_error case final error?) ...[
                const SizedBox(height: AppSpacing.md),
                CcAlert(variant: CcAlertVariant.danger, title: error),
              ],
            ],
          ),
        ),
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.ghost,
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        CcButton(
          loading: _busy,
          onPressed: _valid && !_busy ? _save : null,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// Opens the checker picker for a paused [goal]: any workspace agent but the
/// goal's own, or no separate checker; Save sends `agentGoalRuns.setChecker`.
Future<void> showGoalCheckerDialog(BuildContext context, AgentGoalRun goal) =>
    showCcDialog<void>(
      context: context,
      builder: (_) => _CheckerDialog(goal: goal),
    );

class _CheckerDialog extends ConsumerStatefulWidget {
  const _CheckerDialog({required this.goal});

  final AgentGoalRun goal;

  @override
  ConsumerState<_CheckerDialog> createState() => _CheckerDialogState();
}

class _CheckerDialogState extends ConsumerState<_CheckerDialog> {
  late String? _checker = widget.goal.checkerAgentId;
  bool _busy = false;
  String? _error;

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(agentGoalRunRepositoryProvider)
          .setChecker(widget.goal.workspaceId, widget.goal.id, _checker);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object catch (e) {
      if (mounted) {
        setState(
          () =>
              _error = dispatchFailureMessage(AppLocalizations.of(context), e),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final agents =
        ref.watch(workspaceAgentsProvider(widget.goal.workspaceId)).value ??
        const <Agent>[];
    return CcDialog(
      title: l10n.goalCheckerTitle,
      maxWidth: 520,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          GoalCheckerPicker(
            agents: agents,
            goalAgentId: widget.goal.agentId,
            value: _checker,
            onChanged: (id) => setState(() => _checker = id),
          ),
          if (_error case final error?) ...[
            const SizedBox(height: AppSpacing.md),
            CcAlert(variant: CcAlertVariant.danger, title: error),
          ],
        ],
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.ghost,
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        CcButton(
          loading: _busy,
          onPressed: _busy ? null : _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// Picks who verifies a goal: any of [agents] but [goalAgentId] (when
/// known), or no separate checker, labelled as the weaker choice. One
/// sentence recommends a checker on a different provider from the goal's
/// agent, so the same model does not grade its own work.
class GoalCheckerPicker extends StatelessWidget {
  /// Creates the picker.
  const GoalCheckerPicker({
    super.key,
    required this.agents,
    required this.goalAgentId,
    required this.value,
    required this.onChanged,
  });

  /// The workspace's agents.
  final List<Agent> agents;

  /// The goal's agent, left out of the choices; null when not known.
  final String? goalAgentId;

  /// The chosen checker, or null for none.
  final String? value;

  /// Called with the new choice.
  final ValueChanged<String?> onChanged;

  static const String _none = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    final own = agents.where((a) => a.id == goalAgentId).firstOrNull;
    final choices = [
      for (final a in agents)
        if (a.id != goalAgentId) a,
    ];
    final recommended = own == null
        ? null
        : choices
              .where((a) => agentProviderKey(a) != agentProviderKey(own))
              .firstOrNull
              ?.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CcSelect<String>(
          label: l10n.goalCheckerLabel,
          value: value ?? _none,
          options: [
            CcSelectOption(value: _none, label: l10n.goalCheckerNone),
            for (final a in choices) CcSelectOption(value: a.id, label: a.name),
          ],
          onChanged: (v) => onChanged(v == _none ? null : v),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value == null
              ? l10n.goalCheckerNoneWeaker
              : recommended == null
              ? l10n.goalCheckerRecommendGeneric
              : l10n.goalCheckerRecommend(recommended),
          style: CcTypography.caption.copyWith(color: ds.textSecondary),
        ),
      ],
    );
  }
}

/// Which provider [agent] runs on, as far as the client can tell: the
/// `provider/` prefix of its model id, else its adapter, else its model.
String agentProviderKey(Agent agent) {
  final model = agent.modelId ?? '';
  final slash = model.indexOf('/');
  if (slash > 0) {
    return model.substring(0, slash);
  }
  return agent.adapterId ?? model;
}
