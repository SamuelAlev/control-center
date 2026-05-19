import 'package:cc_rpc/cc_rpc.dart';

/// Drives the host's orchestration EXECUTOR (approve / cancel a proposal) over
/// the RPC client — the thin-client orchestration-action path.
///
/// Forwards to the host's `orchestration.approve` / `orchestration.cancel` ops.
/// Approving hires agents, creates teams, and starts pipelines (cancel does the
/// inverse) via the concrete engine + use-cases, so it runs SERVER-SIDE — wired
/// only by a host that owns the engine (the desktop in-process host). Against a
/// HEADLESS server (which omits these ops) the calls fail loudly; the web client
/// then surfaces an honest "orchestration runs on the server host" state.
///
/// Carries no `workspace_id`: both ops are workspace-scoped, so the host injects
/// the authoritative bound workspace per session and the use-cases re-validate
/// the orchestration belongs to it (the workspace-isolation invariant).
class RemoteOrchestrationActions {
  /// Creates a [RemoteOrchestrationActions] over [_client].
  RemoteOrchestrationActions(this._client);

  final RemoteRpcClient _client;

  /// Approves [orchestrationId] and kicks off materialization (server-side).
  Future<void> approve(String orchestrationId) => _client.call(
    'orchestration.approve',
    {'orchestration_id': orchestrationId},
  );

  /// Cancels (rejects) a proposal or a running orchestration (server-side).
  Future<void> cancel(String orchestrationId) => _client.call(
    'orchestration.cancel',
    {'orchestration_id': orchestrationId},
  );
}
