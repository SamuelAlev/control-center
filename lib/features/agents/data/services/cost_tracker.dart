import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/observability_events.dart';
import 'package:control_center/core/domain/repositories/agent_run_log_repository.dart';
import 'package:control_center/core/domain/value_objects/run_cost.dart';

class CostTracker {
  CostTracker({
    required AgentRunLogRepository runLogRepo,
    DomainEventBus? eventBus,
  })  : _runLogRepo = runLogRepo,
        _eventBus = eventBus;

  final AgentRunLogRepository _runLogRepo;
  final DomainEventBus? _eventBus;

  Future<void> recordUsage({
    required String runLogId,
    required int inputTokens,
    required int outputTokens,
    double costPerInputToken = 0.000003,
    double costPerOutputToken = 0.000015,
  }) async {
    final costCents = ((inputTokens * costPerInputToken) +
            (outputTokens * costPerOutputToken)) *
        100;

    final log = await _runLogRepo.getById(runLogId);
    if (log == null) {
      return;
    }

    await _runLogRepo.upsert(
      log.copyWith(
        cost: RunCost(
          inputTokens: inputTokens,
          outputTokens: outputTokens,
          estimatedCostCents: costCents.round(),
        ),
      ),
    );
  }

  Future<int> getMonthlySpendForAgent(String agentId) async {
    final logs = await _runLogRepo.watchAll().first;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    return logs
        .where((l) =>
            l.agentId == agentId &&
            l.startedAt.isAfter(monthStart))
        .fold<int>(0, (sum, l) => sum + l.cost.estimatedCostCents);
  }

  Future<int> getMonthlySpendTotal() async {
    final logs = await _runLogRepo.watchAll().first;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    return logs
        .where((l) => l.startedAt.isAfter(monthStart))
        .fold<int>(0, (sum, l) => sum + l.cost.estimatedCostCents);
  }

  void checkBudget({
    required int spentCents,
    required int budgetCents,
    required String scopeType,
    required String scopeId,
  }) {
    if (budgetCents <= 0) {
      return;
    }

    final percent = (spentCents / budgetCents * 100).round();
    if (percent >= 100) {
      _eventBus?.publish(BudgetThresholdCrossed(
        scopeType: scopeType,
        scopeId: scopeId,
        spentCents: spentCents,
        budgetCents: budgetCents,
        isHardStop: true,
        occurredAt: DateTime.now(),
      ));
    } else if (percent >= 80) {
      _eventBus?.publish(BudgetThresholdCrossed(
        scopeType: scopeType,
        scopeId: scopeId,
        spentCents: spentCents,
        budgetCents: budgetCents,
        isHardStop: false,
        occurredAt: DateTime.now(),
      ));
    }
  }
}
