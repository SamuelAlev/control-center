import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcGoalCard] — a goal objective with a status badge, a
/// token-budget progress bar and elapsed time. A structured "what is this run
/// trying to achieve and how far through its budget" surface.

const _path = '[Components]/Data';

/// The lifecycle states a goal moves through, each with its budget snapshot.
@widgetbook.UseCase(name: 'Lifecycle', type: CcGoalCard, path: _path)
Widget ccGoalCardLifecycleUseCase(BuildContext context) {
  return const Center(
    child: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CcGoalCard(
            objective: 'Migrate auth to the new token broker',
            status: CcGoalStatus.active,
            statusLabel: 'Active',
            tokensUsed: 42000,
            tokenBudget: 200000,
            elapsed: Duration(minutes: 24),
          ),
          SizedBox(height: 12),
          CcGoalCard(
            objective: 'Triage the flaky integration tests',
            status: CcGoalStatus.complete,
            statusLabel: 'Complete',
            tokensUsed: 88000,
            tokenBudget: 100000,
            elapsed: Duration(hours: 1),
          ),
          SizedBox(height: 12),
          CcGoalCard(
            objective: 'Refactor the dispatch pipeline',
            status: CcGoalStatus.budgetLimited,
            statusLabel: 'Budget limited',
            tokensUsed: 100000,
            tokenBudget: 100000,
            elapsed: Duration(hours: 2),
          ),
        ],
      ),
    ),
  );
}

/// Interactive playground.
@widgetbook.UseCase(name: 'Playground', type: CcGoalCard, path: _path)
Widget ccGoalCardPlaygroundUseCase(BuildContext context) {
  final objective = context.knobs.string(
    label: 'Objective',
    initialValue: 'Ship the release candidate',
  );
  final used = context.knobs.int.slider(
    label: 'Tokens used',
    initialValue: 30000,
    min: 0,
    max: 200000,
  );
  final budget = context.knobs.int.slider(
    label: 'Token budget',
    initialValue: 200000,
    min: 0,
    max: 200000,
  );
  final status = context.knobs.object.dropdown<CcGoalStatus>(
    label: 'Status',
    options: CcGoalStatus.values,
    labelBuilder: (s) => s.name,
  );
  return Center(
    child: SizedBox(
      width: 420,
      child: CcGoalCard(
        objective: objective,
        status: status,
        statusLabel: status.name,
        tokensUsed: used,
        tokenBudget: budget,
        elapsed: const Duration(minutes: 18),
      ),
    ),
  );
}
