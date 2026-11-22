import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/pipelines/domain/templates/goal_pursue_config.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/dispatch/presentation/widgets/goals/goal_contract_editor.dart';
import 'package:control_center/features/pipelines/presentation/widgets/node_field_label.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter/widgets.dart';

/// The `goal.pursue` node's own fields: the goal's budget (required), its
/// segment cap and deadline (optional), and its contract (the editor the
/// goal page uses). Each field says what is wrong with it in words; the
/// section also says when the node has no agent or no objective, the two
/// fields the panel above holds. Writes into the node's extras
/// (`budgetMicros`, `maxRuns`, `deadlineHours`, `contract`) as
/// [GoalPursueConfig] reads them; an invalid value is not written.
class GoalPursueExtrasSection extends StatefulWidget {
  /// Creates the section for a node whose extras are [extras].
  const GoalPursueExtrasSection({
    super.key,
    required this.extras,
    required this.agentId,
    required this.objective,
    required this.onChanged,
  });

  /// The node's extras as saved.
  final Map<String, dynamic> extras;

  /// The node's agent, if picked.
  final String? agentId;

  /// The node's objective (its prompt), if written.
  final String? objective;

  /// Called with the extras to save.
  final ValueChanged<Map<String, dynamic>> onChanged;

  @override
  State<GoalPursueExtrasSection> createState() =>
      _GoalPursueExtrasSectionState();
}

class _GoalPursueExtrasSectionState extends State<GoalPursueExtrasSection> {
  late final _budget = TextEditingController(
    text: switch (widget.extras['budgetMicros']) {
      final int m when m % 1000000 == 0 => '${m ~/ 1000000}',
      final int m => (m / 1000000).toStringAsFixed(2),
      _ => '',
    },
  );
  late final _maxRuns = TextEditingController(
    text: '${widget.extras['maxRuns'] ?? ''}',
  );
  late final _deadline = TextEditingController(
    text: '${widget.extras['deadlineHours'] ?? ''}',
  );
  late final GoalContract? _contract = _readContract();
  bool _contractValid = true;

  GoalContract? _readContract() {
    try {
      final raw = widget.extras['contract'];
      return raw == null ? null : GoalContract.fromJson(raw);
    } on Object {
      return null;
    }
  }

  @override
  void dispose() {
    _budget.dispose();
    _maxRuns.dispose();
    _deadline.dispose();
    super.dispose();
  }

  int? get _budgetMicros {
    final v = double.tryParse(_budget.text.trim());
    final micros = v == null ? null : (v * 1000000).round();
    return micros != null &&
            micros >= 1 &&
            micros <= GoalPursueConfig.maxBudgetMicros
        ? micros
        : null;
  }

  /// The whole number in [c], null when empty, or -1 when out of 1..[max].
  static int? _optional(TextEditingController c, int max) {
    final t = c.text.trim();
    if (t.isEmpty) {
      return null;
    }
    final v = int.tryParse(t);
    return v != null && v >= 1 && v <= max ? v : -1;
  }

  void _write({GoalContract? contract, bool contractChanged = false}) {
    setState(() {});
    final next = Map<String, dynamic>.from(widget.extras);
    if (_budgetMicros case final b?) {
      next['budgetMicros'] = b;
    }
    for (final (key, ctrl, max) in [
      ('maxRuns', _maxRuns, GoalPursueConfig.maxRunsLimit),
      ('deadlineHours', _deadline, GoalPursueConfig.maxDeadlineHours),
    ]) {
      switch (_optional(ctrl, max)) {
        case null:
          next.remove(key);
        case final v when v > 0:
          next[key] = v;
        default:
          break;
      }
    }
    if (contractChanged && _contractValid) {
      if (contract == null) {
        next.remove('contract');
      } else {
        next['contract'] = contract.toJson();
      }
    }
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    const maxDollars = GoalPursueConfig.maxBudgetMicros ~/ 1000000;
    final missing = [
      if (widget.agentId?.trim().isEmpty ?? true) l10n.goalNodeNeedsAgent,
      if (widget.objective?.trim().isEmpty ?? true) l10n.goalNodeNeedsObjective,
      if (!_contractValid) l10n.goalNodeContractInvalid,
    ];
    Widget number(
      Key key,
      TextEditingController c,
      String label,
      String help,
      String? error, {
      bool decimal = false,
    }) => Padding(
      padding: const EdgeInsetsDirectional.only(top: 12),
      child: NodeFieldLabel(
        label: label,
        description: help,
        child: CcTextField(
          key: key,
          controller: c,
          errorText: error,
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              decimal ? RegExp(r'[0-9.]') : RegExp('[0-9]'),
            ),
          ],
          onChanged: (_) => _write(),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final m in missing)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 8),
            child: Text(
              m,
              style: CcTypography.caption.copyWith(color: ds.danger),
            ),
          ),
        number(
          const ValueKey('goal-node-budget'),
          _budget,
          l10n.goalNodeBudget,
          l10n.goalNodeBudgetHelp,
          _budgetMicros == null ? l10n.goalNodeBudgetRange(maxDollars) : null,
          decimal: true,
        ),
        number(
          const ValueKey('goal-node-max-runs'),
          _maxRuns,
          l10n.goalNodeMaxRuns,
          l10n.goalNodeMaxRunsHelp,
          _optional(_maxRuns, GoalPursueConfig.maxRunsLimit) == -1
              ? l10n.goalNodeRange(GoalPursueConfig.maxRunsLimit)
              : null,
        ),
        number(
          const ValueKey('goal-node-deadline'),
          _deadline,
          l10n.goalNodeDeadline,
          l10n.goalNodeDeadlineHelp,
          _optional(_deadline, GoalPursueConfig.maxDeadlineHours) == -1
              ? l10n.goalNodeRange(GoalPursueConfig.maxDeadlineHours)
              : null,
        ),
        const SizedBox(height: 12),
        NodeFieldLabel(
          label: l10n.goalNodeContract,
          description: l10n.goalNodeContractHelp,
          child: GoalContractEditor(
            initial: _contract,
            onChanged: (contract, valid) {
              _contractValid = valid;
              _write(contract: contract, contractChanged: true);
            },
          ),
        ),
      ],
    );
  }
}
