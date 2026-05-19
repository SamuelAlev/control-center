import 'package:cc_domain/features/sandboxing/domain/entities/sandbox_exec_grant.dart';

/// Persistence contract for operator decisions about executing binaries from
/// inside a writable directory tree (see [SandboxExecGrant]).
///
/// Workspace-scoped: every method takes a required `workspaceId`, which is what
/// selects the workspace's database file. There is deliberately no id-only
/// lookup — an id cannot pick a database.
abstract interface class SandboxExecGrantRepository {
  /// Every grant in [workspaceId], newest first.
  Future<List<SandboxExecGrant>> grants(String workspaceId);

  /// Live grants in [workspaceId] (the Settings surface).
  Stream<List<SandboxExecGrant>> watchGrants(String workspaceId);

  /// The decision covering [path], or null when the operator has not been
  /// asked yet. Returns the MOST SPECIFIC (longest) covering grant, so a later
  /// narrow decision wins over an earlier broad one.
  Future<SandboxExecGrant?> decisionFor(String workspaceId, String path);

  /// Records a decision, replacing any existing grant on the same path.
  Future<void> upsert(SandboxExecGrant grant);

  /// Revokes the grant [id] within [workspaceId].
  Future<void> revoke(String workspaceId, String id);
}
