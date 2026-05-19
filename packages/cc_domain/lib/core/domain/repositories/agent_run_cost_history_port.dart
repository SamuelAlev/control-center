import 'package:cc_domain/features/model_routing/domain/entities/usage.dart';

/// Projected, workspace-scoped read of run COST history.
///
/// Deliberately a narrow port of its own rather than another method on
/// `AgentRunLogRepository`. Two reasons:
///
///  * It is a **projection**, not an entity read — three scalars per run. The
///    spend summary used to derive them by materializing every run log of
///    every workspace (each carrying its serialized prompt context) and
///    filtering in Dart, which is precisely what this exists to avoid; putting
///    it on the entity repository invites the same shape back.
///  * `AgentRunLogRepository` has one production implementation per tier and
///    ~25 test fakes that `implements` it. Widening that interface for a
///    server-only optimization would make every one of those fakes stub a
///    method they never call.
///
/// Only the persistence-backed repository implements it; callers hold it as an
/// optional collaborator and fall back when it is absent.
abstract class AgentRunCostHistoryPort {
  /// Cost-bearing runs in [workspaceId] started at or after [since], newest
  /// first. Runs with no recorded cost are excluded.
  Future<List<UsageCostHistoryEntry>> costHistory(
    String workspaceId,
    DateTime since,
  );
}
