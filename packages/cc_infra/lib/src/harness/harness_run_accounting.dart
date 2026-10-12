import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show WorkspaceMismatchException;
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/llm_call_record_repository.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/model_routing/domain/entities/model_info.dart';
import 'package:cc_domain/features/observability/domain/harness_call_record_mapping.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// Accounts physical model calls once, persists them in their owning run, and
/// propagates descendant spend to the parent budget without inflating its own
/// run cost. A child rebinds providers instead of inheriting its parent's meter.
class HarnessRunAccounting implements ProviderCallObserver {
  /// Creates a meter whose records and descendants share one workspace.
  HarnessRunAccounting({
    required this.runId,
    required this.workspaceId,
    required DateTime runStartedAt,
    required this.priceLookup,
    this.conversationId,
    this.repository,
    this.runLogRepository,
    this.parent,
    this.onCall,
    DateTime? clockEpoch,
    Stopwatch? clock,
  }) : clockEpoch = clockEpoch ?? DateTime.now(),
       _clock = clock ?? (Stopwatch()..start()),
       ledger = ProviderCallLedger(runId: runId) {
    if (parent != null && parent!.workspaceId != workspaceId) {
      throw const WorkspaceMismatchException(
        'A model-call accounting lineage cannot cross workspaces.',
      );
    }
    _runOffsetMs = this.clockEpoch.difference(runStartedAt).inMilliseconds;
    _hasRunLogPersistence =
        runLogRepository != null || (parent?._hasRunLogPersistence ?? false);
  }

  /// Durable owner of this meter's physical calls.
  final String runId;

  /// Workspace validated by dispatch before constructing the meter.
  final String workspaceId;

  /// Conversation associated with this run, when present.
  final String? conversationId;

  /// Wall-clock origin corresponding to zero on the monotonic clock.
  final DateTime clockEpoch;

  /// Resolves the serving provider/model's rates; missing rates stay unknown.
  final ModelCost? Function(String providerId, String modelId) priceLookup;

  /// Optional durable per-call ledger.
  final LlmCallRecordRepository? repository;

  /// Optional run summaries updated after accounting each physical call.
  final AgentRunLogRepository? runLogRepository;

  /// Ancestor receiving descendant budget spend, never duplicate call rows.
  final HarnessRunAccounting? parent;

  /// Observer invoked after this meter has banked the record.
  final void Function(ProviderCallRecord record)? onCall;

  /// This run's own calls, including its auxiliary requests but not children.
  final ProviderCallLedger ledger;
  final Stopwatch _clock;
  late final bool _hasRunLogPersistence;
  late final int _runOffsetMs;
  Future<void> _writes = Future<void>.value();
  int _ownCostMicros = 0;
  int _subtreeCostMicros = 0;
  int _subtreeBillableTokens = 0;
  int _unpricedCalls = 0;
  CostBasis? _costBasis;

  /// Elapsed time on this meter's monotonic clock.
  int get elapsedMs => _clock.elapsedMilliseconds;

  /// Offset aligning this clock's origin with the enclosing run.
  int get runOffsetMs => _runOffsetMs;

  /// Exact known spend in this run and descendants, for the owning budget.
  int get subtreeCostMicros => _subtreeCostMicros;

  /// Input, cache-write and output tokens charged to the subtree's budget.
  int get subtreeBillableTokens => _subtreeBillableTokens;

  /// Calls with unreported usage or unavailable prices, not known-free calls.
  int get unpricedCalls => _unpricedCalls;

  /// Rebinds every physical target, including lazy failover targets. Removing
  /// an old recorder prevents a child's usage from being attributed to both
  /// the parent and the child when they reuse the same authenticated transport.
  LlmProviderPort observe(
    LlmProviderPort provider, {
    required String providerId,
  }) {
    while (provider is ObservedLlmProvider) {
      provider = provider.delegate;
    }
    if (provider is FallbackProvider) {
      return provider.mapProviders(
        (target, id) => observe(target, providerId: id),
      );
    }
    return ObservedLlmProvider(
      provider,
      observer: this,
      identity: ledger.identity,
      runId: runId,
      providerId: providerId,
      clock: _clock,
      costResolver: (record) {
        final price = priceLookup(record.providerId, record.model);
        if (price == null || !price.isKnown || !record.usageReported) {
          return null;
        }
        final usage = record.usage;
        return ProviderCallCost(
          (price.estimate(
                    inputTokens: usage.inputTokens,
                    outputTokens: usage.outputTokens,
                    cacheReadTokens: usage.cacheReadTokens,
                    cacheWriteTokens: usage.cacheWriteTokens,
                  ) *
                  1000000)
              .round(),
        );
      },
    );
  }

  @override
  void onProviderCall(ProviderCallRecord record) {
    if (!ledger.add(record)) {
      return;
    }
    _ownCostMicros += record.costMicros ?? 0;
    final basis = record.costMicros == null
        ? CostBasis.unknown
        : CostBasis.fromWire(record.costBasis.wire);
    _costBasis = _costBasis == null
        ? basis
        : CostBasis.merge(_costBasis!, basis);
    _recordBudget(record);

    final repo = repository;
    final runs = runLogRepository;
    if (repo != null || _hasRunLogPersistence) {
      final row = repo == null
          ? null
          : record.toDomainLlmCallRecord(
              runStartedAt: clockEpoch,
              runId: runId,
              workspaceId: workspaceId,
              conversationId: conversationId,
            );
      final snapshot = runs == null ? null : cost();
      _writes = _writes.then((_) async {
        if (repo != null && row != null) {
          await _tryPersist('call record', () => repo.upsert(workspaceId, row));
        }
        if (runs != null && snapshot != null) {
          await _tryPersist(
            'own cost',
            () => runs.updateCost(workspaceId, runId, snapshot),
          );
        }
        final micros = record.costMicros;
        if (micros != null && micros > 0) {
          for (
            var ancestor = parent;
            ancestor != null;
            ancestor = ancestor.parent
          ) {
            final owner = ancestor;
            final ancestorRuns = owner.runLogRepository;
            if (ancestorRuns != null) {
              await _tryPersist(
                'descendant cost for ${owner.runId}',
                () => ancestorRuns.addChildCostMicros(
                  workspaceId,
                  owner.runId,
                  micros,
                ),
              );
            }
          }
        }
      });
    }
    try {
      onCall?.call(record);
    } on Object catch (error) {
      CcInfraLog.warning('Model-call observer failed for $runId: $error');
    }
  }

  Future<void> _tryPersist(
    String operation,
    Future<void> Function() write,
  ) async {
    try {
      await write();
    } on Object catch (error) {
      CcInfraLog.warning(
        'Model $operation persistence failed for $runId: $error',
      );
    }
  }

  void _recordBudget(ProviderCallRecord record) {
    _subtreeCostMicros += record.costMicros ?? 0;
    _subtreeBillableTokens += record.billableTokens;
    if (record.costMicros == null) {
      _unpricedCalls++;
    }
    parent?._recordBudget(record);
  }

  /// Own cost only: descendants have their own rows and explicit rollups.
  RunCost cost({int? durationMs}) {
    final usage = ledger.total;
    return RunCost(
      inputTokens: usage.inputTokens,
      outputTokens: usage.outputTokens,
      thoughtTokens: usage.thoughtTokens,
      cachedReadTokens: usage.cacheReadTokens,
      cachedWriteTokens: usage.cacheWriteTokens,
      costMicros: _ownCostMicros,
      estimatedCostCents: (_ownCostMicros / 10000).round(),
      costBasis: _costBasis ?? CostBasis.estimated,
      durationMs: durationMs ?? runOffsetMs + elapsedMs,
    );
  }

  /// Await before the run's terminal event so all observed calls have reached
  /// the persistence boundary, including a final failed/cancelled request.
  Future<void> flush() => _writes;
}
