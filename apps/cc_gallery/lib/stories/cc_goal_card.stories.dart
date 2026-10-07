import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_goal_card.stories.g.dart';

/// Stories for [CcGoalCard] — a goal objective with a status badge, a
/// token-budget progress bar and elapsed time. A structured "what is this run
/// trying to achieve and how far through its budget" surface.

const _path = '[Components]/Data';

const component = ComponentMeta(name: 'CcGoalCard', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcGoalCardPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    objective: StringArg('Ship the release candidate', name: 'Objective'),
    used: IntArg(
      30000,
      name: 'Tokens used',
      style: const SliderIntArgStyle(min: 0, max: 200000, divisions: 100),
    ),
    budget: IntArg(
      200000,
      name: 'Token budget',
      style: const SliderIntArgStyle(min: 0, max: 200000, divisions: 100),
    ),
    status: EnumArg<CcGoalStatus>(
      CcGoalStatus.values.first,
      name: 'Status',
      values: CcGoalStatus.values,
    ),
  ),
  builder: (context, args) => Showcase.playground(
    (context) => ccGoalCardPlaygroundStory(context, args),
  ),
);

final $Lifecycle = _Story(args: _Args.fixed(preview: ccGoalCardLifecycleStory));

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcGoalCardPlayground {
  CcGoalCardPlayground({
    required this.objective,
    required this.used,
    required this.budget,
    required this.status,
  });

  final String objective;
  final int used;
  final int budget;
  final CcGoalStatus status;
}

/// The lifecycle states a goal moves through, each with its budget snapshot.
Widget ccGoalCardLifecycleStory(BuildContext context) {
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
Widget ccGoalCardPlaygroundStory(
  BuildContext context,
  CcGoalCardPlaygroundArgs args,
) {
  final objective = args.objective;
  final used = args.used;
  final budget = args.budget;
  final status = args.status;
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
