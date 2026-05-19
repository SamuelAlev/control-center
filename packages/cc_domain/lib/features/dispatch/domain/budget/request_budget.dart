/// Soft per-agent-type request budgets and the runaway guard that enforces
/// them. A "request" is one assistant turn in a run. When an agent crosses its
/// soft budget it receives ONE steering notice asking it to wrap up; at 1.5x
/// the budget the run is aborted gracefully so partial output is salvaged.
///
/// Ported from oh-my-pi `task/executor.ts` (`SOFT_REQUEST_BUDGET`,
/// `buildBudgetNotice`, and the soft-budget steer/abort thresholds).
library;

/// Soft request budget for the `explore` agent type.
const int kExploreRequestBudget = 40;

/// Soft request budget for the `quick_task` agent type.
const int kQuickTaskRequestBudget = 40;

/// Default soft request budget for agent types without an explicit entry.
const int kDefaultRequestBudget = 90;

/// Returns the soft request budget (assistant requests per run) for the given
/// [agentType]. `explore` and `quick_task` get a tighter cap; everything else,
/// including `null`, falls back to [kDefaultRequestBudget].
int softRequestBudgetForAgentType(String? agentType) {
  switch (agentType) {
    case 'explore':
      return kExploreRequestBudget;
    case 'quick_task':
      return kQuickTaskRequestBudget;
    default:
      return kDefaultRequestBudget;
  }
}

/// The action a [RequestBudgetTracker] recommends after recording a request.
enum BudgetDecision {
  /// Stay the course; the budget has not been crossed.
  none,

  /// Inject a one-time steering notice asking the agent to wrap up.
  steer,

  /// Abort the run gracefully to salvage partial output.
  abort,
}

/// Tracks assistant requests within a single run and enforces the soft budget.
///
/// The guard fires [BudgetDecision.steer] exactly once, the first time the
/// request count reaches the soft budget, and [BudgetDecision.abort] once the
/// count reaches 1.5x the budget. A non-positive [softBudget] disables the
/// guard entirely, so [record] always returns [BudgetDecision.none].
class RequestBudgetTracker {
  /// Creates a tracker with an explicit [softBudget]. A value `<= 0` disables
  /// the guard.
  RequestBudgetTracker(this.softBudget);

  /// Creates a tracker whose budget is derived from [agentType] via
  /// [softRequestBudgetForAgentType].
  RequestBudgetTracker.forAgentType(String? agentType)
      : softBudget = softRequestBudgetForAgentType(agentType);

  /// The soft budget in assistant requests. `<= 0` disables the guard.
  final int softBudget;

  int _requests = 0;
  bool _steerSent = false;

  /// The number of requests recorded so far.
  int get requests => _requests;

  /// Records one assistant request and returns the recommended action.
  ///
  /// Returns [BudgetDecision.abort] once the count reaches 1.5x the budget;
  /// otherwise [BudgetDecision.steer] the first time the count reaches the
  /// budget; otherwise [BudgetDecision.none].
  BudgetDecision record() {
    _requests += 1;
    if (softBudget <= 0) {
      return BudgetDecision.none;
    }
    if (_requests >= softBudget * 1.5) {
      return BudgetDecision.abort;
    }
    if (!_steerSent && _requests >= softBudget) {
      _steerSent = true;
      return BudgetDecision.steer;
    }
    return BudgetDecision.none;
  }
}

/// Builds the one-time steering notice injected when an agent crosses its soft
/// request budget. [requests] is the count at the moment of the crossing.
String budgetSteerNotice(int requests) {
  return '[budget notice] You have used $requests requests in this run. '
      'Wrap up now: finish the current step and yield your final report.';
}
