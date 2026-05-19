import 'package:cc_domain/features/guardrails/domain/entities/guard_decision.dart';

/// Persistence port for the tamper-evident authorization audit spine.
///
/// Every method is workspace-scoped — `workspaceId` is required and never
/// optional — because the chain is per workspace (it lives in that
/// workspace's own database file, and an export carries it along).
abstract interface class GuardDecisionRepository {
  /// Appends one decision, allocating its chain position (`seq` + `prevHash`)
  /// and computing its `entryHash` atomically, so two concurrent appends
  /// serialize instead of forking the chain.
  Future<void> append(GuardDecision decision);

  /// The most recent decisions, newest first.
  Future<List<GuardDecision>> recent(
    String workspaceId, {
    int limit = 100,
    int? beforeSeq,
  });

  /// Streams the most recent decisions, newest first.
  Stream<List<GuardDecision>> watchRecent(String workspaceId, {int limit = 100});

  /// Walks the chain from [fromSeq] and re-derives every hash.
  ///
  /// This is the claim an operator can hand an auditor: an intact result means
  /// no row was edited, deleted or reordered since it was written.
  Future<ChainVerification> verifyChain(String workspaceId, {int fromSeq = 1});

  /// Reads a page of the chain in order, for export.
  Future<List<GuardDecision>> pageFrom(
    String workspaceId,
    int fromSeq, {
    int limit = 500,
  });

  /// Export-then-truncate: drops every row at or below [uptoSeq] and writes a
  /// checkpoint carrying the removed segment's terminal hash, so the surviving
  /// chain still verifies back to genesis.
  ///
  /// The audit table is deliberately exempt from age-based retention — a hash
  /// chain cannot be pruned from the middle — so this is the ONLY sanctioned
  /// way to shrink it.
  Future<void> truncateWithCheckpoint(
    String workspaceId, {
    required int uptoSeq,
    required DateTime at,
  });
}
