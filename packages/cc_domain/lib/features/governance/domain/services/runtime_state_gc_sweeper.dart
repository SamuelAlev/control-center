import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/governance/domain/repositories/agent_runtime_state_repository.dart';

/// Reaps runtime-state rows that have been stale for the GC threshold (7 days)
/// across all workspaces. A periodic startup/maintenance job, mirroring the
/// orphan-run reaper.
class RuntimeStateGcSweeper {
  /// Creates a [RuntimeStateGcSweeper].
  RuntimeStateGcSweeper({required AgentRuntimeStateRepository repository})
    : _repository = repository;

  final AgentRuntimeStateRepository _repository;

  static const _tag = 'RuntimeStateGcSweeper';

  /// Deletes every runtime-state row stale enough to garbage-collect. Returns
  /// the number reaped.
  Future<int> sweep({DateTime? now}) async {
    final at = now ?? DateTime.now();
    // CROSS-WORKSPACE BY DESIGN — a global maintenance sweep over every
    // workspace's stale runtime rows.
    final all = await _repository.listAll();
    var reaped = 0;
    for (final state in all) {
      if (!state.isReadyForGcAt(at)) {
        continue;
      }
      try {
        await _repository.delete(state.workspaceId, state.agentId);
        reaped++;
      } on Object catch (e, st) {
        CcDomainLog.error(
          '$_tag: failed to reap runtime state for ${state.agentId}',
          e,
          st,
        );
      }
    }
    if (reaped > 0) {
      CcDomainLog.info('$_tag: reaped $reaped stale runtime state row(s)');
    }
    return reaped;
  }
}
